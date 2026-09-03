# Chapter 5 figure data

This index links each Chapter 5 figure to the compact numerical data needed to
reproduce its plotted points or curves. The public files contain evaluated
designs, derived plotting fields, and reduced structural-response data; raw
Nastran result files are intentionally excluded.

The feasibility fields are deterministic binary-label scores used by the
implemented optimizer. They are not calibrated posterior probabilities.

## Figure map

| Figure | Public data | Plotting fields | Rows used |
|---|---|---|---:|
| 5.1 | [FCC evaluations](../data/fcc/evaluations_cases001_071.csv), [BCC evaluations](../data/bcc/evaluations_cases001_071.csv), [SC evaluations](../data/sc/evaluations_cases001_071.csv), [case-51 membership](../data/figures/chapter05/figure_5_1_pareto_membership.csv) | Filter each evaluation table to `case_id <= 51`; plot `mass_kg` against `compliance_Nm`; use the membership table for topology-specific and pooled Pareto status. | 153 evaluations and 153 membership rows |
| 5.2 | [FCC evaluations](../data/fcc/evaluations_cases001_071.csv) | `case_id`, `mass_kg`, `compliance_Nm`, `feasible`, `pareto_case071`, `evaluation_period` | 71 |
| 5.3 | [FCC plotted points](../data/figures/chapter05/figures_5_3_and_5_5_fcc_points.csv), [FCC score field](../data/figures/chapter05/figures_5_3_and_5_5_fcc_feasibility_score_grids.csv) | Field: `a_m`, `t1_over_a`, `score_after_observed`; overlays: evaluated design coordinates, feasibility, plotting group, and Pareto status. | 160,801 field nodes and 71 evaluations |
| 5.4 | [FCC failure mechanisms](../data/figures/chapter05/figure_5_4_fcc_failure_mechanisms.csv) | `a_m`, `t1_over_a`, `plot_category`, `pareto_case071`, skin and lattice stresses | 71 |
| 5.5 | [FCC score fields](../data/figures/chapter05/figures_5_3_and_5_5_fcc_feasibility_score_grids.csv), [plotted points and labels](../data/figures/chapter05/figures_5_3_and_5_5_fcc_points.csv) | `score_before_cases_8_29_feasible`, `score_after_cases_8_29_feasible`, and hypothetical label flags | 160,801 field nodes and 71 labels |
| 5.6 | [Case-67 flutter histories](../data/figures/chapter05/figure_5_6_5_8_case067_flutter_histories.csv) | Filter to `point = 3`; plot `velocity_mps` against the four-point and eighteen-point damping columns. | 37 |
| <a id="figure-57"></a>5.7 | [Node-shard manifest](../data/figures/chapter05/figure_5_7_case067_mode3_nodes_manifest.csv), [node-shard directory](../data/figures/chapter05/), [CSV-only plotting script](../scripts/reproduce_thesis_figure.py) | Eight ordered CSV shards retain reference node coordinates, the mode-3 translational eigenvector, displacement magnitude, mode index, and frequency for a portable four-view point-cloud reconstruction. The original nTop surface shading is not reproduced. | 531,682 |
| 5.8 | [Case-67 flutter histories](../data/figures/chapter05/figure_5_6_5_8_case067_flutter_histories.csv) | Group by `point`; plot `velocity_mps` against both damping histories. | 740 |
| 5.9 | [BCC evaluations](../data/bcc/evaluations_cases001_071.csv) | `case_id`, `mass_kg`, `compliance_Nm`, `feasible`, `pareto_case071` | 71 |
| 5.10 | [BCC score field](../data/figures/chapter05/figure_5_10_bcc_feasibility_score_grid.csv), [BCC evaluations](../data/bcc/evaluations_cases001_071.csv) | Field coordinates and `feasibility_score`; evaluated-design overlays and Pareto status | 160,801 field nodes and 71 evaluations |
| 5.11 | [BCC failure mechanisms](../data/figures/chapter05/figure_5_11_bcc_failure_mechanisms.csv) | `a_m`, `t1_over_a`, `plot_category`, `pareto_optimal`, skin and lattice stresses | 71 |
| 5.12 | [BCC ranked shell stresses](../data/figures/chapter05/figure_5_12_bcc_shell_stress_rank_tails.csv) | For each case, plot `rank_descending` against `shell_von_mises_stress_mpa`; the 220 MPa reference is retained in every row. | 6,000 |
| 5.13 | [BCC root hotspots](../data/figures/chapter05/figure_5_13_bcc_root_hotspots.csv) | For each case, plot `x_m` against `span_y_mm`, colour by shell stress, and mark `is_critical_element`. | 300 |
| 5.14 | [SC evaluations](../data/sc/evaluations_cases001_071.csv) | `case_id`, `mass_kg`, `compliance_Nm`, `feasible`, `pareto_case071` | 71 |
| 5.15 | [SC score field](../data/figures/chapter05/figure_5_15_sc_feasibility_score_grid.csv), [SC evaluations](../data/sc/evaluations_cases001_071.csv) | Field coordinates, clipped and raw scores; evaluated-design overlays and Pareto status | 160,801 field nodes and 71 evaluations |
| 5.16 | [SC failure mechanisms](../data/figures/chapter05/figure_5_16_sc_failure_mechanisms.csv) | `a_m`, `t1_over_a`, `plot_category`, `pareto_optimal`, skin and lattice stresses | 71 |
| 5.17 | [Representative topology values](../data/figures/chapter05/figure_5_17_lattice_material_stress_representatives.csv) | `skin_mass_single_kg`, `lattice_mass_single_kg`, `max_vm_MPa`, topology, and case | 3 |
| 5.18 | [Planform score field](../data/figures/chapter05/figure_5_18_planform_feasibility_score_grid.csv), [planform evaluations](../data/planform/evaluations_cases001_050.csv) | Field coordinates, clipped and raw scores; evaluated-design overlays and final Pareto status | 58,081 field nodes and 50 evaluations |
| 5.19 | [Planform evaluations](../data/planform/evaluations_cases001_050.csv) | `CDitrim`, `Ctrim_Nm`, `feasible`, `final_pareto`, `period`, `case` | 50 |
| 5.20 | [Planform evaluations](../data/planform/evaluations_cases001_050.csv) | `AR`, `CDitrim`, `Ctrim_Nm`, `max_screening_stress_mpa`, `modeled_half_wing_mass_kg`, and status fields | 50 |
| 5.21 | [Observed planform points](../data/figures/chapter05/figure_5_21_planform_taper_observed_points.csv), [rigid lifting-line reference curves](../data/figures/chapter05/figure_5_21_planform_taper_llt_reference_curves.csv) | Evaluated induced drag and torsion-corrected efficiency; reference span-efficiency and taper-only induced-drag-penalty curves | 40 observations and 15,025 reference nodes |

## Provenance and scope

The tables are derived from the same evaluated arrays or retained plot-data
records used to generate the thesis figures:

- Figures 5.1--5.5 use the authoritative lattice comparison, FCC continuation,
  feasibility-score, and label-sensitivity records.
- Figures 5.6--5.8 use the two case-67 SOL 145 calculations and the retained
  SOL 103 mode-shape coordinates. The public plotting script reconstructs a
  portable node-cloud view rather than the proprietary nTop surface rendering.
- Figures 5.9--5.16 use the completed BCC and SC continuation records and the
  corresponding compact stress audits.
- Figure 5.17 uses the three representative topology records selected in the
  thesis.
- Figures 5.18--5.20 use the completed 50-evaluation planform record and its
  retained feasibility-score reconstruction.
- Figure 5.21 uses the 40 evaluated planform cases and the rigid lifting-line
  reference sweep.

All CSVs are free of machine-specific operational metadata and solver-native
payloads. The companion
[machine-readable map](../data/figures/chapter05/figure_data_map.csv) records
the same figure-to-file relationships.
