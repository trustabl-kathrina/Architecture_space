# Fix approach README links to use 05.SS.TT.NN_Topic.md pattern.
$root = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "docs\04_Data_Modeling_Architecture"
Get-ChildItem $root -Recurse -Filter "README.md" -File | ForEach-Object {
    $dir = $_.Directory
    if ($dir.Name -notmatch '^\d+\.\d+\.\d+_') { return }
    $prefix = ($dir.Name -split '_', 2)[0]
    $topics = Get-ChildItem $dir -Filter "${prefix}.*_*.md" -File | Sort-Object Name
    if ($topics.Count -eq 0) { return }
    $text = [IO.File]::ReadAllText($_.FullName)
    if ($text -notmatch '(?s)^---\s*\r?\n(.*?)\r?\n---\s*\r?\n?(.*)$') { return }
    $fm = $Matches[1]
    $title = if ($dir.Name -match '^\d+\.\d+\.\d+_(.+)$') { $Matches[1] -replace '_', ' ' } else { $dir.Name }
    $lines = @(
        '---', $fm, '---', '', "# $title", '', '## Topics', ''
    )
    foreach ($t in $topics) {
        $name = $t.BaseName -replace "^${prefix}\.", '' -replace '^\d+_', '' -replace '_', ' '
        $lines += "- [$name]($($t.Name))"
    }
    [IO.File]::WriteAllText($_.FullName, ($lines -join "`n").TrimEnd() + "`n", [Text.UTF8Encoding]::new($false))
}
Write-Host "Fixed approach README links."
