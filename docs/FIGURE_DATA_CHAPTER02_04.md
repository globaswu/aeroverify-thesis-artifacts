# Figure data for Chapters 2 and 4

This crosswalk identifies the compact numerical tables underlying the
quantitative figures in Chapters 2 and 4 of the thesis. The CSV files contain
the plotted values without including native Nastran result files, commercial
model files, machine-specific paths, archive addresses, licence settings, or
timestamps.

| Thesis figure | Figure-ready data | Rows | Plotting fields |
|---|---|---:|---|
| Figure 2.7, structural-mesh convergence | [`data/figures/chapter02/figure_2_7_mesh_convergence.csv`](../data/figures/chapter02/figure_2_7_mesh_convergence.csv) | 15 | Mesh edge length; compliance; displacement; skin and beam stress percentiles; first modal frequency |
| Figure 2.8, case-64 V-g diagnostic | [`data/figures/chapter02/figure_2_8_case64_vg.csv`](../data/figures/chapter02/figure_2_8_case64_vg.csv) | 1,480 | Configuration; root; velocity; damping; frequency; reduced frequency; eigenvalue components |
| Figure 4.1, representative fixed-area planforms | [`data/figures/chapter04/figure_4_1_representative_fixed_area_planforms.csv`](../data/figures/chapter04/figure_4_1_representative_fixed_area_planforms.csv) | 18 | Case and role; ordered boundary coordinates; planform variables and dimensions; objective values |
| Figure 4.2, frozen topology selection | [`data/figures/chapter04/figure_4_2_topology_selection.csv`](../data/figures/chapter04/figure_4_2_topology_selection.csv) | 3 | Topology and case; mass; compliance; cell parameters; skin and beam stresses and utilizations |

The Chapter 2 and Chapter 4 data dictionaries give the filtering rules,
coordinate conventions, units, and reconstruction equations:

- [Chapter 2 figure-data notes](../data/figures/chapter02/README.md)
- [Chapter 4 figure-data notes](../data/figures/chapter04/README.md)

## Caption links

The following stable thesis-tag links can be used directly in thesis captions:

- Figure 2.7: <https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis/data/figures/chapter02/figure_2_7_mesh_convergence.csv>
- Figure 2.8: <https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis/data/figures/chapter02/figure_2_8_case64_vg.csv>
- Figure 4.1: <https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis/data/figures/chapter04/figure_4_1_representative_fixed_area_planforms.csv>
- Figure 4.2: <https://github.com/globaswu/aeroverify-thesis-artifacts/blob/thesis/data/figures/chapter04/figure_4_2_topology_selection.csv>

## Reproducibility boundary

Figure 2.8 retains every valid SOL 145 point visible in the all-root and
magnified panels. The two trailing non-flutter numeric rows are excluded by the
same positivity and reciprocal-frequency checks used in the analysis.

Figure 4.2 deliberately preserves the finite-sample topology classifications
used when the planform study was defined. They must not be replaced by a later
retrospective classification when reproducing that figure.

The current public `matlab/reproduce_mesh_convergence.m` script produces a
simplified mesh-convergence summary and a root-19 V-g comparison. The CSV files
listed above contain all values in the thesis figures, but exact visual
regeneration of Figures 2.7 and 2.8 requires the plotting script to be extended
to include the stress panel and all-root panels.
