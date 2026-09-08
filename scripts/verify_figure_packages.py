#!/usr/bin/env python3
"""Verify typed numerical and screenshot-composition figure packages."""

from __future__ import annotations

import csv
import ast
import hashlib
import math
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
# Verification must not add bytecode files to the publication bundle.
sys.dont_write_bytecode = True
from figure_packages import CURRENT_PACKAGES, FIGURE_ROOT

EXPECTED = tuple(CURRENT_PACKAGES)
PROHIBITED_TEXT = re.compile(
    r"https?://|[A-Za-z]:\\|\\\\(?:\d{1,3}\.){3}\d{1,3}\\|"
    r"\.(?:mat|op2|f04|f06|h5|ntop|bdf|dat)\b",
    re.IGNORECASE,
)
LAYOUT_FIELDS = {
    "figure", "record_type", "case_id", "view", "source_png", "x_px", "y_px",
    "width_px", "height_px", "x2_px", "y2_px", "text", "font", "font_px",
    "font_weight", "color", "line_width_px", "horizontal_alignment",
    "vertical_alignment", "isotropic_scale_factor", "source_crop_sha256",
}


def adjacent_file(folder: Path, name: str) -> Path:
    path = folder / name
    if path.is_symlink() or path.resolve().parent != folder.resolve() or not path.is_file():
        raise ValueError(f"Non-adjacent or missing package file: {name}")
    return path


def script_reference_text(text: str, kind: str) -> str:
    if kind == "screenshot_composition":
        # Only complete quoted XML namespace identifiers are exempt. Longer
        # URLs beginning with these strings remain subject to the URL check.
        return re.sub(r'''(?<=["'])http://www\.w3\.org/(?:2000/svg|1999/xlink)(?=["'])''', "", text)
    return text


def layout_number(row: dict, key: str, default=None) -> float:
    raw = row.get(key, "").strip()
    value = float(raw) if raw else (float(default) if default is not None else float(raw))
    if not math.isfinite(value):
        raise ValueError(f"Non-finite layout field: {key}")
    return value


def package(figure_id: str) -> tuple[Path, set[str]]:
    spec = CURRENT_PACKAGES[figure_id]
    return spec["folder"], set((*spec["inputs"], *spec["scripts"]))


