# Chapter 3 class-conditional feasibility-score ECDFs

This public package reproduces the numerical display curves for 12 benchmark
configurations, 40 final cTSEMO models and 80 class-conditional empirical
cumulative distribution functions (ECDFs). It contains plot-ready curves and
archived numerical summaries. The private full-precision probe scores, probe
coordinates, analytical-label arrays, MATLAB records and thesis files are not
redistributed. Figure reproduction uses the included CSVs; it does not refit a
model, generate probes or rerun optimization.

## Reproduce the figures

Use Python 3.10 or later with NumPy and Matplotlib. From the repository root,
first verify the release manifest, then run:

```powershell
pwsh -File tools/verify_manifest.ps1
python -m pip install numpy matplotlib
python data/diagnostics/chapter03_ecdf_20260921/reproduce.py
```

The plotting script is portable and can be invoked from any working directory.
The default output is `generated/chapter03_ecdf_20260921/` relative to the
repository root. Set `--output <directory>` to choose another output location.
`--formats png svg pdf` additionally exports a separate PDF for each figure.
The source directory cannot be used as the output directory. Repeating a run
replaces figures of the same name in the selected output directory.

Default outputs are 12 configuration figures, two overview plates and seven
five-replicate plates, each in PNG and SVG; a separate nine-page A4 portrait
`chapter03_ecdf_figure_booklet.pdf` contains the two overview plates followed by
the seven replicate plates. Every plotting box has square `[0,1]` axes. A
`rendering_receipt.json` records input-file hashes, dependency versions and
additional median-compression errors. Export styling uses a portable serif
font; it is not a pixel-identical reproduction of MATLAB's rendering.

## Data and interpretation

For true class `c`, the ordinate is
`F_c(t) = count(p_j <= t and class_j = c) / count(class_j = c)`.
Here `p_j` is the final model's clipped binary-GP feasibility score at probe
`j`. Each class has its own denominator. Green solid curves denote truly
feasible probes; red dashed curves denote truly infeasible probes. This
diagnostic describes score discrimination and saturation on the supplied
probe sets. It does not establish probability calibration or sequential
optimizer performance.

The first overview contains COSSIN1, COSSIN2, BNH, SRN and C2-DTLZ2 with
dimension 3 and radius 0.5. The first four use retained 201-by-201 cell-centred
grids. The fifth is an offline diagnostic reconstructed from its retained
60-evaluation final model on 262,144 new independent randomized
Latin-hypercube probes; it is flagged by `ReconstructedDiagnostic` in
`metrics.csv`. The second overview contains the welded-beam variant, CF1 at
dimensions 4 and 10, C2-DTLZ2 with radius 0.2 at dimensions 4 and 6, and MW7 at
dimensions 4 and 6. Each has five final models, 150 evaluations per model and
a common retained set of 262,144 probes within that configuration. Counts,
dimensions and training budgets are recorded in `metrics.csv` and
`problem_feasibility_summary.csv`.

Bold five-run curves are pointwise medians of the five class-conditional ECDFs
evaluated as right-continuous steps on the union of their score coordinates.
They are not pooled-score ECDFs. Faint curves show individual runs, not
confidence intervals. The KS and signed median-gap annotations are medians of
the five separately computed archived metrics; they are not metrics computed
from the median ECDF. KS is unsigned separation, while the signed gap is
`median(p | feasible) - median(p | infeasible)`. AUC treats feasible as the
positive class and assigns half credit to ties.

The gray open band is `0.4 < p < 0.6`. Its illustrative decision convention is
infeasible for `p <= 0.4`, feasible for `p >= 0.6`, and intermediate otherwise.
It is not a confidence interval. `metrics.csv` retains the separate historical
single-threshold convention: false-feasible rate is
`P(p >= 0.5 | truly infeasible)` and false-infeasible rate is
`P(p < 0.5 | truly feasible)`. These rates must not be substituted for the
band-based outcomes in `trial_feasibility_summary.csv`.

The band summary's `WholeDomain...Fraction` fields divide TP, FP, TN and FN by
all probes; their sum is `NonIntermediateDomainFraction`. That fraction plus
`IntermediateDomainFraction` is one before rounding. Class-conditioned rates
and intermediate fractions use their named true-class denominators instead.
`DomainFeasiblePercent` estimates the feasible share of the uniform input
domain from analytical probe labels. It is not the fraction of evaluated
training designs. Non-intermediate coverage is input-domain coverage, not
Pareto hypervolume or a measure of predictive accuracy.

## Included files and reproduction limits

- `curves/<ProblemId>_draw_curves.csv`: ordered right-continuous step coordinates
  grouped by `Replicate` and `TrueClass`, with `Score` and `ECDF` columns. The
  released files retain the original CSV values. Actual replicates are 1 for
  integration cases and 1–5 for repeated cases. The script computes median
  curves from those rows. It also supports a compatible precomputed
  `Replicate = 0` median, validating it and excluding it from actual-run counts.
- `metrics.csv`: 40 model-level summaries calculated upstream from exact probe
  scores, including AUC, KS, signed median gap, Brier score, single-threshold
  error rates and exact zero/one score fractions.
- `validation.csv`: 80 upstream class-curve checks, including class counts,
  unique scores, drawing points, monotonicity, endpoint checks, draw-only
  errors and retained-reference metric errors. A missing reference metric for
  the reconstructed integration diagnostic is not an observed zero error.
- `problem_feasibility_summary.csv` and `trial_feasibility_summary.csv`: the
  12-configuration and 40-trial summaries, including observed evaluated-design
  outcomes and separately identified probe-based domain/band statistics.
- `extreme_case_reconstruction_audit.csv`: archived checks of selected extreme
  final fields; the plotting script does not rerun these refits.
- `provenance/*.csv`: sanitized source references and recorded SHA-256 hashes.
  Hashes for private upstream records document their identity; those records
  are not included or retrievable through this package. The release manifest
  separately verifies the public files that are actually redistributed.

Upstream draw-only compression has a maximum vertical ECDF error of `1e-4`
for each individual curve. Endpoints and zero/one masses are retained. A
second compression at `1e-4` is applied to the pointwise median for plotting,
giving a total median display bound of `2e-4` relative to the pointwise median
of the exact run ECDFs, apart from CSV floating-point serialization. These
bounds are draw-only approximations; no smoothing or artificial spreading of
endpoint masses is applied. The script disables Matplotlib path simplification
to retain the supplied step coordinates.

Archived metrics and band summaries should be read directly from their CSVs.
The compressed curves do not support exact recomputation of full-score
statistics, exact threshold ties, model fitting or analytical truth checks.
Numerical input validation and median construction during plotting verify the
public drawing inputs, not the unpublished upstream scientific calculations.
