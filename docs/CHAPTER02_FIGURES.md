# Chapter 2 figure reproduction

Each figure folder contains one CSV and independent Python and MATLAB scripts.
Download all three files from a folder. Python requires NumPy and Matplotlib.
MATLAB uses built-in table and graphics
functions. Neither route launches a solver or contacts an external data service.

From the repository root, for example:

```text
python scripts/reproduce_thesis_figure.py 2.1 2.3 2.4 2.12 2.13 2.14 2.15 2.16
```

The figure-specific script can also be run directly with `--output` to select
the image destination. MATLAB users should add the chosen figure folder to
the path and call its `plot_2_N` function. Figure 2.1 additionally accepts its
CSV path as the first argument; other functions accept the output path first.

## Figure 2.1: spanwise geometric diameter

[CSV and scripts](../data/figures/chapter02/figure_2_1)

The CSV contains 51 samples of the specified linear spanwise law for the
four-input campaign's case 55. `eta` is `y/s`; `y_m` and `s_m` are the spanwise
position and semispan in metres. `t_m` and `t_mm` express the geometric strut
diameter in metres and millimetres. `t_over_t1` is normalized by the root
diameter. `a_m`, `t1_m`, and `t2_m` give the cell size and root/tip diameters.
The scripts verify the endpoints, units, normalization, and linear law before
plotting.

The thesis combines this profile with an nTop screenshot of the lattice wing.
The scripts reproduce **the profile only**. They do not reconstruct the nTop
screenshot, wing geometry, or beam section properties. The profile is a
calculation from specified geometry inputs, not a measured structural response.

## Figure 2.3: microscopic shell–lattice coupling

[CSV and scripts](../data/figures/chapter02/figure_2_3)

The CSV contains two actual local examples from FCC lattice-sizing case 55.
This is a different campaign from the four-input case used in Figure 2.1.
`example` distinguishes guarded snapping (`snap_repair`) and ordinary
finite-offset coupling (`ordinary_mpc`). `entity` identifies beam nodes,
projection points, connector triangle vertices, incident beam endpoints, or
surrounding skin triangles. `state` distinguishes original and final
coordinates. `grid_id` and `element_id` preserve node and element identity.

`x_m`, `y_m`, and `z_m` are global coordinates in metres. `local_s_m`,
`local_t_m`, and `local_n_m` express the same coordinates in an orthonormal
frame whose origin is the projection on the connector triangle. The local
`s` direction follows vertices 1 to 2; `n` points from the original beam node
toward the skin; `t` completes the frame. The scripts use these local columns
directly and preserve equal coordinate scale. The micrometre inset is a
uniformly magnified projection, not an exaggerated normal offset.

The source is the retained original/final structural mesh and connector
geometry. Node 491572 moves by 1.298 mm before MPC generation, while node
472299 stays fixed with an 8.189 micrometre offset. The interpolation weights
can be reconstructed from the projection and triangle vertices in this CSV.
The image is a mesh-data rendering, not an nTop screenshot. It illustrates
two connector operations, not a global validation of all connectors.

## Figure 2.4: NACA 65-210 lifting-line schematic

[CSV and scripts](../data/figures/chapter02/figure_2_4)

The figure uses the supplied NACA 65-210 coordinate profile. The drawing
illustrates lifting-line collocation and the one-way correction for wing
twist. Its illustrative angles are not additional simulated observations.
The airfoil outline is not a synthetic symmetric substitute. This schematic
is distinct from the W2GJ camber prescription on the doublet-lattice surface.

## Figure 2.12: lift-curve comparison

[CSV and scripts](../data/figures/chapter02/figure_2_12)

