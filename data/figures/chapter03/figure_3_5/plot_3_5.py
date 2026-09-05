"""Standalone renderer for a single thesis figure-data CSV."""

from __future__ import annotations

import argparse
import csv
import math
import re
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap
import numpy as np


SCRIPT = Path(__file__).resolve()
# This identifier selects the original numerical renderer independently
# of the figure number in the revised thesis.
NUMBER = 6
CSV_FILE = SCRIPT.parent / "figure_3_5.csv"
DEFAULT_OUTPUT = SCRIPT.parent / "plot_3_5.png"

PARSER = argparse.ArgumentParser(
    description="Render Thesis Figure 3.5 from its sibling CSV."
)
PARSER.add_argument(
    "--output",
    type=Path,
    default=DEFAULT_OUTPUT,
    help="Output image path (default: sibling plot_3_5.png).",
)
OUTPUT_FILE = PARSER.parse_args().output.resolve()

plt.rcParams.update(
    {
        "font.family": "serif",
        "font.size": 9,
        "axes.titlesize": 10,
        "axes.labelsize": 9,
        "legend.fontsize": 7,
    }
)


def read_rows(path: Path):
    with path.open(newline="", encoding="utf-8-sig") as stream:
        return list(csv.DictReader(stream))


def number(row, name):
    raw = row.get(name, "")
    if raw in ("", "NaN", "nan"):
        return math.nan
    return float(raw)


def column(rows, name):
    return np.asarray([number(row, name) for row in rows], dtype=float)


def matrix(rows, value, x="normalized_x1", y="normalized_x2"):
    x_values = np.asarray(sorted({number(row, x) for row in rows}), dtype=float)
    y_values = np.asarray(sorted({number(row, y) for row in rows}), dtype=float)
    x_index = {value: index for index, value in enumerate(x_values)}
    y_index = {value: index for index, value in enumerate(y_values)}
    result = np.full((len(y_values), len(x_values)), np.nan)
    for row in rows:
        result[y_index[number(row, y)], x_index[number(row, x)]] = number(row, value)
    if np.isnan(result).any():
        raise RuntimeError(f"Incomplete grid for {value}.")
    return x_values, y_values, result


def format_domain(axis):
    axis.set_xlim(0, 1)
    axis.set_ylim(0, 1)
    axis.set_aspect("equal", adjustable="box")
    axis.set_xlabel(r"Normalized $x_1$")
    axis.set_ylabel(r"Normalized $x_2$")


def scatter_evaluations(axis, rows):
    feasible = [row for row in rows if number(row, "feasible") == 1]
    violating = [row for row in rows if number(row, "feasible") == 0]
    axis.scatter(column(feasible, "normalized_x1"), column(feasible, "normalized_x2"),
                 s=22, facecolors="white", edgecolors="black", linewidths=0.6, zorder=4)
    axis.scatter(column(violating, "normalized_x1"), column(violating, "normalized_x2"),
                 s=24, marker="x", color="#bf1238", linewidths=0.9, zorder=5)


def plot_final_pof(data):
    problems = ["COSSIN1", "COSSIN2", "BNH", "SRN"]
    figure, axes = plt.subplots(2, 2, figsize=(7.4, 7.2), constrained_layout=True)
    image = None
    for axis, problem in zip(axes.flat, problems, strict=True):
        grid = [row for row in data if row["record_type"] == "grid" and row["problem_id"] == problem]
        evaluations = [row for row in data if row["record_type"] == "evaluation" and row["problem_id"] == problem]
        x, y, score = matrix(grid, "pof_score")
        _, _, truth = matrix(grid, "exact_feasible")
        image = axis.pcolormesh(x, y, score, cmap="turbo", shading="auto", vmin=0, vmax=1)
        axis.contour(x, y, truth, levels=[0.5], colors="black", linestyles="--", linewidths=0.8)
        scatter_evaluations(axis, evaluations)
        axis.set_title(f"{problem}: {int(number(grid[0], 'total_evaluations'))} evaluations")
        format_domain(axis)
    figure.colorbar(image, ax=axes, label=r"Binary-feasibility score, $p_i$", shrink=0.85)
    figure.suptitle("Final clipped binary-feasibility fields")
    return figure


