# Expected outputs

`reproduce_all` writes beneath the selected output directory:

| Directory | Principal outputs |
|---|---|
| `fcc/`, `bcc/`, `sc/` | observed Pareto PDF/PNG; feasibility-score PDF/PNG; continuation CSV/TeX; summary CSV |
| `planform/` | objective-space PDF/PNG; square design-space PDF/PNG; summary CSV |
| `multiinput/` | observed Pareto, six square normalized pair plots, adaptive history, summary CSV |
| `mesh_convergence/` | primary-metric PDF/PNG; case-64 root-19 PDF/PNG; summary CSV |
| `case067_flutter/` | four-versus-18-point MKAERO1 comparison PDF/PNG; summary CSV |
| `representative_physics/` | exact-trim CDi comparison; representative mass comparison; summary CSV |
| root | `reproduction_summary.csv` |

Expected numerical postconditions are:

- FCC: 71 evaluations, 33 feasible, 26 observed Pareto;
- BCC: 71, 27, 17;
- SC: 71, 32, 8;
- planform: 50, 39, 14;
- four-input: 100, 70, 38;
- mesh convergence: 17 result rows;
- case 67: 20 points and 37 velocity rows summarized per point;
- exact-trim reconstruction: 150 rows;
- representative cases: 4, 37, 64, 65, and 99.

The tests fail if any expected output is missing or empty.
