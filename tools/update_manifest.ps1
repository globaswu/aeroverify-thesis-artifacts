[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$packageRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$textExtensions = @('.md', '.m', '.py', '.tex', '.ps1', '.json', '.csv', '.txt', '.yml', '.cff')
$utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)

function Get-PortableBytes {
    param([System.IO.FileInfo]$File)
    $isText = $textExtensions -contains $File.Extension.ToLowerInvariant() -or
        $File.Name -in @('.gitignore', '.gitattributes')
    if (-not $isText) {
        return ,([System.IO.File]::ReadAllBytes($File.FullName))
    }
    $content = [System.IO.File]::ReadAllText($File.FullName)
    $normalized = $content -replace "`r`n?", "`n"
    return ,($utf8WithoutBom.GetBytes($normalized))
}

function Get-Sha256Hex {
    param([byte[]]$Bytes)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $algorithm.ComputeHash($Bytes)
    }
    finally {
        $algorithm.Dispose()
    }
    return (($hash | ForEach-Object { $_.ToString('x2') }) -join '')
}

function Get-SourceDescription {
    param([string]$RelativePath)
    switch -Regex ($RelativePath) {
        '^data/fcc/' { return 'finalized FCC public export' }
        '^data/bcc/' { return 'finalized BCC public export' }
        '^data/sc/' { return 'finalized SC public export' }
        '^data/planform/' { return 'aeroverify/artifacts/planform_continuation_final_20260815' }
        '^data/multiinput/evaluations_' { return 'finalized 100-case progress and mass tables joined on case index' }
        '^data/multiinput/' { return 'aeroverify/artifacts/thesis_chapter6_cases001_100_meshprovenance_20260819' }
        '^data/mesh_convergence/' { return 'aeroverify/artifacts/mesh_convergence path-free projection' }
        '^data/diagnostics/fcc_case067/' { return 'aeroverify/artifacts/case067_sol145_mkaero_diagnostic_20260805' }
        '^data/flutter/' { return 'sanitized projection of the guarded final SOL 145 rerun ledger' }
        '^data/representative_physics/' { return 'aeroverify/artifacts/thesis_representative_physics' }
        '^data/benchmarks/seven_solver_comparison/' { return 'completed seven-problem seven-solver comparison, 150 observations per trajectory' }
        '^data/figures/' { return 'standalone figure data and scripts indexed by the current thesis figure number' }
        '^data/tables/chapter05/' { return 'completed topology comparison and selected localized stress observations' }
        '^matlab/\+ctsemo/' { return 'globaswu/cTSEMO v0.2.1 modular package' }
        '^matlab/cTSEMO\.m$' { return 'globaswu/cTSEMO v0.2.1 src/cTSEMO.m' }
        '^matlab/cTSEMOOptions\.m$' { return 'globaswu/cTSEMO v0.2.1 src/cTSEMOOptions.m' }
        '^LICENSE-CTSEMO\.txt$' { return 'globaswu/cTSEMO v0.2.1 LICENSE' }
        default { return 'authored for the curated public release' }
    }
}

$entries = [System.Collections.Generic.List[object]]::new()
foreach ($file in Get-ChildItem -LiteralPath $packageRoot -Recurse -File) {
    $relative = $file.FullName.Substring($packageRoot.Length + 1).Replace('\', '/')
    if ($relative -eq 'manifest.json' -or $relative -eq '.git' -or
            $relative.StartsWith('.git/', [System.StringComparison]::OrdinalIgnoreCase) -or
            $relative.StartsWith('generated/', [System.StringComparison]::OrdinalIgnoreCase) -or
            $relative.StartsWith('test-output/', [System.StringComparison]::OrdinalIgnoreCase) -or
            $relative.StartsWith('tmp/', [System.StringComparison]::OrdinalIgnoreCase)) {
        continue
    }
    [byte[]]$portableBytes = Get-PortableBytes -File $file
    $entries.Add([ordered]@{
        path = $relative
        size_bytes = [int64]$portableBytes.LongLength
        sha256 = Get-Sha256Hex -Bytes $portableBytes
        source = Get-SourceDescription -RelativePath $relative
    })
}

$manifest = [ordered]@{
    schema_version = 2
    release_tag = 'thesis'
    scope = 'curated solver-free thesis reproduction package'
    files = @($entries | Sort-Object path)
}
$json = ($manifest | ConvertTo-Json -Depth 6) -replace "`r`n", "`n"
[System.IO.File]::WriteAllText(
    (Join-Path $packageRoot 'manifest.json'), $json + "`n", $utf8WithoutBom)
Write-Output ("Manifest updated with {0} files." -f $entries.Count)
