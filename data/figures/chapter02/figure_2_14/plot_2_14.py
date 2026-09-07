"""Reproduce the lift comparison from the adjacent CSV; no solver is called.

Requirements: Python 3 and Matplotlib. Run: python plot_2_14.py
The Sivells series is a linear reconstruction from Table I's reported
experimental slope and zero-lift angle, not a set of measured point values.
"""
from __future__ import annotations

import csv
import argparse
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import font_manager

HERE = Path(__file__).resolve().parent
DATA = HERE / "figure_2_14.csv"



def ols(xs: list[float], ys: list[float]) -> tuple[float, float]:
    xbar, ybar = sum(xs) / len(xs), sum(ys) / len(ys)
    slope = sum((x-xbar)*(y-ybar) for x, y in zip(xs, ys)) / sum(
        (x-xbar)**2 for x in xs)
    return slope, ybar - slope*xbar


def zero_crossing(xs: list[float], ys: list[float]) -> float:
    for k in range(len(xs)-1):
        if ys[k] <= 0 <= ys[k+1]:
            return xs[k] - ys[k]*(xs[k+1]-xs[k])/(ys[k+1]-ys[k])
    raise ValueError("No bracketed zero-lift crossing in the input CSV")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=HERE / 'figure_2_14.png')
    args = parser.parse_args()
    with DATA.open(newline="", encoding="utf-8-sig") as stream:
        rows = [{key: float(value) for key, value in r.items()}
                for r in csv.DictReader(stream)]
    alpha = [r["alpha_deg"] for r in rows]
    if alpha != [-2, 0, 2, 4, 6, 8]:
        raise ValueError("Expected the six retained samples from -2 to 8 degrees")
    slopes = {r["reference_slope_per_deg"] for r in rows}
    zeros = {r["reference_zero_lift_deg"] for r in rows}
    if len(slopes) != 1 or len(zeros) != 1:
        raise ValueError("Reference parameters must be constant across CSV rows")
    reference_slope, reference_zero = slopes.pop(), zeros.pop()
    nastran = [r["CL_Nastran"] for r in rows]
    llt = [r["CL_LLT"] for r in rows]
    dense_alpha = [alpha[0] + (alpha[-1]-alpha[0])*k/500 for k in range(501)]
    reference = [reference_slope*(a-reference_zero) for a in dense_alpha]

    available_fonts = {f.name for f in font_manager.fontManager.ttflist}
    family = "Times New Roman" if "Times New Roman" in available_fonts else "DejaVu Serif"
    plt.rcParams.update({
        "font.family": family, "font.size": 10.5, "mathtext.fontset": "stix",
        "axes.labelsize": 11, "axes.titlesize": 12, "axes.linewidth": 0.8,
        "xtick.labelsize": 10, "ytick.labelsize": 10, "legend.fontsize": 9.5,
        "svg.fonttype": "none", "savefig.facecolor": "white",
    })
    fig, ax = plt.subplots(figsize=(7.087, 4.75), facecolor="white")
    fig.subplots_adjust(left=0.12, right=0.975, bottom=0.145, top=0.83)
    ax.plot(dense_alpha, reference, color="#333333", linewidth=1.55,
            linestyle=(0, (5, 3)), label="Sivells (1947), Table I: linear reconstruction", zorder=2)
    ax.plot(alpha, nastran, color="#2166AC", linewidth=1.55, marker="s",
            markersize=5.6, markerfacecolor="white", markeredgewidth=1.2,
            label="Nastran SOL 144", zorder=4)
    ax.plot(alpha, llt, color="#C66B18", linewidth=1.55, marker="^",
            markersize=6.0, markerfacecolor="white", markeredgewidth=1.2,
            linestyle="-.", label="Lifting-line calculation", zorder=3)
    ax.set_xlim(-2.25, 8.25)
    ax.set_ylim(-0.12, 0.94)
    ax.set_xticks(alpha)
    ax.set_yticks([0, 0.2, 0.4, 0.6, 0.8])
    ax.set_xlabel(r"Root-chord incidence, $\alpha$ (deg)", labelpad=7)
    ax.set_ylabel(r"Wing lift coefficient, $C_L$", labelpad=7)
    ax.grid(True, color="#E0E0E0", linewidth=0.6)
    ax.set_axisbelow(True)
    ax.axhline(0, color="#A8A8A8", linewidth=0.7, zorder=1)
    ax.tick_params(direction="out", length=3.5, width=0.8)
    for spine in ax.spines.values():
        spine.set_color("#555555")
    ax.legend(loc="upper left", frameon=True, facecolor="white", framealpha=0.97,
              edgecolor="none", borderpad=0.55, labelspacing=0.65, handlelength=2.9)
    fig.text(0.12, 0.94, "Lift comparison for the NACA 65-210 wing", fontsize=12.5,
             color="#202020", ha="left", va="center")
    fig.text(0.12, 0.886, "Retained calculations and a linear reference from experimental parameters",
             fontsize=9.8, color="#505050", ha="left", va="center")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(args.output, dpi=600)
    plt.close(fig)

    metrics = []
    for name, values in [("Nastran SOL 144", nastran), ("Lifting-line calculation", llt)]:
        slope, intercept = ols(alpha, values)
        metrics.append({
            "series": name, "n": len(alpha), "alpha_min_deg": min(alpha),
            "alpha_max_deg": max(alpha), "slope_per_deg": slope,
            "fitted_CL_at_zero": intercept, "fitted_zero_lift_deg": -intercept/slope,
            "sampled_model_CL_at_zero": values[alpha.index(0)],
            "bracketed_zero_lift_deg": zero_crossing(alpha, values),
            "reference_slope_per_deg": reference_slope,
            "reference_zero_lift_deg": reference_zero,
            "slope_difference_percent": 100*(slope/reference_slope - 1),
            "fitted_zero_lift_difference_deg": -intercept/slope-reference_zero,
        })
    for row in metrics:
        print(row)
    print(args.output)


if __name__ == "__main__":
    main()
