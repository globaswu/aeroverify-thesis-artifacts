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

def number(row, key): return float(row[key])
def flag(value): return str(value).strip().lower() == "true"

rows=rows_from(DATA); llt=[r for r in rows if r["record_type"]=="llt"]; disp=[r for r in rows if r["record_type"]=="trim_displacement"]; cases=sorted({int(r["case_id"]) for r in llt}); colors=plt.cm.tab10(np.linspace(0,.8,len(cases)))
fig,axes=plt.subplots(2,2,figsize=(7.5,8.5))
for case,color in zip(cases,colors):
    a=sorted([r for r in llt if int(r["case_id"])==case],key=lambda r:number(r,"normalized_semispan")); d=sorted([r for r in disp if int(r["case_id"])==case],key=lambda r:number(r,"normalized_semispan")); eta=[number(r,"normalized_semispan") for r in a]; etad=[number(r,"normalized_semispan") for r in d]
    axes[0,0].plot(eta,[number(r,"lift_per_unit_span_n_per_m") for r in a],color=color,lw=1.35,label=f"MI{case}")
    axes[0,1].plot(eta,[number(r,"outboard_bending_moment_nm")/1000 for r in a],color=color,lw=1.35)
    axes[1,0].plot(etad,[number(r,"trim_twist_deg") for r in d],color=color,lw=1.35)
    axes[1,1].plot(etad,[1000*number(r,"trim_vertical_displacement_m") for r in d],color=color,lw=1.35)
titles=["A. Torsion-corrected LLT load","B. Derived outboard-load moment","C. SOL 144 trim twist","D. SOL 144 trim vertical displacement"]; ylabels=["LLT lift per unit span [N/m]","Aerodynamic bending moment [kN m]","Torsional displacement [deg]","Vertical displacement [mm]"]
for ax,title,ylabel in zip(axes.flat,titles,ylabels): ax.set(xlim=(0,1),xlabel="Normalized semispan, y/s [-]",ylabel=ylabel,title=title); ax.grid(True,color="#d9d9d9",lw=.5)
axes[0,0].legend(fontsize=7); fig.suptitle("Representative Static Aerostructural Decomposition",fontweight="bold"); fig.tight_layout(); fig.savefig(OUTPUT,dpi=200,bbox_inches="tight"); plt.close(fig); print(OUTPUT)
