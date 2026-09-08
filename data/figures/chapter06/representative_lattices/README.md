# Representative four-input lattice wings

This package composes genuine nTop viewport crops for evaluated cases 4, 37,
and 99. The nine supplied PNGs are the image inputs. `layout.csv` records the
panel order, dimensions, labels, calibrated scale bars, uniform image scaling,
and source-image hashes. It is a composition recipe, not a numerical dataset
from which nTop geometry or viewport renderings can be regenerated.

## Recompose the figure

Download every file in this folder and run either implementation:

```text
python compose.py --output chosen-output.png
```

```matlab
compose_figure('chosen-output.png')
```

PNG, PDF, and SVG output paths are supported. The default output is
`composed.png`. Multiple named canvases in the layout are stacked into one
atlas without changing their aspect ratios. Python's `--panels` option and
MATLAB's optional second argument `true` also save the separate panel groups.
Python requires Pillow and Matplotlib; MATLAB uses native image and graphics
functions. Both implementations read only the adjacent layout and PNGs.
Font rasterization can vary across platforms; the input images, geometry,
panel placement, and scale conventions are retained.

## What is shown

The first group shows complete half-wing lattice property graphs, with cases
4, 37, and 99 from left to right. The views are uniformly scaled to the common
minimum measured image-plane ruler scale. The graph strokes do not represent
physical member diameters. The scale bars are 0.5 m.

The second group shows inboard solid-lattice details above outboard details,
again ordered 4, 37, and 99. The skin is hidden. These six images retain their
individual magnifications; compare their scale bars, not apparent on-page
member thickness. Inboard bars are 100, 50, and 100 mm; outboard bars are 20,
5, and 20 mm. Bars describe projected image-plane distances, not arbitrary
oblique member lengths. The selected regions have not been established as
homologous physical sections.

Source flecks and dark marks remain in the supplied images. Their physical
origin is not established by these screenshots. The PNG crops preserve the
decoded supplied screenshot pixels; they do not recover pixels lost through
any earlier JPEG encoding. No missing members or surfaces are synthesized.

The figure illustrates retained designs. It does not provide a new simulation,
strength assessment, manufacturing validation, or optimization comparison.
The current printed figure number is recorded in the repository's
`figure_registry.json`; this descriptive package path remains stable.
