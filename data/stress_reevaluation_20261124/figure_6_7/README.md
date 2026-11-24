# Figure 6.7 — representative coupled-design responses

The upper panels report SOL 144 subcase 9 at the maximum analysed incidence of 12° for Cases 4, 37, 64, 65, and 99. The underlying element envelopes come from the contact-refined stress reevaluation and match the casewise table in the thesis data package.

The spanwise data use 140 equal-width bins in normalized semispan. A shell element is assigned by its centroid and a CBEAM element by its midpoint. A bin contains the maximum native element stress among the assigned elements. The shell value is von Mises stress and the beam value is the maximum absolute recovered normal stress. Empty bins have blank stress values. The dashed guide is the 184 MPa screening limit.

The lower panels use the initial optimization records. They show half-wing strain energy over the nine SOL 144 incidence cases and the maximum of the filtered SOL 145 damping at each sampled speed.

- [Spanwise stress profiles](spanwise_stresses_12deg.csv)
- [Native peaks and governing element IDs](peaks_12deg.csv)
- [Strain energy](representative_strain_energy_curves.csv)
- [Damping envelopes](representative_flutter_envelope_curves.csv)
- [Plotting code](plot_figure_6_7.py)

Run `python plot_figure_6_7.py --output figure_6_7.png` with NumPy and Matplotlib.
