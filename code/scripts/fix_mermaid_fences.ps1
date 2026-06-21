$base = Join-Path $PSScriptRoot "..\..\docs\02_Data_Engineering_Architecture\02.03_Data_Orchestration_Architecture\02.03.04_Architecture_Patterns"
$base = [IO.Path]::GetFullPath($base)
$utf8 = New-Object System.Text.UTF8Encoding $false

Get-ChildItem -Path $base -Recurse -Filter *.md | ForEach-Object {
    $lines = [IO.File]::ReadAllLines($_.FullName)
    $changed = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq '`') {
            $lines[$i] = '```'
            $changed = $true
        }
    }
    if ($changed) {
        [IO.File]::WriteAllLines($_.FullName, $lines, $utf8)
        Write-Host "Fixed fences: $($_.Name)"
    }
}

Get-ChildItem -Path $base -Recurse -Filter *.md | ForEach-Object {
    $c = [IO.File]::ReadAllText($_.FullName)
    if ($c -match [char]0x2192 -or $c.Contains([string][char]0x00E2)) {
        $c = $c -replace '\u2192', '->'
        $nc = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding(1252).GetBytes($c))
        if ($nc -ne $c) { $c = $nc }
        [IO.File]::WriteAllText($_.FullName, $c, $utf8)
    }
}
Write-Host "Done"
