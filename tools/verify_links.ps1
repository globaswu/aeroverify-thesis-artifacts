[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$urls = @(
    'https://github.com/globaswu/aeroverify-thesis-artifacts/releases/tag/thesis-v1.0.3',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/releases/download/thesis-v1.0.3/main.pdf',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/releases/download/thesis-v1.0.3/paper2_lattice_topology_aiaa.pdf',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/releases/download/thesis-v1.0.3/thesis_reference_verification_report.pdf',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.3/README.md',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.3/QUICKSTART.md',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.3/manifest.json',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.3/matlab/cTSEMO.m',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.3/matlab/reproduce_all.m',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.3/matlab/reproduce_topology.m',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.3/matlab/reproduce_planform.m',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.3/matlab/reproduce_multiinput.m',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.3/matlab/reproduce_mesh_convergence.m',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.3/matlab/reproduce_case067_flutter.m',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.3/matlab/reproduce_flutter_reassessment.m',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.3/matlab/reproduce_representative_physics.m',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.3/data/fcc/evaluations_cases001_071.csv',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.3/data/bcc/evaluations_cases001_071.csv',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.3/data/sc/evaluations_cases001_071.csv',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.3/data/planform/evaluations_cases001_050.csv',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.3/data/multiinput/evaluations_cases001_100.csv',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.3/data/mesh_convergence/results_summary.csv',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.3/data/diagnostics/fcc_case067/old_vs_18_point_all20.csv',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.3/data/flutter/harmonized_sol145_results.csv',
    'https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis-v1.0.3/docs/FULL_SOLVER_WORKFLOW.md',
    'https://github.com/globaswu/cTSEMO/releases/tag/v0.2.1',
    'https://github.com/globaswu/cTSEMO/blob/v0.2.1/docs/REPRODUCING.md',
    'https://github.com/globaswu/cTSEMO/blob/v0.2.1/docs/RESULTS_MAP.md',
    'https://github.com/globaswu/cTSEMO/blob/v0.2.1/manuscript/artifacts/finite_primary_ablation/problem_ga_vs_finite_pool_pf_comparison.csv',
    'https://github.com/globaswu/cTSEMO/blob/v0.2.1/manuscript/artifacts/finite_primary_ablation/reproduce_finite_primary_ablation.m',
    'https://github.com/globaswu/cTSEMO/blob/v0.2.1/manuscript/artifacts/wb150_thesis/generate_wb150_thesis_artifacts.m'
)

foreach ($url in $urls) {
    $response = Invoke-WebRequest -Uri $url -Method Get -MaximumRedirection 5 -UseBasicParsing
    if ($response.StatusCode -lt 200 -or $response.StatusCode -ge 400) {
        throw "Link check failed ($($response.StatusCode)): $url"
    }
    Write-Output "OK $($response.StatusCode) $url"
}
