# FCC/BCC/SC cTSEMO Thesis Reproducibility Artifacts

This repository packages the finalized evaluation and continuation data used
to analyze the FCC, BCC, and SC lattice optimization studies. The included
MATLAB workflow reproduces the finite-sample Pareto plots, final binary-label
feasibility-score maps, and continuation tables for FCC and BCC. The completed
SC continuation is supplied as normalized, manifest-verified CSV data.

The shared cTSEMO acquisition and feasibility-field source used for the
continuation runs is also preserved.

Repository: <https://github.com/globaswu/aeroverify-thesis-artifacts>

No Git or GitHub command is required to use the downloaded repository.

## Reporting boundary

Each topology contains 71 evaluated designs:

- Cases 1--51 are an inherited initial dataset generated under improper or
  incorrect solver settings. They are retained only to condition the revised
  surrogate and feasibility models and to provide historical physical context.
  They are not evidence of the revised solver's sampling performance.
- Cases 52--71 are 20 additional evaluations selected by the revised cTSEMO
  implementation. Their finite-sample feasibility and Pareto outcomes provide
  limited evidence of solver behavior from this particular initial state.
- No matched continuation with the same initial dataset, random seed, budget,
  and an alternative acquisition was run. The package therefore does not
  establish a causal performance improvement over the earlier solver or a
  competing method.

Historical surrogate, acquisition, and feasibility figures from the first 51
cases are intentionally excluded.

## Completed SC continuation payload

The SC payload contains the complete 71-case evaluation record and the
finalized cases 52--71 continuation summary:

- 32 of 71 evaluations are feasible, and 8 feasible evaluations belong to the
  final finite-sample Pareto set.
- 14 of the 20 continuation evaluations are feasible; all 8 points on the
  final Pareto set are continuation evaluations.
- The saved candidate sources comprise 12 primary and 8 challenger
  selections. All 20 continuation rows have verified archive markers in the
  finalized source table.

The SC continuation used the revised 18-point MKAERO1 reduced-frequency setup
and the strict classifier under which any detected positive damping value over
the checked modes and speeds is a flutter failure. The finalized public CSVs
do not retain per-case stress values, damping histories, acquisition scores,
or fallback flags. Those fields are therefore not reconstructed or inferred
in this package.

The workspace-specific Python analysis script is not included because it
depends on retained case MAT files and local simulation paths that are outside
this lightweight public package.

## Problem definition

The two design variables are cell size, `a_m`, and thickness ratio,
`t1_over_a`. The sampled domain is:

| Variable | Lower bound | Upper bound | Unit |
|---|---:|---:|---|
| `a_m` | 0.01 | 0.03 | m |
| `t1_over_a` | 0.05 | 0.40 | dimensionless |

Both objectives are minimized:

1. Two-wing total mass, `mass_kg` [kg].
2. Two-wing trim compliance, `compliance_Nm` [N m].

The stored aggregate convention is `constraint <= 0` for feasible and
`constraint > 0` for infeasible. Pareto membership is recomputed only among
stored feasible evaluations.

## Prerequisites

- MATLAB R2025b was used to validate this package. The minimum compatible
  MATLAB release has not been established.
- No external dataset is required for the included plots and tables.
- The full nTopology/Nastran simulation chain is not included.

## Reproduce all figures and tables

Run the following commands from the repository root:

```powershell
matlab -batch "addpath('matlab'); reproduce_all(fullfile(pwd,'generated'))"
```

This creates the currently integrated FCC/BCC outputs:

- `generated/fcc/fcc_observed_pareto.{png,pdf}`
- `generated/fcc/fcc_feasibility_score.{png,pdf}`
- `generated/fcc/fcc_continuation_table.{csv,tex}`
- `generated/fcc/fcc_continuation_summary.csv`
- `generated/bcc/bcc_observed_pareto.{png,pdf}`
- `generated/bcc/bcc_feasibility_score.{png,pdf}`
- `generated/bcc/bcc_continuation_table.{csv,tex}`
- `generated/bcc/bcc_continuation_summary.csv`
- `generated/reproduction_summary.csv`

The SC CSV payload is not yet integrated into `reproduce_all`; it can be
audited directly under `data/sc`. This boundary preserves the existing
FCC/BCC reproduction code while releasing the finalized SC evidence without
adding unavailable scalar diagnostics.

The feasibility maps use a 401 by 401 grid and the included
`ctsemo.fitClippedBinaryPof` and `ctsemo.predictClippedBinaryPof` functions.
The plotted field is a clipped deterministic binary-label geometry score. It
is not an independently calibrated posterior probability.

## Validate the package

Run the numerical and reproduction checks:

```powershell
matlab -batch "addpath('matlab'); run_tests"
```

Verify hashes, file completeness, size limits, and excluded file types:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\verify_manifest.ps1
```

## Repository layout

```text
.
|-- README.md
|-- LICENSE-CTSEMO.txt
|-- manifest.json
|-- config/
|   `-- reproduction_config.json
|-- data/
|   |-- README.md
|   |-- fcc/
|   |   |-- evaluations_cases001_071.csv
|   |   `-- continuation_cases052_071.csv
|   |-- bcc/
|   |   |-- evaluations_cases001_071.csv
|   |   `-- continuation_cases052_071.csv
|   `-- sc/
|       |-- evaluations_cases001_071.csv
|       `-- continuation_cases052_071.csv
|-- matlab/
|   |-- +ctsemo/
|   |-- cTSEMOOptions.m
|   |-- reproduce_all.m
|   |-- reproduce_topology.m
|   |-- plot_observed_pareto.m
|   |-- plot_feasibility_score.m
|   |-- write_continuation_table.m
|   `-- run_tests.m
`-- tools/
    `-- verify_manifest.ps1
```

## Dataset provenance

The evaluation tables are sanitized, column-normalized exports of the retained
71-case FCC, BCC, and SC final analysis tables. The FCC and BCC continuation
tables combine objective and constraint values with retained scalar stress,
flutter, and candidate-selection fields. The SC continuation table contains
only fields present in its finalized public source summary. Filesystem paths
and bulky nested metadata were discarded. `manifest.json` records the
repository-relative internal source mapping and SHA-256 hash for every public
payload file except the manifest itself.

The FCC continuation retains the contemporaneous feasibility labels produced
with its historical four-point MKAERO1 setup and classifier. Positive stored
damping values can therefore coexist with `flutter_ok = 1` in the FCC table.
They must not be reinterpreted as passes under the later strict rule. The BCC
continuation uses the revised rule in which any positive damping over the
checked modes and speeds is a flutter failure. The SC continuation uses that
strict rule with the revised 18-point MKAERO1 reduced-frequency setup; its
public table records the screen identifier but not scalar damping values.

## Limitations

- Solver-native `.op2`, `.f06`, `.h5`, `.ntop`, BDF/DAT inputs, heavy MAT
  files, checkpoints, and full simulation outputs are excluded.
- The package reproduces post-processing from retained scalar results; it
  cannot independently rerun or verify the expensive structural and
  aeroelastic simulations.
- The inherited 51-row datasets have known solver-setting limitations and are
  not suitable for evaluating the revised optimization algorithm.
- The continuation records are one sequential realization per topology. They
  do not provide multi-seed uncertainty or a matched algorithmic benchmark.
- The code license included here is the existing cTSEMO source license. No
  separate data or repository-wide license is asserted by this package.
- The repository is a lightweight post-processing package, not a public copy
  of the complete proprietary simulation workspace.
