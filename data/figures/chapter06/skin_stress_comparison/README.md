# Reconstructing the skin von Mises stress surface

This bundle contains the actual undeformed skin mesh and both retained shell-centroid surface von Mises stresses for coupled wing cases 37 and 99 at SOL 144 subcase 9. It supports an independent reconstruction of the evaluated stress field, not a reproduction of the nTop screenshot layout or viewport styling.

The associated thesis images are native nTop Scalar Point Map views. Each point contains the larger of the two shell-fiber von Mises values at the original triangle centroid, expressed in MPa. The point maps use no nodal averaging or additional Field from Point Map interpolation. Their displayed point density is not a count of lattice members or skin-lattice connectors. The source capture magnifications differ; the independent surface reconstruction below instead uses a common orthographic camera and physical scale.

The stored `TRIM 9` angle is `ANGLEA = 0.20944 rad`, equivalent to 12.0000280612 degrees. This is the nominal 12-degree, largest-angle member of the nine fixed-angle subcases. These fields are not the separately interpolated structural-trim stresses. The units follow the retained SI model convention; the OP2 format itself does not encode units.

## Files and data grain

| File | Grain and meaning |
|---|---|
| `cases.csv` | Two case records: subcase, exact stored angle, units, planform dimensions, shell fiber coordinates and mesh counts. |
| `case_37_vertices.csv`, `case_99_vertices.csv` | One row per original GRID node used by the skin triangles; original node ID and basic-system coordinates in metres. |
| `case_37_triangles.csv`, `case_99_triangles.csv` | One row per original CTRIA3, retaining its element ID, original three-node connectivity, and two centroid surface von Mises stresses in pascals. |
| `plot.py` | Python reconstruction from these adjacent CSVs; PNG/PDF/SVG output and an optional derived peak-location CSV. |
| `plot_skin_stress.m` | MATLAB reconstruction from the same adjacent CSVs, with an explicit PNG output path. |

Case 37 contains 307,103 skin-used vertices and 614,202 triangles. Case 99 contains 463,655 vertices and 927,306 triangles. The two surface rows in the source OP2 have output-node ID zero, indicating element-centroid output; they are not two independent elements. Neither recovered case contains a CQUAD4 shell-stress table. No CBEAM or other beam stress is included in these CSVs.

The suffixes `fiber_minus` and `fiber_plus` mean negative and positive local shell fiber coordinate, respectively. They must not be interpreted as the whole wing's lower and upper skins: both physical skins are represented by separate triangles in the mesh. The retained fiber distances are approximately +/-0.00125 m. The exact single-precision values are supplied in `cases.csv`.

Coordinates are exported with up to twelve significant digits, retaining the precision of the matched large-field GRID deck. The stress columns use nine significant decimal digits, enough to roundtrip every original OP2 single-precision value exactly. The reconstruction casts those columns back to single precision before reducing them. All original values are retained; no high values are discarded by the display scale. Each mesh CSV is below 50 MiB, and coordinates are not duplicated in the triangle files.

## Reconstruction

Python requires NumPy and Matplotlib; pyNastran is not required for reconstruction. From any working directory, provide output paths outside this source bundle:

```text
python /path/to/bundle/plot.py --output /path/to/output/skin_stress.png --summary /path/to/output/peak_locations.csv
```

The `--output` extension may be `.png`, `.pdf`, or `.svg`; the output directory must already exist. PNG output is 500 dpi. For PDF/SVG output the dense triangle collection is rasterized at that resolution while text remains vector. `--summary` is optional and writes derived peak locations and their normalized planform coordinates. The scripts never read a raw OP2, native geometry file, external CSV, or network resource.

MATLAB uses standard graphics and needs no additional toolbox:

```matlab
addpath('/path/to/bundle');
plot_skin_stress('/path/to/output/skin_stress.png');
```

The original node IDs are mapped to vertex rows before rendering. Each original triangle receives

`display_vm = max(vm_fiber_minus_Pa, vm_fiber_plus_Pa) / 1e6`.

This is a piecewise-constant surface envelope in MPa. There is no nodal averaging, element-to-element stress interpolation, geometry smoothing, subsampling or point-cloud replacement. The overview retains every original triangle; a local detail shows the exact triangles intersecting the stated local box. Python uses depth-ordered opaque face polygons; MATLAB uses the transformed three-dimensional triangle mesh and an orthographic view. Small raster differences between the two renderers are expected.

## View, scale and interpretation

Both cases share a fixed orthographic camera, azimuth -60 degrees and elevation 40 degrees. The view vector is `[cos(el)*cos(az), cos(el)*sin(az), sin(el)]`; the image-right vector is `[-sin(az), cos(az), 0]`, and image-up is their cross product. No deformation is applied. Whole-wing views share the same physical bounding box: x from -0.035 to 1.025 m, y from -0.04 to 2.56 m, and z from -0.055 to 0.075 m.

The two peak-root details use equal-size boxes positioned around each case's own raw-maximum element centroid: x offsets -28 to +28 mm, y offsets -2 to +18 mm, and z offsets -8 to +8 mm. Their global chordwise locations therefore differ. They are views at the same physical scale, not a claim that identical material points are compared. Scale bars refer to lengths parallel to the orthographic image plane. Circles identify the projected centroids of the raw-maximum elements; they do not enlarge or replace the stress field.

All panels use the same fixed 0-220 MPa blue-to-gold scale. Its five RGB controls are `[0.055,0.13,0.28]`, `[0.10,0.32,0.51]`, `[0.24,0.52,0.62]`, `[0.61,0.70,0.60]`, and `[0.94,0.82,0.34]`. Both raw maxima are below 220 MPa. The scale ceiling is the campaign's numerical screening level, not a newly established physical safety margin.

The maxima reconstructed from these source CSVs are 99,785,296 Pa at element 35,161 for case 37 and 210,424,352 Pa at element 675,562 for case 99. Their triangle-centroid locations are calculated directly from the three retained node coordinates. For normalized position, `eta=y/s`, `c(y)=c_root*[1-(1-taper)*eta]`, and the zero-sweep quarter-chord line is `x_qc=c_root/4`. Local chord fraction is `[x-(x_qc-c(y)/4)]/c(y)`. The normalization uses the nominal planform supplied in `cases.csv` and does not modify the mesh.

The source geometry is the matching archived skin GRID/CTRIA3 deck, including the stored coordinates after near-skin connector preparation. Slight departures of mesh vertices from ideal planform boundaries are retained. The source stress is the CTRIA3 `von_mises` column in `OES1X1`, subcase 9, from each corresponding recovered `aerov144.op2`. The export validates full element/node join coverage, unique keys, two surfaces per element, finite nonnegative stresses and original single-precision roundtrip. No native geometry or OP2 file is needed or included here.

These are simulated local shell responses under two different evaluated configurations and mesh controls. The resulting locations are consistent with critical upper-root skin elements under this load case, but do not isolate a warping benefit, an unwarped-baseline comparison, individual lattice load paths, or a mesh-independent stress margin. An nTop-imported or averaged display can differ from this raw element-centroid envelope and should be labeled with its own field definition.