def plot_classification(data):
    problems = ["COSSIN1", "COSSIN2", "BNH", "SRN"]
    colors = ListedColormap(["#1f2b3b", "#d12e21", "#2e7ad1", "#f29e1f"])
    figure, axes = plt.subplots(2, 2, figsize=(7.4, 7.2), constrained_layout=True)
    image = None
    for axis, problem in zip(axes.flat, problems, strict=True):
        grid = [row for row in data if row["record_type"] == "grid" and row["problem_id"] == problem]
        x, y, classes = matrix(grid, "error_class")
        image = axis.pcolormesh(x, y, classes, cmap=colors, shading="auto", vmin=-0.5, vmax=3.5)
        axis.set_title(problem)
        format_domain(axis)
    colorbar = figure.colorbar(image, ax=axes, ticks=[0, 1, 2, 3], shrink=0.85)
    colorbar.ax.set_yticklabels(["correct violating", "false feasible", "false infeasible", "correct feasible"])
    figure.suptitle(r"Spatial classification outcomes at $p_i\geq0.5$")
    return figure


def plot_learning(data, problem):
    milestones = sorted({number(row, "total_evaluations") for row in data if row["record_type"] == "grid"})
    figure, axes = plt.subplots(2, 2, figsize=(7.4, 7.2), constrained_layout=True)
    image = None
    for axis, milestone in zip(axes.flat, milestones, strict=True):
        grid = [row for row in data if row["record_type"] == "grid" and number(row, "total_evaluations") == milestone]
        evaluations = [row for row in data if row["record_type"] == "evaluation" and number(row, "total_evaluations") == milestone]
        x, y, score = matrix(grid, "pof_score")
        _, _, truth = matrix(grid, "exact_feasible")
        image = axis.pcolormesh(x, y, score, cmap="turbo", shading="auto", vmin=0, vmax=1)
        axis.contour(x, y, score, levels=[0.5], colors="white", linewidths=1.1)
        axis.contour(x, y, truth, levels=[0.5], colors="black", linestyles="--", linewidths=0.9)
        scatter_evaluations(axis, evaluations)
        axis.set_title(f"{problem}, N = {int(milestone)}")
        format_domain(axis)
    figure.colorbar(image, ax=axes, label=r"Binary-feasibility score, $p_i$", shrink=0.85)
    figure.suptitle(f"{problem} feasibility-score learning")
    return figure


def plot_acquisition(data):
    grid = [row for row in data if row["record_type"] == "grid"]
    evaluations = [row for row in data if row["record_type"] == "evaluation"]
    selected = next(row for row in data if row["record_type"] == "selected_point")
    fields = [("pof_score", "(a) Feasibility score", "viridis"),
              ("sampled_hvi", "(b) Sampled HVI", "magma"),
              ("pof_times_sampled_hvi", "(c) PoF times sampled HVI", "magma"),
              ("final_acquisition", "(d) Final acquisition", "magma")]
    _, _, truth = matrix(grid, "exact_feasible")
    figure, axes = plt.subplots(2, 2, figsize=(7.4, 6.8), constrained_layout=True)
    for axis, (field, title, cmap) in zip(axes.flat, fields, strict=True):
        x, y, values = matrix(grid, field)
        image = axis.pcolormesh(x, y, values, cmap=cmap, shading="auto")
        axis.contour(x, y, truth, levels=[0.5], colors="white", linestyles="--", linewidths=0.8)
        scatter_evaluations(axis, evaluations)
        axis.scatter(number(selected, "normalized_x1"), number(selected, "normalized_x2"),
                     marker="*", s=80, facecolor="#35f2ff", edgecolor="black", zorder=6)
        format_domain(axis)
        axis.set_title(title)
        figure.colorbar(image, ax=axis, shrink=0.82)
    figure.suptitle("COSSIN2 iteration-20 acquisition decomposition")
    return figure


def padded(values, fraction=0.08, positive=False):
    low, high = np.nanmin(values), np.nanmax(values)
    span = max(high - low, abs(high) * 0.05, 1e-12)
    low, high = low - fraction * span, high + fraction * span
    return (max(np.nextafter(0.0, 1.0), low) if positive else low), high


def draw_wb_panel(axis, data, log_y, zoom):
    violating = [row for row in data if number(row, "feasible") == 0]
    dominated = [row for row in data if number(row, "feasible") == 1 and number(row, "final_pareto") == 0]
    pareto = sorted([row for row in data if number(row, "final_pareto") == 1],
                    key=lambda row: number(row, "objective_f1_fabrication_cost"))
    newest = [row for row in data if number(row, "is_evaluation_150") == 1]
    axis.scatter(column(violating, "objective_f1_fabrication_cost"), column(violating, "objective_f2_end_deflection"), marker="x", color="0.55", s=25, label="Violating")
    axis.scatter(column(dominated, "objective_f1_fabrication_cost"), column(dominated, "objective_f2_end_deflection"), facecolors="white", edgecolors="#407aa8", s=27, label="Feasible, dominated")
    axis.plot(column(pareto, "objective_f1_fabrication_cost"), column(pareto, "objective_f2_end_deflection"), "-o", color="#0059a6", markersize=4, linewidth=1.6, label="Feasible Pareto front")
    axis.scatter(column(newest, "objective_f1_fabrication_cost"), column(newest, "objective_f2_end_deflection"), marker="D", color="#f07413", edgecolor="#a83805", s=60, label="Evaluation 150")
    axis.set_xlabel(r"Objective $f_1$ (benchmark cost index)")
    axis.set_ylabel(r"Objective $f_2$ (benchmark deflection index)")
    axis.grid(alpha=0.25)
    if log_y:
        axis.set_yscale("log")
    if zoom:
        axis.set_xlim(*padded(column(pareto, "objective_f1_fabrication_cost"), 0.10, True))
        axis.set_ylim(*padded(column(pareto, "objective_f2_end_deflection"), 0.12, True))


