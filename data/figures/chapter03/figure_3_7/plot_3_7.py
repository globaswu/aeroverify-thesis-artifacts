"""Reproduce the four benchmark panels from the adjacent CSV only.

Dependencies: Python, NumPy, Matplotlib. No optimizer, MATLAB data file,
network connection, or benchmark evaluator is needed. Both objectives are
minimized. Only observed, feasible, nondominated solver points are plotted;
the CSV additionally retains every evaluated X/Y/C observation.
"""
from pathlib import Path
import argparse
import csv
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

PROBLEMS = ["CF1_D4", "CF1_D10", "C2DTLZ2_D4_R02", "C2DTLZ2_D6_R02"]
TITLES = ["(a) CF1, D = 4", "(b) CF1, D = 10", "(c) C2-DTLZ2, D = 4", "(d) C2-DTLZ2, D = 6"]
STYLES = [
    ("ctsemo", "cTSEMO (binary)", "#0072B2", "o", True),
    ("hypermapper", "HyperMapper (binary)", "#D55E00", "<", False),
    ("botorch", "BoTorch", "#3C3C3C", "s", False),
    ("trieste", "Trieste", "#585858", "^", False),
    ("usemoc", "USeMOC", "#737373", "D", False),
    ("comboo", "COMBOO", "#909090", "v", False),
    ("pac-moo", "PAC-MOO", "#555555", ">", False),
]


def plot():
    root = Path(__file__).resolve().parent
    with (root / "figure_3_7.csv").open(newline="", encoding="utf-8-sig") as stream:
        records = [r for r in csv.DictReader(stream) if r["is_pareto"] == "1"]
    plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 8,
                         "axes.titlesize": 9, "axes.labelsize": 9,
                         "xtick.labelsize": 8, "ytick.labelsize": 8,
                         "axes.spines.top": False, "axes.spines.right": False})
    fig, axes = plt.subplots(2, 2, figsize=(7.0, 7.25))
    fig.subplots_adjust(left=.09, right=.985, bottom=.18, top=.90, hspace=.40, wspace=.30)
    for ax, problem, title in zip(axes.flat, PROBLEMS, TITLES):
        rows = [r for r in records if r["problem"] == problem]
        ga = np.array([[float(r["normalized_Y1"]), float(r["normalized_Y2"])] for r in rows if r["solver"] == "ga_reference"])
        ax.scatter(ga[:, 0], ga[:, 1], s=3, c="#161616", marker=".", zorder=1)
        # Draw each solver's observed points separately; disconnected regions
        # are never joined by interpolated curves.
        for sid, name, color, marker, filled in reversed(STYLES):
            y = np.array([[float(r["normalized_Y1"]), float(r["normalized_Y2"])] for r in rows if r["solver"] == sid])
            if len(y):
                ax.scatter(y[:, 0], y[:, 1], s=22 if filled else 19, marker=marker,
                           facecolors=color if filled else "none", edgecolors=color,
                           linewidths=.85, zorder=4 if filled else 2)
        ax.set_title(title, loc="left", pad=9)
        ax.set_xlabel("Normalized objective 1")
        ax.set_ylabel("Normalized objective 2")
        ax.grid(color="#E5E5E5", linewidth=.5)
        ax.set_axisbelow(True)
        ax.set_box_aspect(1)
        ax.margins(.07)
    handles = [Line2D([], [], linestyle="none", marker=m, markersize=5,
                       color=c, markerfacecolor=c if fill else "none", label=name)
               for _, name, c, m, fill in STYLES]
    handles.append(Line2D([], [], linestyle="none", marker=".", color="#161616", label="Empirical GA reference"))
    fig.legend(handles=handles, loc="lower center", bbox_to_anchor=(.50,.043), ncol=4,
               frameon=False, columnspacing=1.3, handletextpad=.35, fontsize=8)
    fig.suptitle("Observed feasible Pareto sets", x=.5, y=.974, fontsize=11)
    fig.text(.5,.938,"150 evaluations per solver: 20 shared initial + 130 adaptive; one run",ha="center",fontsize=8)
    fig.text(.5,.014,"Normalization uses the empirical GA front; the GA reference is not a true Pareto front.",ha="center",fontsize=7.5)
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=root / "plot_3_7.png")
    destination = parser.parse_args().output
    destination.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(destination, dpi=300, facecolor="white")
    plt.close(fig)
    print(destination)


if __name__ == "__main__":
    plot()
