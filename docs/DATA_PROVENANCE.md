# Data provenance

The paths below identify source material inside the private research workspace
without exposing a user profile, machine path, network share, or license host.
Public filenames are timestamp-free and stable.

| Public path | Private source record | Transformation |
|---|---|---|
| `data/fcc/` | finalized FCC continuation and observed-front exports | normalized columns; bulky nested records omitted |
| `data/bcc/` | finalized BCC continuation and observed-front exports | normalized columns; bulky nested records omitted |
| `data/sc/` | finalized SC continuation and observed-front exports | normalized columns; fields absent from the final source remain absent |
| `data/planform/evaluations_cases001_050.csv` | `artifacts/planform_continuation_final_20260815/planform_cases001_050_final.csv` | filename normalized; numerical rows copied |
| `data/planform/summary.json` | `artifacts/planform_continuation_final_20260815/planform_continuation_final_summary.json` | copied |
| `data/multiinput/evaluations_cases001_100.csv` | finalized 100-case progress table joined to the final mass/compliance table | joined on unique case index; error payload and record-path field removed |
| `data/multiinput/` supplemental files | `artifacts/thesis_chapter6_cases001_100_meshprovenance_20260819/` | final path-free CSV/JSON files copied and renamed |
| `data/mesh_convergence/results_summary.csv` | `artifacts/mesh_convergence/mesh_convergence_results_summary.csv` | `LightOutputFile` column removed |
| `data/mesh_convergence/study_plan.csv` | public projection of the final results ledger | label, source case, tolerance, and mesh edge length retained |
| `data/diagnostics/fcc_case067/` | `artifacts/case067_sol145_mkaero_diagnostic_20260805/` | 20-point comparison copied and renamed |
| `data/representative_physics/` | `artifacts/thesis_representative_physics/` | four path-free final tables copied and renamed |

`manifest.json` stores a SHA-256 digest and byte count for every release file
except itself. `experiments.json` records the entry point, inputs, expected
checks, and known limitation for each public experiment.

## Known provenance boundaries

- Topology cases 1-51 predate the final settings. Exact setting-level
  differences are unresolved.
- Planform cases 1-40 lack a fully reconstructed selection history.
- Four-input case 65 is the accepted replacement evaluation; its proposal
  metadata remains from the original selection record.
- Four-input cases 1-64 and 66-70 use the baseline mesh epoch, whereas the
  replacement case 65 and cases 71-100 use the refined epoch.
- Solver-native arrays and commercial project files are intentionally absent.
