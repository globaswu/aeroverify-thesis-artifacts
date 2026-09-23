# Case 4 lattice mass profiles before and after section calibration

This dataset reproduces the spanwise and chordwise comparison between the original
CBEAM representation, the adjusted CBEAM representation, and the nTop Slice Body
reference. It concerns the half-wing lattice, excluding skin. The adjustment is the
retained 18 September 2026 candidate obtained by minimizing the sum of the two
unnormalized integrated squared profile errors, with one uniform radius per
original beam and a whole-lattice mass constraint of 36.2745 kg.

## Files and units

| File | Content |
| --- | --- |
| `span_before_after.csv` | 1,866 adjoining spanwise intervals and all three mean mass profiles. |
| `chord_before_after.csv` | 1,033 adjoining chordwise intervals and all three mean mass profiles. |
| `csa_slice_body_original.csv` | 1,867 original spanwise Slice Body areas in mm²; one value per row, without a header or coordinate column. |
| `csay_original.csv` | 1,034 original chordwise Slice Body areas in mm²; one value per row, without a header or coordinate column. |
| `calibration_summary.json` | Retained whole-lattice masses, integrated squared errors, candidate constraints, and solver termination metadata. |
| `source_provenance.csv` | Retained source-file identity and SHA-256 provenance. |
| `reproduce.py` | Numerical verification followed by PNG and SVG reproduction. |

Table source: the packaged CSV headers, source row counts, and calibration summary.
The two comparison CSVs contain the following columns:

| Column | Definition | Unit |
| --- | --- | --- |
| `Start_m` | Lower interval boundary. | m |
| `End_m` | Upper interval boundary. | m |
| `Midpoint_m` | Arithmetic mean of the interval boundaries, used for plotting. | m |
| `Before_kg_m` | Mean original CBEAM mass per unit length in the interval. | kg/m |
| `After_kg_m` | Mean adjusted CBEAM mass per unit length for the raw squared-error candidate. | kg/m |
| `nTop_kg_m` | Mean Slice Body mass per unit length from the two bounding area samples. | kg/m |

Table source: retained profile-export definitions and the packaged CSV headers.
`After_kg_m` belongs to the raw squared-error candidate; the preceding normalized-fit
warm start is recorded separately in `calibration_summary.json` and is not plotted.

## Coordinate and source provenance

Figure coordinate **x is spanwise global nTop/GRID Y**, from root toward tip.
The spanwise area rows are assigned reconstructed positions
`0, 0.001, ..., 1.866 m`. The comparison has 1 mm intervals from 0 to 1.866 m and
midpoints from 0.0005 to 1.8655 m. The initially suggested sequence beginning at
0.001 m was superseded before the retained figures were generated. The final
approximately 0.46 mm of nominal semispan is outside this sampled domain.

The spanwise source record identifies an unchanged copy of the user's Slice Body
area export from **17 September 2026, 23:54 JST**. The recorded nTop 6.0.3 setup
uses body `filterfill`, layer height 0.001 m, feature size 0.0005 m, frame origin
(0, 0, 0), local X = (1, 0, 0), and local Y = (0, 0, -1). The resulting frame
normal is global +Y, with Include Negative Z unchecked. Individual spanwise slice
coordinates were not exported or inspected; the mapping follows the recorded
frame, spacing, row count, and semispan. It is retained as a coordinate
interpretation, not presented as an exported coordinate column.

Figure coordinate **y is chordwise global nTop/GRID X**, measured along the global
root-leading-edge axis; it is not local chord fraction. The chordwise area rows
are assigned positions `0.001, 0.002, ..., 1.034 m`. The comparison covers 1 mm
intervals from 0.001 to 1.034 m, with midpoints from 0.0015 to 1.0335 m.

The chordwise source record identifies an unchanged copy of the user's area
export from **18 September 2026, 00:13 JST**. Its recorded nTop 6.0.3 `slicey`
setup uses `filterfill`, excluding skin, with the same layer height and feature
size, frame origin (0, 0, 0), local X = (0, 1, 0), and local Y = (0, 0, 1).
The normal is global +X, with Include Negative Z unchecked. The record states that
the first two slice heights were inspected as 0.001 and 0.002 m. The final position
follows from this start, spacing, and count; the last individual height was not
read. Neither source area array is reversed, smoothed, or uniformly rescaled.
No artificial zero-area endpoint or extrapolated endpoint is included.

Source identity and hashes are retained in `source_provenance.csv`. Public CSV
text uses UTF-8 encoding and LF line endings while preserving the numerical cell
strings. The provenance distinguishes retained source-byte hashes from the
normalized public-file hashes. The original area-file SHA-256 values are:

