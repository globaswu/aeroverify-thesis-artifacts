# Seven-solver constrained optimization comparison

Research question: what feasible trade-off regions did the tested constrained
optimizers recover under a common budget of recorded design observations?

The dataset contains seven benchmark instances: welded beam (4 inputs), CF1
(4 and 10 inputs), C2-DTLZ2 (4 and 6 inputs), and MW7 (4 and 6 inputs).
Each of the seven solvers has one 150-observation trajectory per instance,
with 20 shared initial designs followed by 130 adaptive observations.
cTSEMO reuses repetition 1 of the earlier study. The 7,350 records count
observations across trajectories, including reused and shared observations.

## Inspect the evidence

- [Hypervolume-ratio table](../../data/benchmarks/seven_solver_comparison/hv_ratio_table.csv)
- [Evaluated inputs X, objectives Y, and labels C](../../data/benchmarks/seven_solver_comparison/evaluations.csv)
- [Observed feasible Pareto sets](../../data/benchmarks/seven_solver_comparison/observed_pareto.csv)
- [Empirical GA reference fronts](../../data/benchmarks/seven_solver_comparison/empirical_ga_fronts.csv)
- [Metric definitions and data dictionary](../../data/benchmarks/seven_solver_comparison/README.md)

The figure packages contain the required evaluated rows and reference points
in one CSV per figure. Run either Python script or the corresponding MATLAB
function; each reads only its adjacent CSV:

```powershell
python data/figures/chapter03/figure_3_7/plot_3_7.py
python data/figures/chapter03/figure_3_8/plot_3_8.py
matlab -batch "addpath('data/figures/chapter03/figure_3_7'); plot_3_7"
matlab -batch "addpath('data/figures/chapter03/figure_3_8'); plot_3_8"
```

## Interpretation

cTSEMO and HyperMapper receive aggregate binary feasibility labels. BoTorch
(qLogNEHVI), Trieste (ECHVI), USeMOC, COMBOO, and PAC-MOO receive individual
continuous constraint margins. Margins stored in binary-method rows are
post hoc audit data, not inputs supplied to those optimizers during selection.

Hypervolume ratios use the same per-problem normalization and empirical GA
reference front. That reference used a larger budget and is not a certified
Pareto front or an equal-budget competitor. One trajectory per solver/problem
does not establish a general statistical ranking. Any difference in performance
cannot be attributed solely to the differing constraint information. These
scripts reconstruct the recorded fronts; they do not restart the optimizers.
