# Thesis reproducibility package

This release adds the completed harmonized SOL 145 topology reassessment and
synchronizes the public thesis and Paper 2 artifacts.

## New evidence

- 65 targeted topology reruns: BCC 15, FCC 32, and SC 18.
- 65 strict numerical passes, zero positive-damping outcomes, zero outstanding
  cases, zero invalid receipts, and zero conflicts in the guarded private
  ledger.
- A sanitized 65-row public table with no machine path, network address,
  license configuration, credential, or native solver output.
- A MATLAB consistency checker and experiment guide.

Together with the prior FCC case-67 diagnostic and 26 BCC/SC continuation
cases already produced under the strict configuration, all 92
static-admissible topology cases through case 71 pass the common numerical
screen. This does not rewrite their historical optimization labels or
selection histories.

## Attached PDFs

- `main.pdf`: updated thesis with the harmonized campaign in the abstract,
  methodology, results, synthesis, and provenance appendix.
- `paper2_lattice_topology_aiaa.pdf`: revised AIAA-format manuscript.
- `thesis_reference_verification_report.pdf`: unchanged citation-evidence
  report; no citation-bearing thesis sentence was changed by this campaign
  update.

| Asset | Pages | SHA-256 |
|---|---:|---|
| `main.pdf` | 218 | `6f56dd6f3bf592f2037cbf7153742f6190f6d969366b5c970df6ac20c548618c` |
| `paper2_lattice_topology_aiaa.pdf` | 14 | `f4c760fe431b102b51cdc903d1be8128d33ca8230260bbda9eff4430ede1e637` |
| `thesis_reference_verification_report.pdf` | 49 | `c1e7f14a58389fa472c6b2a00ce420335a63eab2a2e715a3dcb9c1a2663c9740` |

## Boundary

The new result is an implemented numerical screen over 20 roots and 37
velocities from 30 to 150 m/s. It is not independent flutter validation,
reduced-frequency convergence, a topology-wide flutter ranking, or
certification-level clearance.
