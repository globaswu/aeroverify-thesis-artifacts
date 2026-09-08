"""Current thesis numbering and immutable figure-package identities."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIGURE_ROOT = ROOT / "data" / "figures"
REGISTRY_PATH = ROOT / "figure_registry.json"


def load_registry() -> dict[str, dict]:
    source = json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))
    if source.get("schema_version") != 1:
        raise ValueError("Unsupported figure registry schema")
    result: dict[str, dict] = {}
    seen_packages: set[str] = set()
    for record in source["figures"]:
        figure_id = record["figure"]
        relative = record["package"]
        if not re.fullmatch(r"(?:[1-9]\d*|[A-Z])\.[1-9]\d*", figure_id):
            raise ValueError(f"Invalid current figure number: {figure_id}")
        if not re.fullmatch(r"chapter(?:\d{2}|[A-Z])/[a-zA-Z0-9_]+", relative):
            raise ValueError(f"Unsafe figure package path: {relative}")
        if figure_id in result or relative in seen_packages:
            raise ValueError(f"Duplicate figure number or package: {figure_id}")
        folder = (FIGURE_ROOT / relative).resolve()
        if not folder.is_relative_to(FIGURE_ROOT.resolve()):
            raise ValueError(f"Package escapes figure directory: {relative}")
        printed_chapter = figure_id.split(".")[0]
        chapter_folder = "chapter" + (printed_chapter.zfill(2) if printed_chapter.isdigit() else printed_chapter)
        if folder.parent.name != chapter_folder:
            raise ValueError(f"Printed chapter and package directory disagree: {relative}")
        kind = record["kind"]
        if kind == "csv_plot":
            match = re.fullmatch(r"figure_([A-Z]|\d+)_(\d+)", folder.name)
            if match is None:
                raise ValueError(f"Invalid stable CSV package: {relative}")
            chapter, number = match.groups()
            if chapter != printed_chapter:
                raise ValueError(f"Stable package belongs to a different chapter: {relative}")
            legacy_id = f"{chapter}.{int(number)}"
            primary = folder.name + ".csv"
            scripts = (f"plot_{chapter}_{number}.py", f"plot_{chapter}_{number}.m")
            extra = ("chunk_beams.csv", "chunk_shell_vertices.csv") if relative == "chapter02/figure_2_5" else ()
            inputs = (primary, *extra)
        elif kind == "named_csv_plot":
            legacy_id = None
            primary = record.get("csv", "")
            if not re.fullmatch(r"[a-zA-Z0-9_]+\.csv", primary):
                raise ValueError(f"Unsafe named CSV input: {relative}")
            matlab = record.get("matlab", "")
            if not re.fullmatch(r"plot_[a-zA-Z0-9_]+\.m", matlab):
                raise ValueError(f"Unsafe named MATLAB script: {relative}")
            scripts = ("plot.py", matlab)
            inputs = (primary,)
        elif kind == "screenshot_composition":
            legacy_id = None
            primary = "layout.csv"
            scripts = ("compose.py", "compose_figure.m")
            images = record.get("images", [])
            if not isinstance(images, list) or len(images) != len(set(images)):
                raise ValueError(f"Invalid screenshot input list: {relative}")
            if any(not re.fullmatch(r"[a-zA-Z0-9_-]+\.png", item) for item in images):
                raise ValueError(f"Unsafe screenshot filename: {relative}")
            inputs = (primary, *images)
        else:
            raise ValueError(f"Unsupported reproduction kind: {kind}")
        result[figure_id] = dict(record, folder=folder, legacy_id=legacy_id,
                                 primary=primary, scripts=scripts, inputs=inputs)
        seen_packages.add(relative)
    return result


CURRENT_PACKAGES = load_registry()
LEGACY_PACKAGES = {spec["legacy_id"]: spec for spec in CURRENT_PACKAGES.values()
                   if spec["legacy_id"] is not None}


def package_paths(figure_id: str, *, current: bool = False) -> tuple[Path, Path, Path]:
    spec = (CURRENT_PACKAGES if current else LEGACY_PACKAGES)[figure_id]
    folder = spec["folder"]
    return folder / spec["primary"], folder / spec["scripts"][0], folder
