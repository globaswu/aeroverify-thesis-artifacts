"""Reproduce thesis Figure 4.1 from its sibling CSV file."""

from __future__ import annotations

import argparse
import csv
import math
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt


SCRIPT_DIR = Path(__file__).resolve().parent
CSV_FILE = SCRIPT_DIR / "figure_4_1.csv"
CASE_ORDER = (45, 47, 20)
ROLE_LABELS = {
    45: "Minimum compliance",
    47: "Normalized-distance knee",
    20: "Minimum induced drag",
}
COLORS = {45: "#2b8cbe", 47: "#f0a202", 20: "#e66101"}


def read_rows() -> dict[int, list[dict[str, str]]]:
    with CSV_FILE.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))
    grouped: dict[int, list[dict[str, str]]] = {}
    for row in rows:
        grouped.setdefault(int(row["case_id"]), []).append(row)
    if set(grouped) != set(CASE_ORDER):
        raise ValueError(f"Expected cases {CASE_ORDER}, found {sorted(grouped)}")
    for case_id, case_rows in grouped.items():
        case_rows.sort(key=lambda row: int(row["point_order"]))
        if [int(row["point_order"]) for row in case_rows] != list(range(1, 7)):
            raise ValueError(f"Case {case_id} must contain point_order 1 through 6")
        for field in ("aspect_ratio", "taper_ratio", "CDitrim", "Ctrim_Nm"):
            if not all(math.isfinite(float(row[field])) for row in case_rows):
                raise ValueError(f"Case {case_id} contains a non-finite {field}")
    return grouped


def configure_style() -> None:
    plt.rcParams.update(
        {
            "font.family": "Times New Roman",
            "font.size": 10,
            "axes.titlesize": 14,
            "axes.labelsize": 11,
            "xtick.labelsize": 9,
            "ytick.labelsize": 9,
            "legend.fontsize": 9,
            "pdf.fonttype": 42,
            "ps.fonttype": 42,
            "mathtext.fontset": "custom",
            "mathtext.rm": "Times New Roman",
            "mathtext.it": "Times New Roman:italic",
            "mathtext.bf": "Times New Roman:bold",
        }
    )


def plot(output_file: Path) -> Path:
    grouped = read_rows()
    configure_style()
    output_file.parent.mkdir(parents=True, exist_ok=True)
    if not output_file.suffix:
        raise ValueError("--output must include a file-format suffix")

    maximum_semispan = max(float(grouped[case][0]["semispan_m"]) for case in CASE_ORDER)
    maximum_root_chord = max(
        float(grouped[case][0]["root_chord_m"]) for case in CASE_ORDER
    )

    figure, axes = plt.subplots(3, 1, figsize=(9.0, 7.4), sharex=True, sharey=True)
    for axis, case_id in zip(axes, CASE_ORDER):
        case_rows = grouped[case_id]
        metadata = case_rows[0]
        span = [float(row["spanwise_m"]) for row in case_rows]
        chordwise = [float(row["chordwise_m"]) for row in case_rows]

        axis.fill(
            span,
            chordwise,
            color=COLORS[case_id],
            alpha=0.82,
            edgecolor="#202124",
            linewidth=1.0,
        )
        axis.plot(
            [0.0, 0.0],
            [chordwise[4], chordwise[1]],
            color="#202124",
            linewidth=0.8,
        )
        axis.axhline(0.0, color="#5f6368", linewidth=0.7, linestyle=":")
        axis.set_aspect("equal", adjustable="box")
        axis.set_ylabel("Chordwise [m]")
        axis.set_title(
            f"Case {case_id}: {ROLE_LABELS[case_id]} | "
            f"AR = {float(metadata['aspect_ratio']):.2f} | "
            rf"$\lambda$ = {float(metadata['taper_ratio']):.3f} | "
            rf"$C_{{D_i,\mathrm{{trim}}}}$ = {float(metadata['CDitrim']):.5f} | "
            rf"$C_{{\mathrm{{trim}}}}$ = {float(metadata['Ctrim_Nm']):.2f} N m",
            fontsize=9.2,
            pad=4,
        )
        axis.grid(True, color="#d8dce0", linewidth=0.5, alpha=0.75)
        axis.set_xlim(-1.08 * maximum_semispan, 1.08 * maximum_semispan)
        axis.set_ylim(-0.31 * maximum_root_chord, 0.81 * maximum_root_chord)

    axes[-1].set_xlabel("Spanwise position [m]")
    figure.suptitle(
        "Representative final Pareto planforms: fixed area and unswept quarter-chord",
        fontsize=14,
        y=0.995,
    )
    figure.tight_layout(rect=(0.0, 0.0, 1.0, 0.965))

    figure.savefig(output_file, dpi=240, bbox_inches="tight")
    plt.close(figure)
    return output_file


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        type=Path,
        default=SCRIPT_DIR / "plot_4_1.png",
        help="Exact output file path; Matplotlib infers the format from its suffix.",
    )
    args = parser.parse_args()
    output_file = plot(args.output.expanduser().resolve())
    print(output_file)


if __name__ == "__main__":
    main()
