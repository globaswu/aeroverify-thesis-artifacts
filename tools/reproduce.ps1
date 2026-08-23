[CmdletBinding()]
param(
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
$packageRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $packageRoot 'generated'
}

& (Join-Path $PSScriptRoot 'verify_manifest.ps1')
Push-Location -LiteralPath $packageRoot
try {
    & matlab -batch "addpath('matlab'); run_tests"
    if ($LASTEXITCODE -ne 0) {
        throw "MATLAB tests failed with exit code $LASTEXITCODE"
    }
    $matlabOutput = $OutputDirectory.Replace("'", "''")
    & matlab -batch "addpath('matlab'); reproduce_all('$matlabOutput')"
    if ($LASTEXITCODE -ne 0) {
        throw "MATLAB reproduction failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

Write-Output "Reproduction completed: $OutputDirectory"
