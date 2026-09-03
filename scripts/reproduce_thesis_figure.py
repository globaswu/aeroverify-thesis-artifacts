#!/usr/bin/env python3
"""Reproduce thesis figures from the public CSV files only.

Examples
--------
    python scripts/reproduce_thesis_figure.py 5.9
    python scripts/reproduce_thesis_figure.py 3.1 3.2 6.4 --format pdf
    python scripts/reproduce_thesis_figure.py --all --output-dir reproduced

The script intentionally does not read MAT files, Nastran files, nTop projects,
logs, network locations, or machine-specific paths. Each plotted value comes
from a CSV tracked in this repository. Figure 5.7 is reconstructed as a portable
four-view deformed-node cloud because the proprietary nTop surface-rendering
pipeline is not required to inspect the published mode-shape coordinates.
"""

from __future__ import annotations

import argparse
import csv
import math
import sys
from collections import Counter
from pathlib import Path
from typing import Callable, Iterable

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import BoundaryNorm, ListedColormap
from matplotlib.lines import Line2D
import numpy as np


ROOT = Path(__file__).resolve().parents[1]
INK = "#202124"
BLUE = "#2f6690"
LIGHT_BLUE = "#7ea8be"
ORANGE = "#d97706"
RED = "#b91c1c"
PURPLE = "#7e3f98"
GREY = "#8b929a"
LIGHT_GREY = "#d9dde2"
GOLD = "#b58900"


def _apply_style() -> None:
    plt.rcParams.update(
        {
            "font.family": "DejaVu Sans",
            "font.size": 8.5,
            "axes.titlesize": 9.5,
            "axes.labelsize": 8.5,
            "legend.fontsize": 7.5,
            "xtick.labelsize": 7.5,
            "ytick.labelsize": 7.5,
            "axes.edgecolor": INK,
            "axes.linewidth": 0.8,
            "axes.grid": True,
            "grid.color": "#e5e7eb",
            "grid.linewidth": 0.55,
            "grid.alpha": 0.85,
            "savefig.bbox": "tight",
            "savefig.facecolor": "white",
        }
    )


