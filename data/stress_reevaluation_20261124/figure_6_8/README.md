# Figure 6.8 — planform beam-stress fields at 12°

These are the contact-refined SOL 144 subcase 9 beam results for Cases 4,
37, and 99. The NPZ files contain projected member endpoints in metres,
native beam-element IDs, and maximum absolute beam normal stress in MPa.
The endpoint coordinates are spanwise then chordwise. The peak table
gives the native peak position independently of the interpolated colours.

The plot samples the projected members on a 2.5 mm raster and keeps the
maximum member value in each occupied cell. A normalized Gaussian
interpolation uses a 10 mm standard deviation and support out to 30 mm
within the projected lattice outline. Both the spatial and nonlinear
Turbo colour scales are shared across the three cases.

The exclusion record identifies one isolated Case 4 tip peak. The
interpolation omits its beam element, and the red marker gives the
native value. The screen compares each element with the 90th percentile
of the 24 nearest members in 3D. A flagged element belongs to the top
one percent in its case. It reaches three times the local level and
exceeds that level by at least 50 MPa. The screening records and solver peaks
use the full element set.

Run the plotting script with NumPy, SciPy, and Matplotlib using
the command below.

```text
python plot_figure_6_8.py --output figure_6_8.pdf
```