The CSV contains six retained Nastran and lifting-line lift coefficients
over incidence angles from −2 to 8 degrees. The experimental reference is
the NACA 65-210 wing without washout in Table I of James C. Sivells's
1947 [NACA Technical Note 1422](https://ntrs.nasa.gov/citations/19930082118), *Experimental and Calculated Characteristics
of Three Wings of NACA 64-210 and 65-210 Airfoil Sections With and Without
2° Washout*. The table reports a lift-curve slope of 0.085 per degree and
a zero-lift angle of −1.3 degrees. The plotted reference is the linear
reconstruction `CL = 0.085*(alpha_deg + 1.3)`, not digitized measured points.
The CSV repeats those reference parameters to make both scripts self-contained.

The Nastran calculation includes camber through W2GJ and structural coupling.
It is not a matched W2GJ-on/off test. Agreement in lift-curve slope supports
the lift calculation within this comparison; any zero-lift-angle difference
must remain visible. The comparison does not establish accuracy of profile,
parasite, or total drag, or independently validate the induced-drag objective.

## Figure 2.13: full-wing CFD drag diagnostics

[CSV and scripts](../data/figures/chapter02/figure_2_13)

The CSV contains all 75 samples from a three-mesh full-wing CFD campaign:
25 samples per mesh at iterations 0, 10, ..., 240. The history panel displays
iterations 40–240 so that startup transients do not obscure the later values;
the omitted startup rows remain available in the CSV. `mesh_id` identifies
the coarse, medium, or fine mesh. Iteration, cell count, total drag, pressure
and viscous drag components, flow/reference quantities, and monitor settings
are retained as separate numeric columns.

`CD_total` is the recorded pressure-plus-viscous wing drag coefficient, not
lifting-line induced drag. The pressure and viscous coefficients are
calculated by projecting the respective recorded forces onto the prescribed
drag direction and dividing by dynamic pressure times reference area. Their
sum agrees with the recorded total coefficient to within 4.3e-10 across the
75 rows.

This calculation used the NACA 65-210 coordinate input at 7 degrees incidence,
98.6847632 m/s, nominal Mach 0.29, and reference area 2.32245987 m². It is
distinct from the Mach 0.17 Sivells lift comparison. The three mesh levels
use incompressible RANS with the Spalart–Allmaras turbulence model.

The shading and horizontal whiskers use the nine terminal samples at
iterations 160–240. Whiskers are **observed iteration ranges**, not confidence
intervals, uncertainty bounds, or estimates of discretization error. All
three runs passed their original trailing force-range monitor at iteration
240. Its 60 N drag tolerance exceeded the observed ranges of 1.4628845,
6.2463705, and 12.7891070 N. These accepted results must not be described as
failed convergence under that original criterion.

Monitor acceptance does not demonstrate total-drag accuracy. Boundary-layer
extrusion was disabled in all three meshes; the fine mesh failed one mesh
quality check; no wall-resolution verification or matched experimental
total-drag comparison was available. The figure documents these CFD results
and their limitations without treating the terminal iteration ranges or
small medium-to-fine difference as a validated uncertainty assessment.

## Figure 2.14: mean camber at aerodynamic-box controls

[CSV and scripts](../data/figures/chapter02/figure_2_14)

The CSV supplies 4001 normalized chordwise samples of the NACA 65-210 upper
surface, lower surface, mean camber, and numerical camber derivative. These
values reproduce the geometry preprocessing used for W2GJ, including the
implemented endpoint treatment and piecewise cubic Hermite interpolation.
They are not new CFD or aeroelastic simulation results.

There are 50 control rows, identified by `box_j_zero_based` values 0–49.
At the control of chordwise box `j`, `control_x_over_c = (j+0.75)/50` and
`control_W2GJ = -control_dzc_dx`. Non-control rows use `box_j_zero_based=-1`
and leave control-specific fields as NaN. These NaN entries are intentional,
not missing simulation observations. All fifty control locations and signs,
the fine-grid derivative, and the surface/camber values were checked against
the supplied coordinate profile and preprocessing convention.

Panel A represents 110 spanwise strips by 50 chordwise boxes in normalized
coordinates, without assigning a physical planform aspect ratio. The
highlighted five boxes have indices 35–39. Panel B preserves equal chord and
vertical scale. Panel C explicitly magnifies the vertical coordinate by
36.5 relative to the displayed chord scale; its tangent angles are therefore
visually magnified, while the listed derivatives retain their actual values.

The three-quarter-box control locations are not the quarter-chord lifting
line or its ten spanwise collocation stations. Mean camber supplies an
imposed normal-flow boundary-condition correction. It does not move the
planar aerodynamic surface or represent aeroelastic displacement.

## Figure 2.15: matched rigid W2GJ on/off comparison

[CSV and scripts](../data/figures/chapter02/figure_2_15)

The CSV retains all nine verified incidences from −4 to 12 degrees, the
on/off lift coefficients, independent force-sum checks, and reference/model
metadata. The figure and reported fits use the six points from −2 to
8 degrees. Both SOL 144 runs use the same 5500-box aerodynamic model at
Mach 0.17, 3 degrees dihedral, and zero washout; only the W2GJ include differs.
A fully fixed reference node, rigid aerodynamic interpolation, and an
unloaded scalar carrier provide a **zero-motion numerical carrier**, not a
model of the wing's skin or lattice structure. The half-domain coefficient
reference area is 1.1585009088000002 m². The dashed reference is reconstructed
from Sivells's experimental Table I slope of 0.085 per degree and zero-lift
angle of −1.3 degrees, not digitized measurements. At zero incidence,
`CL_W2GJ_on=0.1379893` and `CL_W2GJ_off=0`. This matched pair isolates the camber
contribution within one rigid inviscid discretization. It does not establish
total-drag accuracy, stall prediction, or mesh convergence; the rounded
experimental tips are approximated by a straight trapezoid, and the residual
against the reconstructed experimental lift relation remains visible.

The rigid benchmark prescribes 3 degrees dihedral, whereas the optimization
campaigns use zero prescribed CAERO1 dihedral. In this benchmark, imported
mean-camber ordinates are interpreted in global XZ section planes. Projection
onto the aerodynamic-panel normal gives `W2GJ = -(dz_c/dx) cos(Gamma)`, with
`Gamma = 3 degrees`, without empirical fitting. If the ordinates instead
describe displacement along the local panel normal, no additional
`cos(Gamma)` factor is needed. Sivells's report does not specify the airfoil
ordinate plane sufficiently to resolve this choice, so the global-XZ
interpretation is an explicit replication assumption, not a universal
Nastran rule.

## Figure 2.16: four rigid dihedral/W2GJ cases

[CSV and scripts](../data/figures/chapter02/figure_2_16)

The four numerical curves are actual rigid SOL 144 calculations combining
zero or 3 degrees dihedral with W2GJ enabled or disabled. They share Mach
0.17, 5500 aerodynamic boxes, and the same historical 600-point NACA 65-210
coordinate dataset. All nine incidences from −4 to 12 degrees are plotted;
regressions and reference-error statistics use only −2 to 8 degrees. The
fifth line is reconstructed from Sivells Table I as
`CL = 0.085*(alpha_deg+1.3)`, not digitized measured points. Panel B shows
actual lift coefficients for the two W2GJ-on curves in a local view near
12 degrees, with incidence limits 11.985–12.003 degrees and lift-coefficient
limits 1.1494–1.1523. Its markers are the original 12-degree solver results:
`CL=1.151878` for zero dihedral and `CL=1.150984` for 3 degrees dihedral.
The visible line portions are straight connectors between recorded
incidences, not additional fine-grid evaluations or extrapolated solutions.
All nine incidences and the W2GJ-off results remain in the upper panel and CSV.
The CSV retains independent force-sum checks and physical metadata alongside
the plotted coefficients; no numerical curve is synthesized by scaling
another curve.

The flat case follows the optimization geometry/camber **convention only**.
These are zero-motion rigid benchmarks, not flexible-wing optimization
results, and they do not use the current 516-point coordinate file. The
3-degree W2GJ-on case uses one cosine projection of the historical unprojected
camber array; the flat case uses that array without a dihedral projection.
The fixed reference node and unloaded scalar carrier are numerical devices,
not a wing structural model. The small dihedral differences apply to these
four inviscid cases on one mesh; they do not establish stall, total-drag
accuracy, or mesh convergence. A panel-normal incidence/camber projection
does not justify applying a blanket cosine factor to the final lift from
the separate planar lifting-line calculation. No lifting-line solver is
implemented or modified by this reproduction package.
