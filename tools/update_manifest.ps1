[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$packageRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))

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
        '^data/representative_physics/' { return 'aeroverify/artifacts/thesis_representative_physics' }
        '^matlab/\+ctsemo/' { return 'aeroverify/+ctsemo current modular package' }
        '^matlab/cTSEMOOptions\.m$' { return 'aeroverify/cTSEMOOptions.m' }
        '^LICENSE-CTSEMO\.txt$' { return 'aeroverify/cTSEMO_release_LICENSE.txt' }
        default { return 'authored for the curated public release' }
    }
}

$entries = [System.Collections.Generic.List[object]]::new()
foreach ($file in Get-ChildItem -LiteralPath $packageRoot -Recurse -File) {
    $relative = $file.FullName.Substring($packageRoot.Length + 1).Replace('\', '/')
    if ($relative -eq 'manifest.json' -or
            $relative.StartsWith('.git/', [System.StringComparison]::OrdinalIgnoreCase) -or
            $relative.StartsWith('generated/', [System.StringComparison]::OrdinalIgnoreCase) -or
            $relative.StartsWith('test-output/', [System.StringComparison]::OrdinalIgnoreCase)) {
        continue
    }
    $entries.Add([ordered]@{
        path = $relative
        size_bytes = [int64]$file.Length
        sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        source = Get-SourceDescription -RelativePath $relative
    })
}

$manifest = [ordered]@{
    schema_version = 2
    release_tag = 'thesis-v1.0.0'
    scope = 'curated solver-free thesis reproduction package'
    generated_utc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
    files = @($entries | Sort-Object path)
}
$json = ($manifest | ConvertTo-Json -Depth 6) -replace "`r`n", "`n"
$utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText(
    (Join-Path $packageRoot 'manifest.json'), $json + "`n", $utf8WithoutBom)
Write-Output ("Manifest updated with {0} files." -f $entries.Count)
