#!/usr/bin/env python3
"""Compose the adjacent layout.csv and its adjacent PNG assets.

Usage: python compose.py --output composed.png [--panels]
Requires Python 3.10+, Pillow, Matplotlib, and NumPy (a Matplotlib dependency).
PNG, PDF, and SVG are supported. PDF/SVG embed the completed raster atlas.

Figure contract: compare the supplied nTop views in the CSV's case/view order;
the screenshots and calibrated scale labels are evidence, not new geometry.
The static montage uses only canvas/image/text/line rows, declared colors and
labels, zero-based top-left edge coordinates, and one isotropic image scale.
Every canvas is rendered at its declared pixel size. Groups are stacked in
first-appearance order, left aligned on white, without gaps or stretching.
Inspect the exported atlas and optionally the separate group PNGs for QA.
"""

from __future__ import annotations

import argparse
import base64
import csv
import hashlib
import io
import math
import sys
import warnings
from collections import OrderedDict
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.font_manager as font_manager
import numpy as np
from matplotlib.backends.backend_agg import FigureCanvasAgg
from matplotlib.figure import Figure
from PIL import Image

DPI = 100  # Converts recipe font/stroke pixels to points; never scales the atlas.
FIELDS = {
    "figure", "record_type", "case_id", "view", "source_png", "x_px", "y_px",
    "width_px", "height_px", "x2_px", "y2_px", "text", "font", "font_px",
    "font_weight", "color", "line_width_px", "horizontal_alignment",
    "vertical_alignment", "isotropic_scale_factor", "source_crop_sha256",
}


def number(row, key, default=None):
    value = row.get(key, "").strip()
    if not value and default is not None:
        return float(default)
    result = float(value)
    if not math.isfinite(result):
        raise ValueError(f"Non-finite {key} in {row['figure']}")
    return result


def adjacent_png(folder, name):
    """Reject URLs, directory paths and links escaping the package folder."""
    if not name or any(mark in name for mark in ("/", "\\", ":")):
        raise ValueError(f"source_png must be an adjacent PNG basename: {name!r}")
    path = (folder / name).resolve()
    if path.parent != folder or path.suffix.lower() != ".png" or not path.is_file():
        raise ValueError(f"Missing/non-adjacent PNG: {name!r}")
    return path


