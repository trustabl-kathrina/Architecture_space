$base = Join-Path $PSScriptRoot "..\..\docs\02_Data_Engineering_Architecture\02.03_Data_Orchestration_Architecture\02.03.04_Architecture_Patterns"
$base = [IO.Path]::GetFullPath($base)
$bell = [char]7
$utf8 = New-Object System.Text.UTF8Encoding $false

Get-ChildItem -Path $base -Recurse -Filter *.md | ForEach-Object {
    $c = [IO.File]::ReadAllText($_.FullName)
    $orig = $c
    $c = $c -replace '(?m)^`mermaid', '```mermaid'
    $c = $c -replace '(?m)^`$', '```'
    $c = $c.Replace("${bell}irflow", 'airflow')
    # UTF-8 mojibake replacements
    $c = $c.Replace([string][char]0x00E2 + [char]0x20AC + [char]0x201C, '-')
    $c = $c.Replace([string][char]0x00E2 + [char]0x20AC + [char]0x201D, '-')
    $c = $c.Replace([string][char]0x00E2 + [char]0x20AC + [char]0x2013, '-')
    $c = $c.Replace([string][char]0x00E2 + [char]0x20AC + [char]0x2014, '-')
    $c = $c.Replace([string][char]0x00E2 + [char]0x0080 + [char]0x0093, '-')
    $c = $c.Replace([string][char]0x00E2 + [char]0x0080 + [char]0x0094, '-')
    $c = $c.Replace([string][char]0x00E2 + [char]0x0080 + [char]0x0099, '->')
    $c = $c.Replace('Retry_And_Idempotency', 'Retry_Strategies')
    # Fix closing mermaid fence (single backtick line)
    $c = $c -replace '(?m)^`$', '```'
    if ($c -ne $orig) {
        [IO.File]::WriteAllText($_.FullName, $c, $utf8)
        Write-Host "Fixed $($_.Name)"
    }
}
Write-Host "Done"
