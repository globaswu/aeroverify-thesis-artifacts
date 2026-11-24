# Figure 6.5 — Case 37 and Case 99 shell stress

The native results are from MSC Nastran SOL 144 subcase 9 at 12° incidence, using the root-graded, contact-refined skin mesh and area-distributed lattice attachments.

| File | Contents |
| --- | --- |
| `case_037_shell.npz`, `case_099_shell.npz` | All skin triangle records in each model. Arrays are `vertices_m` in basic-system coordinates, zero-based `triangles`, solver `shell_eids`, and `stress_MPa`. The final field is the maximum shell von Mises stress from the solver-reported recovery locations for each element. |
| `case_037_plot.npz`, `case_099_plot.npz` | The exact raster values used by the published plotting script, the physical plot bounds, and the native maximum's centroid. |
| `peak_locations.csv` | Subcase, incidence, element count, governing element ID, stress, and centroid for each case. |
| `plot_figure_6_5.py` | Reconstructs the thesis plot using the committed raster data. |

The plot projects the undeformed shell triangles onto spanwise \(y\) and chordwise \(x\) coordinates. Each pixel retains the maximum unaveraged value from the sampled projected triangles. Samples include triangle–pixel-centre intersections and triangle centroids, so the representation retains small contact patches. When the two skins overlap in projection the larger value is shown. The native peaks are marked at the governing element centroids. This is a projected shell-stress envelope on a common physical scale and common colour scale.

The mesh and element values can be read directly with NumPy. To reproduce the display, install NumPy and Matplotlib and run:

```text
python plot_figure_6_5.py --output figure_6_5.png
```
