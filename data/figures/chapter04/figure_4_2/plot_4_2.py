"""Reproduce thesis Figure 4.2 from its sibling CSV file."""

from __future__ import annotations

import argparse
import csv
import math
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt


SCRIPT_DIR = Path(__file__).resolve().parent
CSV_FILE = SCRIPT_DIR / "figure_4_2.csv"
TOPOLOGY_ORDER = ("FCC", "BCC", "SC")
COLORS = {"FCC": "#0072B2", "BCC": "#D95319", "SC": "#77AC30"}


def read_rows() -> list[dict[str, str]]:
    with CSV_FILE.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))
    by_topology = {row["topology"]: row for row in rows}
    if set(by_topology) != set(TOPOLOGY_ORDER) or len(rows) != len(TOPOLOGY_ORDER):
        raise ValueError(f"Expected one row for each of {TOPOLOGY_ORDER}")
    ordered = [by_topology[topology] for topology in TOPOLOGY_ORDER]
    numeric_fields = (
        "cell_size_mm",
        "t1_over_a",
        "two_wing_mass_kg",
        "trim_compliance_Nm",
        "skin_stress_utilization",
        "beam_stress_utilization",
    )
    for row in ordered:
        if not all(math.isfinite(float(row[field])) for field in numeric_fields):
            raise ValueError(f"{row['topology']} contains non-finite plotted data")
    return ordered


def configure_style() -> None:
    plt.rcParams.update(
        {
            "font.family": "Times New Roman",
            "font.size": 10.5,
            "axes.linewidth": 0.8,
            "xtick.direction": "out",
            "ytick.direction": "out",
            "pdf.fonttype": 42,
            "ps.fonttype": 42,
        }
    )


def plot(output_file: Path) -> Path:
    rows = read_rows()
    configure_style()
    output_file.parent.mkdir(parents=True, exist_ok=True)
    if not output_file.suffix:
        raise ValueError("--output must include a file-format suffix")

    mass = [float(row["two_wing_mass_kg"]) for row in rows]
    compliance = [float(row["trim_compliance_Nm"]) for row in rows]
    case_ids = [int(row["case_id"]) for row in rows]
    cell_size_mm = [float(row["cell_size_mm"]) for row in rows]
    t1_over_a = [float(row["t1_over_a"]) for row in rows]
    skin_utilization = [float(row["skin_stress_utilization"]) for row in rows]
    beam_utilization = [float(row["beam_stress_utilization"]) for row in rows]

    figure, axes = plt.subplots(2, 1, figsize=(7.5, 7.4))
    ax1, ax2 = axes

    for index, topology in enumerate(TOPOLOGY_ORDER):
        ax1.scatter(
            mass[index],
            compliance[index],
            s=78,
            color=COLORS[topology],
            edgecolor="black",
            linewidth=0.7,
            zorder=3,
        )
    ax1.grid(True)
    ax1.set_xlabel("Two-wing mass, kg")
    ax1.set_ylabel("Trim compliance, N m")
    ax1.set_title("A. Frozen observed representatives")
    ax1.set_xlim(min(mass) - 1.2, max(mass) + 1.6)
    ax1.set_ylim(min(compliance) - 0.13, max(compliance) + 0.18)

    offsets = ((0.28, 0.04), (0.22, 0.04), (-1.55, -0.09))
    for index, topology in enumerate(TOPOLOGY_ORDER):
        label = (
            f"{topology} {case_ids[index]}\n"
            f"a = {cell_size_mm[index]:.2f} mm, r$_1$ = {t1_over_a[index]:.3f}"
        )
        ax1.text(
            mass[index] + offsets[index][0],
            compliance[index] + offsets[index][1],
            label,
            color="#1f1f1f",
            fontsize=9.5,
            verticalalignment="center",
        )

    x_positions = [1.0, 2.0, 3.0]
    width = 0.30
    ax2.bar(
        [x - width / 2 for x in x_positions],
        skin_utilization,
        width,
        color="#4d4d4d",
        edgecolor="none",
        label="Shell von Mises",
    )
    ax2.bar(
        [x + width / 2 for x in x_positions],
        beam_utilization,
        width,
        color="#a6a6a6",
        edgecolor="none",
        label="CBEAM max. normal",
    )
    ax2.axhline(1.0, color="#BF1E1E", linestyle="--", linewidth=1.2)
    ax2.text(
        3.48,
        1.01,
        "220 MPa screen",
        color="#BF1E1E",
        ha="right",
        va="bottom",
        fontsize=9.5,
    )
    ax2.grid(True, axis="y")
    ax2.set_xticks(x_positions)
    ax2.set_xticklabels(
        [f"{topology} {case_id}" for topology, case_id in zip(TOPOLOGY_ORDER, case_ids)]
    )
    ax2.set_ylabel(r"Stress utilization, $\sigma_{max}/220$ MPa")
    ax2.set_title("B. Retained stress-channel comparison")
    ax2.set_ylim(0.0, 1.12)
    ax2.set_xlim(0.5, 3.5)
    ax2.legend(loc="lower left", frameon=False)

    figure.tight_layout()
    figure.savefig(output_file, dpi=240, bbox_inches="tight")
    plt.close(figure)
    return output_file


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        type=Path,
        default=SCRIPT_DIR / "plot_4_2.png",
        help="Exact output file path; Matplotlib infers the format from its suffix.",
    )
    args = parser.parse_args()
    output_file = plot(args.output.expanduser().resolve())
    print(output_file)


if __name__ == "__main__":
    main()