def plot_wb_front(data):
    figure, axes = plt.subplots(2, 1, figsize=(7.4, 8.6), constrained_layout=True)
    draw_wb_panel(axes[0], data, True, False)
    axes[0].set_title("Complete objective space")
    draw_wb_panel(axes[1], data, False, True)
    axes[1].set_title("Fixed Pareto-region view")
    axes[1].legend(ncol=2, loc="upper center", bbox_to_anchor=(0.5, 1.22))
    figure.suptitle("WB150 replicate-2 Pareto front after 150 evaluations")
    return figure


def plot_hv_histories(data):
    curves = [row for row in data if row["record_type"] == "curve"]
    problems = list(dict.fromkeys(row["problem_id"] for row in curves))
    figure, axes = plt.subplots(2, 4, figsize=(10.0, 6.25), constrained_layout=True)
    for axis, problem in zip(axes.flat, problems, strict=False):
        rows = sorted([row for row in curves if row["problem_id"] == problem],
                      key=lambda row: number(row, "sequential_evaluations"))
        x = column(rows, "sequential_evaluations")
        for seed in range(1, 6):
            axis.plot(x, column(rows, f"seed_{seed}_normalized_hv"), linewidth=0.8, label=f"seed {seed}")
        axis.plot(x, column(rows, "median_normalized_hv"), color="black", linewidth=2.0, label="median")
        axis.set_title(rows[0]["display_name"])
        axis.set_xlim(0, 130)
        axis.set_xlabel("Sequential evaluations")
        axis.set_ylabel("Normalized hypervolume")
        axis.grid(alpha=0.25)
    for axis in axes.flat[len(problems):]:
        axis.set_visible(False)
    axes.flat[0].legend(fontsize=6, ncol=2)
    figure.suptitle("Feasible-front hypervolume histories")
    return figure


def plot_solver_fronts(data):
    labels = list(dict.fromkeys(row["solver_label"] for row in data))
    figure, axes = plt.subplots(1, 2, figsize=(8.4, 4.2), constrained_layout=True)
    for label in labels:
        rows = sorted([row for row in data if row["solver_label"] == label],
                      key=lambda row: number(row, "pareto_point_index"))
        for axis in axes:
            axis.plot(column(rows, "objective_f1_fabrication_cost"), column(rows, "objective_f2_end_deflection"), marker="o", markersize=3, linewidth=1.2, label=label)
    axes[0].set_yscale("log")
    axes[0].set_xlim(0, 350)
    axes[0].set_ylim(3e-4, 5e-2)
    axes[0].set_title("Complete solver-owned feasible fronts")
    axes[1].set_xlim(0, 65)
    axes[1].set_ylim(0, 0.0132)
    axes[1].set_title("Established trade-off region")
    for axis in axes:
        axis.set_xlabel(r"Fabrication cost objective, $f_1$")
        axis.set_ylabel(r"End deflection objective, $f_2$")
        axis.grid(alpha=0.25)
    axes[0].legend(ncol=2, fontsize=6, loc="lower center")
    figure.suptitle("Historical WB150 external-solver pilot")
    return figure


