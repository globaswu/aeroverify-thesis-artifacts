"""Reproduce the completed topology comparison using figure_5_1.csv only.

Requirements: Python 3, NumPy, Matplotlib. No simulation software is required.
The lines join observed nondominated points as visual guides; they are not
surrogate predictions or proof of a continuous Pareto front.
"""
from pathlib import Path
import argparse
import csv

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D


def nondominated(y, eligible):
    result = np.zeros(len(y), dtype=bool)
    for i in np.flatnonzero(eligible):
        result[i] = not np.any(eligible & np.all(y <= y[i], axis=1) & np.any(y < y[i], axis=1))
    return result


def main():
    folder = Path(__file__).resolve().parent
    with (folder / "figure_5_1.csv").open(newline="", encoding="utf-8-sig") as handle:
        rows = list(csv.DictReader(handle))
    topology = np.array([r["topology"] for r in rows])
    y = np.array([[float(r["Y1_two_wing_mass_kg"]), float(r["Y2_two_wing_trim_compliance_Nm"])] for r in rows])
    feasible = np.array([int(r["C_binary_feasible"]) == 1 for r in rows])
    family_pf = np.array([int(r["within_topology_observed_pareto"]) == 1 for r in rows])
    pooled_pf = np.array([int(r["pooled_observed_pareto"]) == 1 for r in rows])
    assert len(rows) == 213 and np.isfinite(y).all()
    assert np.array_equal(nondominated(y, feasible), pooled_pf)
    palette = {"FCC": "#176B91", "BCC": "#B97824", "SC": "#A45078"}
    markers = {"FCC": "o", "BCC": "s", "SC": "^"}
    plt.rcParams.update({"font.family": "Times New Roman", "font.size": 10,
                         "axes.labelsize": 11, "axes.titlesize": 12,
                         "xtick.labelsize": 10, "ytick.labelsize": 10,
                         "axes.linewidth": 0.7, "axes.edgecolor": "#333333",
                         "text.color": "#252525", "axes.labelcolor": "#252525"})
    fig, ax = plt.subplots(figsize=(7.2, 5.3), facecolor="white")
    fig.subplots_adjust(left=0.105, right=0.975, bottom=0.125, top=0.76)
    fig.suptitle("Completed lattice-sizing campaigns", y=0.976, fontsize=13)
    fig.text(0.5, 0.925, "71 evaluations per topology; 92 feasible observations", ha="center", fontsize=10)
    ax.set_axisbelow(True)
    ax.grid(True, color="#E4E4E4", linewidth=0.55)
    for name in ("FCC", "BCC", "SC"):
        group = topology == name
        assert group.sum() == 71
        assert np.array_equal(nondominated(y[group], feasible[group]), family_pf[group])
        mask = group & ~feasible
        ax.scatter(y[mask, 0], y[mask, 1], marker=markers[name], s=26,
                   facecolors="none", edgecolors=palette[name], linewidths=0.7,
                   alpha=0.52, zorder=2)
        mask = group & feasible
        ax.scatter(y[mask, 0], y[mask, 1], marker=markers[name], s=30,
                   facecolors=palette[name], edgecolors="white", linewidths=0.35,
                   zorder=3)
        values = y[group & family_pf]
        values = values[np.argsort(values[:, 0])]
        ax.plot(values[:, 0], values[:, 1], color=palette[name], linewidth=1.1, zorder=2.5)
    ax.scatter(y[pooled_pf, 0], y[pooled_pf, 1], s=82, facecolors="none",
               edgecolors="#202020", linewidths=0.75, zorder=4)
    handles = [Line2D([], [], marker=markers[name], markersize=6, color=palette[name],
                      markerfacecolor=palette[name], linewidth=1.1, label=name)
               for name in ("FCC", "BCC", "SC")]
    handles += [Line2D([], [], marker="o", color="none", markerfacecolor="#555555", markeredgecolor="#555555", label="Feasible"),
                Line2D([], [], marker="o", color="none", markerfacecolor="none", markeredgecolor="#777777", label="Infeasible"),
                Line2D([], [], marker="o", color="none", markerfacecolor="none", markeredgecolor="#202020", markersize=9, label="Pooled front")]
    handles = [handles[i] for i in (0, 3, 1, 4, 2, 5)]
    fig.legend(handles=handles, loc="upper center", bbox_to_anchor=(0.52, 0.895),
               ncol=3, frameon=False, columnspacing=2.0, handletextpad=0.65,
               fontsize=9.5, labelspacing=0.7)
    labels = {"FCC70": (-3, 13, "left"), "FCC26": (-5, 12, "right"), "SC70": (6, 7, "left")}
    for row, (mass, compliance) in zip(rows, y):
        if row["design_id"] in labels:
            dx, dy, align = labels[row["design_id"]]
            ax.annotate(row["design_id"], (mass, compliance), xytext=(dx, dy),
                        textcoords="offset points", ha=align, va="bottom", fontsize=9,
                        bbox=dict(facecolor="white", edgecolor="none", pad=0.6, alpha=0.9))
    ax.set(xlabel="Two-wing structural mass (kg)",
           ylabel=r"Two-wing trim compliance (N $\cdot$ m)",
           xlim=(31, 86), ylim=(42.8, 56.4))
    ax.spines[["top", "right"]].set_visible(False)
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=folder / "plot_5_1.png")
    output = parser.parse_args().output
    output.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output, dpi=300, facecolor="white")
    plt.close(fig)
    print(f"Saved {output.name}: {len(rows)} evaluations, {feasible.sum()} feasible, {pooled_pf.sum()} pooled-front points.")


if __name__ == "__main__":
    main()
