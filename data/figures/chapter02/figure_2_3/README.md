# Microscopic beam-to-skin repair

The same retained two-beam example is shown before and after the 1.002 mm coordinate correction of B. All three receiving skin elements are included. A and C retain their coordinates because they are already within ordinary MPC coupling tolerance of their own receiving facets. C is close to the turning closure surface, not far from all skin.

## Reproduction

- MATLAB: add this folder to the path and call `plot_2_3`. Only the adjacent `figure_2_3.csv` is required. It writes `figure_2_3.png`. Use `plot_2_3('chosen-output.png')` to select the output; PDF and SVG extensions are also supported.
- Python: run `python plot_2_3.py`. Only the adjacent CSV and standard NumPy/Matplotlib dependencies are required. It writes `figure_2_3_python.png`. Use `--output chosen-output.png` to select a PNG, PDF or SVG destination.

The CSV records exact original/final coordinates, receiving vertices, projection points, beam endpoints and fifteen surrounding facets. The eighteen shown skin triangles form one edge-connected disk: actual bridging triangles link all three receiving facets, the boundary has no bow-tie vertices, and the patch has no internal holes. No triangle or coordinate is invented. Both scripts transform these coordinates into the same rigid local frame and plot millimetres. Side views are orthographic projections with equal horizontal and vertical length scales. The scripts do not run geometry generation, Nastran or other numerical solvers.

Thin grey lines denote skin-element edges, thick orange lines denote beam centre-lines, and blue outlines/shading mark the three receiving elements. The blue closure near C is an actual skin element, not a projection line or an extra beam. Orange AB coincides with the upper skin in the repaired side view because of the retained geometry.

## Evidence

| Node | GRID | Receiving skin element | Original gap to its receiving facet | Coordinate correction |
|---|---:|---:|---:|---:|
| A | 573197 | CTRIA3 625042 | 0.001646 μm | 0 |
| B | 573439 | CTRIA3 625400 | 1.002085 mm | 1.002086 mm |
| C | 573730 | CTRIA3 625399 | 0.048107 μm | 0 |

The classification comes from the retained original/final GRID coordinates and MPC cards, independently reconciled with the connector algorithm. The accompanying CSV provides the plotted geometry and projection points. Tiny differences between the original B gap and coordinate correction result from the precision of the saved GRID coordinates.

Suggested caption: Microscopic example of guarded beam-node projection and skin coupling. Only B is relocated; A and C already lie within the ordinary connection tolerance of their respective skin facets. The side views reveal the closure element receiving C. This is a coordinate correction before analysis, not load-induced deformation, and no beam is added.
