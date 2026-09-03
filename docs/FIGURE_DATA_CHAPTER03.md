# Chapter 3 figure data

This directory documents the numerical values plotted in Thesis Figures 3.1--3.13. The reader-facing index is [`figure_data_map.csv`](../data/figures/chapter03/figure_data_map.csv). The exports contain plotted values and marker coordinates, not heavyweight solver output, software logs, machine-specific paths, or execution timestamps.

## Coverage

| Figures | Reader data | Coverage |
| --- | --- | --- |
| 3.1--3.2 | [`fig03_01_02_final_feasibility_fields.csv`](../data/figures/chapter03/fig03_01_02_final_feasibility_fields.csv) | Four final 201-by-201 feasibility fields and their observation overlays for COSSIN1, COSSIN2, BNH, and SRN. |
| 3.3 | [`fig03_03_cossin1_learning.csv`](../data/figures/chapter03/fig03_03_cossin1_learning.csv) | COSSIN1 fields and observation overlays at 20, 30, 40, and 50 evaluations. |
| 3.4 | [`fig03_04_cossin2_learning.csv`](../data/figures/chapter03/fig03_04_cossin2_learning.csv) | COSSIN2 fields and observation overlays at 20, 40, 60, and 80 evaluations. |
| 3.5 | [`fig03_05_cossin2_iteration20_acquisition.csv`](../data/figures/chapter03/fig03_05_cossin2_iteration20_acquisition.csv) | The 201-by-201 feasibility-score, sampled-HVI, direct-product, and final-acquisition fields; 39 observation markers; and the selected point. |
| 3.6 | [`fig03_06_wb150_rep02_evaluations.csv`](../data/figures/chapter03/fig03_06_wb150_rep02_evaluations.csv) | All 150 WB150 replicate-2 evaluations, including the 20-point initial design, 130 sequential evaluations, feasibility state, final Pareto membership, and the evaluation-150 marker. |
| 3.7 | [`fig03_07_highdim_hv_histories.csv`](../data/figures/chapter03/fig03_07_highdim_hv_histories.csv) | Five normalized-hypervolume histories and their pointwise median for each of the seven higher-dimensional problems, from 0 through 130 sequential evaluations. |
| 3.8 | [`fig03_08_wb150_solver_fronts.csv`](../data/figures/chapter03/fig03_08_wb150_solver_fronts.csv) | The 105 solver-owned feasible Pareto points plotted for the seven historical solver implementations. The machine-specific `Source` field in the internal comparison table has deliberately been excluded. |
| 3.9--3.12 | [`fig03_09_12_wb150_conditional_hvi.csv`](../data/figures/chapter03/fig03_09_12_wb150_conditional_hvi.csv) | All four 181-by-121 conditional-survival fields, 121-station profile summaries, and selected-point/support metadata. Filter by `input_index` from 1 to 4 for (h,l,t,b), respectively. |
| 3.13 | [`fig03_13_wb150_hvi_pairwise.csv`](../data/figures/chapter03/fig03_13_wb150_hvi_pairwise.csv) | All 3,750 plotted nodes for the six 25-by-25 pairwise slices. The local copy is byte-identical to the cTSEMO v0.2.1 public record and keeps the CSV-only dispatcher independent of another repository. |

## Schemas and filters

### Figures 3.1--3.4: feasibility fields

The three feasibility-field CSVs have one row per grid node or plotted observation. Use `record_type=grid` for raster/contour fields and `record_type=observation` for the white-circle and red-cross overlays. The final-field file supplies Figures 3.1--3.2; the two problem-specific files supply the four learning milestones in Figures 3.3--3.4.

For every observation row, `normalized_x1` and `normalized_x2` are the two
components of design input X, `objective_y1` and `objective_y2` are the two
components of objective output Y, and `observed_feasible` is the binary label
C. The objective values are retained for auditability but are not inputs to the
binary-feasibility-field fit. Grid rows leave the Y columns blank because they
are diagnostic query locations rather than expensive evaluations.

