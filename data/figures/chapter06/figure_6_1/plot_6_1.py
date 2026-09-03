#!/usr/bin/env python3
"""Replot this thesis figure from the sibling CSV only."""
from pathlib import Path
import argparse
import csv
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

HERE = Path(__file__).resolve().parent
DATA = HERE / "figure_6_1.csv"
parser = argparse.ArgumentParser(description="Replot thesis Figure 6.1 from its sibling CSV.")
parser.add_argument("--output", type=Path, help="Output image path; defaults beside this script.")
arguments = parser.parse_args()
OUTPUT = (arguments.output if arguments.output is not None else HERE / "plot_6_1.png").resolve()
OUTPUT.parent.mkdir(parents=True, exist_ok=True)

plt.rcParams.update({"font.family": "serif", "font.serif": ["Times New Roman", "DejaVu Serif"], "font.size": 9})

def rows_from(path):
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))

def number(row, key):
    return float(row[key])

def flag(value):
    return str(value).strip().lower() == "true"

rows = rows_from(DATA)
evaluations = sorted((r for r in rows if r["record_type"] == "evaluation"), key=lambda r: int(r["case_id"]))
summary = {r["phase"]: r for r in rows if r["record_type"] == "phase_summary"}
cases = np.array([int(r["case_id"]) for r in evaluations])
hv = np.array([number(r, "normalized_hypervolume") for r in evaluations])
fig, axes = plt.subplots(1, 2, figsize=(7.2, 3.35))
ax = axes[0]
ax.plot(cases[cases <= 30], hv[cases <= 30], color="#2878B5", lw=1.5)
ax.plot(cases[cases >= 30], hv[cases >= 30], color="#E66101", lw=1.8)
ax.scatter([30], [1.0], color="#2878B5", s=28, zorder=3)
ax.scatter([100], [hv[-1]], color="#E66101", marker="D", s=32, zorder=3)
ax.axvline(30, color="#222222", ls="--", lw=0.8)
ax.set(xlabel="Finalized evaluation", ylabel=r"$HV_{box}$ / value at case 30", title="Box-restricted hypervolume")
ax.grid(True, color="#d9d9d9", lw=0.55)
ax = axes[1]
phases = ["initial_design", "adaptive_phase"]
labels = ["Initial\ndesign", "Adaptive\nphase"]
feas = [number(summary[p], "phase_feasible_share_percent") for p in phases]
pareto = [number(summary[p], "phase_final_pareto_share_percent") for p in phases]
x = np.arange(2); width = 0.34
ax.bar(x-width/2, feas, width, color="#2878B5", edgecolor="#222222", lw=0.5, label="Feasible evaluations")
ax.bar(x+width/2, pareto, width, color="#E66101", edgecolor="#222222", lw=0.5, label="Members of case-100 PF")
for i,p in enumerate(phases):
    ax.text(i-width/2, feas[i]+2, f'{summary[p]["phase_feasible_count"]}/{summary[p]["phase_size"]}', ha="center", fontsize=7)
    ax.text(i+width/2, pareto[i]+2, f'{summary[p]["phase_final_pareto_count"]}/{summary[p]["phase_size"]}', ha="center", fontsize=7)
ax.set_xticks(x, labels); ax.set_ylim(0,100)
ax.set(ylabel="Share of phase evaluations [%]", title="Feasibility and retained-front yield")
ax.grid(True, axis="y", color="#d9d9d9", lw=0.55); ax.legend(fontsize=7)
fig.suptitle("Optimization Progress Through Case 100", fontweight="bold")
fig.tight_layout(); fig.savefig(OUTPUT, dpi=200, bbox_inches="tight"); plt.close(fig)
print(OUTPUT)
