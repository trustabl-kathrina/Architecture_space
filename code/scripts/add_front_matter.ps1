# Add YAML front matter to all markdown files under docs/
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$DocsRoot = Join-Path $RepoRoot "docs"
$Today = Get-Date -Format "yyyy-MM-dd"

function Get-SectionId([string]$RelativePath) {
    if ($RelativePath -match '(\\|^)(\d{2}(?:\.\d{2}){0,3})') {
        return $Matches[2]
    }
    if ($RelativePath -match '(\\|^)(\d{2})_') {
        return $Matches[2]
    }
    return "00"
}

function Test-CompleteContent([string]$Body) {
    if ($Body -match 'Vendor A' -and $Body -match 'Vendor B') { return $false }
    if ($Body -match 'Use Case 1\*\*: Description of how this is applied') { return $false }
    $words = ([regex]::Matches($Body, '\w+')).Count
    return $words -gt 400
}

function Get-TemplateType([string]$Path, [string]$Body) {
    $lower = $Path.ToLower()
    $name = [IO.Path]::GetFileName($Path).ToLower()
    if ($lower -match '/adr/' -or $name -like 'adr_*') { return 'adr' }
    if ($name -like 'what_is*') { return 'overview' }
    if ($lower -match '/hubs/' -or $name -like '*_hub.md') { return 'hub' }
    if ($Body -match '## Core Concepts' -or $Body -match '## Expert Concepts') { return 'concept' }
    if ($Body -match '(?m)^## \d+\. ') { return 'evaluation' }
    if ($lower -match '/overview/' -or $Path -match '\\d{2}\.\d{2}_Overview\\') { return 'overview' }
    if ($Body -match 'Vendor A') { return 'evaluation' }
    return 'overview'
}

function Get-Tags([string]$Name) {
    $tags = @()
    $lower = $Name.ToLower()
    if ($lower -match 'rag|retrieval') { $tags += 'rag', 'genai' }
    if ($lower -match 'stream|event') { $tags += 'streaming', 'events' }
    if ($lower -match 'vendor|evaluation') { $tags += 'vendor-evaluation' }
    if ($lower -match 'adr') { $tags += 'adr' }
    if ($tags.Count -eq 0) { return 'tags: []' }
    return "tags: [$($tags -join ', ')]"
}

$updated = 0
$skipped = 0

Get-ChildItem -Path $DocsRoot -Recurse -Filter "*.md" | ForEach-Object {
    $file = $_
    if ($file.Name -eq 'README.md' -and $file.DirectoryName -eq $DocsRoot) { return }

    $text = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    if ($text -match '^---\s*\r?\n' -and -not $Force) {
        $skipped++
        return
    }

    $body = $text
    if ($text -match '^---\s*\r?\n.*?\r?\n---\s*\r?\n') {
        $body = $text.Substring($Matches[0].Length)
    }

    $rel = $file.FullName.Substring($DocsRoot.Length + 1)
    $title = $file.BaseName -replace '_', ' '
    $section = Get-SectionId $rel
    $template = Get-TemplateType $rel $body
    $status = if ($file.Name -eq 'README.md') { 'complete' } elseif (Test-CompleteContent $body) { 'complete' } else { 'stub' }
    $tagLine = Get-Tags $file.Name

    $front = @"
---
title: $title
section: "$section"
status: $status
template: $template
last_reviewed: $Today
owner: architecture-team
$tagLine
---

"@

    [IO.File]::WriteAllText($file.FullName, ($front + $body.TrimStart("`n")), [Text.UTF8Encoding]::new($false))
    $updated++
}

Write-Host "Updated: $updated, Skipped: $skipped"