def check_screenshot_layout(spec: dict) -> None:
    """Validate only explicitly declared local PNGs, never arbitrary paths."""
    from PIL import Image

    folder = spec["folder"]
    declared = set(spec["images"])
    if not declared:
        raise ValueError("Screenshot package has no declared PNG inputs")
    for name in declared:
        path = adjacent_file(folder, name)
        with Image.open(path) as picture:
            if picture.format != "PNG" or min(picture.size) <= 0:
                raise ValueError(f"Invalid PNG: {name}")
            picture.verify()
        with Image.open(path) as picture:
            picture.load()
    with adjacent_file(folder, spec["primary"]).open(encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        if not LAYOUT_FIELDS.issubset(reader.fieldnames or []):
            raise ValueError("Layout CSV is missing required composition fields")
        if len(reader.fieldnames) != len(set(reader.fieldnames)):
            raise ValueError("Layout CSV has duplicate fields")
        rows = list(reader)
    canvases = {}
    for row in rows:
        if row.get("record_type") != "canvas":
            continue
        name = row.get("figure", "")
        if not re.fullmatch(r"[a-zA-Z0-9_-]+\.png", name) or name in canvases:
            raise ValueError("Invalid or duplicate named canvas")
        width, height = layout_number(row, "width_px"), layout_number(row, "height_px")
        if not all(value > 0 and value.is_integer() for value in (width, height)):
            raise ValueError("Invalid canvas dimensions")
        if layout_number(row, "x_px", 0) != 0 or layout_number(row, "y_px", 0) != 0:
            raise ValueError("Canvas origin must be zero")
        canvases[name] = (width, height)
    if not canvases:
        raise ValueError("Layout needs at least one canvas record")
    referenced = set()
    for row in rows:
        kind = row.get("record_type")
        if row.get("figure") not in canvases:
            raise ValueError("Layout record has no declared canvas")
        if kind not in {"canvas", "image", "text", "line"}:
            raise ValueError(f"Unknown layout record type: {kind}")
        if row.get("color") and not re.fullmatch(r"#[0-9a-fA-F]{6}", row["color"]):
            raise ValueError("Layout color must be an RGB hex value")
        if kind == "canvas":
            continue
        x, y = layout_number(row, "x_px"), layout_number(row, "y_px")
        if kind == "line":
            layout_number(row, "x2_px")
            layout_number(row, "y2_px")
            if layout_number(row, "line_width_px") <= 0:
                raise ValueError("Line width must be positive")
            continue
        if kind == "text":
            if min(layout_number(row, "width_px", 0), layout_number(row, "height_px", 0)) < 0:
                raise ValueError("Text dimensions cannot be negative")
            if layout_number(row, "font_px") <= 0:
                raise ValueError("Font size must be positive")
            if row["horizontal_alignment"] not in {"", "left", "center", "right"} or row["vertical_alignment"] not in {"", "top", "center", "bottom"}:
                raise ValueError("Invalid text alignment")
            if row["font_weight"] not in {"", "regular", "normal", "bold"}:
                raise ValueError("Invalid text font weight")
            continue
        name = row["source_png"]
        if name not in declared:
            raise ValueError(f"Undeclared screenshot input: {name}")
        referenced.add(name)
        width, height = canvases[row["figure"]]
        w, h = layout_number(row, "width_px"), layout_number(row, "height_px")
        if min(w, h) <= 0:
            raise ValueError(f"Invalid image placement: {name}")
        if x < 0 or y < 0 or x + w > width + 1e-6 or y + h > height + 1e-6:
            raise ValueError(f"Image placement escapes canvas: {name}")
        with Image.open(folder / name) as picture:
            scale = layout_number(row, "isotropic_scale_factor", w / picture.width)
            if scale <= 0 or not (math.isclose(w, picture.width * scale, abs_tol=1e-5, rel_tol=1e-8)
                                  and math.isclose(h, picture.height * scale, abs_tol=1e-5, rel_tol=1e-8)):
                raise ValueError(f"Image dimensions disagree with its isotropic scale: {name}")
        expected_hash = row.get("source_crop_sha256", "")
        if expected_hash and hashlib.sha256((folder / name).read_bytes()).hexdigest() != expected_hash.lower():
            raise ValueError(f"Screenshot source hash mismatch: {name}")
    if referenced != declared:
        raise ValueError("Some declared screenshots are not used by the layout")


def main() -> int:
    failures: list[str] = []
    total_bytes = 0
    csv_count = 0
    image_count = 0
    image_bytes = 0
    expected_folders = {package(fid)[0] for fid in EXPECTED}
    actual_folders = {p.resolve() for p in FIGURE_ROOT.glob("chapter*/*") if p.is_dir()}
    if actual_folders != expected_folders:
        failures.append("Unexpected or missing figure directories")
    for figure_id in EXPECTED:
        spec = CURRENT_PACKAGES[figure_id]
        folder, required = package(figure_id)
        if not folder.is_dir():
            failures.append(f"{figure_id}: missing folder {folder.relative_to(ROOT)}")
            continue
        actual = {path.name for path in folder.iterdir() if path.is_file()}
        if actual - {"README.md"} != required:
            failures.append(f"{figure_id}: files {sorted(actual)} != {sorted(required)}")
            continue
        if any(path.is_dir() for path in folder.iterdir()):
            failures.append(f"{figure_id}: undeclared subdirectory")
        try:
            for name in actual:
                adjacent_file(folder, name)
        except ValueError as error:
            failures.append(f"{figure_id}: {error}")
            continue
        for input_name in spec["inputs"]:
            input_path = folder / input_name
            if input_path.stat().st_size >= 100 * 1024 * 1024:
                failures.append(f"{figure_id}: {input_name} reaches GitHub's 100 MiB limit")
        csv_paths = sorted(folder / name for name in required if name.endswith(".csv"))
        for csv_path in csv_paths:
            csv_count += 1
            total_bytes += csv_path.stat().st_size
            if csv_path.stat().st_size >= 100 * 1024 * 1024:
                failures.append(f"{figure_id}: {csv_path.name} reaches GitHub's 100 MiB limit")
            with csv_path.open("r", encoding="utf-8-sig", newline="") as handle:
                reader = csv.reader(handle)
                if next(reader, None) is None or next(reader, None) is None:
                    failures.append(f"{figure_id}: {csv_path.name} lacks a header or data row")
        if spec["kind"] == "screenshot_composition":
            try:
                check_screenshot_layout(spec)
                image_count += len(spec["images"])
                image_bytes += sum((folder / name).stat().st_size for name in spec["images"])
            except (ValueError, KeyError, OSError, ImportError) as error:
                failures.append(f"{figure_id}: {error}")
        for script_path in (folder / name for name in spec["scripts"]):
            text = script_path.read_text(encoding="utf-8")
            checked_text = script_reference_text(text, spec["kind"])
            if PROHIBITED_TEXT.search(checked_text):
                failures.append(f"{figure_id}: prohibited external-data reference in {script_path.name}")
            for csv_path in csv_paths:
                if csv_path.name not in text:
                    failures.append(f"{figure_id}: {csv_path.name} missing from {script_path.name}")
            if script_path.suffix == '.py':
                ast.parse(text, filename=str(script_path))

    if failures:
        raise SystemExit("Figure-package verification failed:\n" + "\n".join(failures))
    print(
        f"Verified {len(EXPECTED)} self-contained figure folders, "
        f"{csv_count} CSV files, {image_count} declared PNG inputs, and "
        f"{2 * len(EXPECTED)} scripts ({total_bytes} CSV bytes; {image_bytes} PNG bytes)."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
