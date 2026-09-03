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
DATA = HERE / "figure_6_4.csv"
parser = argparse.ArgumentParser(description="Replot thesis Figure 6.4 from its sibling CSV.")
parser.add_argument("--output", type=Path, help="Output image path; defaults beside this script.")
arguments = parser.parse_args()
OUTPUT = (arguments.output if arguments.output is not None else HERE / "plot_6_4.png").resolve()
OUTPUT.parent.mkdir(parents=True, exist_ok=True)

plt.rcParams.update({"font.family": "serif", "font.serif": ["Times New Roman", "DejaVu Serif"], "font.size": 9})

def rows_from(path):
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))

def number(row, key):
    return float(row[key])

def flag(value):
    return str(value).strip().lower() == "true"

rows=rows_from(DATA)
keys=["normalized_x1_ar","normalized_x2_taper_ratio","normalized_x3_primary_member_ratio","normalized_x4_secondary_member_ratio"]
labels=["Normalized AR","Normalized taper ratio","Normalized primary-member ratio","Normalized secondary-member ratio"]
pairs=[(0,1),(0,2),(0,3),(1,2),(1,3),(2,3)]
fig,axes=plt.subplots(3,2,figsize=(6.8,8.2))
for ax,(i,j) in zip(axes.flat,pairs):
    inf=[r for r in rows if not flag(r["c_feasible_label"])]; ini=[r for r in rows if flag(r["c_feasible_label"]) and r["phase"]=="initial_design"]; ada=[r for r in rows if flag(r["c_feasible_label"]) and r["phase"]=="adaptive_phase"]; pf=[r for r in rows if flag(r["final_pareto"])]
    ax.scatter([number(r,keys[i]) for r in inf],[number(r,keys[j]) for r in inf],marker="x",s=25,color="#8c8c8c",label="Infeasible")
    ax.scatter([number(r,keys[i]) for r in ini],[number(r,keys[j]) for r in ini],marker="o",s=25,facecolors="white",edgecolors="#2878B5",label="Initial feasible")
    ax.scatter([number(r,keys[i]) for r in ada],[number(r,keys[j]) for r in ada],marker="D",s=27,color="#E66101",label="Adaptive feasible")
    ax.scatter([number(r,keys[i]) for r in pf],[number(r,keys[j]) for r in pf],marker="o",s=53,facecolors="none",edgecolors="#222222",label="Case-100 Pareto")
    ax.set(xlim=(-.025,1.025),ylim=(-.025,1.025),xlabel=labels[i],ylabel=labels[j]); ax.set_xticks([0,.5,1]); ax.set_yticks([0,.5,1]); ax.set_aspect("equal",adjustable="box"); ax.grid(True,color="#d9d9d9",lw=.55)
handles,legend_labels=axes.flat[0].get_legend_handles_labels(); fig.legend(handles,legend_labels,loc="lower center",ncol=4,fontsize=7)
fig.suptitle("Pairwise Projections of the Four-Dimensional Design Domain",fontweight="bold"); fig.tight_layout(rect=(0,.06,1,.96)); fig.savefig(OUTPUT,dpi=200,bbox_inches="tight"); plt.close(fig); print(OUTPUT)
