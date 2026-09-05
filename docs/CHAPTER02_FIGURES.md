# Chapter 2 figure reproduction

Each figure folder contains one CSV and independent Python and MATLAB scripts.
Download all three files from a folder. Python requires NumPy and Matplotlib.
MATLAB uses built-in table and graphics
functions. Neither route launches a solver or contacts an external data service.

From the repository root, for example:

```text
python scripts/reproduce_thesis_figure.py 2.1 2.3 2.4 2.12
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