def read_csv(relative: str, columns: Iterable[str] | None = None) -> dict[str, np.ndarray]:
    path = ROOT / relative
    if not path.is_file():
        raise FileNotFoundError(f"Required public CSV is missing: {path}")
    with path.open("r", encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        if reader.fieldnames is None:
            raise ValueError(f"CSV has no header: {path}")
        names = list(columns) if columns is not None else list(reader.fieldnames)
        missing = [name for name in names if name not in reader.fieldnames]
        if missing:
            raise KeyError(f"{path.name} lacks columns: {', '.join(missing)}")
        values = {name: [] for name in names}
        for row in reader:
            for name in names:
                values[name].append(row[name])
    return {name: np.asarray(items, dtype=str) for name, items in values.items()}


def read_csv_parts(pattern: str, columns: Iterable[str]) -> dict[str, np.ndarray]:
    paths = sorted(ROOT.glob(pattern))
    if not paths:
        raise FileNotFoundError(f"No public CSV shards match: {pattern}")
    parts = [read_csv(path.relative_to(ROOT).as_posix(), columns) for path in paths]
    return {name: np.concatenate([part[name] for part in parts]) for name in columns}


def num(data: dict[str, np.ndarray], name: str) -> np.ndarray:
    raw = data[name]
    out = np.full(raw.shape, np.nan, dtype=float)
    for i, item in enumerate(raw):
        text = str(item).strip()
        if text and text.lower() not in {"nan", "na", "none"}:
            out[i] = float(text)
    return out


def text(data: dict[str, np.ndarray], name: str) -> np.ndarray:
    return np.char.strip(data[name].astype(str))


def flag(data: dict[str, np.ndarray], name: str) -> np.ndarray:
    return np.isin(np.char.lower(text(data, name)), ["1", "true", "yes", "y", "pass"])


def subset(data: dict[str, np.ndarray], mask: np.ndarray) -> dict[str, np.ndarray]:
    return {key: values[mask] for key, values in data.items()}


def gridify(x: np.ndarray, y: np.ndarray, z: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    valid = np.isfinite(x) & np.isfinite(y) & np.isfinite(z)
    x, y, z = x[valid], y[valid], z[valid]
    xs = np.unique(x)
    ys = np.unique(y)
    image = np.full((len(ys), len(xs)), np.nan)
    xi = np.searchsorted(xs, x)
    yi = np.searchsorted(ys, y)
    image[yi, xi] = z
    return xs, ys, image


def heatmap(ax: plt.Axes, x: np.ndarray, y: np.ndarray, z: np.ndarray, *,
            cmap: str = "viridis", label: str = "", vmin: float | None = None,
            vmax: float | None = None) -> None:
    xs, ys, image = gridify(x, y, z)
    mesh = ax.pcolormesh(xs, ys, image, shading="auto", cmap=cmap, vmin=vmin, vmax=vmax)
    cb = ax.figure.colorbar(mesh, ax=ax, pad=0.02, shrink=0.88)
    if label:
        cb.set_label(label)


def observations(ax: plt.Axes, x: np.ndarray, y: np.ndarray, feasible: np.ndarray,
                 *, size: float = 22.0) -> None:
    ax.scatter(x[~feasible], y[~feasible], marker="x", s=size, c=RED, linewidths=0.9, zorder=5)
    ax.scatter(x[feasible], y[feasible], marker="o", s=size, facecolors="white",
               edgecolors=INK, linewidths=0.75, zorder=5)


def pareto_scatter(ax: plt.Axes, x: np.ndarray, y: np.ndarray, feasible: np.ndarray,
                   pareto: np.ndarray, cases: np.ndarray | None = None,
                   annotate: bool = True) -> None:
    ax.scatter(x[~feasible], y[~feasible], marker="x", c=GREY, s=24, linewidths=0.9,
               label="Infeasible")
    dom = feasible & ~pareto
    ax.scatter(x[dom], y[dom], marker="o", facecolors="white", edgecolors=BLUE,
               s=28, linewidths=0.9, label="Feasible dominated")
    pf = feasible & pareto
    order = np.argsort(x[pf])
    ax.plot(x[pf][order], y[pf][order], color=INK, lw=0.9, zorder=2)
    ax.scatter(x[pf], y[pf], marker="o", c=INK, s=28, label="Observed Pareto", zorder=4)
    if annotate and cases is not None:
        for xx, yy, cc in zip(x[pf], y[pf], cases[pf]):
            ax.annotate(str(int(cc)), (xx, yy), xytext=(3, 3), textcoords="offset points", fontsize=6.5)


def square(ax: plt.Axes) -> None:
    ax.set_box_aspect(1)


def save(fig: plt.Figure, output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output, dpi=220)
    plt.close(fig)


def fig_2_7(output: Path) -> None:
    d = read_csv("data/figures/chapter02/figure_2_7_mesh_convergence.csv")
    x = num(d, "mesh_edge_length_mm")
    tol = num(d, "geometry_tolerance_mm")
    panels = [
        ("two_wing_compliance_Nm", "Two-wing compliance (N m)"),
        ("maximum_vertical_deflection_m", "Maximum vertical deflection (m)"),
        ("stress", "99.75th-percentile stress (MPa)"),
        ("first_modal_frequency_Hz", "First modal frequency (Hz)"),
    ]
    fig, axes = plt.subplots(2, 2, figsize=(8.8, 6.4), constrained_layout=True)
    for ax, (column, ylabel) in zip(axes.flat, panels):
        for value in np.unique(tol):
            m = tol == value
            order = np.argsort(x[m])
            if column == "stress":
                ax.plot(x[m][order], num(d, "skin_vm_p9975_MPa")[m][order], marker="o", ms=3.2,
                        label=f"Skin, tolerance {value:g} mm")
                ax.plot(x[m][order], num(d, "cbeam_normal_stress_p9975_MPa")[m][order], marker="s",
                        ms=3.0, ls="--", label=f"CBEAM, tolerance {value:g} mm")
            else:
                ax.plot(x[m][order], num(d, column)[m][order], marker="o", ms=3.5,
                        label=f"tolerance {value:g} mm")
        ax.set_xlabel("Mesh edge length (mm)")
        ax.set_ylabel(ylabel)
    axes.flat[0].legend(frameon=False)
    axes.flat[2].legend(frameon=False, fontsize=6.5, ncol=2)
    fig.suptitle("Figure 2.7: structural-mesh convergence")
    save(fig, output)


def fig_2_8(output: Path) -> None:
    d = read_csv("data/figures/chapter02/figure_2_8_case64_vg.csv")
    cfg = text(d, "configuration")
    root = num(d, "root").astype(int)
    velocity = num(d, "velocity_mps")
    damping = num(d, "damping_g")
    configs = list(dict.fromkeys(cfg.tolist()))
    colors = plt.cm.tab10(np.linspace(0, 1, max(len(configs), 2)))
    fig, axes = plt.subplots(1, 2, figsize=(10.2, 4.1), constrained_layout=True)
    for color, name in zip(colors, configs):
        m_cfg = cfg == name
        for rr in np.unique(root[m_cfg]):
            m = m_cfg & (root == rr)
            order = np.argsort(velocity[m])
            axes[0].plot(velocity[m][order], damping[m][order], color=color, lw=0.65, alpha=0.55)
        m = m_cfg & (root == 19)
        order = np.argsort(velocity[m])
        axes[1].plot(velocity[m][order], damping[m][order], color=color, lw=1.25,
                     marker="o", ms=2.2, label=name)
    for ax in axes:
        ax.axhline(0, color=INK, lw=0.8, ls=":")
        ax.set_xlabel("Velocity (m/s)")
        ax.set_ylabel("Damping, g")
    axes[0].set_title("All retained roots")
    axes[1].set_title("Magnified root 19")
    axes[1].legend(frameon=False)
    fig.suptitle("Figure 2.8: case-64 V-g diagnostic")
    save(fig, output)


def _feasibility_panels(relative: str, output: Path, *, mode: str,
                        milestones: bool = False) -> None:
    columns = ["problem_id", "total_evaluations", "record_type", "normalized_x1",
               "normalized_x2", "pof_score", "exact_feasible", "error_class",
               "observed_feasible"]
    d = read_csv(relative, columns)
    problems = list(dict.fromkeys(text(d, "problem_id").tolist()))
    totals = np.unique(num(d, "total_evaluations")).astype(int)
    groups = [(problems[0], n) for n in totals] if milestones else [(p, None) for p in problems]
    n = len(groups)
    rows, cols = (2, 2) if n <= 4 else (math.ceil(n / 3), 3)
    fig, axes = plt.subplots(rows, cols, figsize=(3.7 * cols, 3.5 * rows), constrained_layout=True)
    axes = np.atleast_1d(axes).ravel()
    for ax, (problem, total) in zip(axes, groups):
        m = text(d, "problem_id") == problem
        if total is not None:
            m &= num(d, "total_evaluations") == total
        grid = m & (text(d, "record_type") == "grid")
        obs = m & (text(d, "record_type") == "observation")
        x, y = num(d, "normalized_x1"), num(d, "normalized_x2")
        if mode == "score":
            heatmap(ax, x[grid], y[grid], num(d, "pof_score")[grid], cmap="viridis",
                    label="Feasibility score", vmin=0, vmax=1)
            xs, ys, image = gridify(x[grid], y[grid], num(d, "pof_score")[grid])
            if np.nanmin(image) <= 0.5 <= np.nanmax(image):
                ax.contour(xs, ys, image, levels=[0.5], colors="white", linewidths=1.0)
            exact = num(d, "exact_feasible")[grid]
            xe, ye, exact_img = gridify(x[grid], y[grid], exact)
            if np.nanmin(exact_img) < 0.5 < np.nanmax(exact_img):
                ax.contour(xe, ye, exact_img, levels=[0.5], colors=INK,
                           linestyles="--", linewidths=0.9)
        else:
            classes = num(d, "error_class")[grid]
            xs, ys, image = gridify(x[grid], y[grid], classes)
            cmap = ListedColormap(["#d9dde2", "#f4a582", "#92c5de", "#2166ac"])
            norm = BoundaryNorm([-0.5, 0.5, 1.5, 2.5, 3.5], cmap.N)
            ax.pcolormesh(xs, ys, image, shading="auto", cmap=cmap, norm=norm)
        if np.any(obs):
            observations(ax, x[obs], y[obs], flag(d, "observed_feasible")[obs], size=18)
        title = problem if total is None else f"{problem}, N={total}"
        ax.set_title(title)
        ax.set_xlabel("Normalized input 1")
        ax.set_ylabel("Normalized input 2")
        ax.set_xlim(0, 1)
        ax.set_ylim(0, 1)
        square(ax)
    for ax in axes[n:]:
        ax.axis("off")
    save(fig, output)


def fig_3_1(output: Path) -> None:
    _feasibility_panels("data/figures/chapter03/fig03_01_02_final_feasibility_fields.csv", output, mode="score")


def fig_3_2(output: Path) -> None:
    _feasibility_panels("data/figures/chapter03/fig03_01_02_final_feasibility_fields.csv", output, mode="class")


def fig_3_3(output: Path) -> None:
    _feasibility_panels("data/figures/chapter03/fig03_03_cossin1_learning.csv", output,
                        mode="score", milestones=True)


def fig_3_4(output: Path) -> None:
    _feasibility_panels("data/figures/chapter03/fig03_04_cossin2_learning.csv", output,
                        mode="score", milestones=True)


def fig_3_5(output: Path) -> None:
    d = read_csv("data/figures/chapter03/fig03_05_cossin2_iteration20_acquisition.csv")
    record = text(d, "record_type")
    grid = record == "grid"
    obs = record == "observation"
    selected = record == "selected_point"
    x, y = num(d, "normalized_x1"), num(d, "normalized_x2")
    panels = [
        ("pof_score", "Feasibility score"),
        ("sampled_hvi", "Sampled HVI"),
        ("pof_times_sampled_hvi", "Score x sampled HVI"),
        ("final_acquisition", "Final acquisition"),
    ]
    fig, axes = plt.subplots(2, 2, figsize=(8.2, 7.3), constrained_layout=True)
    for ax, (column, title_) in zip(axes.flat, panels):
        heatmap(ax, x[grid], y[grid], num(d, column)[grid], label=title_)
        if np.any(obs):
            observations(ax, x[obs], y[obs], flag(d, "observed_feasible")[obs], size=15)
        if np.any(selected):
            ax.scatter(x[selected], y[selected], marker="*", s=95, c=ORANGE,
                       edgecolors=INK, linewidths=0.6, zorder=8)
        ax.set_title(title_)
        ax.set_xlabel("Normalized input 1")
        ax.set_ylabel("Normalized input 2")
        ax.set_xlim(0, 1)
        ax.set_ylim(0, 1)
        square(ax)
    fig.suptitle("Figure 3.5: COSSIN2 iteration-20 acquisition decomposition")
    save(fig, output)


def fig_3_6(output: Path) -> None:
    d = read_csv("data/figures/chapter03/fig03_06_wb150_rep02_evaluations.csv")
    x = num(d, "objective_f1_fabrication_cost")
    y = num(d, "objective_f2_end_deflection")
    feas = flag(d, "feasible")
    pf = flag(d, "final_pareto")
    fig, axes = plt.subplots(2, 1, figsize=(6.8, 7.4), constrained_layout=True)
    for ax in axes:
        pareto_scatter(ax, x, y, feas, pf, num(d, "evaluation_index"), annotate=False)
    axes[0].set_yscale("log")
    axes[0].set_title("Complete objective range")
    axes[1].set_xlim(*np.nanpercentile(x[feas], [1, 99]))
    axes[1].set_ylim(*np.nanpercentile(y[feas], [1, 99]))
    axes[1].set_title("Established trade-off region")
    final = flag(d, "is_evaluation_150")
    for ax in axes:
        ax.scatter(x[final], y[final], marker="D", s=55, c=ORANGE, edgecolors=INK,
                   linewidths=0.7, label="Evaluation 150", zorder=7)
        ax.set_xlabel("Fabrication-cost objective")
        ax.set_ylabel("End-deflection objective")
    axes[0].legend(frameon=False)
    fig.suptitle("Figure 3.6: WB150 replicate-2 final Pareto frame")
    save(fig, output)


def fig_3_7(output: Path) -> None:
    d = read_csv("data/figures/chapter03/fig03_07_highdim_hv_histories.csv")
    ids = list(dict.fromkeys(text(d, "problem_id").tolist()))
    fig, axes = plt.subplots(2, 4, figsize=(12.0, 6.2), constrained_layout=True, sharex=True)
    axes = axes.ravel()
    x_all = num(d, "sequential_evaluations")
    for ax, pid in zip(axes, ids):
        m = text(d, "problem_id") == pid
        order = np.argsort(x_all[m])
        x = x_all[m][order]
        for seed in range(1, 6):
            ax.plot(x, num(d, f"seed_{seed}_normalized_hv")[m][order], lw=0.8,
                    alpha=0.75)
        ax.plot(x, num(d, "median_normalized_hv")[m][order], color=INK, lw=1.8,
                label="Median")
        display = text(d, "display_name")[m][0]
        ax.set_title(display)
        ax.set_xlabel("Sequential evaluations")
        ax.set_ylabel("Normalized hypervolume")
    for ax in axes[len(ids):]:
        ax.axis("off")
    axes[0].legend(frameon=False)
    fig.suptitle("Figure 3.7: higher-dimensional hypervolume histories")
    save(fig, output)


def fig_3_8(output: Path) -> None:
    d = read_csv("data/figures/chapter03/fig03_08_wb150_solver_fronts.csv")
    x = num(d, "objective_f1_fabrication_cost")
    y = num(d, "objective_f2_end_deflection")
    solver = text(d, "solver_label")
    solvers = list(dict.fromkeys(solver.tolist()))
    colors = plt.cm.tab10(np.linspace(0, 1, len(solvers)))
    fig, axes = plt.subplots(1, 2, figsize=(10.4, 4.3), constrained_layout=True)
    for color, name in zip(colors, solvers):
        m = solver == name
        order = np.argsort(x[m])
        for ax in axes:
            ax.plot(x[m][order], y[m][order], marker="o", ms=2.8, lw=1.0,
                    color=color, label=name)
    axes[0].set_title("Complete objective range")
    axes[0].set_yscale("log")
    axes[1].set_title("Established trade-off region")
    axes[1].set_xlim(*np.nanpercentile(x, [5, 95]))
    axes[1].set_ylim(*np.nanpercentile(y, [5, 95]))
    for ax in axes:
        ax.set_xlabel("Fabrication-cost objective")
        ax.set_ylabel("End-deflection objective")
    axes[0].legend(frameon=False, ncol=2)
    fig.suptitle("Figure 3.8: historical WB150 solver-owned fronts")
    save(fig, output)


def _conditional_hvi(relative: str, output: Path, *, input_index: int | None = None,
                     title_: str = "") -> None:
    d = read_csv(relative)
    if input_index is not None:
        d = subset(d, num(d, "input_index") == input_index)
        field_x = "input_physical"
        threshold = "threshold_normalized"
        prob = "log10_conditional_exceedance_probability"
        frac = "positive_hvi_fraction"
        mean = "mean_normalized_hvi"
        median = "median_normalized_hvi"
        p90 = "p90_normalized_hvi"
        p99 = "p99_normalized_hvi"
        maximum = "sampled_profile_maximum_normalized_hvi"
    else:
        field_x = "input_physical"
        threshold = "normalized_hvi_threshold"
        prob = "display_log10_exceedance_probability"
        frac = "positive_hvi_fraction"
        mean = "mean_normalized_hvi"
        median = "median_normalized_hvi"
        p90 = "p90_normalized_hvi"
        p99 = "p99_normalized_hvi"
        maximum = "sampled_profile_maximum_normalized_hvi"
    record = text(d, "record_type") if "record_type" in d else None
    survival = record == "survival_grid" if record is not None else np.isfinite(num(d, threshold))
    profile = record == "profile_station" if record is not None else np.isfinite(num(d, frac))
    x = num(d, field_x)
    fig, axes = plt.subplots(3, 1, figsize=(6.8, 9.6), constrained_layout=True)
    heatmap(axes[0], x[survival], num(d, threshold)[survival], num(d, prob)[survival],
            cmap="magma", label="log10 conditional exceedance probability")
    axes[0].set_xlabel("Input value")
    axes[0].set_ylabel("Normalized HVI threshold")
    axes[0].set_title("Conditional survival field")
    order = np.argsort(x[profile])
    xp = x[profile][order]
    for column, label_, ls in [(mean, "Mean", "-"), (median, "Median", "--"),
                               (p90, "90th percentile", "-"), (p99, "99th percentile", ":"),
                               (maximum, "Sample maximum", "-.")]:
        axes[1].plot(xp, num(d, column)[profile][order], lw=1.1, ls=ls, label=label_)
    axes[1].set_xlabel("Input value")
    axes[1].set_ylabel("Normalized sampled HVI")
    axes[1].set_title("Conditional magnitude")
    axes[1].legend(frameon=False)
    axes[2].plot(xp, num(d, frac)[profile][order], color=BLUE, lw=1.4)
    axes[2].set_xlabel("Input value")
    axes[2].set_ylabel("Positive-HVI fraction")
    axes[2].set_ylim(-0.02, 1.02)
    axes[2].set_title("Positive support")
    fig.suptitle(title_)
    save(fig, output)


def fig_3_9(output: Path) -> None:
    _conditional_hvi("data/figures/chapter03/fig03_09_12_wb150_conditional_hvi.csv", output,
                     input_index=1, title_="Figure 3.9: conditional HVI versus weld thickness")


def fig_3_10(output: Path) -> None:
    _conditional_hvi("data/figures/chapter03/fig03_09_12_wb150_conditional_hvi.csv", output,
                     input_index=2, title_="Figure 3.10: conditional HVI versus weld length")


def fig_3_11(output: Path) -> None:
    _conditional_hvi("data/figures/chapter03/fig03_09_12_wb150_conditional_hvi.csv", output,
                     input_index=3, title_="Figure 3.11: conditional HVI versus beam depth")


def fig_3_12(output: Path) -> None:
    _conditional_hvi("data/figures/chapter03/fig03_09_12_wb150_conditional_hvi.csv", output,
                     input_index=4, title_="Figure 3.12: conditional HVI versus beam thickness")


def fig_3_13(output: Path) -> None:
    d = read_csv("data/figures/chapter03/fig03_13_wb150_hvi_pairwise.csv")
    pair = num(d, "PairId").astype(int)
    a = num(d, "GridA")
    b = num(d, "GridB")
    hvi = num(d, "HVI_draw")
    positive = hvi[hvi > 0]
    floor = max(np.nanmin(positive) if positive.size else 1e-16, 1e-16)
    log_hvi = np.log10(np.maximum(hvi, floor))
    fig, axes = plt.subplots(2, 3, figsize=(10.5, 6.8), constrained_layout=True)
    for ax, pid in zip(axes.flat, np.unique(pair)):
        m = pair == pid
        heatmap(ax, a[m], b[m], log_hvi[m], cmap="magma", label="log10 sampled HVI")
        ia = int(num(d, "InputA")[m][0])
        ib = int(num(d, "InputB")[m][0])
        ax.set_xlabel(f"Normalized input {ia}")
        ax.set_ylabel(f"Normalized input {ib}")
        ax.set_xlim(0, 1)
        ax.set_ylim(0, 1)
        square(ax)
    fig.suptitle("Figure 3.13: WB150 pairwise sampled-HVI slices")
    save(fig, output)


def fig_4_1(output: Path) -> None:
    d = read_csv("data/figures/chapter04/figure_4_1_representative_fixed_area_planforms.csv")
    cases = np.unique(num(d, "case_id").astype(int))
    fig, ax = plt.subplots(figsize=(8.0, 4.8), constrained_layout=True)
    for case in cases:
        m = num(d, "case_id").astype(int) == case
        order = np.argsort(num(d, "point_order")[m])
        x = num(d, "chordwise_m")[m][order]
        y = num(d, "spanwise_m")[m][order]
        role = text(d, "role")[m][0]
        ax.plot(x, y, marker="o", ms=3, lw=1.4, label=f"Case {case}: {role}")
    ax.set_xlabel("Chordwise coordinate (m)")
    ax.set_ylabel("Spanwise coordinate (m)")
    ax.set_aspect("equal", adjustable="datalim")
    ax.set_title("Figure 4.1: representative fixed-area planforms")
    ax.legend(frameon=False)
    save(fig, output)


def fig_4_2(output: Path) -> None:
    d = read_csv("data/figures/chapter04/figure_4_2_topology_selection.csv")
    names = text(d, "topology")
    x = np.arange(len(names))
    fig, axes = plt.subplots(1, 2, figsize=(9.0, 3.9), constrained_layout=True)
    axes[0].scatter(num(d, "two_wing_mass_kg"), num(d, "trim_compliance_Nm"),
                    c=[BLUE, ORANGE, PURPLE], s=55)
    for xx, yy, name in zip(num(d, "two_wing_mass_kg"), num(d, "trim_compliance_Nm"), names):
        axes[0].annotate(name, (xx, yy), xytext=(4, 3), textcoords="offset points")
    axes[0].set_xlabel("Two-wing mass (kg)")
    axes[0].set_ylabel("Trim compliance (N m)")
    width = 0.36
    axes[1].bar(x - width / 2, num(d, "skin_stress_utilization"), width,
                color=LIGHT_BLUE, label="Skin")
    axes[1].bar(x + width / 2, num(d, "beam_stress_utilization"), width,
                color=ORANGE, label="Beam")
    axes[1].axhline(1, color=INK, ls="--", lw=0.9)
    axes[1].set_ylabel("Stress utilization")
    axes[1].set_xticks(x, names)
    axes[1].legend(frameon=False)
    fig.suptitle("Figure 4.2: frozen topology selection")
    save(fig, output)


def fig_5_1(output: Path) -> None:
    d = read_csv("data/figures/chapter05/figure_5_1_pareto_membership.csv")
    topo = text(d, "topology")
    topologies = list(dict.fromkeys(topo.tolist()))
    fig, axes = plt.subplots(2, 2, figsize=(9.2, 7.5), constrained_layout=True)
    for ax, name in zip(axes.flat[:3], topologies):
        m = topo == name
        pareto_scatter(ax, num(d, "mass_kg")[m], num(d, "compliance_Nm")[m],
                       flag(d, "feasible")[m], flag(d, "topology_pareto_case051")[m],
                       num(d, "case_id")[m])
        ax.set_title(name)
    ax = axes.flat[3]
    pareto_scatter(ax, num(d, "mass_kg"), num(d, "compliance_Nm"), flag(d, "feasible"),
                   flag(d, "pooled_pareto_case051"), num(d, "case_id"), annotate=False)
    for name, marker in zip(topologies, ["o", "s", "^"]):
        m = (topo == name) & flag(d, "pooled_pareto_case051")
        ax.scatter(num(d, "mass_kg")[m], num(d, "compliance_Nm")[m], marker=marker,
                   s=45, label=name)
    ax.set_title("Pooled")
    for ax in axes.flat:
        ax.set_xlabel("Lattice-wing mass (kg)")
        ax.set_ylabel("Trim compliance (N m)")
    axes.flat[0].legend(frameon=False)
    axes.flat[3].legend(frameon=False)
    fig.suptitle("Figure 5.1: observed lattice mass-compliance trade-offs")
    save(fig, output)


def _lattice_front(relative: str, output: Path, title_: str) -> None:
    d = read_csv(relative)
    fig, ax = plt.subplots(figsize=(6.5, 4.8), constrained_layout=True)
    pareto_scatter(ax, num(d, "mass_kg"), num(d, "compliance_Nm"), flag(d, "feasible"),
                   flag(d, "pareto_case071"), num(d, "case_id"))
    ax.set_xlabel("Lattice-wing mass (kg)")
    ax.set_ylabel("Trim compliance (N m)")
    ax.set_title(title_)
    ax.legend(frameon=False)
    save(fig, output)


def fig_5_2(output: Path) -> None:
    _lattice_front("data/fcc/evaluations_cases001_071.csv", output,
                   "Figure 5.2: completed FCC continuation Pareto record")


def _score_map(field_file: str, points_file: str, output: Path, *, x_field: str,
               y_field: str, score_field: str, point_x: str, point_y: str,
               point_feasible: str, point_pareto: str, title_: str) -> None:
    grid = read_csv(field_file)
    pts = read_csv(points_file)
    fig, ax = plt.subplots(figsize=(6.2, 5.2), constrained_layout=True)
    x, y, z = num(grid, x_field), num(grid, y_field), num(grid, score_field)
    heatmap(ax, x, y, z, label="Binary feasibility score", vmin=0, vmax=1)
    xs, ys, image = gridify(x, y, z)
    if np.nanmin(image) <= 0.5 <= np.nanmax(image):
        ax.contour(xs, ys, image, levels=[0.5], colors="white", linewidths=1.1)
    xp, yp = num(pts, point_x), num(pts, point_y)
    feas, pf = flag(pts, point_feasible), flag(pts, point_pareto)
    observations(ax, xp, yp, feas)
    ax.scatter(xp[pf], yp[pf], s=45, facecolors="none", edgecolors=INK, linewidths=1.1)
    ax.set_xlabel("Cell size, a (m)" if "a_m" in x_field else "Aspect ratio")
    ax.set_ylabel("Primary-member ratio, t1/a" if "t1" in y_field else "Taper ratio")
    square(ax)
    ax.set_title(title_)
    save(fig, output)


def fig_5_3(output: Path) -> None:
    _score_map("data/figures/chapter05/figures_5_3_and_5_5_fcc_feasibility_score_grids.csv",
               "data/figures/chapter05/figures_5_3_and_5_5_fcc_points.csv", output,
               x_field="a_m", y_field="t1_over_a", score_field="score_after_observed",
               point_x="a_m", point_y="t1_over_a", point_feasible="feasible_observed",
               point_pareto="pareto_case071",
               title_="Figure 5.3: completed FCC feasibility-score map")


def _failure_map(relative: str, output: Path, title_: str, *, case_field: str,
                 pareto_field: str) -> None:
    d = read_csv(relative)
    category = text(d, "plot_category")
    styles = {
        "feasible": ("o", BLUE, "Feasible"),
        "skin_stress_only": ("x", ORANGE, "Skin only"),
        "lattice_stress_only": ("+", PURPLE, "Lattice only"),
        "skin_and_lattice_stress": ("s", RED, "Skin and lattice"),
        "unresolved_infeasible": ("^", GREY, "Unresolved"),
    }
    fig, ax = plt.subplots(figsize=(6.2, 5.2), constrained_layout=True)
    for key, (marker, color, label_) in styles.items():
        m = np.char.lower(category) == key
        if not np.any(m):
            continue
        if marker in {"o"}:
            ax.scatter(num(d, "a_m")[m], num(d, "t1_over_a")[m], marker=marker,
                       facecolors="white", edgecolors=color, s=32, label=label_)
        else:
            ax.scatter(num(d, "a_m")[m], num(d, "t1_over_a")[m], marker=marker,
                       c=color, s=35, label=label_)
    pf = flag(d, pareto_field)
    ax.scatter(num(d, "a_m")[pf], num(d, "t1_over_a")[pf], s=55, facecolors="none",
               edgecolors=INK, linewidths=1.1, label="Observed Pareto")
    ax.set_xlabel("Cell size, a (m)")
    ax.set_ylabel("Primary-member ratio, t1/a")
    square(ax)
    ax.legend(frameon=False, ncol=2)
    ax.set_title(title_)
    save(fig, output)


def fig_5_4(output: Path) -> None:
    _failure_map("data/figures/chapter05/figure_5_4_fcc_failure_mechanisms.csv", output,
                 "Figure 5.4: FCC observed stress-failure mechanisms",
                 case_field="case_id", pareto_field="pareto_case071")


def fig_5_5(output: Path) -> None:
    grid = read_csv("data/figures/chapter05/figures_5_3_and_5_5_fcc_feasibility_score_grids.csv")
    pts = read_csv("data/figures/chapter05/figures_5_3_and_5_5_fcc_points.csv")
    x, y = num(grid, "a_m"), num(grid, "t1_over_a")
    panels = [
        ("score_before_cases_8_29_feasible", "score_before_observed", 51,
         "Before continuation (cases 1-51)"),
        ("score_after_cases_8_29_feasible", "score_after_observed", 71,
         "Through case 71"),
    ]
    fig, axes = plt.subplots(2, 1, figsize=(6.5, 10.2), constrained_layout=True)
    for ax, (column, baseline_column, last_case, title_) in zip(axes, panels):
        heatmap(ax, x, y, num(grid, column), label="Binary feasibility score", vmin=0, vmax=1)
        xs, ys, hypothetical_image = gridify(x, y, num(grid, column))
        _, _, baseline_image = gridify(x, y, num(grid, baseline_column))
        ax.contour(xs, ys, hypothetical_image, levels=[0.5], colors="white", linewidths=1.1)
        ax.contour(xs, ys, baseline_image, levels=[0.5], colors=INK, linestyles="--", linewidths=1.0)
        m = num(pts, "case_id") <= last_case
        feasible = num(pts, "constraint_hypothetical") <= 0
        observations(ax, num(pts, "a_m")[m], num(pts, "t1_over_a")[m], feasible[m], size=18)
        flipped = flag(pts, "hypothetically_flipped") & m
        ax.scatter(num(pts, "a_m")[flipped], num(pts, "t1_over_a")[flipped], marker="D",
                   s=48, facecolors="none", edgecolors=ORANGE, linewidths=1.1)
        ax.set_xlabel("Cell size, a (m)")
        ax.set_ylabel("Primary-member ratio, t1/a")
        ax.set_title(title_ + ": hypothetical labels")
        square(ax)
    fig.suptitle("Figure 5.5: hypothetical FCC feasibility-label sensitivity")
    save(fig, output)


def fig_5_6(output: Path) -> None:
    d = read_csv("data/figures/chapter05/figure_5_6_5_8_case067_flutter_histories.csv")
    m = num(d, "point") == 3
    order = np.argsort(num(d, "velocity_mps")[m])
    x = num(d, "velocity_mps")[m][order]
    fig, ax = plt.subplots(figsize=(6.7, 4.4), constrained_layout=True)
    ax.plot(x, num(d, "four_point_damping_g")[m][order], color=GREY, ls="--", lw=1.4,
            label="Four-point MKAERO1")
    ax.plot(x, num(d, "eighteen_point_damping_g")[m][order], color=RED, lw=1.5,
            label="Eighteen-point MKAERO1")
    ax.axhline(0, color=INK, ls=":", lw=0.8)
    ax.set_xlabel("Velocity (m/s)")
    ax.set_ylabel("Damping, g")
    ax.set_title("Figure 5.6: FCC case 67 point-3 MKAERO1 sensitivity")
    ax.legend(frameon=False)
    save(fig, output)


def fig_5_7(output: Path) -> None:
    columns = ["x_m", "y_m", "z_m", "ux_mode3", "uy_mode3", "uz_mode3",
               "displacement_magnitude", "frequency_hz"]
    d = read_csv_parts(
        "data/figures/chapter05/figure_5_7_case067_mode3_nodes_part*.csv", columns)
    xyz = np.column_stack([num(d, "x_m"), num(d, "y_m"), num(d, "z_m")])
    disp = np.column_stack([num(d, "ux_mode3"), num(d, "uy_mode3"), num(d, "uz_mode3")])
    mag = num(d, "displacement_magnitude")
    deformed = xyz + disp
    # The complete 531,682-node table remains public. A deterministic stride
    # caps rendered points for a practical vector/PDF size without changing the
    # data contract or the displayed modal geometry.
    stride = max(1, int(math.ceil(len(mag) / 160000)))
    take = np.arange(0, len(mag), stride)
    ref_take = take[::5]
    fig = plt.figure(figsize=(10.6, 7.8), constrained_layout=True)
    axes = [fig.add_subplot(2, 2, 1), fig.add_subplot(2, 2, 2, projection="3d"),
            fig.add_subplot(2, 2, 3), fig.add_subplot(2, 2, 4)]
    views = [(0, 1, "Top", "x (m)", "y (m)"),
             (0, 2, "Front", "x (m)", "z (m)"),
             (1, 2, "Right", "y (m)", "z (m)")]
    for ax, (i, j, name, xlabel, ylabel) in zip([axes[0], axes[2], axes[3]], views):
        ax.scatter(xyz[ref_take, i], xyz[ref_take, j], s=0.06, c=LIGHT_GREY,
                   linewidths=0, rasterized=True)
        sc = ax.scatter(deformed[take, i], deformed[take, j], s=0.10, c=mag[take],
                        cmap="turbo", linewidths=0, rasterized=True)
        ax.set_title(name)
        ax.set_xlabel(xlabel)
        ax.set_ylabel(ylabel)
        ax.set_aspect("equal", adjustable="datalim")
    ax3 = axes[1]
    ax3.scatter(xyz[ref_take, 0], xyz[ref_take, 1], xyz[ref_take, 2], s=0.03,
                c=LIGHT_GREY, linewidths=0, rasterized=True)
    ax3.scatter(deformed[take, 0], deformed[take, 1], deformed[take, 2], s=0.07,
                c=mag[take], cmap="turbo", linewidths=0, rasterized=True)
    ax3.view_init(elev=22, azim=-55)
    ax3.set_title("Oblique")
    ax3.set_xlabel("x (m)")
    ax3.set_ylabel("y (m)")
    ax3.set_zlabel("z (m)")
    cb = fig.colorbar(sc, ax=axes, pad=0.02, shrink=0.72)
    cb.set_label("Normalized mode-3 displacement magnitude")
    frequency = num(d, "frequency_hz")[0]
    fig.suptitle(f"Figure 5.7: FCC case 67 SOL 103 mode 3 ({frequency:.6f} Hz)")
    save(fig, output)


def fig_5_8(output: Path) -> None:
    d = read_csv("data/figures/chapter05/figure_5_6_5_8_case067_flutter_histories.csv")
    points = np.unique(num(d, "point").astype(int))
    fig, axes = plt.subplots(5, 4, figsize=(10.2, 10.2), constrained_layout=False, sharex=True)
    for ax, point in zip(axes.flat, points):
        m = num(d, "point").astype(int) == point
        order = np.argsort(num(d, "velocity_mps")[m])
        x = num(d, "velocity_mps")[m][order]
        ax.plot(x, num(d, "four_point_damping_g")[m][order], color=GREY, ls="--", lw=0.9)
        ax.plot(x, num(d, "eighteen_point_damping_g")[m][order], color=RED, lw=1.0)
        ax.axhline(0, color=INK, ls=":", lw=0.65)
        ax.set_title(f"Point {point}")
    for ax in axes[-1, :]:
        ax.set_xlabel("Velocity (m/s)")
    for ax in axes[:, 0]:
        ax.set_ylabel("Damping, g")
    handles = [Line2D([0], [0], color=GREY, ls="--", label="Four-point MKAERO1"),
               Line2D([0], [0], color=RED, label="Eighteen-point MKAERO1")]
    fig.suptitle("Figure 5.8: FCC case 67 all-point MKAERO1 sensitivity", y=0.992)
    fig.legend(handles=handles, loc="upper center", bbox_to_anchor=(0.5, 0.972),
               ncol=2, frameon=False)
    fig.subplots_adjust(left=0.07, right=0.99, bottom=0.06, top=0.91,
                        wspace=0.30, hspace=0.34)
    save(fig, output)


def fig_5_9(output: Path) -> None:
    _lattice_front("data/bcc/evaluations_cases001_071.csv", output,
                   "Figure 5.9: completed BCC continuation Pareto front")


def fig_5_10(output: Path) -> None:
    _score_map("data/figures/chapter05/figure_5_10_bcc_feasibility_score_grid.csv",
               "data/bcc/evaluations_cases001_071.csv", output,
               x_field="a_m", y_field="t1_over_a", score_field="feasibility_score",
               point_x="a_m", point_y="t1_over_a", point_feasible="feasible",
               point_pareto="pareto_case071",
               title_="Figure 5.10: completed BCC feasibility-score map")


def fig_5_11(output: Path) -> None:
    _failure_map("data/figures/chapter05/figure_5_11_bcc_failure_mechanisms.csv", output,
                 "Figure 5.11: BCC observed stress-failure mechanisms",
                 case_field="case", pareto_field="pareto_optimal")


def fig_5_12(output: Path) -> None:
    d = read_csv("data/figures/chapter05/figure_5_12_bcc_shell_stress_rank_tails.csv")
    cases = np.unique(num(d, "case").astype(int))
    fig, ax = plt.subplots(figsize=(7.0, 4.8), constrained_layout=True)
    for case in cases:
        m = num(d, "case").astype(int) == case
        order = np.argsort(num(d, "rank_descending")[m])
        ax.plot(num(d, "rank_descending")[m][order], num(d, "shell_von_mises_stress_mpa")[m][order],
                lw=1.0, label=f"Case {case}")
        first = m & (num(d, "rank_descending") == 1)
        ax.scatter(num(d, "rank_descending")[first], num(d, "shell_von_mises_stress_mpa")[first],
                   marker="*", s=48, edgecolors=INK, linewidths=0.45)
    ax.axhline(np.nanmedian(num(d, "stress_limit_mpa")), color=INK, ls="--", lw=0.9,
               label="220 MPa screen")
    ax.set_xlabel("Descending stress rank")
    ax.set_xscale("log")
    ax.set_ylabel("Shell von Mises stress (MPa)")
    ax.set_title("Figure 5.12: BCC upper shell-stress tails")
    ax.legend(frameon=False, ncol=2)
    save(fig, output)


def fig_5_13(output: Path) -> None:
    d = read_csv("data/figures/chapter05/figure_5_13_bcc_root_hotspots.csv")
    cases = np.unique(num(d, "case").astype(int))
    fig, axes = plt.subplots(2, 3, figsize=(10.5, 6.5), constrained_layout=True)
    for ax, case in zip(axes.flat, cases):
        m = num(d, "case").astype(int) == case
        sc = ax.scatter(num(d, "x_m")[m], num(d, "span_y_mm")[m],
                        c=num(d, "shell_von_mises_stress_mpa")[m], cmap="magma", s=24)
        critical = m & flag(d, "is_critical_element")
        ax.scatter(num(d, "x_m")[critical], num(d, "span_y_mm")[critical], marker="*",
                   s=80, c=RED, edgecolors=INK, linewidths=0.5)
        ax.axhline(0.4943, color=INK, ls="--", lw=0.7)
        ax.set_title(f"Case {case}")
        ax.set_xlabel("Chordwise x (m)")
        ax.set_ylabel("Spanwise y (mm)")
        fig.colorbar(sc, ax=ax, pad=0.02, label="Stress (MPa)")
    fig.suptitle("Figure 5.13: BCC localization of highest shell stresses")
    save(fig, output)


def fig_5_14(output: Path) -> None:
    _lattice_front("data/sc/evaluations_cases001_071.csv", output,
                   "Figure 5.14: completed SC continuation Pareto front")


def fig_5_15(output: Path) -> None:
    _score_map("data/figures/chapter05/figure_5_15_sc_feasibility_score_grid.csv",
               "data/sc/evaluations_cases001_071.csv", output,
               x_field="a_m", y_field="t1_over_a", score_field="binary_feasibility_score",
               point_x="a_m", point_y="t1_over_a", point_feasible="feasible",
               point_pareto="pareto_case071",
               title_="Figure 5.15: completed SC feasibility-score map")


def fig_5_16(output: Path) -> None:
    _failure_map("data/figures/chapter05/figure_5_16_sc_failure_mechanisms.csv", output,
                 "Figure 5.16: SC observed stress-failure mechanisms",
                 case_field="case", pareto_field="pareto_optimal")


def fig_5_17(output: Path) -> None:
    d = read_csv("data/figures/chapter05/figure_5_17_lattice_material_stress_representatives.csv")
    names = np.array([f"{g} case {int(c)}" for g, c in zip(text(d, "group"), num(d, "case"))])
    x = np.arange(len(names))
    skin = 2 * num(d, "skin_mass_single_kg")
    lattice = 2 * num(d, "lattice_mass_single_kg")
    fig, axes = plt.subplots(2, 1, figsize=(7.0, 6.0), constrained_layout=True)
    axes[0].bar(x, skin, color=LIGHT_BLUE, label="Skin")
    axes[0].bar(x, lattice, bottom=skin, color=ORANGE, label="Lattice")
    axes[0].set_ylabel("Two-wing mass (kg)")
    axes[0].legend(frameon=False)
    axes[1].bar(x, num(d, "max_vm_MPa"), color=[BLUE, ORANGE, PURPLE])
    axes[1].axhline(220, color=INK, ls="--", lw=0.9, label="220 MPa screen")
    axes[1].set_ylabel("Maximum screening stress (MPa)")
    axes[1].legend(frameon=False)
    for ax in axes:
        ax.set_xticks(x, names)
    fig.suptitle("Figure 5.17: material allocation and stress reserve")
    save(fig, output)


def fig_5_18(output: Path) -> None:
    _score_map("data/figures/chapter05/figure_5_18_planform_feasibility_score_grid.csv",
               "data/planform/evaluations_cases001_050.csv", output,
               x_field="aspect_ratio", y_field="taper_ratio", score_field="binary_feasibility_score",
               point_x="AR", point_y="taper_ratio", point_feasible="feasible",
               point_pareto="final_pareto",
               title_="Figure 5.18: final planform feasibility-score field")


def fig_5_19(output: Path) -> None:
    d = read_csv("data/planform/evaluations_cases001_050.csv")
    x, y = num(d, "CDitrim"), num(d, "Ctrim_Nm")
    fig, ax = plt.subplots(figsize=(6.5, 4.8), constrained_layout=True)
    pareto_scatter(ax, x, y, flag(d, "feasible"), flag(d, "final_pareto"), num(d, "case"))
    continuation = (num(d, "case") >= 41) & flag(d, "final_pareto")
    ax.scatter(x[continuation], y[continuation], s=55, facecolors="none", edgecolors=ORANGE,
               linewidths=1.2, label="Continuation Pareto")
    ax.set_ylim(top=min(125, ax.get_ylim()[1]))
    ax.set_xlabel("Trim induced-drag coefficient")
    ax.set_ylabel("Trim compliance (N m)")
    ax.set_title("Figure 5.19: observed planform objective trade-off")
    ax.legend(frameon=False)
    save(fig, output)


def fig_5_20(output: Path) -> None:
    d = read_csv("data/planform/evaluations_cases001_050.csv")
    panels = [
        ("AR", "CDitrim", "Aspect ratio", "Trim induced-drag coefficient"),
        ("AR", "Ctrim_Nm", "Aspect ratio", "Trim compliance (N m)"),
        ("AR", "max_screening_stress_mpa", "Aspect ratio", "Maximum screening stress (MPa)"),
        ("AR", "modeled_half_wing_mass_kg", "Aspect ratio", "Modelled half-wing mass (kg)"),
    ]
    feas, pf = flag(d, "feasible"), flag(d, "final_pareto")
    continuation = num(d, "case") >= 41
    fig, axes = plt.subplots(2, 2, figsize=(8.8, 7.0), constrained_layout=True)
    for ax, (xc, yc, xl, yl) in zip(axes.flat, panels):
        x, y = num(d, xc), num(d, yc)
        ax.scatter(x[~feas], y[~feas], marker="x", c=GREY, s=25)
        ax.scatter(x[feas & ~pf], y[feas & ~pf], facecolors="white", edgecolors=BLUE, s=27)
        ax.scatter(x[pf], y[pf], c=INK, s=27)
        ax.scatter(x[pf & continuation], y[pf & continuation], facecolors="none",
                   edgecolors=ORANGE, s=52, linewidths=1.1)
        ax.set_xlabel(xl)
        ax.set_ylabel(yl)
    fig.suptitle("Figure 5.20: observed structural and objective trends")
    save(fig, output)


def fig_5_21(output: Path) -> None:
    obs = read_csv("data/figures/chapter05/figure_5_21_planform_taper_observed_points.csv")
    ref = read_csv("data/figures/chapter05/figure_5_21_planform_taper_llt_reference_curves.csv")
    ars = np.unique(num(ref, "AR"))
    chosen = ars[np.linspace(0, len(ars) - 1, min(5, len(ars))).astype(int)]
    fig, axes = plt.subplots(2, 2, figsize=(9.0, 7.2), constrained_layout=True)
    for ar in chosen:
        m = np.isclose(num(ref, "AR"), ar)
        order = np.argsort(num(ref, "TaperRatio")[m])
        axes[0, 0].plot(num(ref, "TaperRatio")[m][order], num(ref, "RigidSpanEfficiency")[m][order],
                        lw=1.0, label=f"AR={ar:g}")
        axes[0, 1].plot(num(ref, "TaperRatio")[m][order], num(ref, "TaperOnlyCDiPenaltyPct")[m][order],
                        lw=1.0, label=f"AR={ar:g}")
    axes[0, 0].set_xlabel("Taper ratio")
    axes[0, 0].set_ylabel("Rigid span efficiency")
    axes[0, 0].legend(frameon=False, ncol=2)
    axes[0, 1].set_xlabel("Taper ratio")
    axes[0, 1].set_ylabel("Taper-only induced-drag penalty (%)")
    axes[1, 0].scatter(num(obs, "TaperRatio"), num(obs, "TorsionCorrectedE"),
                       c=np.where(flag(obs, "Feasible"), BLUE, GREY), s=28)
    axes[1, 0].set_xlabel("Taper ratio")
    axes[1, 0].set_ylabel("Torsion-corrected span efficiency")
    axes[1, 1].scatter(num(obs, "AbsoluteTaperDistance"), num(obs, "TaperOnlyCDiPenaltyPct"),
                       c=np.where(flag(obs, "Pareto"), ORANGE, BLUE), s=28)
    axes[1, 1].set_xlabel("Absolute distance from rigid optimum taper")
    axes[1, 1].set_ylabel("Taper-only induced-drag penalty (%)")
    fig.suptitle("Figure 5.21: taper-ratio theory and observed-result checks")
    save(fig, output)


def fig_6_1(output: Path) -> None:
    d = read_csv("data/figures/chapter06/figure_6_01_optimization_progress.csv")
    case = num(d, "case_id")
    order = np.argsort(case)
    phases = list(dict.fromkeys(text(d, "phase").tolist()))
    fig, axes = plt.subplots(1, 2, figsize=(9.2, 3.8), constrained_layout=True)
    axes[0].plot(case[order], num(d, "normalized_hypervolume")[order], color=BLUE, lw=1.5)
    axes[0].axvline(30.5, color=INK, ls="--", lw=0.8)
    axes[0].set_xlabel("Evaluation")
    axes[0].set_ylabel("Normalized box hypervolume")
    x = np.arange(len(phases))
    shares_f = []
    shares_p = []
    for phase in phases:
        m = text(d, "phase") == phase
        shares_f.append(num(d, "phase_feasible_share_percent")[m][0])
        shares_p.append(num(d, "phase_final_pareto_share_percent")[m][0])
    width = 0.36
    axes[1].bar(x - width / 2, shares_f, width, color=BLUE, label="Feasible")
    axes[1].bar(x + width / 2, shares_p, width, color=ORANGE, label="Final Pareto")
    axes[1].set_xticks(x, phases)
    axes[1].set_ylabel("Share of phase evaluations (%)")
    axes[1].legend(frameon=False)
    fig.suptitle("Figure 6.1: optimization progress and phase yield")
    save(fig, output)


def fig_6_2(output: Path) -> None:
    d = read_csv("data/multiinput/evaluations_cases001_100.csv")
    x, y = num(d, "CDitrim"), num(d, "Ctrim")
    feas, pf = flag(d, "Feasible"), flag(d, "Pareto")
    case = num(d, "Case")
    fig, ax = plt.subplots(figsize=(7.0, 5.0), constrained_layout=True)
    pareto_scatter(ax, x, y, feas, pf, case, annotate=False)
    refined = (case == 65) | (case >= 71)
    ax.scatter(x[refined], y[refined], s=45, facecolors="none", edgecolors=ORANGE,
               linewidths=1.0, label="Refined mesh")
    ax.set_xlabel("Trim induced-drag coefficient")
    ax.set_ylabel("Trim compliance")
    ax.set_title("Figure 6.2: finalized objective space")
    ax.legend(frameon=False)
    save(fig, output)


def fig_6_3(output: Path) -> None:
    d = read_csv("data/figures/chapter06/figure_6_03_feasibility_mechanisms.csv")
    shell = num(d, "shell_vm_utilization")
    beam = num(d, "cbeam_normal_utilization")
    mechanism = text(d, "failure_mechanism")
    categories = list(dict.fromkeys(mechanism.tolist()))
    palette = plt.cm.tab10(np.linspace(0, 1, max(len(categories), 2)))
    fig, axes = plt.subplots(1, 2, figsize=(9.4, 4.2), constrained_layout=True)
    for color, cat in zip(palette, categories):
        m = mechanism == cat
        axes[0].scatter(shell[m], beam[m], s=28, color=color, label=cat)
    pf = flag(d, "final_pareto")
    axes[0].scatter(shell[pf], beam[pf], s=48, facecolors="none", edgecolors=INK,
                    linewidths=1.0)
    axes[0].axvline(1, color=INK, ls="--", lw=0.8)
    axes[0].axhline(1, color=INK, ls="--", lw=0.8)
    axes[0].set_xlabel("Shell von Mises utilization")
    axes[0].set_ylabel("CBEAM normal-stress utilization")
    axes[0].legend(frameon=False, fontsize=6.5)
    counts = Counter(mechanism.tolist())
    axes[1].bar(range(len(categories)), [counts[c] for c in categories], color=palette)
    axes[1].set_xticks(range(len(categories)), categories, rotation=25, ha="right")
    axes[1].set_ylabel("Evaluations")
    fig.suptitle("Figure 6.3: feasibility mechanisms")
    save(fig, output)


def fig_6_4(output: Path) -> None:
    d = read_csv("data/figures/chapter06/figure_6_04_normalized_design_space.csv")
    columns = ["normalized_ar", "normalized_lambda", "normalized_r1", "normalized_r2"]
    labels = ["AR", "lambda", "r1", "r2"]
    pairs = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
    feas, pf = flag(d, "feasible"), flag(d, "final_pareto")
    fig, axes = plt.subplots(2, 3, figsize=(9.8, 6.4), constrained_layout=True)
    for ax, (i, j) in zip(axes.flat, pairs):
        x, y = num(d, columns[i]), num(d, columns[j])
        ax.scatter(x[~feas], y[~feas], marker="x", c=GREY, s=20)
        ax.scatter(x[feas], y[feas], facecolors="white", edgecolors=BLUE, s=22)
        ax.scatter(x[pf], y[pf], facecolors="none", edgecolors=INK, s=42, linewidths=1.0)
        ax.set_xlabel(f"Normalized {labels[i]}")
        ax.set_ylabel(f"Normalized {labels[j]}")
        ax.set_xlim(0, 1)
        ax.set_ylim(0, 1)
        square(ax)
    fig.suptitle("Figure 6.4: pairwise projections of the four-input design set")
    save(fig, output)


def fig_6_5(output: Path) -> None:
    _conditional_hvi_ch6(5, "aspect_ratio", output, "Figure 6.5: sampled HVI versus aspect ratio")


def fig_6_6(output: Path) -> None:
    _conditional_hvi_ch6(6, "taper_ratio", output, "Figure 6.6: sampled HVI versus taper ratio")


def fig_6_7(output: Path) -> None:
    _conditional_hvi_ch6(7, "primary_member_ratio", output, "Figure 6.7: sampled HVI versus primary-member ratio")


def fig_6_8(output: Path) -> None:
    _conditional_hvi_ch6(8, "secondary_member_ratio", output, "Figure 6.8: sampled HVI versus secondary-member ratio")


def _conditional_hvi_ch6(index: int, suffix: str, output: Path, title_: str) -> None:
    profile = read_csv(f"data/figures/chapter06/figure_6_0{index}_hvi_{suffix}.csv")
    survival = read_csv(f"data/figures/chapter06/figure_6_0{index}_hvi_survival.csv")
    x = num(profile, "input_physical")
    order = np.argsort(x)
    fig, axes = plt.subplots(1, 3, figsize=(11.0, 3.5), constrained_layout=True)
    heatmap(axes[0], num(survival, "input_physical"), num(survival, "normalized_hvi_threshold"),
            num(survival, "display_log10_exceedance_probability"), cmap="magma",
            label="log10 conditional exceedance probability")
    axes[0].set_xlabel("Input value")
    axes[0].set_ylabel("Normalized HVI threshold")
    axes[0].set_title("Conditional survival field")
    for column, label_, ls in [
        ("mean_normalized_hvi", "Mean", "-"),
        ("median_normalized_hvi", "Median", "--"),
        ("p90_normalized_hvi", "90th percentile", "-"),
        ("p99_normalized_hvi", "99th percentile", ":"),
        ("sampled_profile_maximum_normalized_hvi", "Sample maximum", "-."),
    ]:
        axes[1].plot(x[order], num(profile, column)[order], lw=1.1, ls=ls, label=label_)
    axes[1].set_xlabel("Input value")
    axes[1].set_ylabel("Normalized sampled HVI")
    axes[1].set_title("Conditional magnitude")
    axes[1].legend(frameon=False)
    axes[2].plot(x[order], num(profile, "positive_hvi_fraction")[order], color=BLUE, lw=1.4)
    axes[2].set_ylim(-0.02, 1.02)
    axes[2].set_xlabel("Input value")
    axes[2].set_ylabel("Positive-HVI fraction")
    axes[2].set_title("Positive support")
    fig.suptitle(title_)
    save(fig, output)


def fig_6_9(output: Path) -> None:
    d = read_csv("data/multiinput/evaluations_cases001_100.csv")
    feasible = flag(d, "Feasible")
    d = subset(d, feasible)
    columns = ["AR", "lambda", "r1", "r2", "WingMassTotal", "CDitrim", "Ctrim"]
    labels = ["AR", "lambda", "r1", "r2", "Mass", "CDi trim", "Compliance"]
    raw = np.column_stack([num(d, c) for c in columns])
    lo, hi = np.nanmin(raw, axis=0), np.nanmax(raw, axis=0)
    normed = (raw - lo) / np.where(hi > lo, hi - lo, 1)
    phase = text(d, "Source")
    pareto = flag(d, "Pareto")
    fig, ax = plt.subplots(figsize=(10.3, 5.0), constrained_layout=True)
    for row, source, is_pf in zip(normed, phase, pareto):
        color = ORANGE if is_pf and "adaptive" in source.lower() else INK if is_pf else LIGHT_BLUE
        alpha = 0.9 if is_pf else 0.35
        ax.plot(range(len(columns)), row, color=color, alpha=alpha, lw=1.0 if is_pf else 0.65)
    ax.set_xticks(range(len(columns)), labels)
    ax.set_xlim(0, len(columns) - 1)
    ax.set_ylim(0, 1)
    ax.set_ylabel("Axis-wise normalized value")
    ax.set_title("Figure 6.9: feasible design-response parallel coordinates")
    save(fig, output)


def fig_6_10(output: Path) -> None:
    d = read_csv("data/multiinput/evaluations_cases001_100.csv")
    mass, comp = num(d, "WingMassTotal"), num(d, "Ctrim")
    feas, pf = flag(d, "Feasible"), flag(d, "Pareto")
    case = num(d, "Case")
    fig, axes = plt.subplots(1, 2, figsize=(9.6, 4.1), constrained_layout=True)
    pareto_scatter(axes[0], mass, comp, feas, pf, case, annotate=False)
    axes[0].set_xlabel("Two-wing mass")
    axes[0].set_ylabel("Trim compliance")
    initial = case <= 30
    groups = {}
    for ar, lam in zip(num(d, "AR")[initial], num(d, "lambda")[initial]):
        groups.setdefault((ar, lam), None)
    for color, (ar, lam) in zip(plt.cm.tab10(np.linspace(0, 1, len(groups))), groups):
        m = initial & np.isclose(num(d, "AR"), ar) & np.isclose(num(d, "lambda"), lam)
        order = np.argsort(num(d, "r1")[m] + num(d, "r2")[m])
        axes[1].plot(mass[m][order], comp[m][order], color=color, lw=0.9)
        axes[1].scatter(mass[m & feas], comp[m & feas], facecolors="white", edgecolors=color, s=28)
        axes[1].scatter(mass[m & ~feas], comp[m & ~feas], marker="x", color=color, s=28)
    axes[1].set_xlabel("Two-wing mass")
    axes[1].set_ylabel("Trim compliance")
    axes[1].set_title("Initial planform-corner groups")
    fig.suptitle("Figure 6.10: compliance-mass relationship")
    save(fig, output)


def fig_6_11(output: Path) -> None:
    llt = read_csv("data/figures/chapter06/figure_6_11_llt_curves.csv")
    disp = read_csv("data/figures/chapter06/figure_6_11_trim_displacement_curves.csv")
    cases = np.unique(num(llt, "case_id").astype(int))
    fig, axes = plt.subplots(2, 2, figsize=(9.0, 7.0), constrained_layout=True)
    for case in cases:
        m1 = num(llt, "case_id").astype(int) == case
        o1 = np.argsort(num(llt, "normalized_semispan")[m1])
        x1 = num(llt, "normalized_semispan")[m1][o1]
        axes[0, 0].plot(x1, num(llt, "lift_per_unit_span_N_per_m")[m1][o1], lw=1.0, label=f"MI{case}")
        axes[0, 1].plot(x1, num(llt, "outboard_bending_moment_Nm")[m1][o1], lw=1.0)
        m2 = num(disp, "case_id").astype(int) == case
        o2 = np.argsort(num(disp, "normalized_semispan")[m2])
        x2 = num(disp, "normalized_semispan")[m2][o2]
        axes[1, 0].plot(x2, num(disp, "trim_twist_deg")[m2][o2], lw=1.0)
        axes[1, 1].plot(x2, num(disp, "trim_vertical_displacement_m")[m2][o2], lw=1.0)
    labels = ["Lift per unit span (N/m)", "Outboard bending moment (N m)",
              "Trim twist (deg)", "Vertical displacement (m)"]
    for ax, ylabel in zip(axes.flat, labels):
        ax.set_xlabel("Normalized semispan")
        ax.set_ylabel(ylabel)
    axes[0, 0].legend(frameon=False, ncol=2)
    fig.suptitle("Figure 6.11: static aerodynamic and structural decomposition")
    save(fig, output)


def fig_6_12(output: Path) -> None:
    stress = read_csv("data/figures/chapter06/figure_6_12_trim_stress_curves.csv")
    energy = read_csv("data/figures/chapter06/figure_6_12_strain_energy_curves.csv")
    flutter = read_csv("data/figures/chapter06/figure_6_12_flutter_envelope_curves.csv")
    cases = np.unique(num(stress, "case_id").astype(int))
    fig, axes = plt.subplots(2, 2, figsize=(9.2, 7.0), constrained_layout=True)
    components = list(dict.fromkeys(text(stress, "stress_component").tolist()))
    for case in cases:
        for component, ax in zip(components[:2], axes[0, :]):
            m = (num(stress, "case_id").astype(int) == case) & (text(stress, "stress_component") == component)
            order = np.argsort(num(stress, "normalized_semispan")[m])
            ax.plot(num(stress, "normalized_semispan")[m][order], num(stress, "trim_stress_MPa")[m][order],
                    lw=1.0, label=f"MI{case}")
        me = num(energy, "case_id").astype(int) == case
        oe = np.argsort(num(energy, "angle_of_attack_deg")[me])
        axes[1, 0].plot(num(energy, "angle_of_attack_deg")[me][oe],
                        num(energy, "half_wing_strain_energy_Nm")[me][oe], lw=1.0)
        mf = num(flutter, "case_id").astype(int) == case
        of = np.argsort(num(flutter, "velocity_m_per_s")[mf])
        axes[1, 1].plot(num(flutter, "velocity_m_per_s")[mf][of],
                        num(flutter, "maximum_filtered_damping")[mf][of], lw=1.0)
    axes[0, 0].set_title(components[0] if components else "Shell stress")
    axes[0, 1].set_title(components[1] if len(components) > 1 else "CBEAM stress")
    for ax in axes[0, :]:
        ax.set_xlabel("Normalized semispan")
        ax.set_ylabel("Trim stress (MPa)")
    axes[1, 0].set_xlabel("Angle of attack (deg)")
    axes[1, 0].set_ylabel("Half-wing strain energy (N m)")
    axes[1, 1].set_xlabel("Velocity (m/s)")
    axes[1, 1].set_ylabel("Maximum filtered damping")
    axes[1, 1].axhline(0, color=INK, ls="--", lw=0.8)
    axes[0, 0].legend(frameon=False, ncol=2)
    fig.suptitle("Figure 6.12: stress, energy, and flutter decomposition")
    save(fig, output)


FIGURES: dict[str, Callable[[Path], None]] = {
    "2.7": fig_2_7, "2.8": fig_2_8,
    "3.1": fig_3_1, "3.2": fig_3_2, "3.3": fig_3_3, "3.4": fig_3_4,
    "3.5": fig_3_5, "3.6": fig_3_6, "3.7": fig_3_7, "3.8": fig_3_8,
    "3.9": fig_3_9, "3.10": fig_3_10, "3.11": fig_3_11, "3.12": fig_3_12,
    "3.13": fig_3_13,
    "4.1": fig_4_1, "4.2": fig_4_2,
    "5.1": fig_5_1, "5.2": fig_5_2, "5.3": fig_5_3, "5.4": fig_5_4,
    "5.5": fig_5_5, "5.6": fig_5_6, "5.7": fig_5_7, "5.8": fig_5_8,
    "5.9": fig_5_9, "5.10": fig_5_10, "5.11": fig_5_11, "5.12": fig_5_12,
    "5.13": fig_5_13, "5.14": fig_5_14, "5.15": fig_5_15, "5.16": fig_5_16,
    "5.17": fig_5_17, "5.18": fig_5_18, "5.19": fig_5_19, "5.20": fig_5_20,
    "5.21": fig_5_21,
    "6.1": fig_6_1, "6.2": fig_6_2, "6.3": fig_6_3, "6.4": fig_6_4,
    "6.5": fig_6_5, "6.6": fig_6_6, "6.7": fig_6_7, "6.8": fig_6_8,
    "6.9": fig_6_9, "6.10": fig_6_10, "6.11": fig_6_11, "6.12": fig_6_12,
}

# Repository-relative, reader-visible data dependencies.  Shared CSVs appear
# more than once by design because each figure can be invoked independently.
FIGURE_DATA: dict[str, tuple[str, ...]] = {
    "2.7": ("data/figures/chapter02/figure_2_7_mesh_convergence.csv",),
    "2.8": ("data/figures/chapter02/figure_2_8_case64_vg.csv",),
    "3.1": ("data/figures/chapter03/fig03_01_02_final_feasibility_fields.csv",),
    "3.2": ("data/figures/chapter03/fig03_01_02_final_feasibility_fields.csv",),
    "3.3": ("data/figures/chapter03/fig03_03_cossin1_learning.csv",),
    "3.4": ("data/figures/chapter03/fig03_04_cossin2_learning.csv",),
    "3.5": ("data/figures/chapter03/fig03_05_cossin2_iteration20_acquisition.csv",),
    "3.6": ("data/figures/chapter03/fig03_06_wb150_rep02_evaluations.csv",),
    "3.7": ("data/figures/chapter03/fig03_07_highdim_hv_histories.csv",),
    "3.8": ("data/figures/chapter03/fig03_08_wb150_solver_fronts.csv",),
    "3.9": ("data/figures/chapter03/fig03_09_12_wb150_conditional_hvi.csv",),
    "3.10": ("data/figures/chapter03/fig03_09_12_wb150_conditional_hvi.csv",),
    "3.11": ("data/figures/chapter03/fig03_09_12_wb150_conditional_hvi.csv",),
    "3.12": ("data/figures/chapter03/fig03_09_12_wb150_conditional_hvi.csv",),
    "3.13": ("data/figures/chapter03/fig03_13_wb150_hvi_pairwise.csv",),
    "4.1": ("data/figures/chapter04/figure_4_1_representative_fixed_area_planforms.csv",),
    "4.2": ("data/figures/chapter04/figure_4_2_topology_selection.csv",),
    "5.1": ("data/figures/chapter05/figure_5_1_pareto_membership.csv",),
    "5.2": ("data/fcc/evaluations_cases001_071.csv",),
    "5.3": ("data/figures/chapter05/figures_5_3_and_5_5_fcc_feasibility_score_grids.csv",
            "data/figures/chapter05/figures_5_3_and_5_5_fcc_points.csv"),
    "5.4": ("data/figures/chapter05/figure_5_4_fcc_failure_mechanisms.csv",),
    "5.5": ("data/figures/chapter05/figures_5_3_and_5_5_fcc_feasibility_score_grids.csv",
            "data/figures/chapter05/figures_5_3_and_5_5_fcc_points.csv"),
    "5.6": ("data/figures/chapter05/figure_5_6_5_8_case067_flutter_histories.csv",),
    "5.7": ("data/figures/chapter05/figure_5_7_case067_mode3_nodes_manifest.csv",
            "data/figures/chapter05/figure_5_7_case067_mode3_nodes_part01.csv",
            "data/figures/chapter05/figure_5_7_case067_mode3_nodes_part02.csv",
            "data/figures/chapter05/figure_5_7_case067_mode3_nodes_part03.csv",
            "data/figures/chapter05/figure_5_7_case067_mode3_nodes_part04.csv",
            "data/figures/chapter05/figure_5_7_case067_mode3_nodes_part05.csv",
            "data/figures/chapter05/figure_5_7_case067_mode3_nodes_part06.csv",
            "data/figures/chapter05/figure_5_7_case067_mode3_nodes_part07.csv",
            "data/figures/chapter05/figure_5_7_case067_mode3_nodes_part08.csv"),
    "5.8": ("data/figures/chapter05/figure_5_6_5_8_case067_flutter_histories.csv",),
    "5.9": ("data/bcc/evaluations_cases001_071.csv",),
    "5.10": ("data/figures/chapter05/figure_5_10_bcc_feasibility_score_grid.csv",
             "data/bcc/evaluations_cases001_071.csv"),
    "5.11": ("data/figures/chapter05/figure_5_11_bcc_failure_mechanisms.csv",),
    "5.12": ("data/figures/chapter05/figure_5_12_bcc_shell_stress_rank_tails.csv",),
    "5.13": ("data/figures/chapter05/figure_5_13_bcc_root_hotspots.csv",),
    "5.14": ("data/sc/evaluations_cases001_071.csv",),
    "5.15": ("data/figures/chapter05/figure_5_15_sc_feasibility_score_grid.csv",
             "data/sc/evaluations_cases001_071.csv"),
    "5.16": ("data/figures/chapter05/figure_5_16_sc_failure_mechanisms.csv",),
    "5.17": ("data/figures/chapter05/figure_5_17_lattice_material_stress_representatives.csv",),
    "5.18": ("data/figures/chapter05/figure_5_18_planform_feasibility_score_grid.csv",
             "data/planform/evaluations_cases001_050.csv"),
    "5.19": ("data/planform/evaluations_cases001_050.csv",),
    "5.20": ("data/planform/evaluations_cases001_050.csv",),
    "5.21": ("data/figures/chapter05/figure_5_21_planform_taper_observed_points.csv",
             "data/figures/chapter05/figure_5_21_planform_taper_llt_reference_curves.csv"),
    "6.1": ("data/figures/chapter06/figure_6_01_optimization_progress.csv",),
    "6.2": ("data/multiinput/evaluations_cases001_100.csv",),
    "6.3": ("data/figures/chapter06/figure_6_03_feasibility_mechanisms.csv",),
    "6.4": ("data/figures/chapter06/figure_6_04_normalized_design_space.csv",),
    "6.5": ("data/figures/chapter06/figure_6_05_hvi_aspect_ratio.csv",
            "data/figures/chapter06/figure_6_05_hvi_survival.csv"),
    "6.6": ("data/figures/chapter06/figure_6_06_hvi_taper_ratio.csv",
            "data/figures/chapter06/figure_6_06_hvi_survival.csv"),
    "6.7": ("data/figures/chapter06/figure_6_07_hvi_primary_member_ratio.csv",
            "data/figures/chapter06/figure_6_07_hvi_survival.csv"),
    "6.8": ("data/figures/chapter06/figure_6_08_hvi_secondary_member_ratio.csv",
            "data/figures/chapter06/figure_6_08_hvi_survival.csv"),
    "6.9": ("data/multiinput/evaluations_cases001_100.csv",),
    "6.10": ("data/multiinput/evaluations_cases001_100.csv",),
    "6.11": ("data/figures/chapter06/figure_6_11_llt_curves.csv",
             "data/figures/chapter06/figure_6_11_trim_displacement_curves.csv"),
    "6.12": ("data/figures/chapter06/figure_6_12_trim_stress_curves.csv",
             "data/figures/chapter06/figure_6_12_strain_energy_curves.csv",
             "data/figures/chapter06/figure_6_12_flutter_envelope_curves.csv"),
}


def output_name(figure_id: str, suffix: str) -> str:
    chapter, number = figure_id.split(".")
    return f"thesis_figure_{int(chapter):02d}_{int(number):02d}.{suffix}"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("figures", nargs="*", help="Figure IDs, for example 5.9 6.4")
    parser.add_argument("--all", action="store_true", help="Reproduce every CSV-reproducible figure")
    parser.add_argument("--list", action="store_true", help="List supported figure IDs and exit")
    parser.add_argument("--output-dir", type=Path, default=ROOT / "reproduced",
                        help="Output directory (default: repository/reproduced)")
    parser.add_argument("--format", choices=["png", "pdf", "svg"], default="png")
    args = parser.parse_args(argv)
    if args.list:
        for figure_id in FIGURES:
            status = "CSV reproducible"
            dependencies = "; ".join(FIGURE_DATA[figure_id]) or "no portable numerical CSV"
            print(f"{figure_id:>4}  {status:19}  {output_name(figure_id, 'png'):28}  {dependencies}")
        return 0
    targets = list(FIGURES) if args.all else args.figures
    if not targets:
        parser.error("supply at least one figure ID or use --all")
    unknown = [value for value in targets if value not in FIGURES]
    if unknown:
        parser.error(f"unknown figure ID(s): {', '.join(unknown)}")
    _apply_style()
    failures = []
    for figure_id in targets:
        output = args.output_dir.resolve() / output_name(figure_id, args.format)
        try:
            FIGURES[figure_id](output)
            print(f"{figure_id}: {output}")
        except Exception as exc:  # report every requested figure in batch mode
            failures.append((figure_id, str(exc)))
            print(f"{figure_id}: ERROR: {exc}", file=sys.stderr)
    if failures:
        print(f"Failed: {len(failures)} of {len(targets)} figure(s)", file=sys.stderr)
        return 1
    print(f"Reproduced {len(targets)} figure(s) from repository CSV files only.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
