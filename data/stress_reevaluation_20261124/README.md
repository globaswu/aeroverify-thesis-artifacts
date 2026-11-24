# Contact-refined stress reevaluation and lattice refinements

This release documents the 24 November 2026 thesis results. It contains 363 case-level outputs from MSC Nastran SOL 144 at 12° incidence, 26 verified joint skin and lattice refinements, and the samples behind the updated shell-stress and flutter figures.

## Data for the thesis

| Thesis material | Data |
| --- | --- |
| Tables 5.1, 7.1, and D.9–D.15 | [Casewise stress and eligibility](casewise_stress.csv), [per-study tables](casewise), [counts](summary.json) |
| Observed Pareto plots in Chapters 5 and 6 | [Pareto membership](pareto_membership.csv) |
| Lattice stress-failure maps in Chapter 5 | [Component stresses and failure classifications](failure_mechanisms.csv) |
| Feasibility fields in Chapters 5 and 6 and Appendix D | [Paired score grids and 184 MPa grids](feasibility) |
| Figure 5.24 and Table D.16 | [Joint refinements and trim samples](refinement) |
| Figure 5.25 | [BCC 33 PK roots](refinement/BCC033_PK_roots.csv), [FCC 18 PK roots](refinement/FCC018_PK_roots.csv) |
| Figure 6.5 | [Case 37 and Case 99 shell meshes, stress envelopes, and plotting code](figure_6_5) |
| Figure 6.7 | [Spanwise 12° shell and CBEAM stress profiles, strain energy, and damping](figure_6_7) |
| Figure 2.8 and Table 2.7 | [Full-wing attachment comparisons](model_checks) |
| Bonded rod–plate mesh and convergence figures and table | [Mesh settings, planar meshes, and stress profiles](model_checks/coupon) |

The initial optimization used an aggregate feasibility label covering trim, component stress, and applicable flutter checks. The stress reevaluation uses a refined shell mesh and distributed attachment loads at 12°. A design passes a stress limit when both the maximum absolute beam normal stress and maximum shell von Mises stress are at or below it. The Pareto comparisons use the evaluated objective coordinates from the initial optimization and apply each stated eligibility rule. The `comparison` column in the membership file distinguishes the pooled topology front from within-study fronts.

The refinement table reports assembled finite element mass. Its parent masses use the first-stage geometric convention. The refined trim response is evaluated by interpolating half-wing strain energy in the lift-equivalent bracket and multiplying by four. The 184 MPa comparison is based on the static stress screen. The separate PK tables give the two sampled flutter checks.

Casewise CSV headers give units. Empty fields and printed dashes preserve unavailable or inapplicable quantities. For lattice score grids, `x1` is cell size in metres and `x2` is the root member-size ratio. For planform grids they are aspect ratio and taper ratio. The `original_score` and `score_12deg` columns represent scores fitted to the initial optimization and 220 MPa stress labels, respectively. The 184 MPa two-input NPZ grids contain query coordinates, evaluated design coordinates, the clipped score, and the stress labels. The four-input score CSV also contains the 184 MPa field.

This package provides the compact numerical records and source data for the items listed above. [The thesis companion release](https://github.com/globaswu/aeroverify-thesis-artifacts/releases/tag/thesis) documents the initial optimization and earlier analytical examples. Rerunning geometry generation or solving requires the licensed software and model inputs described in the companion workflow documentation.

Run `python verify_release.py` from any location to check the hashes and primary result counts. The figure-specific README explains the steps for reproducing Figure 6.5.
