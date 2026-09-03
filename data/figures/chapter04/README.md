# Chapter 4 figure data

These compact CSV files contain the numerical values plotted in the two
quantitative figures in Chapter 4 of the thesis. They contain no solver working
directories, archive addresses, licence-server settings, or timestamps.

## Figure 4.1: representative fixed-area planforms

`figure_4_1_representative_fixed_area_planforms.csv` contains the six boundary
vertices used for each of cases 45, 47, and 20. Join the rows for each case in
ascending `point_order` and close the polygon by connecting point 6 to point 1.
The vertical root-chord line joins points 5 and 2. The dotted quarter-chord
reference is `chordwise_m = 0`.

The design and objective values are exact copies of the corresponding rows in
`data/planform/evaluations_cases001_050.csv`. The plotted geometry is calculated
from the fixed full-wing area `S = 2.3224598712 m^2` as

```
semispan = sqrt(AR * S) / 2
root_chord = S / (semispan * (1 + taper_ratio))
tip_chord = taper_ratio * root_chord
```

The boundary-coordinate convention follows the plotted figure: at each spanwise
station, the two chordwise edges are `0.75 * chord` and `-0.25 * chord`, so the
unswept quarter-chord reference remains at zero.

## Figure 4.2: frozen topology-selection comparison

`figure_4_2_topology_selection.csv` contains every plotted point and bar value:
the two-wing mass and trim compliance in panel A, and the skin and beam stress
utilizations in panel B. Each utilization is the corresponding stress divided by
the stated 220 MPa screening limit.

The three rows reproduce the finite-sample selection used when the planform
study was defined: the lightest recorded feasible point on each topology's
observed Pareto set in that frozen snapshot. This selection basis is intentionally
preserved and must not be replaced by a later retrospective classification.
The internal source table includes machine-specific file-location fields, so the
public CSV contains only the numerical and classification fields required to
reproduce the figure.
