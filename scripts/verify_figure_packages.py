#!/usr/bin/env python3
"""Verify standalone CSV/two-script figure packages and the explicit 2.5 exception."""

from __future__ import annotations

import csv
import ast
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
# Verification must not add bytecode files to the publication bundle.
sys.dont_write_bytecode = True
from reproduce_thesis_figure import SUPPORTED, package_paths

EXPECTED = SUPPORTED
AUXILIARY_CSV = {
    "2.5": {"chunk_beams.csv", "chunk_shell_vertices.csv"},
}
PROHIBITED_TEXT = re.compile(
    r"https?://|[A-Za-z]:\\|\\\\(?:\d{1,3}\.){3}\d{1,3}\\|"
    r"\.(?:mat|op2|f04|f06|h5|ntop|bdf|dat)\b",
    re.IGNORECASE,
)


def package(figure_id: str) -> tuple[Path, set[str]]:
    chapter_text, number_text = figure_id.split(".")
    chapter, number = chapter_text, int(number_text)
    stem = f"figure_{chapter}_{number}"
    _, _, folder = package_paths(figure_id)
    required = {f"{stem}.csv", f"plot_{chapter}_{number}.py", f"plot_{chapter}_{number}.m"}
    required.update(AUXILIARY_CSV.get(figure_id, set()))
    return folder, required


def main() -> int:
    failures: list[str] = []
    total_bytes = 0
    csv_count = 0
    expected_folders = {package(fid)[0] for fid in EXPECTED}
    actual_folders = {p for p in (ROOT / "data/figures").glob("chapter*/figure_*") if p.is_dir()}
    if actual_folders != expected_folders:
        failures.append("Unexpected or missing figure directories")
    for figure_id in EXPECTED:
        folder, required = package(figure_id)
        if not folder.is_dir():
            failures.append(f"{figure_id}: missing folder {folder.relative_to(ROOT)}")
            continue
        actual = {path.name for path in folder.iterdir() if path.is_file()}
        if actual - {"README.md"} != required:
            failures.append(f"{figure_id}: files {sorted(actual)} != {sorted(required)}")
            continue
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
        for script_path in sorted(folder.glob("plot_*.*")):
            text = script_path.read_text(encoding="utf-8")
            if PROHIBITED_TEXT.search(text):
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
        f"{csv_count} CSV files, and {2 * len(EXPECTED)} plotting scripts "
        f"({total_bytes} CSV bytes)."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
