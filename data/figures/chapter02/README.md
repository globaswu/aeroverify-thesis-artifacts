# Chapter 2 figure data

These UTF-8 CSV files provide the plotted numerical values for the quantitative
figures in Chapter 2. They contain no filesystem paths, timestamps, solver
licensing details, remote archive addresses, or solver-native result arrays.

## Figure 2.7: structural-mesh convergence

[`figure_2_7_mesh_convergence.csv`](figure_2_7_mesh_convergence.csv) contains
the 15 observations plotted for source cases 4, 37, 64, 65, and 99 at the
fixed 1.5 mm geometry tolerance and the three tested mesh edge lengths. One
row provides the compliance, maximum vertical deflection, skin and CBEAM
99.75th-percentile stresses, and first retained modal frequency for one
case/mesh combination. Units are stated in the column names.

The values are a direct, figure-specific projection of
[`../../mesh_convergence/results_summary.csv`](../../mesh_convergence/results_summary.csv).
No numerical values were recalculated.

## Figure 2.8: case-64 V-g diagnostic

[`figure_2_8_case64_vg.csv`](figure_2_8_case64_vg.csv) contains all retained
valid SOL 145 samples used by the four panels: 740 samples for the 2.5 mm
edge-length configuration and 740 samples for the 2.0 mm geometry-tolerance
configuration.
The `root`, `velocity_mps`, and `damping_g` columns define every plotted V-g
curve. The remaining retained scalar columns support independent checking of
the modal point. The `positive` column is true exactly when `damping_g > 0`.
Rows are retained only when reduced frequency, inverse reduced frequency,
velocity, and frequency are positive and finite and the reciprocal-frequency
error satisfies `abs(reduced_frequency * inverse_reduced_frequency - 1) <=
0.01`. This removes one trailing non-flutter numeric row from each compact
source table.

The smaller
[`../../mesh_convergence/case64_positive_g_root19.csv`](../../mesh_convergence/case64_positive_g_root19.csv)
is the root-19 subset only; it is sufficient for the two magnified panels but
not for the two all-root panels. The figure-specific file therefore publishes
the complete compact tables underlying the original figure without including
the much larger native Nastran files.
