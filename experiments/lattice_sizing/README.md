# FCC, BCC, and SC lattice sizing

This guide plots the evaluated mass-compliance results and the reconstructed
binary-feasibility score for the FCC, BCC, and SC studies. It uses the released
data; it does not run a new wing simulation.

## Inspect the data without running code

Open an evaluation CSV on GitHub, or download it for inspection:

| Lattice family | All evaluations | Continuation cases |
|---|---|---|
| FCC | [CSV](../../data/fcc/evaluations_cases001_071.csv) | [CSV](../../data/fcc/continuation_cases052_071.csv) |
| BCC | [CSV](../../data/bcc/evaluations_cases001_071.csv) | [CSV](../../data/bcc/continuation_cases052_071.csv) |
| SC | [CSV](../../data/sc/evaluations_cases001_071.csv) | [CSV](../../data/sc/continuation_cases052_071.csv) |

## Plot one family in MATLAB

1. [Download the complete thesis source ZIP](https://github.com/globaswu/aeroverify-thesis-artifacts/archive/refs/tags/thesis.zip) and extract it. Downloading only this README or one MATLAB file is not sufficient.
2. Open MATLAB. Set its **Current Folder** to the extracted repository root: the folder containing `matlab`, `data`, and `config`. Do not use this `experiments/lattice_sizing` subfolder as the working folder.
3. Paste the following into the **MATLAB Command Window**:

```matlab
addpath('matlab');
topology = 'fcc';                 % Choose 'fcc', 'bcc', or 'sc'.
outputFolder = fullfile(pwd, 'generated', topology);
summary = reproduce_topology(topology, outputFolder);
disp(summary);
disp(outputFolder);
```

4. Open the output folder printed by the command. On Windows, you can open it directly from MATLAB with `winopen(outputFolder)`.

For FCC, open these images:

- `generated/fcc/fcc_observed_pareto.png`: evaluated mass-compliance trade-offs.
- `generated/fcc/fcc_feasibility_score.png`: reconstructed design-space feasibility score.

The plotting functions save and close their figures, so no plot window remains
open automatically. They also write PDF versions of both plots,
`fcc_continuation_table.csv`, `fcc_continuation_table.tex`, and
`fcc_continuation_summary.csv` in the same folder. BCC and SC use the
corresponding filename prefixes.

MATLAB R2025b is the validated release; the minimum compatible release has not
been established. No nTop, Nastran, or OpenFOAM installation is needed for
these plotting commands.

## Alternative: run from PowerShell

From the same extracted repository root, paste this into **PowerShell**, not
the MATLAB Command Window:

```powershell
matlab -batch "addpath('matlab'); reproduce_topology('fcc',fullfile(pwd,'generated','fcc'))"
```

Replace both `fcc` occurrences with `bcc` or `sc`. MATLAB must be on the
terminal's search path; otherwise use the MATLAB-window instructions above.

## Check the result

Inputs are the matching `data/<topology>` folder and
`config/reproduction_config.json`. The summary should report:

| Family | Evaluations | Feasible | Observed Pareto |
|---|---:|---:|---:|
| FCC | 71 | 33 | 26 |
| BCC | 71 | 27 | 17 |
| SC | 71 | 32 | 8 |

The score is not a calibrated probability. These commands reproduce
optimization-result plots, not the nTop unit-cell screenshots. If you arrived
from the unit-cell figure in Chapter 1, the link provides the associated study
data; the proprietary nTop projects are not distributed here.

For a single numbered quantitative figure, use its adjacent CSV and plotting
script from the [figure index](../../docs/FIGURE_DATA_MAP.md).

## A red cross beside this file on GitHub

The icon beside a file's last commit reports that commit's checks, not
necessarily the current release. The initial publication had a Windows
line-ending size mismatch; the verifier was subsequently made portable.
See the [current verification runs](https://github.com/globaswu/aeroverify-thesis-artifacts/actions/workflows/verify.yml)
and the [manifest troubleshooting guide](../../docs/TROUBLESHOOTING.md#a-manifest-check-fails).
