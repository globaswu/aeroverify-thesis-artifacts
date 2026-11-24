"""Plot the five representative coupled designs using the released CSV files."""
import argparse
import csv
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
import numpy as np

ROOT = Path(__file__).resolve().parent
CASES = (4, 37, 64, 65, 99)
COLORS = dict(zip(CASES, ("#176a9c","#c65313","#ca9514","#7b45a5","#318244"), strict=True))
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument("--output",type=Path,default=Path("figure_6_7.png"))
args=parser.parse_args()

def read(filename):
    with (ROOT/filename).open(encoding="utf-8",newline="") as stream:
        return list(csv.DictReader(stream))

stress=read("spanwise_stresses_12deg.csv")
energy=read("representative_strain_energy_curves.csv")
damping=read("representative_flutter_envelope_curves.csv")
plt.rcParams.update({"font.family":"serif","font.serif":["Times New Roman","DejaVu Serif"],
                     "font.size":11,"mathtext.fontset":"stix","axes.labelcolor":"#172733",
                     "axes.axisbelow":True,"pdf.fonttype":42,"text.color":"#172733"})
fig,ax=plt.subplots(2,2,figsize=(7.4867,9.46))
stress_axes=(ax[0,0],ax[0,1])
for panel, comp in zip(stress_axes, ("shell_von_mises","cbeam_maxabs_normal"), strict=True):
    for n in CASES:
        series=[row for row in stress if int(row["case_id"])==n and row["stress_component"]==comp]
        assert len(series)==140
        edges=[float(x["span_left"]) for x in series]+[float(series[-1]["span_right"])]
        values=[float(x["peak_MPa"]) if x["peak_MPa"] else np.nan for x in series]
        panel.stairs(values,edges,color=COLORS[n],linewidth=1.25)
    panel.set(xlim=(0,1),ylim=(0,200),yticks=(0,40,80,120,160,200),
              xlabel=r"Normalized semispan, $y/s$")
    panel.axhline(184,color="#7f716c",linestyle="--",linewidth=.85)
    panel.text(.52,184,"184 MPa",va="bottom",ha="center",fontsize=8,color="#645450",
               bbox={"facecolor":"white","edgecolor":"none","pad":1.0})
for n in CASES:
    e=[r for r in energy if int(r["case_id"])==n]
    v=[r for r in damping if int(r["case_id"])==n]
    ax[1,0].plot([float(r["angle_of_attack_deg"]) for r in e],
                 [float(r["half_wing_strain_energy_Nm"]) for r in e],
                 "o-",color=COLORS[n],markersize=3.5,linewidth=1.25,
                 markerfacecolor="white",markeredgewidth=.75)
    ax[1,1].plot([float(r["velocity_m_per_s"]) for r in v],
                 [1e5*float(r["maximum_filtered_damping"]) for r in v],
                 color=COLORS[n],linewidth=1.25)
ax[0,0].set_ylabel("Shell von Mises stress (MPa)")
ax[0,1].set_ylabel("Absolute beam normal stress (MPa)")
ax[1,0].set(xlabel="Angle of attack (°)",ylabel=r"Half-wing strain energy (N m)",
            xlim=(-4.5,12.5),xticks=(-4,0,4,8,12),ylim=(0,120))
ax[1,1].set(xlabel="Speed (m/s)",ylabel=r"Maximum filtered damping, $10^5g$",
            xlim=(27,153),ylim=(-1.8,.045),xticks=(30,60,90,120,150))
ax[1,1].axhline(0,color="#7f716c",linestyle="--",linewidth=.85)
for a,title in zip(ax.flat,("(a) Skin stress at 12°","(b) CBEAM stress at 12°",
                           "(c) Strain energy","(d) Sampled damping"),strict=True):
    a.set_title(title,loc="left",fontsize=12,pad=7)
    a.grid(color="#d9e0e4",linewidth=.6)
    a.tick_params(labelsize=9,length=3)
legend=[Line2D([],[],color=COLORS[n],label=f"Case {n}",linewidth=1.6) for n in CASES]
fig.legend(handles=legend,loc="upper center",bbox_to_anchor=(.5,.983),
           ncol=5,frameon=False,columnspacing=1.08,fontsize=10)
fig.subplots_adjust(top=.913,bottom=.065,left=.125,right=.979,wspace=.36,hspace=.31)
fig.savefig(args.output,dpi=300,facecolor="white")
