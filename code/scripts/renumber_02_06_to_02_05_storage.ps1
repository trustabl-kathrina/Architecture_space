# Renumber 02.06 Data Storage Architecture -> 02.05 (final section set under 02).
# Removes placeholder 02.05 Data Reliability from meta references.
param([switch]$DryRun)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$DeRoot = Join-Path $RepoRoot "docs\02_Data_Engineering_Architecture"
$OldSec = Join-Path $DeRoot "02.06_Data_Storage_Architecture"
$NewSec = Join-Path $DeRoot "02.05_Data_Storage_Architecture"

$Stats = @{ renamed_dirs = 0; content_files = 0 }

Write-Host "Phase 1: rename subdirectories (deepest first)"
if (Test-Path $OldSec) {
    Get-ChildItem $OldSec -Directory -Recurse | Sort-Object { $_.FullName.Length } -Descending | ForEach-Object {
        if ($_.Name -match '^02\.06\.') {
            $newName = $_.Name -replace '^02\.06\.', '02.05.'
            if (-not $DryRun) { Rename-Item -LiteralPath $_.FullName -NewName $newName }
            $Stats.renamed_dirs++
            Write-Host "  $($_.Name) -> $newName"
        }
    }
    if (Test-Path $NewSec) { throw "Target already exists: $NewSec" }
    if (-not $DryRun) { Rename-Item -LiteralPath $OldSec -NewName "02.05_Data_Storage_Architecture" }
    $Stats.renamed_dirs++
    Write-Host "  02.06_Data_Storage_Architecture -> 02.05_Data_Storage_Architecture"
} elseif (-not (Test-Path $NewSec)) {
    throw "Neither old nor new storage section found under $DeRoot"
} else {
    Write-Host "  Storage section already at 02.05"
}

Write-Host "Phase 2: update file contents (storage-scoped replacements only)"
$ContentRoots = @(
    (Join-Path $RepoRoot "docs"),
    (Join-Path $RepoRoot "code")
)

# Full-path fragments — safe for global replace (won't match nested streaming IDs)
$LiteralReplacements = @(
    @{ Old = '02.06_Data_Storage_Architecture'; New = '02.05_Data_Storage_Architecture' }
    @{ Old = '02.06.07_Storage_Patterns'; New = '02.05.07_Storage_Patterns' }
    @{ Old = '02.06.06_Analytical_Stores'; New = '02.05.06_Analytical_Stores' }
    @{ Old = '02.06.05_Operational_Data_Store'; New = '02.05.05_Operational_Data_Store' }
    @{ Old = '02.06.04_Data_Marts'; New = '02.05.04_Data_Marts' }
    @{ Old = '02.06.03_Lakehouse'; New = '02.05.03_Lakehouse' }
    @{ Old = '02.06.02_Data_Warehouse'; New = '02.05.02_Data_Warehouse' }
    @{ Old = '02.06.01_Data_Lake'; New = '02.05.01_Data_Lake' }
    @{ Old = '02.05_Data_Reliability_Architecture'; New = '' }
    @{ Old = '| 02.06 | Data Storage'; New = '| 02.05 | Data Storage' }
    @{ Old = '| 02.06 | ↳ Data Storage Architecture'; New = '| 02.05 | ↳ Data Storage Architecture' }
    @{ Old = '## 02.06 — Data Storage Architecture'; New = '## 02.05 — Data Storage Architecture' }
    @{ Old = '# 02.06 Data Storage Architecture'; New = '# 02.05 Data Storage Architecture' }
    @{ Old = '"02.06 Data Storage"'; New = '"02.05 Data Storage"' }
    @{ Old = '02.06 | Data Storage |'; New = '02.05 | Data Storage |' }
    @{ Old = '02.06.04–02.06.05'; New = '02.05.04–02.05.05' }
    @{ Old = '`02.06_*` under 02'; New = '`02.05_*` under 02' }
    @{ Old = 'nested domains (`00.10`, `02.06`, `08.10`, `11.12`)'; New = 'nested domains (`00.10`, `02.05`, `08.10`, `11.12`)' }
    @{ Old = 'Use hierarchical IDs **02.06**, **00.10**'; New = 'Use hierarchical IDs **02.05**, **00.10**' }
    @{ Old = '(incl. `02.06` storage'; New = '(incl. `02.05` storage' }
    @{ Old = '| 03 | **02.06** | 02 Data Engineering | `02_Data_Engineering_Architecture/02.06_Data_Storage_Architecture/` |'; New = '| 03 | **02.05** | 02 Data Engineering | `02_Data_Engineering_Architecture/02.05_Data_Storage_Architecture/` |' }
    @{ Old = 'domain entries use IDs `02.06`, `00.10`'; New = 'domain entries use IDs `02.05`, `00.10`' }
    @{ Old = 'Nested domain IDs **00.10, 02.06, 02.07, 08.10, 11.12**'; New = 'Nested domain IDs **00.10, 02.05, 02.07, 08.10, 11.12**' }
    @{ Old = 'hierarchical domain IDs (00.10, 02.06, 02.07, 08.10, 11.12)'; New = 'hierarchical domain IDs (00.10, 02.05, 02.07, 08.10, 11.12)' }
    @{ Old = '| 10 | Data Storage'; New = '| 02.05 | Data Storage' }
    @{ Old = '| 03 | Data Storage'; New = '| 02.05 | Data Storage' }
)