def load_recipe(folder):
    layout = folder / "layout.csv"
    with layout.open(encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        if not FIELDS.issubset(reader.fieldnames or []):
            raise ValueError(f"layout.csv is missing columns: {FIELDS - set(reader.fieldnames or [])}")
        rows = list(reader)
    groups = OrderedDict()
    assets = {}
    protected = {layout.resolve(), Path(__file__).resolve(), (folder / "compose_figure.m").resolve()}
    for row in rows:
        name = row["figure"].strip()
        if not name:
            raise ValueError("Every layout row must identify its figure group")
        if row["record_type"] not in {"canvas", "image", "text", "line"}:
            raise ValueError(f"Unknown record_type: {row['record_type']!r}")
        groups.setdefault(name, []).append(row)
        if row["record_type"] != "image":
            continue
        path = adjacent_png(folder, row["source_png"])
        protected.add(path)
        expected = row["source_crop_sha256"].strip().lower()
        if path not in assets:
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            with Image.open(path) as original:
                pixels = original.convert("RGBA").copy()
            assets[path] = (pixels, digest)
        source, actual = assets[path]
        if expected and expected != actual:
            raise ValueError(f"SHA-256 mismatch for {path.name}: expected {expected}, got {actual}")
        width, height = number(row, "width_px"), number(row, "height_px")
        scale = number(row, "isotropic_scale_factor", width / source.width)
        if min(width, height, scale) <= 0:
            raise ValueError(f"Non-positive image dimensions/scale: {path.name}")
        if not (math.isclose(width, source.width * scale, abs_tol=1e-5, rel_tol=1e-8)
                and math.isclose(height, source.height * scale, abs_tol=1e-5, rel_tol=1e-8)):
            raise ValueError(f"Image dimensions do not match its isotropic scale: {path.name}")
    if not groups:
        raise ValueError("The layout contains no figure groups")
    return groups, assets, protected


def canvas_size(rows):
    canvases = [row for row in rows if row["record_type"] == "canvas"]
    if len(canvases) != 1:
        raise ValueError("Each figure group requires exactly one canvas row")
    row = canvases[0]
    w, h = number(row, "width_px"), number(row, "height_px")
    if min(w, h) <= 0 or not w.is_integer() or not h.is_integer():
        raise ValueError("Canvas dimensions must be positive integer pixels")
    if number(row, "x_px", 0) != 0 or number(row, "y_px", 0) != 0:
        raise ValueError("Canvas origins must be (0, 0)")
    return int(w), int(h), row["color"] or "#ffffff"


def render_group(folder, rows, assets):
    width, height, background = canvas_size(rows)
    fig = Figure(figsize=(width / DPI, height / DPI), dpi=DPI, facecolor=background)
    canvas = FigureCanvasAgg(fig)
    ax = fig.add_axes((0, 0, 1, 1), xlim=(0, width), ylim=(height, 0), frameon=False)
    ax.set_axis_off()
    ax.set_aspect("equal", adjustable="box")
    known_fonts = set()
    for order, row in enumerate(rows):
        kind = row["record_type"]
        if kind == "canvas":
            continue
        x, y = number(row, "x_px"), number(row, "y_px")
        if kind == "image":
            source = assets[adjacent_png(folder, row["source_png"])][0]
            w, h = number(row, "width_px"), number(row, "height_px")
            if x < -1e-5 or y < -1e-5 or x + w > width + 1e-5 or y + h > height + 1e-5:
                raise ValueError(f"Image extends beyond its canvas: {row['source_png']}")
            # Matplotlib extents are image edges. At 1:1 integer placement,
            # nearest interpolation preserves every source pixel exactly.
            native = abs(w - source.width) < 1e-8 and abs(h - source.height) < 1e-8
            ax.imshow(source, extent=(x, x + w, y + h, y), origin="upper",
                      interpolation="nearest" if native else "bicubic",
                      resample=not native, aspect="equal", zorder=order)
        elif kind == "line":
            ax.plot((x, number(row, "x2_px")), (y, number(row, "y2_px")),
                    color=row["color"] or "#000000",
                    linewidth=number(row, "line_width_px") * 72 / DPI,
                    solid_capstyle="butt", zorder=order)
        elif kind == "text":
            w, h = number(row, "width_px", 0), number(row, "height_px", 0)
            horizontal = row["horizontal_alignment"] or "left"
            vertical = row["vertical_alignment"] or "top"
            if horizontal not in {"left", "center", "right"} or vertical not in {"top", "center", "bottom"}:
                raise ValueError("Text alignment must be left/center/right and top/center/bottom")
            x += {"left": 0, "center": w / 2, "right": w}[horizontal]
            y += {"top": 0, "center": h / 2, "bottom": h}[vertical]
            family = row["font"] or "sans-serif"
            weight = "normal" if row["font_weight"] in {"", "regular"} else row["font_weight"]
            if (family, weight) not in known_fonts:
                try:
                    font_manager.findfont(font_manager.FontProperties(family=family, weight=weight), fallback_to_default=False)
                except ValueError:
                    warnings.warn(f"Font {family!r} ({weight}) unavailable; Matplotlib will substitute. Text pixels can differ.")
                known_fonts.add((family, weight))
            ax.text(x, y, row["text"], ha=horizontal, va=vertical,
                    fontsize=number(row, "font_px") * 72 / DPI,
                    fontfamily=family, fontweight=weight, color=row["color"] or "#000000",
                    parse_math=False, clip_on=True, zorder=order)
    canvas.draw()
    result = Image.fromarray(np.asarray(canvas.buffer_rgba()).copy()).convert("RGB")
    fig.clear()
    if result.size != (width, height):
        raise RuntimeError(f"Renderer changed the declared canvas size: {result.size}")
    return result


def write_atlas(atlas, output):
    suffix = output.suffix.lower()
    if suffix == ".png":
        atlas.save(output, dpi=(DPI, DPI))
    elif suffix == ".svg":
        png = io.BytesIO()
        atlas.save(png, format="PNG")
        encoded = base64.b64encode(png.getvalue()).decode("ascii")
        output.write_text(
            f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
            f'width="{atlas.width}" height="{atlas.height}" viewBox="0 0 {atlas.width} {atlas.height}">'
            f'<image width="{atlas.width}" height="{atlas.height}" '
            f'xlink:href="data:image/png;base64,{encoded}"/></svg>\n', encoding="utf-8")
    elif suffix == ".pdf":
        # The PDF embeds a lossless raster; no JPEG conversion or extra crop.
        fig = Figure(figsize=(atlas.width / DPI, atlas.height / DPI), dpi=DPI)
        ax = fig.add_axes((0, 0, 1, 1), frameon=False)
        ax.imshow(atlas, interpolation="none", aspect="equal")
        ax.set_axis_off()
        fig.savefig(output, format="pdf", dpi=DPI, pad_inches=0, facecolor="white")
        fig.clear()
    else:
        raise ValueError("Output extension must be .png, .pdf or .svg")


def compose(output=None, save_panels=False):
    folder = Path(__file__).resolve().parent
    output = Path(output).expanduser().resolve() if output else folder / "composed.png"
    if output.suffix.lower() not in {".png", ".pdf", ".svg"}:
        raise ValueError("Output extension must be .png, .pdf or .svg")
    groups, assets, protected = load_recipe(folder)
    if output in protected:
        raise ValueError("Output would overwrite a package input")
    panels = [(name, render_group(folder, rows, assets)) for name, rows in groups.items()]
    atlas = Image.new("RGB", (max(panel.width for _, panel in panels), sum(panel.height for _, panel in panels)), "white")
    y = 0
    for _, panel in panels:
        atlas.paste(panel, (0, y))
        y += panel.height
    output.parent.mkdir(parents=True, exist_ok=True)
    write_atlas(atlas, output)
    if save_panels:
        panel_dir = output.parent / (output.stem + "_panels")
        panel_dir.mkdir(parents=True, exist_ok=True)
        for index, (name, panel) in enumerate(panels, 1):
            # Number prefixes make even duplicate/sanitized group stems unique.
            stem = "".join(c if c.isalnum() or c in "-_" else "_" for c in Path(name).stem)
            path = (panel_dir / f"{index:02d}_{stem}.png").resolve()
            if path in protected:
                raise ValueError("Panel output would overwrite a package input")
            panel.save(path, dpi=(DPI, DPI))
    print(f"Wrote {output} ({atlas.width} x {atlas.height} px; {len(panels)} groups; {len(assets)} PNG assets verified)")
    return output


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--output", type=Path, help="Chosen .png/.pdf/.svg path (default: composed.png beside this script)")
    parser.add_argument("--panels", action="store_true", help="Also save each group as PNG in <output-stem>_panels/")
    args = parser.parse_args()
    try:
        compose(args.output, args.panels)
    except (OSError, ValueError, RuntimeError) as error:
        print(f"Composition failed: {error}", file=sys.stderr)
        raise SystemExit(1) from error


if __name__ == "__main__":
    main()
