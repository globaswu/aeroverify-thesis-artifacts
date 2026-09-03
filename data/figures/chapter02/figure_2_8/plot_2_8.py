"""Reproduce thesis Figure 2.8 from the sibling CSV only."""

import argparse
import csv
from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.ticker import FormatStrFormatter


HERE = Path(__file__).resolve().parent
DATA_FILE = HERE / "figure_2_8.csv"
DEFAULT_OUTPUT_FILE = HERE / "plot_2_8.png"

CONFIGURATIONS = [
    ("coarse_edge_length_2p5_mm", "Coarse edge length: 2.5 mm"),
    ("geometry_tolerance_2p0_mm", "Geometry tolerance: 2.0 mm"),
]


def format_axis(axis, title, scientific=False):
    axis.set_xlim(30, 150)
    axis.axhline(0.0, color="0.1", linewidth=1.1)
    axis.set_title(title, loc="left", fontsize=10, fontweight="normal")
    axis.set_xlabel("Velocity, V [m/s]")
    axis.set_ylabel("Damping, g [-]")
    axis.grid(True, linestyle=":", alpha=0.25)
    if scientific:
        axis.set_ylim(-1.6e-5, 2.0e-6)
        axis.yaxis.set_major_formatter(FormatStrFormatter("%.1e"))
    else:
        axis.set_ylim(-0.16, 0.02)


def plot_all_roots(axis, data, title):
    roots = sorted({row["root"] for row in data})
    colors = plt.get_cmap("tab20").colors
    for index, root in enumerate(roots):
        rows = sorted(
            (row for row in data if row["root"] == root),
            key=lambda row: row["velocity_mps"],
        )
        axis.plot(
            [row["velocity_mps"] for row in rows],
            [row["damping_g"] for row in rows],
            linewidth=0.85,
            color=colors[index % len(colors)],
        )
    format_axis(axis, title)


def plot_root_19(axis, data, title):
    rows = sorted(
        (row for row in data if row["root"] == 19),
        key=lambda row: row["velocity_mps"],
    )
    axis.plot(
        [row["velocity_mps"] for row in rows],
        [row["damping_g"] for row in rows],
        linewidth=1.15,
        color=(0.00, 0.31, 0.55),
        label="Root 19",
    )
    positive = [row for row in rows if row["positive"]]
    axis.scatter(
        [row["velocity_mps"] for row in positive],
        [row["damping_g"] for row in positive],
        s=28,
        color=(0.80, 0.16, 0.12),
        label="Positive sample",
        zorder=3,
    )
    format_axis(axis, title, scientific=True)
    axis.legend(loc="lower left", frameon=False, fontsize=8)


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT_FILE,
        help="Output image file (default: sibling plot_2_8.png)",
    )
    return parser.parse_args()


def main(output_file=DEFAULT_OUTPUT_FILE):
    required = {"configuration", "root", "velocity_mps", "damping_g", "positive"}
    with DATA_FILE.open(newline="", encoding="utf-8") as stream:
        reader = csv.DictReader(stream)
        missing = required.difference(reader.fieldnames or [])
        if missing:
            raise ValueError(f"Missing required columns: {sorted(missing)}")
        data = []
        for source in reader:
            data.append(
                {
                    "configuration": source["configuration"],
                    "root": int(source["root"]),
                    "velocity_mps": float(source["velocity_mps"]),
                    "damping_g": float(source["damping_g"]),
                    "positive": source["positive"].strip().lower()
                    in {"1", "true"},
                }
            )
    if len(data) != 1480:
        raise ValueError(f"Expected 1,480 valid V-g samples, found {len(data)}")
    if sorted({row["root"] for row in data}) != list(range(1, 21)):
        raise ValueError("Expected retained roots 1 through 20")

    plt.rcParams.update({"font.family": "Times New Roman", "font.size": 9})
    figure, axes = plt.subplots(2, 2, figsize=(7.25, 10.75), constrained_layout=True)
    figure.suptitle("Case 64 V-g diagnostic", fontsize=13, fontweight="bold")

    for row_index, (configuration, title) in enumerate(CONFIGURATIONS):
        subset = [row for row in data if row["configuration"] == configuration]
        if len(subset) != 740:
            raise ValueError(
                f"Expected 740 samples for {configuration}, found {len(subset)}"
            )
        plot_all_roots(
            axes[row_index, 0],
            subset,
            f"{'a' if row_index == 0 else 'c'}. {title}, all roots",
        )
        plot_root_19(
            axes[row_index, 1],
            subset,
            f"{'b' if row_index == 0 else 'd'}. {title}, root 19",
        )

    output_file = Path(output_file).expanduser().resolve()
    output_file.parent.mkdir(parents=True, exist_ok=True)
    figure.savefig(output_file, dpi=220, facecolor="white")
    plt.close(figure)
    print(output_file)


if __name__ == "__main__":
    arguments = parse_args()
    main(arguments.output)
