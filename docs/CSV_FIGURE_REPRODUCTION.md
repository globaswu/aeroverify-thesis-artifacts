# CSV-only thesis-figure reproduction

The public thesis package provides a single dispatcher that reconstructs every
quantitative thesis figure in Chapters 2--6 from repository CSV files only:

```powershell
python scripts/reproduce_thesis_figure.py --list
python scripts/reproduce_thesis_figure.py 5.9
python scripts/reproduce_thesis_figure.py 3.1 5.5 6.11 --format pdf
python scripts/reproduce_thesis_figure.py --all --output-dir reproduced
```

The dispatcher requires Python 3.10 or later, NumPy, and Matplotlib. It does
not read MAT files, Nastran decks or results, nTop projects, logs, archive
locations, or network resources. Output names are deterministic, for example
`thesis_figure_05_09.png`. The `--all` command covers all 50 requested figures:
2.7--2.8, 3.1--3.13, 4.1--4.2, 5.1--5.21, and 6.1--6.12.

## Input, output, and label convention

For an evaluated design, **X** is the design-variable input vector, **Y** is
the objective-output vector, and **C** is the binary feasibility label. The
CSV columns use domain-specific names rather than anonymous array positions:

- lattice sizing: `X = [a_m, t1_over_a]`,
  `Y = [mass_kg, compliance_Nm]`, and `C = feasible`;
- planform sizing: `X = [AR, taper_ratio]`,
  `Y = [CDitrim, Ctrim_Nm]`, and `C = feasible`;
- four-input sizing: `X = [AR, lambda, r1, r2]`,
  `Y = [CDitrim, Ctrim]`, and `C = Feasible`.

Objective-space figures plot Y and use C only to distinguish feasible and
infeasible observations. Feasibility-score figures fit or display a continuous
field from X and C; Y is not an input to that feasibility model. Figure 5.5's
point table retains both the observed C labels and the hypothetical labels in
which cases 8 and 29 are treated as feasible. The same table retains the two Y
objectives, so the diagnostic remains auditable without another data source.

## Independent feasibility-field refit

The bundled MATLAB routine refits the implemented clipped binary-feasibility
model from the published X and C values rather than merely displaying the
published dense field:

```matlab
addpath("matlab")
reproduce_feasibility_map_from_csv("5.3")
reproduce_feasibility_map_from_csv("5.5")
reproduce_feasibility_map_from_csv("5.10")
reproduce_feasibility_map_from_csv("5.15")
reproduce_feasibility_map_from_csv("5.18")
```

Each generated title reports the maximum absolute difference between the
refitted field and the published plotted field. The routine reads only CSV and
the bundled `ctsemo.fitClippedBinaryPof` / `ctsemo.predictClippedBinaryPof`
implementation.

## Figure 5.7 portable reconstruction

Figure 5.7 is supplied as eight CSV shards containing 531,682 total nodes,
with a small [shard manifest](../data/figures/chapter05/figure_5_7_case067_mode3_nodes_manifest.csv).
The shards contain reference coordinates,
the mode-3 translational eigenvector, displacement magnitude, mode index, and
frequency. The table was recovered from the retained case-67 nTop modal cache
and matched one-for-one to the GRID card order. Numeric round-trip checks found
zero difference from the cached doubles and GRID coordinates.

The dispatcher plots top, oblique, front, and right deformed-node views from
the ordered shards. It uses a deterministic plotting stride to limit output
size; the CSV set itself retains every node. This portable point-cloud rendering is not claimed
to duplicate nTop's proprietary surface shading or camera settings. Exact
surface/wireframe reconstruction would additionally require the shell and beam
connectivity tables.

## Data maps

The chapter-specific data maps list the exact CSVs and fields used by every
figure:

- [Chapters 2 and 4](FIGURE_DATA_CHAPTER02_04.md)
- [Chapter 3](FIGURE_DATA_CHAPTER03.md)
- [Chapter 5](FIGURE_DATA_CHAPTER05.md)
- [Chapter 6](FIGURE_DATA_CHAPTER06.md)