def plot_conditional(data):
    survival = [row for row in data if row["record_type"] == "survival_grid"]
    profile = sorted([row for row in data if row["record_type"] == "profile_station"],
                     key=lambda row: number(row, "input_physical"))
    metadata_row = next(row for row in data if row["record_type"] == "metadata")
    x, thresholds, log_probability = matrix(survival, "log10_conditional_exceedance_probability", "input_physical", "threshold_normalized")
    _, _, probability = matrix(survival, "conditional_exceedance_probability", "input_physical", "threshold_normalized")
    y = np.log10(thresholds)
    figure, axes = plt.subplots(3, 1, figsize=(7.5, 9.2), constrained_layout=True)
    image = axes[0].pcolormesh(x, y, log_probability, shading="auto", cmap="viridis")
    axes[0].contour(x, y, probability, levels=[0.01, 0.1, 0.5], colors="black", linewidths=0.7)
    axes[0].set_ylim(-8, 0)
    axes[0].set_ylabel("log10 normalized HVI threshold")
    axes[0].set_title("A. Conditional HVI survival")
    figure.colorbar(image, ax=axes[0], label="log10 exceedance probability")
    physical = column(profile, "input_physical")
    axes[1].plot(physical, column(profile, "p90_normalized_hvi"), label="90th percentile")
    axes[1].plot(physical, column(profile, "p99_normalized_hvi"), label="99th percentile")
    axes[1].plot(physical, column(profile, "mean_normalized_hvi"), "--", label="conditional mean")
    axes[1].plot(physical, column(profile, "sampled_profile_maximum_normalized_hvi"), color="black", label="sampled profile maximum")
    axes[1].scatter(number(metadata_row, "selected_input_physical"), number(metadata_row, "selected_hvi_normalized"), marker="*", s=70, color="#b33a3a", label="selected design")
    axes[1].set_yscale("log")
    axes[1].set_ylim(1e-8, 1.15)
    axes[1].set_title("B. Conditional quantiles and profile")
    axes[1].legend(ncol=2)
    axes[2].plot(physical, column(profile, "positive_hvi_fraction"), color="#e86e17", label="positive-HVI fraction")
    axes[2].plot(physical, column(profile, "mean_normalized_hvi"), "--", color="#1769aa", label="conditional mean")
    axes[2].set_yscale("log")
    axes[2].set_ylim(1e-8, 1)
    axes[2].set_title("C. Positive-HVI support and conditional mean")
    axes[2].legend()
    for axis in axes:
        axis.set_xlabel(f"{metadata_row['input_name']}, {metadata_row['input_symbol']}")
        axis.grid(alpha=0.25)
    figure.suptitle(f"WB150 iteration-130 conditional sampled HVI versus {metadata_row['input_name']}")
    return figure


def plot_pairwise(data):
    slices = [row for row in data if row["record_type"] == "slice_grid"]
    positive = np.asarray([number(row, "hvi_draw") for row in slices if number(row, "hvi_draw") > 1e-12])
    vmin = np.floor(2 * np.log10(positive).min()) / 2
    vmax = np.ceil(2 * np.log10(positive).max()) / 2
    pair_ids = sorted({int(number(row, "pair_id")) for row in slices})
    figure, axes = plt.subplots(3, 2, figsize=(7.5, 9.2), constrained_layout=True)
    image = None
    for axis, pair_id in zip(axes.flat, pair_ids, strict=True):
        rows = [row for row in slices if int(number(row, "pair_id")) == pair_id]
        input_a, input_b = int(number(rows[0], "input_a")), int(number(rows[0], "input_b"))
        x, y, values = matrix(rows, "hvi_draw", f"x{input_a}", f"x{input_b}")
        image = axis.pcolormesh(x, y, np.log10(values + 1e-12), shading="auto", cmap="viridis", vmin=vmin, vmax=vmax)
        axis.set_xlabel(rf"$x_{input_a}$")
        axis.set_ylabel(rf"$x_{input_b}$")
        axis.set_title(rf"$x_{input_a}$ and $x_{input_b}$")
        axis.set_aspect("equal", adjustable="box")
    figure.colorbar(image, ax=axes, label=r"$\log_{10}(\mathrm{sampled\ HVI}+10^{-12})$", shrink=0.82)
    figure.suptitle("WB150 pairwise slices of sampled HVI")
    return figure


data = read_rows(CSV_FILE)
if NUMBER == 1:
    figure = plot_final_pof(data)
elif NUMBER == 2:
    figure = plot_classification(data)
elif NUMBER == 3:
    figure = plot_learning(data, "COSSIN1")
elif NUMBER == 4:
    figure = plot_learning(data, "COSSIN2")
elif NUMBER == 5:
    figure = plot_acquisition(data)
elif NUMBER == 6:
    figure = plot_wb_front(data)
elif NUMBER == 7:
    figure = plot_hv_histories(data)
elif NUMBER == 8:
    figure = plot_solver_fronts(data)
elif NUMBER in (9, 10, 11, 12):
    figure = plot_conditional(data)
elif NUMBER == 13:
    figure = plot_pairwise(data)
else:
    raise RuntimeError(f"Unsupported Chapter 3 figure number: {NUMBER}")

OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
figure.savefig(OUTPUT_FILE, dpi=180, bbox_inches="tight")
plt.close(figure)
print(OUTPUT_FILE)
