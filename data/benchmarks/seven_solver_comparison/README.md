# Seven-solver constrained optimization comparison

These files contain the completed comparison on seven benchmark instances:
welded beam (4 inputs), CF1 (4 and 10 inputs), C2-DTLZ2 (4 and 6 inputs,
radius 0.2), and MW7 (4 and 6 inputs). Both objectives are minimized.

Every solver/problem trajectory contains 150 evaluations: the same ordered
20 initial designs for each problem followed by 130 adaptive evaluations.
cTSEMO and HyperMapper receive aggregate binary feasibility labels. BoTorch
(qLogNEHVI), Trieste (ECHVI), USeMOC, COMBOO and PAC-MOO receive individual
continuous constraint margins. This is one trajectory per method/problem.
The cTSEMO records reuse repetition 1 of the earlier five-repetition study.
The sum of the recorded budgets is 7,350, including reused cTSEMO records
and repeated accounting of the shared initial observations.
The budget counts recorded design observations. Duplicate checks of a
recorded design's exact objective and constraint values add no training
observation and are excluded from that count. The current PAC-MOO adapter
retains infeasible initial designs without rejection or replacement.

## Files

- `evaluations.csv`: all 7,350 evaluated solver observations, including inputs,
  objective responses, binary labels, audit margins and Pareto membership.
- `observed_pareto.csv`: the 757 unique feasible nondominated solver points.
- `empirical_ga_fronts.csv`: the 2,884 empirical reference points.
- `solver_metrics.csv`: all 49 solver/problem metric rows.
- `hv_ratio_table.csv`: the seven-by-seven hypervolume-ratio table.
- `validation.csv` and `ga_validation.csv`: numerical reconstruction checks.
- [Figure 3.7](../../figures/chapter03/figure_3_7): one CSV and independent
  Python/MATLAB scripts for the four CF1 and C2-DTLZ2 panels.
- [Figure 3.8](../../figures/chapter03/figure_3_8): one CSV and independent
  Python/MATLAB scripts for the welded-beam and two MW7 panels.

Run the Python script inside either figure directory with Python, NumPy and
Matplotlib installed, or run its MATLAB function using base MATLAB. Each
script reads only the adjacent CSV. The figure CSV contains every evaluated
design for its problems as well as the empirical reference, so reconstruction
does not require a solver, the original experiment directory, or external
data. Python and MATLAB may differ slightly in typography and axis ticks.

## Data definitions

`X1` to `X10` contain the input vector in the benchmark's prescribed variable
coordinates. Unused coordinates are blank. Welded-beam inputs retain the
source benchmark's inch units; other inputs are dimensionless. `Y1` and `Y2`
are the recorded objective responses; for welded beam these are the source
fabrication-cost objective and deflection in inches. `C` is the binary
feasibility label (1 feasible, 0 infeasible). `audit_margin1` to
`audit_margin4` retain the individual constraint margins with the convention
that all applicable margins must be at most zero. Margins in binary-method
rows are post hoc audit data, not information given to the online optimizer.

`is_pareto` identifies one representative of every unique feasible
nondominated objective pair in that solver's 150-evaluation history.
`row_kind` distinguishes `solver_evaluation` from `ga_reference`.
`evaluation_index` is the within-trajectory observation index for solver rows
and an exported reference-row index for GA rows. `phase` is `initial`,
`adaptive`, or `reference`.

The normalized objectives are
`normalized_Yj = (Yj - ga_minimum_Yj) / ga_range_Yj`.
The minimum and range come from that problem's empirical GA front and are
included in each row. The figures show only the feasible nondominated rows.
No lines interpolate between disconnected regions.

## Metrics and interpretation

The GA reference pools the final population and returned front from eight
`gamultiobj` runs per problem (population 240, maximum 240 generations).
It is a higher-budget empirical reference, not a certified Pareto front or
an equal-budget competitor. The retained GA candidate CSV is not the full
history of all GA function evaluations.

Hypervolume uses reference `(1.1, 1.1)` in the GA-normalized objective space.
`HVToGARatio` divides a solver's hypervolume by the reference front's
hypervolume. IGD averages the nearest Euclidean distance from each GA point
to the solver front; GD averages the reverse direction. Additive epsilon is
`max_g min_s max_j(z_sj - z_gj)`. Coverage is the fraction of GA reference
points within normalized Euclidean distance 0.02 of the solver front.
These metrics are recomputed from the observed fronts; individual solver
trace hypervolume values are not used.

One run per method/problem does not quantify run-to-run variability or
establish a general ranking. Differences between binary-label and
continuous-margin methods cannot be attributed solely to their constraint
information. No runtime ranking is inferred. The CSV scripts reproduce the
recorded figures; restarting an optimizer need not reproduce a resumed
trajectory bit-for-bit.
