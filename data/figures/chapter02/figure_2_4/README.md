# Figure 2.4: contrasting near-skin mesh-repair and coupling outcomes

Download this folder and run either plotting script. No Nastran, nTop, archive access,
solver licence, or additional data files are needed. The single input file is
`figure_2_4.csv`. The original finite-element geometry is retained in SI units.

```bash
python -m pip install numpy matplotlib
python plot_2_4.py --output figure_2_4.png
```

Alternatively, from this directory in MATLAB:

```matlab
plot_2_4
```

Python saves one stacked atlas to `--output` (PNG, PDF or SVG). Omit the option
to save `figure_2_4.png` beside the script. Add `--panels` to save separate panel
PNGs as well. MATLAB likewise saves one atlas to `figure_2_4.png` by default;
`plot_2_4('chosen-output.png')` selects a PNG, PDF or SVG destination. Its optional
second argument, `plot_2_4('chosen-output.png',true)`, also saves separate a-d/e-h
panel PNGs beside that output. Both implementations stack native panel rasters
without stretching; PDF/SVG atlas exports embed the same high-definition bitmap.
Python and MATLAB use the same CSV coordinates, classifications and scales; text
layout and rasterisation can differ. Neither script reruns an expensive simulation.

## What is shown

| Panels | CSV example | Behaviour |
| --- | --- | --- |
| a-b | `single_B_A_ordinary_C_beyond` | A remains in ordinary coupling tolerance; B is snapped; C remains outside repair reach. |
| c-d | `B_rejected_length` | A proposed move of B is rejected by the incident-beam length-change guard. Dashed segments show the proposal, not retained beams. |
| e-f | `two_node` | Adjacent B and C both move, onto two distinct receiving skin triangles sharing an edge. |
| g-h | `finite_offset` | An approximately 8.189 μm offset is retained because it lies within the ordinary 10 μm coupling tolerance. |

The selected examples illustrate the procedure, not the prevalence or mechanical
performance of any outcome. All are from one retained FCC sizing model. Coordinates
are mesh-preparation values, not load-induced displacements. Unchanged nodes are not
necessarily constrained supports. MPC equations do not introduce physical beams.
Only the selected beam chains are drawn; additional incident members are retained
in the CSV for the upper examples. In the two-node example C has additional incident
members outside the illustration.

Orange thick lines denote lattice beam centre-lines. Thin grey lines denote skin
element boundaries. Blue denotes receiving skin elements. In a strict side view,
triangular skin faces can collapse to lines. Panels g-h are an equally scaled,
micrometre-size crop; they do not exaggerate the normal coordinate relative to the
in-plane coordinate. Beam segments leaving that view are cropped.

## CSV fields

The table is tidy at the geometric-entity/state/vertex grain. Blank fields are not
applicable or not supplied, rather than zero. All coordinates and distances use
metres. Read `entity` before interpreting a row.

- `example`: panel-group key, or `all_candidates` / `source` for audit/provenance.
- `entity`: `node`, `beam_endpoint`, `skin_vertex`, `audit` or `provenance`.
- `state`: `original` and `final` are retained coordinates. `projection` is the
  independently reconstructed point on a nearby skin facet. `all_proposals` is the
  trial configuration used by the length guard before rejected candidates are
  removed. It is not the final mesh. `unchanged` is used for skin geometry.
- `role`: A, B, C, or Q when the node has a figure label.
- `element_id`, `grid_id`, `vertex_index`: retained element and node identifiers
  and the ordered vertex/endpoint index. These identifiers are case-local.
- `x_m`, `y_m`, `z_m`: global geometry coordinates. Plots use rigid local frames
  constructed from these coordinates; there is no change in the underlying shape.
- `classification`: calculated reason/category except `coordinates_unchanged`,
  which asserts only the retained coordinate observation.
- `evidence_kind`: retained deck/report data, reconstructed geometry/settings, or
  a reconstructed-versus-retained membership audit.
- `receiving_for`: roles coupled to the skin facet. A suffix
  `_proposed_not_receiving` instead identifies a tested projection facet for a
  rejected or out-of-reach node; it must not be treated as a completed connection.
- `selected_pair`: 1 for one of the illustrated A-B / B-C members, 0 for other
  incident members included as context. Blank for non-beam rows.
- `projection_distance_m`: original node-to-calculated-projection distance, not
  necessarily the final retained gap.
- `coordinate_correction_m`: Euclidean original-to-final GRID coordinate change.
- `ordinary_tolerance_m`, `snap_tolerance_m`: retained case connection/repair
  distances, respectively 0.00001 m and 0.0030639880082520532 m.
- `weight_1`, `weight_2`, `weight_3`: triangular interpolation weights in the
  ordered vertices of the node's `element_id`, not vertex identifiers.
- `original_length_m`, `proposal_length_m`, `length_ratio`,
  `fractional_length_change`: beam lengths before repair and in the all-proposals
  configuration used for the guard; ratio = proposed/original and fractional
  change = absolute(proposed-original)/original.
- `metric`, `value`, `text`: audit counts/settings or SHA-256 source fingerprints.

## Evidence and reconstruction limitations

Original and repaired GRID coordinates, CBEAM connectivity, shell vertices, and MPC
membership were read from retained input records. The compact connector report
retains aggregate counts and distance settings, but **not the original per-node
status/rejection table**. Therefore the detailed reason labels are reconstructed
from the current connector implementation, not recovered historical status strings.

The independent reconstruction used the retained distances and smoothness radius,
32 nearby shell centroids and the current-source element-coordinate/guard settings.
Across **164,791 eligible nodes**, its moved-node classification and connected-node
MPC membership each have **zero mismatches** against the retained records. This
supports agreement with those two observable outcomes. It does not establish that
every historical intermediate reason string was identical or validate the physical
effect of the repairs. The source report/settings/hash audit is included directly
in the CSV; no external record is required to inspect it.

The reconstructed counts are: ordinary coupling 27,344; snapped nodes 24,146;
outside snap reach 111,011; length-guard rejection 2,249; outlier rejection 32;
isolated-proposal rejection 9. The three rejection categories sum to 2,290, matching
the retained guard-rejection total. The first two categories sum to 51,490,
matching the retained connected-node total. These counts describe this one mesh,
not all optimization cases.

The snap threshold alone is not sufficient for movement. An acceptable facet
projection and the applicable geometric safeguards are also needed. A small gap
within ordinary coupling tolerance can remain without a coordinate change; the
MPC then contains the finite offset's rotational contribution. Rejected proposals
remain proposals, not new nodes, members, or guaranteed skin attachments.
