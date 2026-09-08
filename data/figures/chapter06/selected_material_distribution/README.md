# Selected material distribution

This figure compares four evaluated Chapter 6 designs: case 4 (initial corner), case 37 (adaptive, lightest feasible), case 64 (adaptive, intermediate compromise), and case 99 (adaptive, lowest feasible trim induced drag).

The bundle contains one self-contained four-row CSV, `selected_material_distribution.csv`, and two alternative plotting implementations. Each implementation reads only that adjacent CSV. No optimizer, geometry engine, solver, private archive, or network connection is used.

## Reproduce

Python requires Matplotlib. From any working directory, choose an output path outside this source bundle:

```text
python plot.py --output /path/to/output/selected_material_distribution.png
```

The Python output argument supports `.png`, `.pdf`, and `.svg`. PNG output is 600 dpi. The output directory must already exist.

MATLAB uses its standard graphics functions and needs no additional toolbox. Add this bundle directory to the MATLAB path and supply a PNG output filename:

```matlab
addpath('/path/to/this/bundle');
plot_material_distribution('/path/to/output/selected_material_distribution.png');
```

The thesis raster was generated with MATLAB R2025b at 600 dpi. The two implementations reproduce the same data and visual encodings; their raster pixels need not be identical.

## Definitions and sources

Panel (a) plots the prescribed linear nominal input law

`t(eta) = t1 + (t2 - t1)*eta`, with `eta = y/s` from zero at the root to one at the tip.

The CSV supplies the evaluated nominal root and tip diameters, in mm. Intermediate line points are evaluations of this prescribed law, not independent measurements. These profiles are not extracted post-warp member diameters, inferred relative-density fields, or optimized connectivity. The optimized endpoint values describe a prescribed grading family.

Panel (b) stacks the stored two-wing skin mass and nTop implicit-lattice mass, in kg, with a zero baseline. Their sum agrees with the stored two-wing optimization mass to within 1e-9 kg. The implicit-lattice contribution is not the sum of CBEAM length-area volumes. Labels inside the open segments identify skin mass; labels above the stacks identify total mass.

The selected cases and scalar responses come from the repository's accepted 100-case analysis:

- `data/multiinput/evaluations_cases001_100.csv`, keyed by `Case` = 4, 37, 64, 99, establishes origin and total mass.
- `data/representative_physics/representative_physics_cases004_037_064_065_099.csv` supplies the physical endpoint dimensions (legacy columns `R1_m` and `R2_m`, multiplied by 1000). These fields are nominal member diameters despite their legacy column names.
- `data/representative_physics/mass_compliance_check_cases004_037_064_065_099.csv` supplies `StoredSkinMassHalf_kg` and `NtopLatticeMassHalf_kg`; each is multiplied by two.

The plot retains those source values at their saved precision. It displays case 4/37/64/99 in the same order and colors in both panels, with distinct line styles and endpoint markers. It does not isolate a causal sizing effect because the four designs also differ in planform and trim condition.

Suggested caption: Selected nominal member grading and two-wing mass allocation for cases 4, 37, 64 and 99. (a) The prescribed linear diameter law evaluated using each design's root and tip parameters; these are nominal input profiles, not post-warp diameter measurements. (b) Stored skin mass and nTop implicit-lattice mass under the optimization mass convention. Case 4 is an initial corner; cases 37, 64 and 99 are adaptive evaluations.
