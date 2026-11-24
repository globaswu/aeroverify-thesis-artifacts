# Rod–plate mesh sequences

The three solid meshes use quadratic tetrahedra. The tabulated joint
and far-field dimensions are nominal size targets. The plate and rod
share the six-node triangular faces at the bonded interface. The
beam–shell sequence uses the same physical footprint and the same 12
beam elements at all three levels. Its fitted octagon contains 14, 56 and
224 shell triangles. The mesh counts and receiving-node counts come from
the verified solver input decks.

The profile difference in the mesh table is the relative L2 difference
from the finest solid model, evaluated at 80 common stations outside
the footprint. The profile files in this directory give the physical
station coordinates and the in-plane stress values.

The planar edge arrays in mesh_views.npz show the corner edges of the
tetrahedral faces in the plate's upper-face plane and the shell edges on
its midsurface. The plot uses the actual meshes around the footprint.
The files named mesh_levels.csv and plot_mesh_sequence.py provide the
table inputs and the mesh-panel rendering. Run the plot with NumPy and
Matplotlib using the --output argument to select a file.
