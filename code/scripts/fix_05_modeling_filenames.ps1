$root = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "docs\04_Data_Modeling_Architecture"
$n = 0
Get-ChildItem $root -Recurse -Filter '*.md' -File | ForEach-Object {
    if ($_.Name -match '^(\d+\.\d+\.\d+)_[^.]+\.(\d{2})_(.+)$') {
        $newName = "$($Matches[1]).$($Matches[2])_$($Matches[3])"
        if ($_.Name -ne $newName) {
            Rename-Item -LiteralPath $_.FullName -NewName $newName
            $n++
        }
    }
}
Write-Host "Renamed $n files"
