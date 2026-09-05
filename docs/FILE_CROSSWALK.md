# Thesis-to-repository file crosswalk

All thesis-artifact links below resolve through the stable `thesis` tag.

| Thesis material | Public entry point | Public evidence |
|---|---|---|
| Release identity and integrity | [`tools/verify_manifest.ps1`](../tools/verify_manifest.ps1) | [`manifest.json`](../manifest.json) |
| Exact plotted data for thesis figures | [`docs/FIGURE_DATA_MAP.md`](FIGURE_DATA_MAP.md) | [`data/figures`](../data/figures) |
| cTSEMO implementation and Chapter 3 | [`matlab/cTSEMO.m`](../matlab/cTSEMO.m), [`matlab/+ctsemo/`](../matlab/+ctsemo/) | [canonical cTSEMO v0.2.1 release](https://github.com/globaswu/cTSEMO/releases/tag/v0.2.1), [result map](https://github.com/globaswu/cTSEMO/blob/v0.2.1/docs/RESULTS_MAP.md) |
| Seven-solver comparison in Chapter 3 | [benchmark guide](../experiments/seven_solver_comparison/README.md), [Figure 3.7](../data/figures/chapter03/figure_3_7), [Figure 3.8](../data/figures/chapter03/figure_3_8) | [HV-ratio table](../data/benchmarks/seven_solver_comparison/hv_ratio_table.csv), [X/Y/C evaluations](../data/benchmarks/seven_solver_comparison/evaluations.csv), [observed Pareto points](../data/benchmarks/seven_solver_comparison/observed_pareto.csv) |
| FCC/BCC/SC lattice studies | [`matlab/reproduce_topology.m`](../matlab/reproduce_topology.m) | [`data/fcc`](../data/fcc), [`data/bcc`](../data/bcc), [`data/sc`](../data/sc) |
| Fixed-area planform | [`matlab/reproduce_planform.m`](../matlab/reproduce_planform.m) | [`data/planform`](../data/planform) |
| Four-input campaign | [`matlab/reproduce_multiinput.m`](../matlab/reproduce_multiinput.m) | [`data/multiinput`](../data/multiinput) |
| Structural-mesh sensitivity | [`matlab/reproduce_mesh_convergence.m`](../matlab/reproduce_mesh_convergence.m) | [`data/mesh_convergence`](../data/mesh_convergence) |
| FCC case-67 MKAERO1 diagnostic | [`matlab/reproduce_case067_flutter.m`](../matlab/reproduce_case067_flutter.m) | [`data/diagnostics/fcc_case067`](../data/diagnostics/fcc_case067) |
| nTop mode-shape screenshots in Figure 2.8 | [point-cloud plotting scripts](../data/figures/chapter02/figure_2_8) | [reference nodes and modal displacements](../data/figures/chapter02/figure_2_8/figure_2_8.csv) |
| Harmonized topology SOL 145 reassessment | [`matlab/reproduce_flutter_reassessment.m`](../matlab/reproduce_flutter_reassessment.m) | [`data/flutter/harmonized_sol145_results.csv`](../data/flutter/harmonized_sol145_results.csv) |
| Exact-trim and representative physics | [`matlab/reproduce_representative_physics.m`](../matlab/reproduce_representative_physics.m) | [`data/representative_physics`](../data/representative_physics) |
| New coupled evaluations | [`docs/FULL_SOLVER_WORKFLOW.md`](FULL_SOLVER_WORKFLOW.md) | external licensed assets required |

The thesis captions and appendices link to the corresponding public data and
scripts. The [figure index](FIGURE_DATA_MAP.md) is the numbering crosswalk for
all 53 packages in the revised manuscript.
