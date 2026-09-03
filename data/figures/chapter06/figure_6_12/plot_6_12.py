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
DATA = HERE / "figure_6_12.csv"
parser = argparse.ArgumentParser(description="Replot thesis Figure 6.12 from its sibling CSV.")
parser.add_argument("--output", type=Path, help="Output image path; defaults beside this script.")
arguments = parser.parse_args()
OUTPUT = (arguments.output if arguments.output is not None else HERE / "plot_6_12.png").resolve()
OUTPUT.parent.mkdir(parents=True, exist_ok=True)

plt.rcParams.update({"font.family": "serif", "font.serif": ["Times New Roman", "DejaVu Serif"], "font.size": 9})

def rows_from(path):
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))

def number(row, key): return float(row[key])
def flag(value): return str(value).strip().lower() == "true"

rows=rows_from(DATA); stress=[r for r in rows if r["record_type"]=="trim_stress"]; energy=[r for r in rows if r["record_type"]=="strain_energy"]; flutter=[r for r in rows if r["record_type"]=="flutter_envelope"]; cases=sorted({int(r["case_id"]) for r in stress}); colors=plt.cm.tab10(np.linspace(0,.8,len(cases)))
fig,axes=plt.subplots(2,2,figsize=(7.5,8.5))
for case,color in zip(cases,colors):
    shell=sorted([r for r in stress if int(r["case_id"])==case and r["stress_component"]=="shell_von_mises"],key=lambda r:number(r,"normalized_semispan")); beam=sorted([r for r in stress if int(r["case_id"])==case and r["stress_component"]=="cbeam_maxabs_normal"],key=lambda r:number(r,"normalized_semispan")); en=sorted([r for r in energy if int(r["case_id"])==case],key=lambda r:number(r,"angle_of_attack_deg")); fl=sorted([r for r in flutter if int(r["case_id"])==case],key=lambda r:number(r,"velocity_m_per_s"))
    axes[0,0].plot([number(r,"normalized_semispan") for r in shell],[number(r,"trim_stress_mpa") for r in shell],color=color,lw=1.35,label=f"MI{case}")
    axes[0,1].plot([number(r,"normalized_semispan") for r in beam],[number(r,"trim_stress_mpa") for r in beam],color=color,lw=1.35)
    axes[1,0].plot([number(r,"angle_of_attack_deg") for r in en],[number(r,"half_wing_strain_energy_nm") for r in en],"o-",color=color,lw=1.15,ms=3.5)
    axes[1,1].plot([number(r,"velocity_m_per_s") for r in fl],[1e5*number(r,"maximum_filtered_damping") for r in fl],color=color,lw=1.25)
axes[0,0].set(xlim=(0,1),ylim=(0,100),xlabel="Normalized semispan, y/s [-]",ylabel="Shell von Mises stress [MPa]",title="A. Trim shell stress")
axes[0,1].set(xlim=(0,1),ylim=(0,100),xlabel="Normalized semispan, y/s [-]",ylabel="CBEAM max-absolute normal stress [MPa]",title="B. Trim CBEAM stress")
axes[1,0].set(xlabel="Angle of attack [deg]",ylabel="Half-wing strain energy [N m]",title="C. Parsed SOL 144 total strain energy")
axes[1,1].set(xlabel="Velocity [m/s]",ylabel="Maximum filtered damping, 1e5 g [-]",title="D. Conservative V-g envelope over roots"); axes[1,1].axhline(0,color="#222222",ls="--",lw=.8)
for ax in axes.flat: ax.grid(True,color="#d9d9d9",lw=.5)
axes[0,0].legend(fontsize=7); fig.suptitle("Representative Stress, Energy, and Aeroelastic Response",fontweight="bold"); fig.tight_layout(); fig.savefig(OUTPUT,dpi=200,bbox_inches="tight"); plt.close(fig); print(OUTPUT)