The classification code is:

- `0`: correctly classified violating point;
- `1`: false-feasible classification;
- `2`: false-infeasible classification;
- `3`: correctly classified feasible point.

Across the final-field and two learning-history files there are 485,362 data
rows: 484,812 grid rows and 550 observation rows. `NaN` denotes a field that is
not applicable to that `record_type`.

### Figure 3.5: acquisition decomposition

`fig03_05_cossin2_iteration20_acquisition.csv` has 40,441 data rows. The 40,401 `grid` rows contain every pixel value used in the four panels. The `observation` rows contain the 39 plotted training markers, and the single `selected_point` row contains the star and its stored acquisition terms. `pof_times_sampled_hvi` is the direct product, whereas `final_acquisition` also includes the saved background and anti-clustering terms.

The 39 observation rows also retain `objective_y1` and `objective_y2`; the
selected point is not assigned Y because it had not yet been returned by the
expensive objective at the saved pre-evaluation selection state.

The reconstructed feasibility score, sampled HVI, masks, and final acquisition were checked against all 513 stored candidate values using the same tolerance as the figure reconstruction.

### Figure 3.6: WB150 Pareto evolution

`fig03_06_wb150_rep02_evaluations.csv` contains one row per evaluation. `plot_class` directly gives the grey-cross, open-circle, or blue-Pareto category, and `is_evaluation_150` identifies the orange diamond. The file contains 109 feasible evaluations and 16 members of the final feasible Pareto front.

### Figure 3.7: hypervolume histories

`fig03_07_highdim_hv_histories.csv` is a wide, plot-ready table with one row per problem and sequential-evaluation count. The five coloured curves are `seed_1_normalized_hv` through `seed_5_normalized_hv`; `median_normalized_hv` is the black curve. `total_evaluations` equals 20 plus `sequential_evaluations`.

The normalization values used by the figure remain available in the [tagged cTSEMO normalization table](https://github.com/globaswu/cTSEMO/blob/v0.2.1/manuscript/artifacts/ga_primary_dimension/ga_primary_highdim_normalization.csv).

### Figure 3.8: historical solver fronts

`fig03_08_wb150_solver_fronts.csv` is sorted within each solver by increasing fabrication-cost objective. `retained_evaluations` is 150 for all displayed fronts. `true_oracle_calls` is 178 for PAC-MOO and 150 for the other six implementations. These columns preserve the unequal-call qualification stated in the thesis.

### Figures 3.9--3.12: conditional HVI

`fig03_09_12_wb150_conditional_hvi.csv` uses three record types:

- `survival_grid`: the normalized HVI threshold, conditional exceedance probability, and its floored base-10 logarithm for panel A;
- `profile_station`: positive-HVI fraction, conditional mean, median, 90th percentile, 99th percentile, and sampled profile maximum for panels B and C;
- `metadata`: selected input/HVI marker, final positive-support locations, sample count, iteration, training count, normalization maximum, and positive tolerance.

The data are the plotted conditional statistics over the fixed 2,048-point nuisance design. The full unaggregated nuisance samples are not duplicated because they are not individual plotted points.

## Reconciliation with the public cTSEMO record

The numerical sources were reconciled with the public [cTSEMO v0.2.1 tag](https://github.com/globaswu/cTSEMO/tree/v0.2.1):

- the four two-dimensional run records used by Figures 3.1--3.5 are byte-identical to the tagged records;
- the feasibility-field values and milestone histories agree numerically with the tagged field record;
- the design, objective, feasibility, evaluation-index, and iteration arrays in all 35 higher-dimensional run records used by Figures 3.6 and 3.7 agree element-by-element with the tagged records;
- the complete Figure 3.13 CSV is retained locally and is byte-identical to its
  immutable cTSEMO v0.2.1 tagged source.

These checks establish numerical consistency with the published artifact while keeping the thesis-facing files compact and directly readable as CSV.
