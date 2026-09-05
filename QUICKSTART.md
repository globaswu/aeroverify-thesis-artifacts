# Quick start

## 1. Download

Download the [complete `thesis` source ZIP](https://github.com/globaswu/aeroverify-thesis-artifacts/archive/refs/tags/thesis.zip)
and extract it to a writable directory. The repository root is the extracted
folder containing `matlab`, `data`, and `config`. Run the terminal commands
below from that folder, not from an `experiments/` subfolder. Do not place
generated files under `data/`.

To inspect data without software, open the [FCC](data/fcc/evaluations_cases001_071.csv),
[BCC](data/bcc/evaluations_cases001_071.csv), or
[SC](data/sc/evaluations_cases001_071.csv) CSV directly on GitHub.
For MATLAB Command Window instructions and the images to open afterwards,
see the [lattice-sizing guide](experiments/lattice_sizing/README.md).

## 2. Verify the release

From PowerShell in the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\verify_manifest.ps1
python scripts/verify_figure_packages.py
```

A successful run reports the number of listed files and confirms hashes,
sizes, excluded file types, machine-path screening, and file completeness.
The verifier compares text as UTF-8 with LF line endings, so normal Windows
CRLF conversion does not invalidate a release. For a red cross shown beside
an older file commit, consult the [current workflow runs](https://github.com/globaswu/aeroverify-thesis-artifacts/actions/workflows/verify.yml)
and [troubleshooting](docs/TROUBLESHOOTING.md#a-manifest-check-fails).

## 3. Run all solver-free checks

```powershell
matlab -batch "addpath('matlab'); run_tests"
```

The tests check the packaged numerical records and create all public outputs in
a temporary directory. They do not call nTopology, MSC Nastran, or OpenFOAM.

## 4. Keep the generated outputs

```powershell
matlab -batch "addpath('matlab'); reproduce_all(fullfile(pwd,'generated'))"
```

Study-specific commands are also available:

```powershell
matlab -batch "addpath('matlab'); reproduce_topology('fcc',fullfile(pwd,'generated','fcc'))"
matlab -batch "addpath('matlab'); reproduce_planform(fullfile(pwd,'generated','planform'))"
matlab -batch "addpath('matlab'); reproduce_multiinput(fullfile(pwd,'generated','multiinput'))"
matlab -batch "addpath('matlab'); reproduce_mesh_convergence(fullfile(pwd,'generated','mesh_convergence'))"
matlab -batch "addpath('matlab'); reproduce_flutter_reassessment(fullfile(pwd,'generated','flutter_reassessment'))"
```

Expected filenames and numerical postconditions are listed in
[docs/EXPECTED_OUTPUTS.md](docs/EXPECTED_OUTPUTS.md).

## 5. Reproduce one thesis figure

Each data-based figure has a self-contained CSV/Python/MATLAB folder. For
example:

```powershell
python data/figures/chapter05/figure_5_1/plot_5_1.py
matlab -batch "addpath('data/figures/chapter05/figure_5_1'); plot_5_1"
```

To use the optional Python dispatcher:

```powershell
python -m pip install -r requirements-figures.txt
python scripts/reproduce_thesis_figure.py 5.1
```

See [docs/FIGURE_DATA_MAP.md](docs/FIGURE_DATA_MAP.md) for all 53 folders,
including supplementary figures in Appendices C and D. Figure 2.8 is a special
case: the thesis displays nTop screenshots, whereas the scripts reconstruct
the same modal node field as a point cloud.

The seven-solver benchmark's [hypervolume-ratio table](data/benchmarks/seven_solver_comparison/hv_ratio_table.csv)
and [evaluations](data/benchmarks/seven_solver_comparison/evaluations.csv)
are directly inspectable as CSV. Figures 3.7 and 3.8 plot the observed Pareto
sets using only their respective adjacent CSV files. Consult the
[benchmark guide](experiments/seven_solver_comparison/README.md) for the
binary-label versus continuous-margin information supplied to the methods.

## 6. Understand the boundary

The public commands reconstruct analyses from evaluated scalar records. A new
physical case needs licensed external software and project assets that are not
in this repository. Read [docs/REPRODUCIBILITY_SCOPE.md](docs/REPRODUCIBILITY_SCOPE.md)
before describing the package as a simulation rerun.
