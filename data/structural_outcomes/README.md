# Structural outcome calculations

Compact scalar records supporting the selected lattice-wing and planform outcome tables. This folder is designed for `data/structural_outcomes/` in the accompanying public data repository. It contains no native geometry, solver arrays, or private document/media files.

Run from any working directory with Python 3:

```text
python path/to/structural_outcomes/recalculate.py
```

The script uses only the six adjacent `source_*.csv` numerical input tables and the Python standard library. It regenerates these files beside itself:

| File | Contents |
|---|---|
| `chapter05_topology_outcomes.csv` | Eight selected FCC/BCC/SC designs, nominal diameters, component masses, objectives and screening stresses. |
| `chapter05_planform_outcomes.csv` | Planform cases 45, 47 and 20, including geometric and component-mass comparisons. |
| `chapter06_representative_outcomes.csv` | Coupled cases 4, 37, 64 and 99, geometry, masses, stresses, trim response and aerodynamic load diagnostics. |
| `chapter06_load_diagnostics.csv` | Independently integrated half-wing lift, root aerodynamic moment and lift centroid. |
| `design_comparisons.csv` | Directed differences and percentage changes between named cases. |
| `chapter06_corner_pairs.csv` | All 32 one-input comparisons among the 16 initial corners, with the other three inputs fixed. |
| `chapter06_corner_summary.csv` | Minimum, median and maximum percentage changes across eight pairs per input. |

`source_provenance.csv` maps included column groups to existing public files using repository-relative paths and case selectors. Those pointers document provenance; the recalculation does not read outside this folder. Numerical identities, unique case keys, matched-pair counts and load-profile coordinates are validated on each run. Export rounding is allowed within the explicit tolerances in the script.

## Quantities and conventions

- Lengths are metres unless a column ends `_mm`; mass is kilograms; compliance and aerodynamic moment are N m; stress is MPa. Aspect ratio, taper, diameter ratios, coefficients and utilization are dimensionless.
- Nominal circular-member endpoint diameters are `t1 = CellSize_m * RootRatio` and `t2 = t1 * TipRootRatio`. They are geometry inputs, not Nastran beam radii or measurements inferred from graph strokes. The fixed-area trapezoid uses `semispan = sqrt(AR*S)/2` and `root_chord = S/[semispan*(1+taper)]`.
- Optimization mass is `2*(SkinMassHalf_kg + LatticeMassHalf_kg)`. Lattice mass here is the implicit-geometry quantity. The included diagnostic deck/CBEAM masses can differ because of beam representation and joint-volume accounting; they are not substituted into the optimization total. Stored shell mass and deck mass also need not be identical under every mesh configuration. A skin mass fraction does not measure its stiffness or strain-energy share.
- Two-wing trim compliance is four times retained half-wing trim strain energy. The recorded induced-drag objective remains `CDitrim`, including its original interpolation convention.
- Shell screening stress is the raw von Mises maximum; lattice screening stress is the maximum absolute CBEAM normal stress. Both use the fixed-angle screening cases and the 220 MPa limit. They differ from the separately exported stresses interpolated at structural trim. Screening reserve `100*(1-max_stress/220)` is a numerical margin, not a validated safety factor.
- Topology and planform signed labels use `C <= 0` for accepted records. Coupled records retain their published Boolean feasibility. Case 4 is an initial prescribed corner; cases 37, 64 and 99 are adaptive. Cases 4/37/64 retain baseline mesh controls, whereas case 99 uses refined controls.
- All differences use `to - from`; every percentage uses `100*(to/from - 1)`, with the direction encoded by the case columns. Corner comparisons include stress-infeasible designs and each design's own coupled trim response.

## Load and lever-arm arithmetic

For each of four coupled representatives, the included 401-point public lifting-line profile supplies normalized semispan `eta` and lift per unit span `l(eta)`. The script sets `y = eta*semispan` and applies the trapezoidal rule to calculate:

```text
L_half = integral(l(y) dy)
M_root_aero = integral(y*l(y) dy)
y_lift = M_root_aero/L_half
normalized_lift_centroid = y_lift/semispan
```

The integrated moments are checked against independently retained public root-moment scalars. These are torsion-corrected lifting-line aerodynamic quantities evaluated at lifting-line trim. They are not extracted doublet-lattice-model loads, finite element internal forces, recovered root reactions, or a decomposition of bending and torsion. Structural trim deformation is a separately retained SOL 144 result.

For planforms the script also supplies the projected-area centroid `semispan*(1+2*taper)/[3*(1+taper)]`. This is a geometric quantity, not an observed aerodynamic load centroid.

## Provenance and interpretation limits

“Observed” here means a stored result from a numerical evaluation, not a physical measurement. Nominal diameters, two-wing component sums, percentage differences, area centroids and load integrals are calculated from included values. Statements about longer loading levers, regenerated lattice population or load sharing are interpretations subject to the stated model; the tables do not isolate member-force or energy contributions.

The planform component masses and half-wing trim energies for cases 45/47/20 are newly supplied scalar exports from retained evaluated outputs (`skinMass`, `latticeMass`, `trimStrainEnergy`). They were not present in the earlier public scalar tables. The published planform total masses and compliances provide cross-checks. This bundle makes the scalar arithmetic reproducible; it does not make the underlying native geometry or raw solver outputs publicly available.

The public FCC40 reference table has a legacy field named `t2_over_a` containing 0.5. The verified input definition is `t2/t1`, and this bundle explicitly names the quantity `TipRootRatio`. It must not be read as `t2/a`. The public solver-workflow input definitions provide the correct convention.

Topology cases 1-51 are inherited conditioning records; their `initial_training` label in earlier exports does not establish their original sampling origin. FCC26/FCC40/BCC17 were already present before the continuation. FCC61 is a primary continuation selection; FCC70/SC53/SC70 are challenger selections. The common topology flutter reassessment does not remove unresolved earlier static-setting differences. Planform20 retains the earlier flutter acceptance basis; 45/47 use the strict continuation basis.

The three pictured topology representatives are each family's minimum-mass feasible example; only FCC70 belongs to the pooled observed front. No matched complete-wing relative-density comparison, conventional spar/rib baseline, manufacturing validation, or new unit-cell/connectivity search is established by these calculations.
