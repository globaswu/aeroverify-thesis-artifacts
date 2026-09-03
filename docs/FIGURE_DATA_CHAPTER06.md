# Chapter 6 figure data

This index maps every quantitative figure in Chapter 6 to the compact public
data needed to reproduce its plotted points, curves, or fields. The tables
contain evaluated results or deterministic reductions of those results; they
do not contain native MSC Nastran output, commercial project files, machine
paths, archive locations, or licensing information.

The machine-readable version of this index, including column lists and source
provenance, is
[`figure_data_map.csv`](../data/figures/chapter06/figure_data_map.csv).

| Figure | Public data | Rows | Coverage |
|---|---|---:|---|
| 6.1 | [`figure_6_01_optimization_progress.csv`](../data/figures/chapter06/figure_6_01_optimization_progress.csv) | 100 | Prefix box-hypervolume history, normalization, phase membership, feasibility, final Pareto membership, and the two phase-yield summaries. |
| 6.2 | [`evaluations_cases001_100.csv`](../data/multiinput/evaluations_cases001_100.csv) | 100 | All evaluated objective pairs and their feasibility, final-Pareto, initial/adaptive, and case-index classifications. The refined-mesh overlay comprises case 65 and cases 71--100. |
| 6.3 | [`figure_6_03_feasibility_mechanisms.csv`](../data/figures/chapter06/figure_6_03_feasibility_mechanisms.csv) | 100 | Shell and CBEAM utilization coordinates plus the mutually exclusive outcome class used in the count panel. |
| 6.4 | [`figure_6_04_normalized_design_space.csv`](../data/figures/chapter06/figure_6_04_normalized_design_space.csv) | 100 | Four normalized input coordinates used in all six pairwise projections. |
| 6.5 | [`profile`](../data/figures/chapter06/figure_6_05_hvi_aspect_ratio.csv); [`survival field`](../data/figures/chapter06/figure_6_05_hvi_survival.csv) | 121; 21,901 | Aspect-ratio conditional profiles and the full 181-by-121 exceedance field. |
| 6.6 | [`profile`](../data/figures/chapter06/figure_6_06_hvi_taper_ratio.csv); [`survival field`](../data/figures/chapter06/figure_6_06_hvi_survival.csv) | 121; 21,901 | Taper-ratio conditional profiles and the full 181-by-121 exceedance field. |
| 6.7 | [`profile`](../data/figures/chapter06/figure_6_07_hvi_primary_member_ratio.csv); [`survival field`](../data/figures/chapter06/figure_6_07_hvi_survival.csv) | 121; 21,901 | Primary-member-ratio conditional profiles and the full 181-by-121 exceedance field. |
| 6.8 | [`profile`](../data/figures/chapter06/figure_6_08_hvi_secondary_member_ratio.csv); [`survival field`](../data/figures/chapter06/figure_6_08_hvi_survival.csv) | 121; 21,901 | Secondary-member-ratio conditional profiles and the full 181-by-121 exceedance field. |
| 6.9 | [`evaluations_cases001_100.csv`](../data/multiinput/evaluations_cases001_100.csv) | 100 | Exact values on all seven axes. Filtering `Feasible=True` gives the 70 plotted polylines. |
| 6.10 | [`evaluations_cases001_100.csv`](../data/multiinput/evaluations_cases001_100.csv) | 100 | Two-wing mass, trim compliance, feasibility, final-Pareto membership, and the four initial planform-corner groups. |
| 6.11 | [`LLT curves`](../data/figures/chapter06/figure_6_11_llt_curves.csv); [`trim displacements`](../data/figures/chapter06/figure_6_11_trim_displacement_curves.csv); [`case summary`](../data/representative_physics/representative_physics_cases004_037_064_065_099.csv) | 2,005; 2,505; 5 | Lift, outboard-load moment, twist, and vertical displacement for MI4, MI37, MI64, MI65, and MI99. |
| 6.12 | [`trim stresses`](../data/figures/chapter06/figure_6_12_trim_stress_curves.csv); [`strain energy`](../data/figures/chapter06/figure_6_12_strain_energy_curves.csv); [`flutter envelope`](../data/figures/chapter06/figure_6_12_flutter_envelope_curves.csv); [`case summary`](../data/representative_physics/representative_physics_cases004_037_064_065_099.csv) | 1,400; 45; 185; 5 | Shell stress, CBEAM stress, fixed-angle strain energy, maximum filtered damping, and representative extrema. |

## Interpretation and plotting notes

- Figure 6.1 uses the physical reference point stored in every row of its CSV.
  `normalized_hypervolume` is divided by `case30_hypervolume`.
- Figure 6.3 uses separate shell von Mises and CBEAM maximum-absolute normal
  stress channels. Utilization is stress divided by the 220 MPa limit retained
  in the finalized campaign records.
- Figure 6.4 uses the stated bounds for aspect ratio, taper ratio, and the two
  member-sizing ratios. The six displayed panels are pairwise projections, not
  four-dimensional slices.
- In Figures 6.5--6.8, each profile station integrates the same 2,048-point
  stratified nuisance sample over the other three inputs. The survival files
  contain both the exceedance probability and the exact log-transformed value
  displayed by the heat map. These finite-sample reductions are not causal
  one-variable sensitivities.
- Figures 6.11 and 6.12 use the representative cases identified in the thesis.
  The CSVs contain plotted response summaries only; no solver-native arrays
  were copied.

All row counts and schemas are repeated in the machine-readable map so that a
reader can validate a download before plotting.
