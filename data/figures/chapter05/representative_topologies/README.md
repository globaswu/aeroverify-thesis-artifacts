# Representative lattice topologies

This package composes six genuine nTop viewport crops for FCC case 70,
BCC case 17, and SC case 53. The PNGs are the required image inputs.
`layout.csv` records their order, placement, labels, scale bars, isotropic
image transformations, and source hashes. It is a composition recipe, not
the numerical geometry needed to regenerate an nTop rendering.

## Recompose the figure

Download every file in this folder, then use either implementation:

```text
python compose.py --output chosen-output.png
```

```matlab
compose_figure('chosen-output.png')
```

The default output is `composed.png`; PNG, PDF and SVG destinations are
supported. PDF/SVG embed the completed raster montage rather than converting
the screenshots to vector geometry. Python requires Pillow, Matplotlib and
NumPy; MATLAB uses its native graphics and bundled JVM. Both implementations
read only the adjacent layout and PNGs. Font rasterization and permitted
scaled-image interpolation can differ between runtimes.

## Views and scale conventions

Columns show FCC case 70, BCC case 17, and SC case 53, from left to right.
The upper row shows the complete modeled half-wing lattice property graphs
at a common ruler-calibrated orthographic image-plane scale. Each overview
has a 0.5 m scale bar. The graph strokes do not encode member diameters.

The lower row shows visually selected inboard solid-lattice fields with the
skin hidden. These images retain their independent captured magnifications;
each has its own 50 mm scale bar. Equal panel dimensions do not imply equal
member thickness or identical physical sections. The selected local regions
and magnifications differ between cases. The bars indicate projected
image-plane distances, not arbitrary oblique three-dimensional lengths.

The supplied crops preserve decoded screenshot pixels, including visible
source marks. They do not recover information lost through earlier JPEG
encoding, and the screenshot alone does not establish the physical origin
of any mark. No geometry is reconstructed, repaired, or synthesized by the
composition scripts.

These are illustrative retained designs, not a matched optimization or
strength comparison. The current printed number is specified in the
repository's `figure_registry.json`; this descriptive package path is stable.
