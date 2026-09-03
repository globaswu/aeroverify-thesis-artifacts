# Public data dictionary

All public tables are UTF-8 CSV files with one header row. They were exported
through explicit schemas: no column contains a personal filesystem path,
remote archive path, credential, raw solver array, or native commercial file.

## Topology studies

`fcc/`, `bcc/`, and `sc/` each contain the complete 71-row evaluated record and
the cases 52-71 continuation table. Common fields are:

| Field | Meaning |
|---|---|
| `case_id` | Contiguous case index. |
| `a_m` | Cell size [m]. |
| `t1_over_a` | Primary member-thickness ratio [-]. |
| `mass_kg` | Two-wing total mass [kg]. |
| `compliance_Nm` | Two-wing trim compliance [N m]. |
| `constraint` | Stored aggregate label; values at or below zero are feasible. |
| `feasible` | Authoritative stored feasibility label. |
| `pareto_case071` | Observed feasible Pareto membership after case 71. |
| `selection_source` | Saved primary or challenger source for continuation rows. |

FCC/BCC continuation tables retain more scalar diagnostics than the finalized
SC export. Missing SC stress, damping, acquisition, and fallback fields are not
inferred. The three campaigns also retain different contemporaneous flutter
rules; see each `flutter_screen` field.

## Harmonized flutter reassessment

`flutter/harmonized_sol145_results.csv` contains a separate retrospective
verification layer for 65 targeted stress-admissible cases. It preserves the
historical labels above while recording the common strict-screen result. All 65
rows pass. The table contains no native solver output or machine, archive, or
license configuration.

## Planform

`planform/evaluations_cases001_050.csv` contains aspect ratio, taper ratio,
trim induced-drag coefficient, trim compliance, feasibility, observed Pareto
membership, selection source, half-wing mass, and component stress summaries.

## Four-input campaign

`multiinput/evaluations_cases001_100.csv` joins the public design, objective,
constraint, stress, flutter, acquisition, and mass fields by case index. The
join is one-to-one for cases 1-100. The folder also contains the archived
adaptive hypervolume/stress history, observed Pareto subset, representative
designs, and final JSON summary.

## Mesh convergence and case-67 diagnostic

`mesh_convergence/results_summary.csv` contains 17 compact solver-result rows.
Its original local light-output path field was deliberately removed.
`diagnostics/fcc_case067/old_vs_18_point_all20.csv` contains the 20-point
four-versus-18-frequency comparison, with 37 velocity rows summarized per
tracked point.

## Representative physics

The exact-trim file contains 50 planform plus 100 four-input rows. The other
tables contain the five representative cases 4, 37, 64, 65, and 99 used for
compact physical and mass-convention checks.

Source folders, transformations, and limitations are recorded in
`docs/DATA_PROVENANCE.md` and `experiments.json`.

## Figure-level exports

`figures/chapter02`, `figures/chapter03`, `figures/chapter04`,
`figures/chapter05`, and `figures/chapter06` contain the exact numerical rows
used by thesis figures that cannot be reconstructed directly from the compact
campaign tables above. Their schemas, filters, and relationships to the
rendered panels are listed in [`docs/FIGURE_DATA_MAP.md`](../docs/FIGURE_DATA_MAP.md).
These exports omit native solver files, machine paths, archive locations,
licence configuration, and non-scientific execution timestamps.
