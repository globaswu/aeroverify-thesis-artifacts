# Lattice-wing stress verification

These tables support the fixed-angle structural comparisons in Chapter 2. All stresses are in MPa and the angle of attack is 12 degrees. The beam measure is the maximum absolute native section-normal stress. The shell measure is the von Mises stress over the reported fibres.

| Table | Comparison |
|---|---|
| [Tapered member](tapered_member.csv) | FCC70 with one to four elements per member at fixed geometry, restraints and attachment sites. |
| [Root edge](root_edge.csv) | FCC70, SC53 and BCC58 at three background skin resolutions. Take the greater upper- and lower-skin value for each design and resolution. These controls use a finite-width clamp. |
| [Shell resolution](sc053_shell.csv) | SC53 with a fixed section-plane footprint operator. Divide the absolute difference between successive peaks by the finer-mesh peak. |
| [Full-wing comparison](fullwing.csv) | Four pairs with the same prescribed tapered lattice and loading. Skin discretization and attachment coupling change together. |
| [Beam-stress distribution](fcc070_ecdf.csv) | Sorted FCC70 element envelopes and empirical percentiles for the reference and contact-resolved models. The two stress columns are sorted independently. A row represents a rank, rather than an element match. |
| [Attachment weights](fcc070_attachment.csv) | Physical GRID coordinates, integrated nodal areas and normalized receiver weights for the illustrated FCC70 attachment, beam GRID 417029. |

The full-wing reference columns correspond to the tapered reference meshes. The original optimization datasets retain their published labels.
