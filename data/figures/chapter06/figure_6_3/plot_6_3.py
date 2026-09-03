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
DATA = HERE / "figure_6_3.csv"
parser = argparse.ArgumentParser(description="Replot thesis Figure 6.3 from its sibling CSV.")
parser.add_argument("--output", type=Path, help="Output image path; defaults beside this script.")
arguments = parser.parse_args()
OUTPUT = (arguments.output if arguments.output is not None else HERE / "plot_6_3.png").resolve()
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
fig,axes=plt.subplots(1,2,figsize=(7.2,3.65))
cats=["feasible","shell_von_mises_only","cbeam_normal_only","shell_and_cbeam"]
labels=["Feasible","Shell VM","CBEAM normal","Shell + CBEAM"]
phases=["initial_design","adaptive_phase"]; colors=["#2878B5","#E66101"]; x=np.arange(len(cats)); width=.36
for j,p in enumerate(phases):
    counts=[sum(r["phase"]==p and r["failure_mechanism"]==c for r in rows) for c in cats]
    axes[0].bar(x+(j-.5)*width,counts,width,color=colors[j],edgecolor="#222222",lw=.5,label=p.replace("_"," ").title())
axes[0].set_xticks(x,labels,rotation=18,ha="right"); axes[0].set_ylabel("Number of evaluations"); axes[0].set_title("Feasibility outcomes"); axes[0].grid(True,axis="y",color="#d9d9d9",lw=.55); axes[0].legend(fontsize=7)
ax=axes[1]
groups=[([r for r in rows if not flag(r["c_feasible_label"])],"x","#8c8c8c","Infeasible"),([r for r in rows if flag(r["c_feasible_label"]) and r["phase"]=="initial_design"],"o","#2878B5","Initial feasible"),([r for r in rows if flag(r["c_feasible_label"]) and r["phase"]=="adaptive_phase"],"D","#E66101","Adaptive feasible")]
for group,m,c,label in groups:
    xs=[number(r,"shell_utilization") for r in group]; ys=[number(r,"cbeam_utilization") for r in group]
    if label=="Initial feasible": ax.scatter(xs,ys,marker=m,s=29,facecolors="white",edgecolors=c,label=label)
    else: ax.scatter(xs,ys,marker=m,s=30,color=c,label=label)
pareto=[r for r in rows if flag(r["final_pareto"])]; ax.scatter([number(r,"shell_utilization") for r in pareto],[number(r,"cbeam_utilization") for r in pareto],s=57,facecolors="none",edgecolors="#222222",label="Case-100 Pareto")
ax.axvline(1,color="#222222",ls="--",lw=.8); ax.axhline(1,color="#222222",ls="--",lw=.8); ax.set_xscale("log"); ax.set_yscale("log"); ax.set_aspect("equal",adjustable="box")
ax.set(xlabel="Shell von Mises utilization",ylabel="CBEAM normal-stress utilization",title="Stress-screening map"); ax.grid(True,color="#d9d9d9",lw=.55); ax.legend(fontsize=6.5)
fig.suptitle("Feasibility Mechanisms at 100 Finalized Evaluations",fontweight="bold"); fig.tight_layout(); fig.savefig(OUTPUT,dpi=200,bbox_inches="tight"); plt.close(fig); print(OUTPUT)
