"""Reproduce thesis Figure 2.7 from the sibling CSV only."""

import argparse
import csv
from pathlib import Path

import matplotlib.pyplot as plt


HERE = Path(__file__).resolve().parent
DATA_FILE = HERE / "figure_2_7.csv"
DEFAULT_OUTPUT_FILE = HERE / "plot_2_7.png"

REQUIRED_COLUMNS = {
    "case_id",
    "geometry_tolerance_mm",
    "mesh_edge_length_mm",
    "two_wing_compliance_Nm",
    "maximum_vertical_deflection_m",
    "skin_vm_p9975_MPa",
    "cbeam_normal_stress_p9975_MPa",
    "first_modal_frequency_Hz",
}


def plot_metric(axis, data, cases, column, ylabel, colors):
    for index, case_id in enumerate(cases):
        rows = sorted(
            (row for row in data if row["case_id"] == case_id),
            key=lambda row: row["mesh_edge_length_mm"],
        )
        axis.plot(
            [row["mesh_edge_length_mm"] for row in rows],
            [row[column] for row in rows],
            "-o",
            linewidth=1.4,
            color=colors[index],
            markerfacecolor=colors[index],
            label=f"Case {case_id}",
        )
    axis.set_xlabel("Target mesh edge length [mm]")
    axis.set_ylabel(ylabel)
    axis.grid(True, alpha=0.35)


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT_FILE,
        help="Output image file (default: sibling plot_2_7.png)",
    )
    return parser.parse_args()


def main(output_file=DEFAULT_OUTPUT_FILE):
    with DATA_FILE.open(newline="", encoding="utf-8") as stream:
        reader = csv.DictReader(stream)
        missing = REQUIRED_COLUMNS.difference(reader.fieldnames or [])
        if missing:
            raise ValueError(f"Missing required columns: {sorted(missing)}")
        data = []
        for source in reader:
            row = {name: float(source[name]) for name in REQUIRED_COLUMNS}
            row["case_id"] = int(row["case_id"])
            data.append(row)
    if len(data) != 15:
        raise ValueError(f"Expected 15 plotted observations, found {len(data)}")
    if not all(row["geometry_tolerance_mm"] == 1.5 for row in data):
        raise ValueError("Figure 2.7 requires a fixed 1.5 mm geometry tolerance")

    cases = sorted({row["case_id"] for row in data})
    if cases != [4, 37, 64, 65, 99]:
        raise ValueError(f"Unexpected case set: {cases}")
    # MATLAB's lines(5), matching the thesis figure.
    colors = [
        (0.0000, 0.4470, 0.7410),
        (0.8500, 0.3250, 0.0980),
        (0.9290, 0.6940, 0.1250),
        (0.4940, 0.1840, 0.5560),
        (0.4660, 0.6740, 0.1880),
    ]

    plt.rcParams.update({"font.family": "Times New Roman", "font.size": 9})
    figure, axes = plt.subplots(2, 2, figsize=(9, 9), constrained_layout=True)
    figure.suptitle("Aeroelastic mesh-convergence results", fontweight="bold")

    plot_metric(
        axes[0, 0],
        data,
        cases,
        "two_wing_compliance_Nm",
        "Two-wing compliance at 10 deg [N m]",
        colors,
    )
    axes[0, 0].set_ylim(0, 350)
    plot_metric(
        axes[0, 1],
        data,
        cases,
        "maximum_vertical_deflection_m",
        "Maximum vertical deflection at 10 deg [m]",
        colors,
    )
    axes[0, 1].set_ylim(0.01, 0.10)

    stress_axis = axes[1, 0]
    for index, case_id in enumerate(cases):
        rows = sorted(
            (row for row in data if row["case_id"] == case_id),
            key=lambda row: row["mesh_edge_length_mm"],
        )
        stress_axis.plot(
            [row["mesh_edge_length_mm"] for row in rows],
            [row["skin_vm_p9975_MPa"] for row in rows],
            "-o",
            linewidth=1.4,
            color=colors[index],
            markerfacecolor=colors[index],
            label=f"Case {case_id}",
        )
        stress_axis.plot(
            [row["mesh_edge_length_mm"] for row in rows],
            [row["cbeam_normal_stress_p9975_MPa"] for row in rows],
            "--s",
            linewidth=1.2,
            color=colors[index],
        )
    stress_axis.set_xlabel("Target mesh edge length [mm]")
    stress_axis.set_ylabel("99.75th-percentile stress [MPa]")
    stress_axis.set_ylim(0, 120)
    stress_axis.grid(True, alpha=0.35)
    stress_axis.legend(
        title="Solid: skin VM; dashed: CBEAM normal",
        loc="upper center",
        bbox_to_anchor=(0.5, -0.16),
        ncol=2,
        frameon=True,
        fontsize=8,
        title_fontsize=8,
    )

    plot_metric(
        axes[1, 1],
        data,
        cases,
        "first_modal_frequency_Hz",
        "First retained modal frequency [Hz]",
        colors,
    )
    axes[1, 1].set_ylim(14, 32)
    axes[0, 0].legend(loc="best", fontsize=8)
    axes[0, 1].legend(loc="best", fontsize=8)
    axes[1, 1].legend(loc="best", fontsize=8)
    for axis in axes.flat:
        axis.set_xlim(1.8, 2.5)

    output_file = Path(output_file).expanduser().resolve()
    output_file.parent.mkdir(parents=True, exist_ok=True)
    figure.savefig(output_file, dpi=220, facecolor="white")
    plt.close(figure)
    print(output_file)


if __name__ == "__main__":
    arguments = parse_args()
    main(arguments.output)
