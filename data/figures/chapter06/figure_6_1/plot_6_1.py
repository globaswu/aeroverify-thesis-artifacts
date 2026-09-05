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
def xy(group): return [number(r,"y1_cditrim") for r in group], [number(r,"y2_ctrim_nm") for r in group]
def draw(ax):
    groups=[([r for r in rows if not flag(r["c_feasible_label"])],"x",36,"#8c8c8c","Infeasible"),
            ([r for r in rows if flag(r["c_feasible_label"]) and not flag(r["final_pareto"])],"o",40,"#2878B5","Feasible, dominated"),
            ([r for r in rows if flag(r["final_pareto"]) and int(r["case_id"])<=30],"o",48,"#222222","Initial-design Pareto"),
            ([r for r in rows if flag(r["final_pareto"]) and int(r["case_id"])>30],"D",50,"#E66101","Adaptive Pareto")]
    for group,marker,size,color,label in groups:
        x,y=xy(group)
        if marker=="o" and label.startswith("Feasible"):
            ax.scatter(x,y,marker=marker,s=size,facecolors="white",edgecolors=color,lw=1.1,label=label)
        else: ax.scatter(x,y,marker=marker,s=size,color=color,label=label)
    refined=[r for r in rows if flag(r["refined_mesh"])]
    x,y=xy(refined); ax.scatter(x,y,marker="s",s=66,facecolors="none",edgecolors="#6A3D9A",lw=0.8,label="Refined mesh")
    front=sorted([r for r in rows if flag(r["final_pareto"])],key=lambda r:number(r,"y1_cditrim"))
    x,y=xy(front); ax.plot(x,y,color="#222222",lw=1)
    ax.grid(True,color="#d9d9d9",lw=0.55)
fig,ax=plt.subplots(figsize=(7.0,5.1))
draw(ax); ax.set(xlabel=r"Trim induced-drag coefficient, $C_{D_i,trim}$ [-]",ylabel=r"Two-wing trim compliance, $C_{trim}$ [N m]",title="Four-Input Objective Space (100 Evaluations)")
ax.legend(loc="lower center",bbox_to_anchor=(0.5,-0.29),ncol=2,fontsize=7)
inset=ax.inset_axes([0.43,0.43,0.54,0.48]); draw(inset)
front=[r for r in rows if flag(r["final_pareto"])]; xs=[number(r,"y1_cditrim") for r in front]; ys=[number(r,"y2_ctrim_nm") for r in front]
inset.set_xlim(min(xs)-0.06*(max(xs)-min(xs)),max(xs)+0.06*(max(xs)-min(xs))); inset.set_ylim(min(ys)-0.06*(max(ys)-min(ys)),max(ys)+0.06*(max(ys)-min(ys))); inset.set_title("Feasible-front detail",fontsize=8)
if inset.get_legend() is not None: inset.get_legend().remove()
fig.tight_layout(); fig.savefig(OUTPUT,dpi=200,bbox_inches="tight"); plt.close(fig); print(OUTPUT)
