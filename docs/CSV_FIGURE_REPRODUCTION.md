# Self-contained thesis figure packages

Every quantitative thesis figure has its own folder. For example:

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

The per-figure contract covers 50 figures: 2.7--2.8, 3.1--3.13, 4.1--4.2,
5.1--5.21, and 6.1--6.12. Figure 5.7 contains all 531,682 recovered mode-shape
nodes in one CSV. Its scripts provide a portable point-cloud reconstruction;
they do not claim to duplicate proprietary nTop surface shading or camera
settings.
