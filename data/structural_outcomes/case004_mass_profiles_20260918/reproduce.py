#!/usr/bin/env python3
"""Verify and plot the retained Case 4 mass-profile calibration data."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np


DATA_DIR = Path(__file__).resolve().parent
DEFAULT_OUTPUT = DATA_DIR.parents[2] / "generated" / DATA_DIR.name
DENSITY_KG_M3 = 2700.0
RTOL = 1e-10
ATOL = 1e-10
COLUMNS = (
    "Start_m", "End_m", "Midpoint_m", "Before_kg_m", "After_kg_m", "nTop_kg_m"
)
AXES = {
    "span": ("csa_slice_body_original.csv", 1867, 0.0),
    "chord": ("csay_original.csv", 1034, 0.001),
}


def close(actual, expected, label: str, *, rtol=RTOL, atol=ATOL) -> None:
    """Raise before plotting if a retained numerical relationship is broken."""
    np.testing.assert_allclose(
        actual, expected, rtol=rtol, atol=atol, err_msg=label
    )


def verify_data(data_dir: Path = DATA_DIR):
    """Return verified profiles and calculated results without writing files."""
    summary = json.loads((data_dir / "calibration_summary.json").read_text("utf-8"))
    if summary["case"] != 4 or summary["objective_units"] != "kg^2/m":
        raise ValueError("Expected the Case 4 integrated squared-error summary.")
    for key in ("mass_before_kg", "mass_after_kg", "mass_target_kg"):
        if not np.isfinite(summary[key]) or summary[key] <= 0:
            raise ValueError(f"Invalid whole-lattice mass: {key}")
    close(summary["mass_after_kg"], summary["mass_target_kg"],
          "Recorded whole-lattice mass and constraint target disagree")

    profiles = {}
    report = {
        "verification": "passed",
        "relative_tolerance": RTOL,
        "absolute_tolerance": ATOL,
        "density_kg_m3": DENSITY_KG_M3,
        "whole_lattice_mass_before_kg_from_summary": summary["mass_before_kg"],
        "whole_lattice_mass_after_kg_from_summary": summary["mass_after_kg"],
        "whole_lattice_mass_target_kg_from_summary": summary["mass_target_kg"],
        "whole_mass_check": "Summary consistency only; profiles cover shorter domains.",
        "axes": {},
    }
    for axis, (area_name, sample_count, first_position) in AXES.items():
        profile = np.genfromtxt(
            data_dir / f"{axis}_before_after.csv", delimiter=",", names=True,
            dtype=np.float64, encoding="utf-8",
        )
        if profile.dtype.names != COLUMNS or profile.shape != (sample_count - 1,):
            raise ValueError(f"Unexpected {axis} profile columns or row count.")
        values = np.column_stack([profile[name] for name in COLUMNS])
        if not np.all(np.isfinite(values)) or np.any(values < 0):
            raise ValueError(f"Nonfinite or negative {axis} profile value.")
        area = np.loadtxt(data_dir / area_name, delimiter=",", dtype=np.float64)
        if area.shape != (sample_count,) or not np.all(np.isfinite(area)):
            raise ValueError(f"Unexpected {axis} area samples.")
        if np.any(area <= 0):
            raise ValueError(f"Nonpositive {axis} source area.")

        edges = first_position + np.arange(sample_count) * 0.001
        width = profile["End_m"] - profile["Start_m"]
        close(profile["Start_m"], edges[:-1], f"{axis} interval starts",
              rtol=0, atol=1e-12)
        close(profile["End_m"], edges[1:], f"{axis} interval ends",
              rtol=0, atol=1e-12)
        close(profile["Midpoint_m"], (edges[:-1] + edges[1:]) / 2,
              f"{axis} interval midpoints", rtol=0, atol=1e-12)
        close(width, 0.001, f"{axis} interval widths", rtol=0, atol=1e-12)
        target = DENSITY_KG_M3 * 1e-6 * (area[:-1] + area[1:]) / 2
        close(profile["nTop_kg_m"], target,
              f"{axis} Slice Body area-to-mass conversion")

        squared_before = float(np.sum((profile["Before_kg_m"] - target) ** 2 * width))
        squared_after = float(np.sum((profile["After_kg_m"] - target) ** 2 * width))
        close(squared_before, summary["original"][axis],
              f"{axis} original integrated squared error")
        close(squared_after, summary["corrected"][axis],
              f"{axis} adjusted integrated squared error")
        masses = {
            name: float(np.sum(profile[name] * width))
            for name in ("Before_kg_m", "After_kg_m", "nTop_kg_m")
        }
        close(masses["nTop_kg_m"], summary[f"{axis}_target_integral_kg"],
              f"{axis} sampled Slice Body mass")
        for column, key in (("Before_kg_m", "mass_before_kg"),
                            ("After_kg_m", "mass_after_kg")):
            tolerance = ATOL + RTOL * abs(summary[key])
            if masses[column] > summary[key] + tolerance:
                raise ValueError(f"{axis} sampled mass exceeds whole-lattice {key}.")

        profiles[axis] = profile
        report["axes"][axis] = {
            "interval_count": len(profile),
            "domain_m": [float(profile["Start_m"][0]), float(profile["End_m"][-1])],
            "integrated_squared_error_before_kg2_m": squared_before,
            "integrated_squared_error_after_kg2_m": squared_after,
            "common_domain_mass_before_kg": masses["Before_kg_m"],
            "common_domain_mass_after_kg": masses["After_kg_m"],
            "sampled_slice_body_mass_kg": masses["nTop_kg_m"],
            "adjusted_mass_outside_common_domain_kg": (
                summary["mass_after_kg"] - masses["After_kg_m"]
            ),
        }

    for state, field in (("original", "before"), ("corrected", "after")):
        combined = sum(
            report["axes"][axis][f"integrated_squared_error_{field}_kg2_m"]
            for axis in AXES
        )
        close(combined, summary[state]["total"], f"Combined {state} squared error")
        report[f"combined_squared_error_{field}_kg2_m"] = combined
    return profiles, report


def render(profiles, output_dir: Path) -> list[Path]:
    """Write one two-panel figure as PNG and SVG, using identical axis scales."""
    plt.rcParams.update({
        "font.family": "DejaVu Sans", "font.size": 10,
        "axes.labelsize": 11, "axes.titlesize": 12,
        "axes.spines.top": False, "axes.spines.right": False,
        "axes.edgecolor": "#555555", "text.color": "#252525",
        "axes.labelcolor": "#252525", "svg.fonttype": "none",
    })
    figure, panels = plt.subplots(1, 2, figsize=(12, 4.8), sharey=True)
    figure.subplots_adjust(left=0.075, right=0.985, bottom=0.23,
                           top=0.76, wspace=0.14)
    styles = (
        ("Before_kg_m", "Original CBEAM", "#C46A13", "--", 1.1, 1),
        ("After_kg_m", "Adjusted CBEAM", "#556B2F", "-.", 1.25, 3),
        ("nTop_kg_m", "Slice Body", "#1565A8", "-", 1.0, 2),
    )
    maximum = max(float(np.max(table[name]))
                  for table in profiles.values() for name, *_ in styles)
    for panel, (axis, title, xlabel) in zip(panels, (
        ("span", "(a) Spanwise", "Span coordinate, x (m; global Y)"),
        ("chord", "(b) Chordwise", "Chord coordinate, y (m; global X)"),
    )):
        table = profiles[axis]
        for column, label, color, linestyle, linewidth, zorder in styles:
            panel.plot(table["Midpoint_m"], table[column], label=label,
                       color=color, linestyle=linestyle, linewidth=linewidth,
                       zorder=zorder)
        panel.set(title=title, xlabel=xlabel,
                  xlim=(table["Start_m"][0], table["End_m"][-1]),
                  ylim=(0, maximum * 1.06))
        panel.set_title(title, pad=12)
        panel.grid(axis="y", color="#DADADA", linewidth=0.6)
        panel.set_axisbelow(True)
    panels[0].set_ylabel("Lattice mass per unit length (kg/m)")
    handles, labels = panels[0].get_legend_handles_labels()
    figure.legend(handles, labels, loc="upper center", bbox_to_anchor=(0.53, 0.93),
                  ncol=3, frameon=False, handlelength=3.4, columnspacing=2.4)
    figure.suptitle("Case 4 lattice mass profiles", x=0.53, y=0.995, fontsize=15)
    figure.text(0.075, 0.095,
                "Interval means over 1 mm bins; only the saved sampled domains are shown.",
                fontsize=9)
    figure.text(0.075, 0.048,
                "Source: retained Case 4 calibration and Slice Body records; "
                "Slice Body conversion uses density 2700 kg/m\N{SUPERSCRIPT THREE}.",
                fontsize=8.5, color="#444444")
    output_dir.mkdir(parents=True, exist_ok=True)
    paths = [output_dir / f"case004_mass_profiles.{extension}"
             for extension in ("png", "svg")]
    figure.savefig(paths[0], dpi=300, facecolor="white", bbox_inches="tight")
    figure.savefig(paths[1], facecolor="white", bbox_inches="tight",
                   metadata={"Date": None})
    plt.close(figure)
    return paths


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT,
                        help="PNG/SVG output directory (default: repository generated directory).")
    args = parser.parse_args()
    profiles, report = verify_data()
    print(json.dumps(report, indent=2, allow_nan=False))
    for path in render(profiles, args.output.resolve()):
        print(f"Wrote {path}")


if __name__ == "__main__":
    main()
