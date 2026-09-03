# Thesis reproducibility package

This release synchronizes the thesis and both AIAA-format manuscripts and adds
direct CSV-and-script reproduction for every quantitative thesis figure.

## New evidence

- 65 targeted topology reruns: BCC 15, FCC 32, and SC 18.
- 65 strict numerical passes, zero positive-damping outcomes, zero outstanding
  cases, zero invalid receipts, and zero conflicts in the guarded private
  ledger.
- A sanitized 65-row public table with no machine path, network address,
  license configuration, credential, or native solver output.
- A MATLAB consistency checker and experiment guide.
- Figure-specific CSV files for all 50 quantitative figures in Chapters 2--6.
- A Python dispatcher that regenerates all 50 figures from public CSV files
  only, without MAT files, Nastran output, nTop projects, or private paths.
- A MATLAB routine that refits the five lattice/planform feasibility maps from
  the published design inputs (X) and binary labels (C); the accompanying
  case CSVs retain the objective responses (Y).

Together with the prior FCC case-67 diagnostic and 26 BCC/SC continuation
cases already produced under the strict configuration, all 92
static-admissible topology cases through case 71 pass the common numerical
screen. This does not rewrite their historical optimization labels or
selection histories.

## Attached PDFs

- `main.pdf`: updated thesis with the harmonized campaign in the abstract,
  methodology, results, synthesis, and provenance appendix.
- `paper2_lattice_topology_aiaa.pdf`: revised AIAA-format manuscript.
- `paper3_integrated_aerostructural_aiaa.pdf`: revised AIAA-format manuscript.
- `thesis_reference_verification_report.pdf`: unchanged citation-evidence
  report; no citation-bearing thesis sentence was changed by this campaign
  update.

| Asset | Pages | SHA-256 |
|---|---:|---|
| `main.pdf` | 218 | `b2948682205f439808a5d459e3eaad5fb0f19909d8d956fbc4d48c6a2d743c03` |
| `paper2_lattice_topology_aiaa.pdf` | 14 | `88250ab56a7c063a2940e0ef2809b4d6abb1fb7c27e0959b964c95eaa81042f3` |
| `paper3_integrated_aerostructural_aiaa.pdf` | 16 | `f6934d07ce8b5790abff524b5a94554d600a5a96394f719135e71b409a58a8c6` |
| `thesis_reference_verification_report.pdf` | 49 | `c1e7f14a58389fa472c6b2a00ce420335a63eab2a2e715a3dcb9c1a2663c9740` |

## Boundary

The new result is an implemented numerical screen over 20 roots and 37
velocities from 30 to 150 m/s. It is not independent flutter validation,
reduced-frequency convergence, a topology-wide flutter ranking, or
certification-level clearance.
