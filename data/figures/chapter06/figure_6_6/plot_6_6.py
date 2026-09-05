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
DATA = HERE / "figure_6_6.csv"
parser = argparse.ArgumentParser(description="Replot thesis Figure 6.6 from its sibling CSV.")
parser.add_argument("--output", type=Path, help="Output image path; defaults beside this script.")
arguments = parser.parse_args()
OUTPUT = (arguments.output if arguments.output is not None else HERE / "plot_6_6.png").resolve()
OUTPUT.parent.mkdir(parents=True, exist_ok=True)

plt.rcParams.update({"font.family": "serif", "font.serif": ["Times New Roman", "DejaVu Serif"], "font.size": 9})

def rows_from(path):
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))

def number(row, key): return float(row[key])
def flag(value): return str(value).strip().lower() == "true"

rows=[r for r in rows_from(DATA) if flag(r["c_feasible_label"])]
keys=["x1_ar","x2_taper_ratio","x3_primary_member_ratio","x4_secondary_member_ratio","two_wing_mass_kg","y1_cditrim","y2_ctrim_nm"]
labels=["AR","lambda","r1","r2","m2W","CDi,trim","Ctrim"]
bounds={"x1_ar":(6,12),"x2_taper_ratio":(.2,.8),"x3_primary_member_ratio":(.05,.4),"x4_secondary_member_ratio":(.15,.5)}
ranges={k:(min(number(r,k) for r in rows),max(number(r,k) for r in rows)) for k in keys}; ranges.update(bounds)
def scaled(r): return [(number(r,k)-ranges[k][0])/(ranges[k][1]-ranges[k][0]) for k in keys]
fig,ax=plt.subplots(figsize=(7.2,4.9)); x=np.arange(len(keys))
for r in rows:
    if flag(r["final_pareto"]) and r["phase"]=="adaptive_phase": color,lw,alpha="#E66101",1.8,.92
    elif flag(r["final_pareto"]): color,lw,alpha="#222222",1.35,.78
    else: color,lw,alpha="#2878B5",.8,.28
    ax.plot(x,scaled(r),color=color,lw=lw,alpha=alpha)
for i in range(len(keys)): ax.plot([i,i],[0,1],color="#222222",lw=.65)
ax.set_xticks(x,labels); ax.set_yticks([]); ax.set_xlim(-.2,len(keys)-.8); ax.set_ylim(-.03,1.03)
ax.set_title("Parallel Coordinates of the 70 Feasible Evaluations\n"
             "Mass is diagnostic; the two rightmost axes are minimized objectives")
for spine in ax.spines.values(): spine.set_visible(False)
from matplotlib.lines import Line2D
ax.legend(handles=[Line2D([0],[0],color="#2878B5",label="Feasible, dominated"),Line2D([0],[0],color="#222222",label="Initial-design Pareto"),Line2D([0],[0],color="#E66101",label="Adaptive Pareto")],loc="lower center",bbox_to_anchor=(.5,-.16),ncol=3,fontsize=7)
fig.tight_layout(); fig.savefig(OUTPUT,dpi=200,bbox_inches="tight"); plt.close(fig); print(OUTPUT)
