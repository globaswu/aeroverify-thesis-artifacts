# Figure 2.5 — retained FCC55 lattice patch

This self-contained package reproduces the before/after geometry illustration
from three supplied CSV files. It contains a spatial crop of retained FCC/55
input geometry: 399 CBEAM elements, 348 beam GRID points, and 713 skin triangles.
The geometry is not regenerated, and neither script invokes a structural solver.

## Files and execution

- `figure_2_5.csv`: one row per visible beam GRID, with original/final coordinates,
  reconstructed classification, projection coordinates and distance, receiving
  or candidate triangle ID, three interpolation weights, and
  `full_lattice_degree` counted using all retained case CBEAMs.
- `chunk_beams.csv`: actual CBEAM element IDs, endpoint GRID IDs, and lengths.
- `chunk_shell_vertices.csv`: three ordered rows per actual CTRIA3, with GRID
  IDs and coordinates; flags distinguish receiving and rejected-candidate facets.
- `plot_2_5.m`: MATLAB figure generator; run `plot_2_5` in MATLAB. Produces
  `figure_2_5.png`. Use `plot_2_5('chosen-output.png')` for a chosen path;
  `.pdf` and `.svg` are also supported. Verified using MATLAB R2025b.
- `plot_2_5.py`: Python equivalent; run `python plot_2_5.py`. Requires Python
  3.10+, NumPy and Matplotlib. Produces `figure_2_5_python.png`.
  Use `python plot_2_5.py --output chosen-output.png` for a chosen path;
  `.pdf` and `.svg` are also supported.

All three CSV files must remain beside the scripts. The scripts locate their
own directory, so execution does not depend on an absolute path. Python and
MATLAB use the same data, rigid coordinate frame, physical scaling, palette,
and six-panel comparison; typography and 3-D depth ordering can differ between
renderers. The CSV inputs use metres; plotted coordinates use millimetres.

## What the illustration shows

Within this crop, 31 nodes move by 1.468007720–2.966788688 mm (median
1.690528377 mm). The other 317 nodes retain exactly identical coordinates:
50 are ordinary MPC connections, 21 are beam-length guard rejections, and 246
are beyond the snap tolerance. The retained ordinary connection tolerance is
10 μm and the snap tolerance is 3.063988008 mm.

Strong orange lines are the 60 actual CBEAM centre-lines incident to at least
one relocated node; pale orange lines are the other 339 unchanged members.
All 399 members are drawn in each overview panel. Grey edges are skin-element
boundaries. Blue faces identify all 75 receiving facets used by the 81 visible
connected nodes. Open and filled markers identify the same 31 repair nodes
before and after movement. The views use an orthographic projection, one rigid
local coordinate transformation, equal spatial units, and no displacement
magnification. No projection connector is depicted as a beam.

Panels (a,b) retain the full oblique comparison. Panels (c,d) rotate the side
projection within the local skin plane by 5° to separate otherwise stacked
lattice rows: the horizontal position is `h = x*cos(5°) + y*sin(5°)`, and the
vertical coordinate is the original local-normal coordinate. The 5° is solely
a viewing direction, not wing dihedral or a change to the physical model. This
is a rigid view change, not a rotation of individual nodes. The same projection is applied
to the complete original/final beam and skin data.

Dashed boxes in (c,d) locate panels (e,f), which enlarge the identical
`h = [-24,-8] mm`, `normal = [-4,0.6] mm` window. Fifteen relocated nodes have
their original horizontal positions in this window. The window is an axis crop
of the same full projection, not a new element-selection or repair algorithm;
no beams are added or removed from the data. Horizontal and vertical units
remain equal within each panel, and before/after panels have identical limits.
The actual receiving facets are slightly curved about the mean reference plane,
so skin contact does not require a local-normal coordinate of exactly zero.

The refreshed preview files are `figure_2_5_filtered.png` (MATLAB) and
`figure_2_5_filtered_python.png` (Python). Existing earlier preview PNGs were
retained; run the scripts with a chosen output path to avoid overwriting them.

## Selection and provenance

The crop contains complete beams whose **original midpoints** fall within a
50 mm square centred at global `(x,y) = (0.28,1.0)` m and within global
`z = 0.010–0.045` m. This was the smallest of the tested 40, 45, and 50 mm
widths meeting the requested illustrative density of 30–100 repaired nodes
and 100–400 beam elements. Selection did not use stress or performance results.
Boundary nodes can have additional incident beams outside this spatial crop.

Coordinates and connectivity were extracted from retained FCC/55
`shellbeam_connector_source.bdf`, `grid.dat`, `cbeam.dat`, `shell.dat`, and
`mpc.dat`. Receiving facets for all visible connected nodes and selected
projection facets for visible rejected nodes are included. Additional skin
context comes from the same retained upper-surface mesh.

The plotted original state is **after the nTop lattice-length filter and beam
export, but before the MATLAB connector changes coordinates**. The saved nTop
graph connects the length-filter output to the lattice finite-element mesh and
then to the beam export. Its threshold expression is
`min(2*t1, 0.1*a, tskin)`, equal to 1.225595203 mm for this case. The saved
comparison enum is 4; its exact operator label was not independently recovered
from the inspected local graph, and is not inferred here.

Among the 31 highlighted repaired nodes, full-case connectivity gives 29 nodes
of degree two and two nodes of degree four; none is a terminal degree-one node.
Therefore this crop illustrates movement of intermediate and junction nodes,
not the closure of 31 disconnected terminal gaps. A length filter does not
establish a uniform clearance below the skin. The `full_lattice_degree` column
counts connectivity in the entire retained case, including beams outside the
displayed crop.

Per-node reason strings were reconstructed from the connector algorithm and
retained coordinates because the original per-node report table was not
retained locally. Across all 164,791 eligible case nodes, reconstruction
produced zero discrepancies in retained moved-node membership and zero
discrepancies in retained MPC membership. Case-level counts also match the
retained report. These classifications should be described as calculated
reconstructions, not recovered historical per-node log entries.

This figure illustrates geometric repair behaviour in one spatial crop. It
does not establish strength, accuracy, robustness, computational efficiency,
or optimisation improvement.

## Input SHA-256

```text
figure_2_5.csv
b0661591d0ba5aeebf13ae06aad904f1ac155378b86750971861d3068438890b

chunk_beams.csv
86d665dc2def2be29c7d8c625a9feb569e27b470ad9480061e64b75efb49e38b

chunk_shell_vertices.csv
5ecf8e34a2eb05a17c9be08454aa64fe48aff2ee1afb8da48d56f8ba28964a32
```
