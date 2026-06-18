# Replace legacy flat section numbers (03,07,09,10,12) with hierarchical IDs in prose and metadata.
param([switch]$DryRun)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$Roots = @(
    (Join-Path $RepoRoot "docs"),
    (Join-Path $RepoRoot "code")
)

# Order matters: longer / more specific patterns first
$Replacements = @(
    @{ Pattern = '(?i)\bsection 09 consolidation\b'; Replacement = '02.01.02 streaming consolidation' }
    @{ Pattern = '(?i)\bsection 09 event and streaming architecture\b'; Replacement = '02.01.02 Streaming and Streaming Architecture' }
    @{ Pattern = '(?i)\bsection 09 event\b'; Replacement = '02.01.02 Streaming' }
    @{ Pattern = '(?i)\bsection 09\b'; Replacement = '02.07' }
    @{ Pattern = '(?i)\bsection 10\b'; Replacement = '08.10' }
    @{ Pattern = '(?i)\bsection 12\b'; Replacement = '11.12' }
    @{ Pattern = '(?i)\bsection 07\.(\d{2})\b'; Replacement = '00.10.$1' }
    @{ Pattern = '(?i)\bsection 07\b'; Replacement = '00.10' }
    @{ Pattern = '(?i)\bsection 03\b'; Replacement = '02.06' }
    @{ Pattern = '(?i)\bsection 08\.03\b'; Replacement = '08.10' }
    @{ Pattern = '\| 09 \|'; Replacement = '| 02.01.02 |' }
    @{ Pattern = '\| 10 \| Data Storage'; Replacement = '| 02.06 | Data Storage' }
    @{ Pattern = '\| 07 \| Data Governance'; Replacement = '| 00.10 | Data Governance' }
    @{ Pattern = '\| 10 \| Real-Time Analytics'; Replacement = '| 08.10 | Real-Time Analytics' }
    @{ Pattern = '\| 12 \| Agentic AI'; Replacement = '| 11.12 | Agentic AI' }
    @{ Pattern = '\| 03 \| Data Storage'; Replacement = '| 02.06 | Data Storage' }
    @{ Pattern = 'Streaming / events \| 09 \|'; Replacement = 'Streaming / events | 02.01.02 |' }
    @{ Pattern = 'Real-time OLAP \| 10 \|'; Replacement = 'Real-time OLAP | 08.10 |' }
    @{ Pattern = 'RAG / vectors \| 11\.03, 11\.07 \| 12'; Replacement = 'RAG / vectors | 11.03, 11.07 | 11.12' }
    @{ Pattern = 'merge into section 10'; Replacement = 'merge into 08.10' }
    @{ Pattern = 'canonical in section 12'; Replacement = 'canonical in 11.12' }
    @{ Pattern = 'Agent protocols canonical in section 12'; Replacement = 'Agent protocols canonical in 11.12' }
    @{ Pattern = 'Real-time engines canonical in section 10'; Replacement = 'Real-time engines canonical in 08.10' }
    @{ Pattern = 'Legacy section numbers \*\*03, 07, 09, 10, 12\*\*'; Replacement = 'Nested domain IDs **00.10, 02.06, 02.07, 08.10, 11.12**' }
    @{ Pattern = 'Legacy section numbers \(03, 07, 09, 10, 12\)'; Replacement = 'hierarchical domain IDs (00.10, 02.06, 02.07, 08.10, 11.12)' }
    @{ Pattern = 'Navigation tables retain legacy numbers 03, 07, 09, 10, 12.*'; Replacement = 'All levels use hierarchical IDs (e.g. 02.01.02.01.01) aligned with folder names.' }
    @{ Pattern = 'section: "12"'; Replacement = 'section: "11.12"' }
    @{ Pattern = 'id: "03"'; Replacement = 'id: "02.06"' }
    @{ Pattern = 'id: "07"'; Replacement = 'id: "00.10"' }
    @{ Pattern = 'id: "09"'; Replacement = 'id: "02.01.02"' }
    @{ Pattern = 'id: "10"'; Replacement = 'id: "08.10"' }
    @{ Pattern = 'id: "12"'; Replacement = 'id: "11.12"' }
)

$fixed = 0
foreach ($root in $Roots) {
    if (-not (Test-Path $root)) { continue }
    Get-ChildItem $root -Recurse -Include *.md,*.yaml,*.yml,*.ps1 | ForEach-Object {
        if ($_.Name -in @('update_hierarchical_section_numbers.ps1')) { return }
        $text = [IO.File]::ReadAllText($_.FullName)
        $orig = $text
        foreach ($r in $Replacements) {
            $text = [regex]::Replace($text, $r.Pattern, $r.Replacement)
        }
        if ($text -ne $orig) {
            if (-not $DryRun) {
                [IO.File]::WriteAllText($_.FullName, $text, [Text.UTF8Encoding]::new($false))
            }
            $fixed++
        }
    }
}
Write-Host "Updated hierarchical section references in $fixed files"
