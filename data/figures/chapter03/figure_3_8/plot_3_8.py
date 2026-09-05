"""Reproduce the three benchmark panels from the adjacent CSV only.

Dependencies: Python, NumPy, Matplotlib. The CSV retains every X/Y/C
observation as well as the empirical GA reference. No optimizer, external
data, or benchmark evaluation is required to reconstruct this figure.
"""
from pathlib import Path
import argparse
import csv
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

PROBLEMS = ["WELDEDBEAM", "MW7_D4", "MW7_D6"]
TITLES = ["(a) Welded beam, D = 4", "(b) MW7, D = 4", "(c) MW7, D = 6"]
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
    with (root / "figure_3_8.csv").open(newline="", encoding="utf-8-sig") as stream:
        records = [r for r in csv.DictReader(stream) if r["is_pareto"] == "1"]
    plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 8,
                         "axes.titlesize": 9, "axes.labelsize": 9,
                         "xtick.labelsize": 8, "ytick.labelsize": 8,
                         "axes.spines.top": False, "axes.spines.right": False})
    fig, axes = plt.subplots(2, 2, figsize=(7.0, 7.0))
    fig.subplots_adjust(left=.09, right=.985, bottom=.09, top=.90, hspace=.36, wspace=.30)
    for ax, problem, title in zip(axes.flat, PROBLEMS, TITLES):
        rows = [r for r in records if r["problem"] == problem]
        ga = np.array([[float(r["normalized_Y1"]), float(r["normalized_Y2"])] for r in rows if r["solver"] == "ga_reference"])
        ax.scatter(ga[:, 0], ga[:, 1], s=3, c="#161616", marker=".", zorder=1)
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
    axes.flat[3].axis("off")
    axes.flat[3].legend(handles=handles, loc="upper left", bbox_to_anchor=(.02,.98),
                        frameon=False, labelspacing=.5, handletextpad=.5, fontsize=8)
    axes.flat[3].text(.04,.02,"cTSEMO and HyperMapper use binary labels.\nOther solvers use continuous margins.\n\nThe pooled GA reference is empirical;\nit is not a true Pareto front.",
                      transform=axes.flat[3].transAxes, va="bottom", fontsize=8, linespacing=1.4)
    fig.suptitle("Observed feasible Pareto sets", x=.5, y=.974, fontsize=11)
    fig.text(.5,.938,"150 evaluations per solver: 20 shared initial + 130 adaptive; one run",ha="center",fontsize=8)
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=root / "plot_3_8.png")
    destination = parser.parse_args().output
    destination.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(destination, dpi=300, facecolor="white")
    plt.close(fig)
    print(destination)


if __name__ == "__main__":
    plot()
