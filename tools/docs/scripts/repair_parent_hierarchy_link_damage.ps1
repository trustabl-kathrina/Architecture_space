# Repair cross-prefix corruption from global numeric replacement during parent hierarchy migration
param([switch]$DryRun)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$Roots = @(
    (Join-Path $RepoRoot "docs"),
    (Join-Path $RepoRoot "code")
)

$Replacements = @(
    @{ Old = '02.00.08.10.'; New = '02.01.02.' }
    @{ Old = '02.00.10.'; New = '02.01.02.' }
    @{ Old = '00.08.10.'; New = '00.10.' }
    @{ Old = '08.08.10.'; New = '08.10.' }
    @{ Old = '11.11.11.12.'; New = '11.12.' }
    @{ Old = '08.08_Analytics_Architecture/08.08_Analytics_Architecture/'; New = '' }
    @{ Old = '08.08_Analytics_Architecture\08.08_Analytics_Architecture/'; New = '' }
    @{ Old = '11.11_AI_Data_Architecture\11.11_AI_Data_Architecture/11.11_AI_Data_Architecture\11.11_AI_Data_Architecture/11.11_AI_Data_Architecture\11.11_AI_Data_Architecture/'; New = '' }
    @{ Old = '11.11_AI_Data_Architecture\11.11_AI_Data_Architecture/11.11_AI_Data_Architecture\11.11_AI_Data_Architecture/'; New = '' }
    @{ Old = '11.11_AI_Data_Architecture\11.11_AI_Data_Architecture/'; New = '' }
    @{ Old = '11.11_AI_Data_Architecture/11.11_AI_Data_Architecture/'; New = '' }
)

$fixed = 0
foreach ($root in $Roots) {
    if (-not (Test-Path $root)) { continue }
    Get-ChildItem $root -Recurse -Include *.md,*.yaml,*.yml,*.ps1 | ForEach-Object {
        if ($_.Name -eq 'repair_parent_hierarchy_link_damage.ps1') { return }
        $text = [IO.File]::ReadAllText($_.FullName)
        $orig = $text
        foreach ($r in $Replacements) {
            if ([string]::IsNullOrEmpty($r.Old)) { continue }
            $text = $text.Replace($r.Old, $r.New)
        }
        $text = [regex]::Replace($text, '(docs/[^`\s\)"'']+)\\', { $args[0].Value.Replace('\', '/') })
        if ($text -ne $orig) {
            if (-not $DryRun) {
                [IO.File]::WriteAllText($_.FullName, $text, [Text.UTF8Encoding]::new($false))
            }
            $fixed++
            Write-Host "Fixed: $($_.FullName.Substring($RepoRoot.Length + 1))"
        }
    }
}
Write-Host "Repaired $fixed files"
