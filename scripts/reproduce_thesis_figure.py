#!/usr/bin/env python3
"""Run one or all self-contained thesis figure packages.

Examples
--------
    python scripts/reproduce_thesis_figure.py 5.1
    python scripts/reproduce_thesis_figure.py 5.1 5.9 6.5 --format pdf
    python scripts/reproduce_thesis_figure.py --all

Each delegated plotting script reads only the single CSV beside it.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SUPPORTED = (
    "2.7", "2.8",
    "3.1", "3.2", "3.3", "3.4", "3.5", "3.6", "3.7", "3.8",
    "3.9", "3.10", "3.11", "3.12", "3.13",
    "4.1", "4.2",
    "5.1", "5.2", "5.3", "5.4", "5.5", "5.6", "5.7", "5.8",
    "5.9", "5.10", "5.11", "5.12", "5.13", "5.14", "5.15",
    "5.16", "5.17", "5.18", "5.19", "5.20", "5.21",
    "6.1", "6.2", "6.3", "6.4", "6.5", "6.6", "6.7", "6.8",
    "6.9", "6.10", "6.11", "6.12",
)


def package_paths(figure_id: str) -> tuple[Path, Path, Path]:
    chapter_text, number_text = figure_id.split(".")
    stem = f"figure_{int(chapter_text)}_{int(number_text)}"
    folder = ROOT / "data" / "figures" / f"chapter{int(chapter_text):02d}" / stem
    return folder / f"{stem}.csv", folder / f"plot_{int(chapter_text)}_{int(number_text)}.py", folder


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("figures", nargs="*", help="Figure IDs such as 5.1 or 6.12")
    parser.add_argument("--all", action="store_true", help="Run every figure package")
    parser.add_argument("--list", action="store_true", help="List available packages")
    parser.add_argument("--format", choices=("png", "pdf", "svg"), default="png")
    parser.add_argument("--output-dir", type=Path, default=ROOT / "reproduced")
    args = parser.parse_args()

    if args.list:
        for figure_id in SUPPORTED:
            csv_path, script_path, _ = package_paths(figure_id)
            print(f"{figure_id:>4}  {csv_path.relative_to(ROOT)}  {script_path.relative_to(ROOT)}")
        return 0

    targets = list(SUPPORTED) if args.all else args.figures
    if not targets:
        parser.error("supply at least one figure ID or use --all")
    unknown = [figure_id for figure_id in targets if figure_id not in SUPPORTED]
    if unknown:
        parser.error("unknown figure ID(s): " + ", ".join(unknown))

    args.output_dir.mkdir(parents=True, exist_ok=True)
    failures: list[tuple[str, int]] = []
    for figure_id in targets:
        csv_path, script_path, folder = package_paths(figure_id)
        if not csv_path.is_file() or not script_path.is_file():
            print(f"{figure_id}: incomplete package in {folder}", file=sys.stderr)
            failures.append((figure_id, 2))
            continue
        chapter_text, number_text = figure_id.split(".")
        output = args.output_dir / f"thesis_figure_{int(chapter_text):02d}_{int(number_text):02d}.{args.format}"
        result = subprocess.run(
            [sys.executable, str(script_path), "--output", str(output)],
            cwd=folder,
            check=False,
        )
        if result.returncode:
            failures.append((figure_id, result.returncode))
        else:
            print(f"{figure_id}: {output}")

    if failures:
        for figure_id, code in failures:
            print(f"{figure_id}: failed with exit code {code}", file=sys.stderr)
        return 1
    print(f"Reproduced {len(targets)} figure(s) from self-contained per-figure packages.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
