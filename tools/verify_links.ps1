[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$urls = @(
    'https://github.com/globaswu/aeroverify-thesis-artifacts/releases/tag/thesis-v1.0.0',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.0/README.md',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.0/manifest.json',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.0/matlab/reproduce_all.m',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.0/data/planform/evaluations_cases001_050.csv',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.0/data/multiinput/evaluations_cases001_100.csv',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.0/data/mesh_convergence/results_summary.csv'
)

foreach ($url in $urls) {
    $response = Invoke-WebRequest -Uri $url -Method Get -MaximumRedirection 5
    if ($response.StatusCode -lt 200 -or $response.StatusCode -ge 400) {
        throw "Link check failed ($($response.StatusCode)): $url"
    }
    Write-Output "OK $($response.StatusCode) $url"
}
