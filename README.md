# Aeroelastic Lattice-Wing Thesis Reproducibility Package

This repository is the curated public companion to Sen Wu's doctoral thesis,
*Aeroelastic Bayesian Optimization of Additively Manufactured Multi-Layer
Lattice-Structured Wings*. It contains portable MATLAB code and frozen,
path-free tables for checking the reported finite-sample results without
uploading the 74 GB research workspace.

- Stable release: [thesis-v1.0.1](https://github.com/globaswu/aeroverify-thesis-artifacts/releases/tag/thesis-v1.0.1)
- Final thesis: [main.pdf](https://github.com/globaswu/aeroverify-thesis-artifacts/releases/download/thesis-v1.0.1/main.pdf)
- Start here: [QUICKSTART.md](QUICKSTART.md)
- Thesis-to-file crosswalk: [docs/FILE_CROSSWALK.md](docs/FILE_CROSSWALK.md)
- Machine-readable experiment register: [experiments.json](experiments.json)

## What runs from this repository

The single MATLAB command below reconstructs public figures, tables, and
summary checks for all packaged wing studies:

```powershell
matlab -batch "addpath('matlab'); reproduce_all(fullfile(pwd,'generated'))"
```

The package checks the following frozen records:

| Study | Evaluations or rows | Feasible | Observed Pareto |
|---|---:|---:|---:|
| FCC lattice sizing | 71 | 33 | 26 |
| BCC lattice sizing | 71 | 27 | 17 |
| SC lattice sizing | 71 | 32 | 8 |
| Fixed-area planform | 50 | 39 | 14 |
| Four-input aerostructural campaign | 100 | 70 | 38 |
| Structural-mesh sensitivity | 17 | not applicable | not applicable |
| FCC case-67 reduced-frequency diagnostic | 20 tracked points | not applicable | not applicable |
| Exact-trim LLT reconstruction | 150 cases | not applicable | not applicable |

These counts are recomputed from evaluated objectives and authoritative stored
feasibility labels. Surrogate fronts are not substituted for observed fronts.

## Reproducibility levels

1. **Executable here.** MATLAB regenerates plots and tables from the released
   CSV and JSON files. `run_tests` verifies row counts, logical labels, Pareto
   membership, selected numerical controls, and expected output files.
2. **Executable core software.** `matlab/+ctsemo` contains the current modular
   cTSEMO implementation used by this package. The complete analytical
   benchmark campaigns are maintained as a separate software release and are
   not reconstructed from the aerostructural tables.
3. **Documented licensed-solver interface.** New physical evaluations require
   MATLAB, nTopology, MSC Nastran, and, for polar regeneration, OpenFOAM. The
   proprietary nTopology projects, solver-native outputs, and third-party
   optimizer trees are not redistributed. See
   [docs/FULL_SOLVER_WORKFLOW.md](docs/FULL_SOLVER_WORKFLOW.md).

Publishing the orchestration boundary does not make the historical expensive
campaigns bitwise reproducible. The repository supports independent replay of
the reported compact-record analyses and records what is missing for a fresh
solver run.

## Validate before use

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\verify_manifest.ps1
matlab -batch "addpath('matlab'); run_tests"
```

Or run both through:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\reproduce.ps1
```

The MATLAB tests were validated with MATLAB R2025b. The minimum compatible
release was not established. No Git or GitHub command is required after
downloading the release archive.

## Scientific boundaries

- Topology cases 1-51 are retained as inherited conditioning and descriptive
  data. Their source settings do not match the final configuration, and the
  exact setting-level differences are unresolved.
- The FCC continuation retains its contemporaneous four-point MKAERO1 screen.
  BCC and SC use later strict positive-damping rejection rules. These labels
  must not be homogenized retrospectively.
- Planform cases 1-40 do not have a fully reconstructed candidate-selection
  history. Cases 41-50 are the documented continuation.
- The final four-input record spans two mesh epochs and includes a replacement
  evaluation for case 65. The original launcher alone does not recreate the
  final 100-row record.
- The geometry score reconstructed for the two-input studies is a clipped,
  deterministic binary-label score. It is not a calibrated probability.
- The exact-trim files replay the frozen LLT calculation. They do not validate
  the physical fidelity of LLT, DLM, finite element, or flutter models.

## Repository map

```text
.
|-- QUICKSTART.md
|-- experiments.json
|-- manifest.json
|-- config/
|-- data/
|   |-- fcc/  bcc/  sc/
|   |-- planform/
|   |-- multiinput/
|   |-- mesh_convergence/
|   |-- diagnostics/fcc_case067/
|   `-- representative_physics/
|-- experiments/              study-specific guides
|-- matlab/                    executable public workflows
|-- docs/                      scope, provenance, software, outputs
`-- tools/                     manifest and one-command checks
```

Generated files are written only beneath `generated/`, which is ignored by
Git. Source data under `data/` are treated as immutable release inputs.

## License and citation

Project-owned content is released under the BSD 2-Clause License. The cTSEMO
source retains its own matching notice in `LICENSE-CTSEMO.txt`. Commercial
software and proprietary project files are not included. See
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and [CITATION.cff](CITATION.cff).