```text
csa_slice_body_original.csv
90a607c9aa60d2f22b5dacf4a06ad59de8625d4af70535dc3bedbd2bd1478b5f

csay_original.csv
b662636b4f2dd64a8bae9e1bc6b37d7f3226e87a076ed91f4123bc8c8c975e08
```

## Calculations and interpretation

Let A_i be an original Slice Body area sample in mm², rho = 2700 kg/m³ the
retained material density, and delta_q_i the interval width in m. The target
interval mean is

```text
w_SliceBody,i = rho * 1e-6 * (A_i + A_(i+1)) / 2             [kg/m]
m_i          = w_i * delta_q_i                              [kg]
J_axis       = sum((w_CBEAM,i - w_SliceBody,i)^2 * delta_q_i) [kg²/m]
```

The target calculation is equivalent to trapezoidal integration of the bounding
area samples followed by division by interval width. The CBEAM profiles project
independent finite-radius circular members, retaining additive overlaps and the
original per-member normalization at the full geometric domain boundaries.
They are geometric mass representations, not a spatial extraction of the
assembled finite element mass matrix. The adjusted candidate changes each
eligible original beam's uniform radius, without subdivision or additional beams.

Integrate the saved **interval means using the interval widths**. Straight lines
between interval midpoints are plotting guides; applying trapezoidal integration
to those plotted midpoints would change the integration limits and quadrature.

The retained summary gives an original whole-lattice mass of
48.196732841931812 kg and adjusted mass of 36.274500000000046 kg. The unscaled
Slice Body sampled integrals are 36.622349604132594 kg spanwise and
37.024719502392813 kg chordwise. These represent distinct sampled directional
domains and must not be replaced by the imposed whole-lattice target.
Source: `calibration_summary.json`, fields `mass_before_kg`, `mass_after_kg`,
`span_target_integral_kg`, and `chord_target_integral_kg`.

The saved CBEAM profiles also cover shorter domains than the full geometric
profiles. Consequently, their integrated `After_kg_m` values are slightly below
the whole-lattice mass. The reproduction prints those common-domain masses and
their differences from the summary mass; it does not assert that the sampled
profile integral equals 36.2745 kg. Without the full beam geometry and section
arrays, these plot files cannot independently recompute the whole-lattice mass.

## Reproduce and verify

Dependencies: Python 3.10 or later, NumPy, and Matplotlib. From the repository root:

```sh
python data/structural_outcomes/case004_mass_profiles_20260918/reproduce.py
```

The default outputs are:

```text
generated/case004_mass_profiles_20260918/case004_mass_profiles.png
generated/case004_mass_profiles_20260918/case004_mass_profiles.svg
```

Choose another output directory with:

```sh
python data/structural_outcomes/case004_mass_profiles_20260918/reproduce.py --output generated/case4_custom
```

The script locates inputs beside itself, independent of the working directory.
Before creating figures it checks the column schema, row counts, finite and
nonnegative profiles, positive source areas, coordinate sequences, interval
midpoints, and 1 mm widths. It recomputes the Slice Body conversion directly from
both original area files and checks the original and adjusted integrated squared
errors against the axis-specific and combined summary values. It also verifies
the sampled Slice Body integrals, checks that common-domain CBEAM masses do not
exceed their corresponding whole-lattice masses, and checks consistency between
the recorded adjusted mass and the target. That last check verifies the summary's
internal consistency, not an independent reconstruction of total beam mass.

Numerical comparisons use relative and absolute tolerances of `1e-10`, with
absolute tolerance `1e-12 m` for coordinates and widths. These allow the decimal
rounding of the retained CSVs while remaining small relative to the plotted
values. A failed verification stops execution before figure output. Calculated
results are printed to standard output; only PNG and SVG figures are written.
Both panels use the same vertical scale and distinguish all three profiles by
color and line style. Their source caption is included in the exported figure.

## Scope of the candidate

The retained fit stopped at its configured 200-iteration limit with exit flag 0.
It is a feasible calibration candidate, not a claimed converged, global, or
unique optimum. The raw targets are not rescaled to the whole-lattice target.
Matching two directional profiles does not uniquely identify the three-dimensional
mass distribution, joint behavior, mass matrix, or stiffness. Changing radii also
changes axial and bending properties. This release reproduces the saved geometric
mass comparison and does not supply new stiffness, structural-response, or flutter
validation, or replace the original campaign results. Source:
`calibration_summary.json` and the retained profile and coordinate definitions.