# Regex replacements — scoped to storage paths / front matter under storage tree
$RegexReplacements = @(
    @{ Pattern = 'section: "02\.06"'; Replacement = 'section: "02.05"' }
    @{ Pattern = '(?<![\d\.])02\.06\.0([1-7])(?![\d\.])'; Replacement = '02.05.0$1' }
    @{ Pattern = '\r?\n\| 02\.05 \| Data Reliability Architecture \|[^\r\n]*'; Replacement = '' }
    @{ Pattern = '\r?\n\s+-\s+02\.05_Data_Reliability_Architecture'; Replacement = '' }
)

foreach ($root in $ContentRoots) {
    if (-not (Test-Path $root)) { continue }
    Get-ChildItem $root -Recurse -Include *.md,*.yaml,*.yml,*.ps1 -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Name -eq 'renumber_02_06_to_02_05_storage.ps1') { return }
        $text = [IO.File]::ReadAllText($_.FullName)
        $orig = $text
        foreach ($r in $LiteralReplacements) {
            $text = $text.Replace($r.Old, $r.New)
        }
        foreach ($r in $RegexReplacements) {
            $text = [regex]::Replace($text, $r.Pattern, $r.Replacement)
        }
        if ($text -ne $orig) {
            if (-not $DryRun) {
                [IO.File]::WriteAllText($_.FullName, $text, [Text.UTF8Encoding]::new($false))
            }
            $Stats.content_files++
        }
    }
}

Write-Host "Phase 3: patch taxonomy domain id for storage"
$TaxonomyPath = Join-Path $RepoRoot "docs\_meta\taxonomy.yaml"
if (Test-Path $TaxonomyPath) {
    $text = [IO.File]::ReadAllText($TaxonomyPath)
    $orig = $text
    # Only the storage domain block (follows 02.01.04, before id "04")
    $text = [regex]::Replace($text,
        '(?s)(  - id: "02\.05"\r?\n    path: 02_Data_Engineering_Architecture/02\.05_Data_Storage_Architecture\r?\n    parent: "02"\r?\n    domain_id: "02\.05")',
        '  - id: "02.05"$0'.Replace('  - id: "02.05"  - id: "02.05"', '  - id: "02.05"'))
    # Simpler: fix duplicate if any, ensure single id/domain_id
    $text = [regex]::Replace($text,
        '(  - id: "02\.05"\r?\n    path: 02_Data_Engineering_Architecture/02\.05_Data_Storage_Architecture\r?\n    parent: "02"\r?\n    domain_id: )"02\.06"',
        '${1}"02.05"')
    $text = $text.Replace('observability, and reliability architecture.', 'observability, and storage architecture.')
    if ($text -ne $orig -and -not $DryRun) {
        [IO.File]::WriteAllText($TaxonomyPath, $text, [Text.UTF8Encoding]::new($false))
        $Stats.content_files++
    }
}

Write-Host "Done. Renamed dirs=$($Stats.renamed_dirs) Content files=$($Stats.content_files)"
if ($DryRun) { Write-Host "(Dry run)" }
