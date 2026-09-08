# Self-contained thesis figure packages

The 63 original numerical figure packages retain stable folders, for example:

```text
data/figures/chapter05/figure_5_1/
|-- figure_5_1.csv
|-- plot_5_1.py
`-- plot_5_1.m
```

The Python and MATLAB scripts resolve their own folder and read only the CSV
data beside them. Figure 2.5 uses three tables: its primary
`figure_2_5.csv` contains nodes, `chunk_beams.csv` contains connectivity, and
`chunk_shell_vertices.csv` contains skin geometry. Keep all three beside its
scripts. The newer Figure 6.5 skin-stress package uses five CSVs: a case table
and separate vertex and triangle-stress tables for each wing. The other numerical
packages use one CSV. Scripts do not read MAT files,
Nastran decks or results, nTop projects, data outside their figure folder,
network locations, or private paths.

## Reproduce one figure

For a current printed number, use:

```powershell
python scripts/reproduce_thesis_figure.py --current 5.2
```

The [registry](../figure_registry.json) maps current numbers to stable paths.
Folder names, embedded script help, and default filenames may retain earlier
package numbers. This preserves existing URLs and direct-script commands.
For a numerical package, either script can still be invoked directly:

```powershell
python data/figures/chapter05/figure_5_1/plot_5_1.py
matlab -batch "addpath('data/figures/chapter05/figure_5_1'); plot_5_1"
```

Each script accepts an optional output path. The Python scripts use
`--output`; the MATLAB functions accept the path as their first argument.

## Reproduce several or all figures

The optional dispatcher delegates to the same per-figure Python scripts:

```powershell
python scripts/reproduce_thesis_figure.py --current 5.1
python scripts/reproduce_thesis_figure.py --current 5.1 5.9 6.5 --format pdf
python scripts/reproduce_thesis_figure.py --current --all
```

Install the lightweight Python dependencies with:

```powershell
python -m pip install -r requirements-figures.txt
```

Without `--current`, arguments retain their legacy package meanings. For
example, bare `5.2` still selects the FCC Pareto package; `--current 5.2`
selects the newly inserted topology screenshot montage.

## Screenshot compositions

The skin-stress package for Figure 6.5 is different from a screenshot composition.
It reconstructs the raw skin surface directly from the complete mesh and both
centroid fiber stresses. The nTop views use the same stress observations as scalar
point maps; the Python/MATLAB scripts render the finite element surface without
requiring nTop or reproducing its viewport styling.

The three descriptive montage folders use `layout.csv`, declared local PNG
crops, `compose.py`, and `compose_figure.m`. Their CSV records panel placement and
annotations, not the numerical geometry needed to regenerate an nTop view.
Scripts recompose the supplied genuine screenshots, optionally stacking
multiple panel groups into one atlas. They do not open nTop, rebuild its model,
rerun a solver, or retrieve outside data. The README in each package explains
the depicted views, scale conventions, and any interpretation limitations.

## X, Y, and C convention

For evaluated designs, **X** is the design-input vector, **Y** is the
expensive black-box objective-response vector, and **C** is the binary
feasibility label. Objective-space figures plot Y. Feasibility maps locate
samples in X and fit the field from X and C; Y remains in the same figure CSV
for traceability but is not an input to the feasibility fit. Dense fields,
curves, evaluation rows, and annotations are distinguished by `record_type`
where a figure requires more than one data grain.

## Scope

The [figure index](FIGURE_DATA_MAP.md) maps 68 packages to current thesis
numbering: 65 CSV plots/reconstructions and three screenshot compositions,
including the supplementary numerical figures in Appendices C and D.
Figure 2.10 contains all 531,682 recovered mode-shape nodes in one CSV. The
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
