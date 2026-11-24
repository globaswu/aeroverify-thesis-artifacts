# Figure 5.25 — refined-wing beam stress fields

This comparison uses the lightest verified refinement with a trim
response in each topology. The three variants are FCC 18a, BCC 33a,
and SC 66a in Table D.16. The beam envelopes are from SOL 144 subcase 9
in the contact-refined, 12° stress checks.

Each NPZ file contains the native beam identifiers, the projected
spanwise and chordwise coordinates of its endpoints in metres, and
the maximum absolute element normal stresses in MPa. The figure uses
the same raster, Gaussian interpolation, support distance, colour map,
and nonlinear colour scale as Figure 6.8. The same 3D neighbourhood
screen flagged zero elements in these three refinements. Open circles
identify native peaks, and their coordinates are in peak_locations.csv.

The spanwise table gives the native, length-weighted 95th percentile
for each equal semispan quarter. The weights are the actual 3D lengths
of the beam elements, assigned by midpoint.

Recreate the display with NumPy, SciPy, and Matplotlib by running
python plot_figure_5_25.py --output figure_5_25.pdf in this directory.
