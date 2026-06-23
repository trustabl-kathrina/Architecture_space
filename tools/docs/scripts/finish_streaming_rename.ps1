$root = Join-Path $PSScriptRoot "..\..\docs\02_Data_Engineering_Architecture\02.01_Data_Ingestion_Architecture\02.01.02_Streaming"
$root = [IO.Path]::GetFullPath($root)

function To-LongPath([string]$Path) {
    $p = [IO.Path]::GetFullPath($Path)
    if ($p.StartsWith('\\?\')) { return $p }
    if ($p.StartsWith('\\')) { return '\\?\UNC\' + $p.Substring(2) }
    return '\\?\' + $p
}

$n = 0
Get-ChildItem $root -Recurse -Force | Where-Object { $_.Name -match '^02\.07\.' } |
    Sort-Object { $_.FullName.Length } -Descending | ForEach-Object {
    $newName = $_.Name -replace '^02\.07\.', '02.01.02.'
    $dest = Join-Path $_.DirectoryName $newName
    if (Test-Path $dest) { return }
    try {
        if ($_.PSIsContainer) {
            [IO.Directory]::Move((To-LongPath $_.FullName), (To-LongPath $dest))
        } else {
            [IO.File]::Move((To-LongPath $_.FullName), (To-LongPath $dest))
        }
        $n++
    } catch { Write-Warning $_.Exception.Message }
}
Write-Host "Renamed $n remaining 02.07 items"
