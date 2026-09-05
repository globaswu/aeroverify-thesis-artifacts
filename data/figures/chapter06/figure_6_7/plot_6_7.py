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
DATA = HERE / "figure_6_7.csv"
parser = argparse.ArgumentParser(description="Replot thesis Figure 6.7 from its sibling CSV.")
parser.add_argument("--output", type=Path, help="Output image path; defaults beside this script.")
arguments = parser.parse_args()
OUTPUT = (arguments.output if arguments.output is not None else HERE / "plot_6_7.png").resolve()
OUTPUT.parent.mkdir(parents=True, exist_ok=True)

plt.rcParams.update({"font.family": "serif", "font.serif": ["Times New Roman", "DejaVu Serif"], "font.size": 9})

def rows_from(path):
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))

def number(row, key): return float(row[key])
def flag(value): return str(value).strip().lower() == "true"

rows=rows_from(DATA); feasible=[r for r in rows if flag(r["c_feasible_label"])]
def rank(a):
    a=np.asarray(a); order=np.argsort(a,kind="mergesort"); out=np.empty(len(a),float); i=0
    while i<len(a):
        j=i+1
        while j<len(a) and a[order[j]]==a[order[i]]: j+=1
        out[order[i:j]]=(i+j-1)/2+1; i=j
    return out
mass=np.array([number(r,"two_wing_mass_kg") for r in feasible]); comp=np.array([number(r,"y2_ctrim_nm") for r in feasible]); pearson=np.corrcoef(mass,comp)[0,1]; spearman=np.corrcoef(rank(mass),rank(comp))[0,1]
fig,axes=plt.subplots(1,2,figsize=(7.2,3.7)); ax=axes[0]
initial=[r for r in feasible if r["phase"]=="initial_design"]; adaptive=[r for r in feasible if r["phase"]=="adaptive_phase"]; pf=[r for r in feasible if flag(r["final_pareto"])]
ax.scatter([number(r,"two_wing_mass_kg") for r in initial],[number(r,"y2_ctrim_nm") for r in initial],s=31,facecolors="white",edgecolors="#2878B5",label="Initial feasible")
ax.scatter([number(r,"two_wing_mass_kg") for r in adaptive],[number(r,"y2_ctrim_nm") for r in adaptive],marker="D",s=32,color="#E66101",label="Adaptive feasible")
ax.scatter([number(r,"two_wing_mass_kg") for r in pf],[number(r,"y2_ctrim_nm") for r in pf],s=58,facecolors="none",edgecolors="#222222",label="Case-100 Pareto")
ax.set(xlabel="Full two-wing structural mass [kg]",ylabel="Two-wing trim compliance [N m]",title=f"Feasible sample (n=70)\nPearson r={pearson:.2f}; Spearman rho={spearman:.2f}"); ax.grid(True,color="#d9d9d9",lw=.55); ax.legend(fontsize=6.5); ax.set_box_aspect(1)
ax=axes[1]; corners=[r for r in rows if int(r["case_id"])<=16]; plans=sorted({(number(r,"x1_ar"),number(r,"x2_taper_ratio")) for r in corners}); colors=["#2878B5","#E66101","#2E8B57","#A23B72"]
for color,key in zip(colors,plans):
    group=sorted([r for r in corners if number(r,"x1_ar")==key[0] and number(r,"x2_taper_ratio")==key[1]],key=lambda r:number(r,"two_wing_mass_kg"))
    ax.plot([number(r,"two_wing_mass_kg") for r in group],[number(r,"y2_ctrim_nm") for r in group],color=color,lw=1.1,label=f"AR={key[0]:.0f}, lambda={key[1]:.1f}")
    ok=[r for r in group if flag(r["c_feasible_label"])]; bad=[r for r in group if not flag(r["c_feasible_label"])]
    ax.scatter([number(r,"two_wing_mass_kg") for r in ok],[number(r,"y2_ctrim_nm") for r in ok],color=color,s=27)
    ax.scatter([number(r,"two_wing_mass_kg") for r in bad],[number(r,"y2_ctrim_nm") for r in bad],color=color,marker="x",s=30)
ax.set(xlabel="Full two-wing structural mass [kg]",ylabel="Two-wing trim compliance [N m]",title="Matched planform corners"); ax.grid(True,color="#d9d9d9",lw=.55); ax.legend(fontsize=6.5); ax.set_box_aspect(1)
fig.suptitle("Compliance-Mass Relationship Through Case 100",fontweight="bold"); fig.tight_layout(); fig.savefig(OUTPUT,dpi=200,bbox_inches="tight"); plt.close(fig); print(OUTPUT)
