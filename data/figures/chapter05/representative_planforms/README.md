# Representative planform lattice wings

This package composes three genuine nTop lattice property-graph crops for
planform cases 45, 47, and 20, from left to right. The supplied PNGs are the
image inputs; `layout.csv` records their panel mapping, uniform scaling,
labels, calibrated scale bars, and source hashes. Evaluated numerical CSV
data alone cannot regenerate these viewport renderings.

## Recompose the figure

Download all files in this folder and run either entrypoint:

```text
python compose.py --output chosen-output.png
```

```matlab
compose_figure('chosen-output.png')
```

The default output is `composed.png`. PNG, PDF and SVG are supported; the
latter two embed the completed raster montage rather than creating vector
wing geometry. Python requires Pillow, Matplotlib and NumPy. MATLAB uses
native graphics and its bundled JVM. Both scripts read only the adjacent
layout and three PNGs. Font rasterization and allowed scaled-image
interpolation can differ between runtimes.

## Interpretation

The complete modeled half-wing property graphs use a common ruler-calibrated
orthographic image-plane scale, with a 0.5 m bar beneath each panel.
The case-20 input remains at its native pixel size; cases 45 and 47 use the
isotropic scale factors recorded in the CSV. No image is stretched or given
an independent horizontal/vertical scaling.

Graph display strokes do not encode physical member diameters. The scale bars
describe projected image-plane distances, not arbitrary oblique
three-dimensional lengths. These are illustrative retained design views,
not a new simulation or a matched strength/performance comparison.

The native PNGs preserve the decoded supplied screenshot pixels, including
any source marks; they do not recover information lost through earlier JPEG
encoding. The composition scripts do not rebuild, repair, or synthesize
lattice geometry. The repository's `figure_registry.json` records the current
printed figure number while this descriptive package path remains stable.
