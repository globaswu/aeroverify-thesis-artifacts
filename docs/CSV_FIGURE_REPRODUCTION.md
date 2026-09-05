# Self-contained thesis figure packages

Every data-based thesis figure has its own folder. For example:

```text
data/figures/chapter05/figure_5_1/
|-- figure_5_1.csv
|-- plot_5_1.py
`-- plot_5_1.m
```

The Python and MATLAB scripts resolve their own folder and read only the single
CSV beside them. They do not read MAT files, Nastran decks or results, nTop
projects, other CSV files, network locations, or private paths.

## Reproduce one figure

Run either script inside the desired folder:

```powershell
python data/figures/chapter05/figure_5_1/plot_5_1.py
matlab -batch "addpath('data/figures/chapter05/figure_5_1'); plot_5_1"
```

Each script accepts an optional output path. The Python scripts use
`--output`; the MATLAB functions accept the path as their first argument.

## Reproduce several or all figures

The optional dispatcher delegates to the same per-figure Python scripts:

```powershell
python scripts/reproduce_thesis_figure.py 5.1
python scripts/reproduce_thesis_figure.py 5.1 5.9 6.5 --format pdf
python scripts/reproduce_thesis_figure.py --all
```

Install the lightweight Python dependencies with:

```powershell
python -m pip install -r requirements-figures.txt
```

## X, Y, and C convention

For evaluated designs, **X** is the design-input vector, **Y** is the
expensive black-box objective-response vector, and **C** is the binary
feasibility label. Objective-space figures plot Y. Feasibility maps locate
samples in X and fit the field from X and C; Y remains in the same figure CSV
for traceability but is not an input to the feasibility fit. Dense fields,
curves, evaluation rows, and annotations are distinguished by `record_type`
where a figure requires more than one data grain.

## Scope

The [figure index](FIGURE_DATA_MAP.md) lists all 53 packages under the current
thesis numbering, including the supplementary figures in Appendices C and D.
Figure 2.8 contains all 531,682 recovered mode-shape nodes in one CSV. The
thesis image consists of nTop screenshots; its scripts provide a portable
point-cloud reconstruction from the reference coordinates and mode-3
displacements. nTop surface shading and camera settings are not reproduced.
Modal amplitudes have arbitrary normalization and are not operational wing
deflections.

Figure 5.1 contains all 213 completed FCC, BCC, and SC evaluations. Its CSV
retains the two input variables, two-wing mass and compliance objectives,
binary and original signed feasibility labels, and both within-topology and
pooled observed Pareto flags. `C_binary_feasible=1` corresponds to feasible,
whereas the original `C_signed_recorded=-1` denotes feasible. The figure
supports the observed trade-offs within these finite samples. Missing field
values are left empty, and historical labels are preserved alongside the
separate harmonized flutter evidence.

Figures 3.7 and 3.8 contain evaluated inputs X, objectives Y, binary labels C,
observed Pareto flags, and empirical reference-front rows. Their scripts plot
the observed feasible nondominated objective pairs. Audit margins retained in
binary-method rows were not supplied to those optimizers. The complete
comparison and metric definitions are available in the
[seven-solver dataset](../data/benchmarks/seven_solver_comparison/README.md).
