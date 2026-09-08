#!/usr/bin/env python3
"""Run current thesis figures or stable legacy reproduction packages.

Examples
--------
    python scripts/reproduce_thesis_figure.py --current 5.2
    python scripts/reproduce_thesis_figure.py --current 5.1 5.9 6.5 --format pdf
    python scripts/reproduce_thesis_figure.py --current --all
    python scripts/reproduce_thesis_figure.py 5.2  # legacy FCC Pareto package

--current resolves printed thesis numbers through figure_registry.json.
Without it, bare IDs retain their legacy package meanings and output names.
CSV plots read their adjacent numerical data. Screenshot compositions read
declared local PNGs and layout metadata; they do not regenerate nTop geometry.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

sys.dont_write_bytecode = True
from figure_packages import ROOT, CURRENT_PACKAGES, LEGACY_PACKAGES, package_paths


SUPPORTED = tuple(LEGACY_PACKAGES)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("figures", nargs="*", help="Figure IDs such as 5.1, C.1, or D.6")
    parser.add_argument("--current", action="store_true", help="Interpret IDs as current printed figure numbers")
    parser.add_argument("--all", action="store_true", help="Run every figure package")
    parser.add_argument("--list", action="store_true", help="List available packages")
    parser.add_argument("--format", choices=("png", "pdf", "svg"), default="png")
    parser.add_argument("--output-dir", type=Path, default=ROOT / "generated" / "figures")
    args = parser.parse_args()
    packages = CURRENT_PACKAGES if args.current else LEGACY_PACKAGES

    if args.list:
        for figure_id, spec in packages.items():
            csv_path, script_path, _ = package_paths(figure_id, current=args.current)
            print(f"{figure_id:>4}  current={spec['figure']:>4}  {spec['kind']}  "
                  f"{csv_path.relative_to(ROOT)}  {script_path.relative_to(ROOT)}")
        return 0

    targets = list(packages) if args.all else args.figures
    if not targets:
        parser.error("supply at least one figure ID or use --all")
    unknown = [figure_id for figure_id in targets if figure_id not in packages]
    if unknown:
        parser.error("unknown figure ID(s): " + ", ".join(unknown))

    args.output_dir = args.output_dir.resolve()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    failures: list[tuple[str, int]] = []
    for figure_id in targets:
        spec = packages[figure_id]
        csv_path, script_path, folder = package_paths(figure_id, current=args.current)
        if not all((folder / item).is_file() for item in (*spec['inputs'], *spec['scripts'])):
            print(f"{figure_id}: incomplete package in {folder}", file=sys.stderr)
            failures.append((figure_id, 2))
            continue
        chapter_text, number_text = figure_id.split(".")
        chapter_dir = chapter_text.zfill(2) if chapter_text.isdigit() else chapter_text
        prefix = "thesis_current_figure" if args.current else "thesis_figure"
        output = args.output_dir / f"{prefix}_{chapter_dir}_{int(number_text):02d}.{args.format}"
        result = subprocess.run(
            [sys.executable, str(script_path), "--output", str(output)],
            cwd=folder,
            check=False,
        )
        if result.returncode or not output.is_file() or output.stat().st_size == 0:
            failures.append((figure_id, result.returncode or 3))
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
