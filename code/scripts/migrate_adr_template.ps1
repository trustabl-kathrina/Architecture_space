# Migrate stub ADR files from evaluation template to ADR template format
$ErrorActionPreference = "Stop"
$DocsRoot = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "docs"

$adrTemplate = @'
# {TITLE}

## Status

Proposed

## Date

2026-06-18

## Context

This decision addresses a significant architecture choice in {SECTION}. Document the driver, constraints, and stakeholders.

## Decision

Record the chosen approach after architecture review. Replace this placeholder with the approved decision.

## Consequences

### Positive

- TBD

### Negative

- TBD

## Alternatives considered

| Alternative | Why not chosen |
| --- | --- |
| TBD | TBD |

## Related

- [Section README]({README})
'@

$count = 0
Get-ChildItem -Path $DocsRoot -Recurse -Filter "ADR_*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $text = Get-Content -Path $_.FullName -Raw -Encoding UTF8
    if ($text -notmatch 'Vendor A') { return }
    $rel = $_.FullName.Substring($DocsRoot.Length + 1)
    $parts = $rel -split '\\'
    $sectionDir = $parts[0]
    $subDir = ($parts | Where-Object { $_ -match '^\d{2}\.\d{2}_' } | Select-Object -First 1)
    $sectionId = if ($subDir) { ($subDir -split '_')[0] } else { ($sectionDir -split '_')[0] }
    $title = $_.BaseName -replace '_', ' '
    $body = $adrTemplate -replace '\{TITLE\}', $title -replace '\{SECTION\}', $sectionId -replace '\{README\}', '../README.md'
    if ($text -match '(?s)^(---\s*\r?\n.*?\r?\n---\s*\r?\n)') {
        $fm = $Matches[1] -replace 'template: evaluation', 'template: adr' -replace 'status: stub', 'status: draft'
        $newText = $fm + $body
        [IO.File]::WriteAllText($_.FullName, $newText + "`n", [Text.UTF8Encoding]::new($false))
        $count++
    }
}

Write-Host "Migrated $count ADR files to ADR template."
