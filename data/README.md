# Data Dictionary

All data are comma-separated UTF-8 text with one header row. No column contains
a local filesystem path, remote archive path, credential, or raw solver array.

## Evaluation tables

`fcc/evaluations_cases001_071.csv` and
`bcc/evaluations_cases001_071.csv` contain:

| Column | Meaning |
|---|---|
| `case_id` | Case index, contiguous from 1 through 71. |
| `a_m` | Cell size [m]. |
| `t1_over_a` | Thickness-to-cell-size ratio [-]. |
| `mass_kg` | Two-wing total mass [kg]. |
| `compliance_Nm` | Two-wing trim compliance [N m]. |
| `constraint` | Stored aggregate constraint label; values at or below zero are feasible. |
| `feasible` | Logical value derived from `constraint <= 0`. |
| `pareto_case071` | Feasible finite-sample Pareto membership after case 71. |
| `evaluation_period` | `initial_training` for cases 1--51 or `revised_continuation` for cases 52--71. |
| `evidence_role` | Initial rows are `conditioning_only`; continuation rows are `revised_solver_assessment`. |

The initial rows were generated under improper or incorrect solver settings.
Their objectives and labels are preserved as inherited training state, not as
evidence of revised-solver performance.

## Continuation tables

`fcc/continuation_cases052_071.csv` and
`bcc/continuation_cases052_071.csv` add:

| Column | Meaning |
|---|---|
| `max_stress_MPa` | Stored governing stress metric [MPa]. |
| `stress_limit_MPa` | Applied stress limit [MPa]. |
| `stress_ok` | Stored stress-screen result. |
| `max_flutter_damping` | Maximum stored SOL 145 damping value over checked modes and speeds. |
| `flutter_ok` | Contemporaneous flutter-screen result. |
| `trim_ok` | Stored trim-range result. |
| `simulation_ok` | Stored simulation-completion result. |
| `feasibility_result` | Compact reason string derived from failed component checks. |
| `selection_source` | Saved candidate source: `primary` or `challenger`. |
| `fallback_used` | Whether the explicit fallback selector was used. |
| `selected_acquisition` | Acquisition score of the selected candidate. |
| `primary_acquisition` | Maximum saved primary-pool acquisition score. |
| `challenger_acquisition` | Maximum saved challenger-pool acquisition score. |
| `flutter_screen` | Identifier for the contemporaneous flutter rule. |

FCC and BCC `flutter_ok` values are not directly interchangeable. FCC used the
historical four-point MKAERO1 setup and contemporaneous classifier. BCC used
the revised strict rule that fails any detected positive damping value.

