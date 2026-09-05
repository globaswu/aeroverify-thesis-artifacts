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
DATA = HERE / "figure_D_3.csv"
parser = argparse.ArgumentParser(description="Replot thesis Figure D.3 from its sibling CSV.")
parser.add_argument("--output", type=Path, help="Output image path; defaults beside this script.")
arguments = parser.parse_args()
OUTPUT = (arguments.output if arguments.output is not None else HERE / "plot_D_3.png").resolve()
OUTPUT.parent.mkdir(parents=True, exist_ok=True)
plt.rcParams.update({"font.family": "serif", "font.serif": ["Times New Roman", "DejaVu Serif"], "font.size": 9})

def rows_from(path):
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))

def number(row, key):
    return float(row[key])

rows=rows_from(DATA)
profile=[r for r in rows if r["record_type"]=="profile"]
survival=[r for r in rows if r["record_type"]=="survival"]
profile=sorted(profile,key=lambda r:number(r,"input_physical"))
x=np.array([number(r,"input_physical") for r in profile])
thresholds=np.array(sorted({number(r,"normalized_hvi_threshold") for r in survival}))
xi=np.array(sorted({number(r,"input_physical") for r in survival}))
lookup={(number(r,"normalized_hvi_threshold"),number(r,"input_physical")):r for r in survival}
prob=np.array([[number(lookup[(t,v)],"conditional_exceedance_probability") for v in xi] for t in thresholds])
display=np.array([[number(lookup[(t,v)],"display_log10_exceedance_probability") for v in xi] for t in thresholds])
fig,axes=plt.subplots(3,1,figsize=(7.5,10.2))
ax=axes[0]
mesh=ax.pcolormesh(xi,np.log10(thresholds),display,shading="auto",cmap="viridis",vmin=np.log10(1/2048),vmax=0)
cs=ax.contour(xi,np.log10(thresholds),prob,levels=[.01,.1,.5],colors="#222222",linewidths=.8)
ax.clabel(cs,fontsize=7)
ax.set(xlabel="Aspect ratio, AR [-]",ylabel="log10 normalized HVI threshold",title="A. Conditional HVI survival field")
ax.set_yticks([-8,-6,-4,-2,0], labels=["$10^{-8}$","$10^{-6}$","$10^{-4}$","$10^{-2}$","$10^0$"])
ax.set_ylabel("Normalized HVI threshold [-]")
bar=fig.colorbar(mesh,ax=ax,label="Conditional exceedance probability")
bar.set_ticks([np.log10(1/2048),-3,-2,-1,0], labels=["<=1/2048","$10^{-3}$","$10^{-2}$","$10^{-1}$","1"])
def positive(name):
    a=np.array([number(r,name) for r in profile])
    return np.where(a>0,a,np.nan)
ax=axes[1]
ax.plot(x,positive("p90_normalized_hvi"),color="#D59E1A",lw=1.6,label="90th percentile")
ax.plot(x,positive("p99_normalized_hvi"),color="#E86E17",lw=1.8,label="99th percentile")
ax.plot(x,positive("mean_normalized_hvi"),"--",color="#1769AA",lw=1.7,label="Conditional mean")
ax.plot(x,positive("sampled_profile_maximum_normalized_hvi"),color="#222222",lw=2,label="Sampled profile maximum")
ax.scatter([number(profile[0],"selected_input_physical")],[number(profile[0],"selected_hvi_normalized")],marker="*",s=90,zorder=6,clip_on=False,color="#B33A3A",edgecolors="white",label="Selected design")
ax.set_yscale("log"); ax.set_ylim(1e-8,1.15)
ax.set(xlabel="Aspect ratio, AR [-]",ylabel="Normalized HVI [-]",title="B. Conditional quantiles and profile")
ax.grid(True,which="both",color="#d9d9d9",lw=.5); ax.legend(fontsize=7)
ax=axes[2]
ax.plot(x,positive("positive_hvi_fraction"),color="#E86E17",lw=2,label="Positive-HVI fraction")
ax.plot(x,positive("mean_normalized_hvi"),"--",color="#1769AA",lw=1.8,label="Conditional mean")
ax.set_yscale("log"); ax.set_ylim(1e-8,1)
ax.set(xlabel="Aspect ratio, AR [-]",ylabel="Conditional domain-volume statistic [-]",title="C. Positive-HVI support and conditional mean")
ax.grid(True,which="both",color="#d9d9d9",lw=.5); ax.legend(fontsize=8)
fig.suptitle("Frozen sampled-HVI field versus aspect ratio before evaluation 100",fontweight="bold")
for panel in axes:
    panel.set_xlim(float(xi[0]), float(xi[-1]))
    panel.grid(False, which="minor")
    panel.tick_params(labelsize=9)
positive_indices=np.flatnonzero(np.array([number(r,"positive_hvi_fraction") for r in profile])>0)
if len(positive_indices) and positive_indices[-1]+1 < len(profile):
    zero_start=number(profile[positive_indices[-1]+1],"input_physical")
    axes[1].axvline(zero_start, color="#777777", linestyle=":", linewidth=.8)
    axes[1].text(.98,.20,f"All sampled HVI = 0 for AR >= {zero_start:g}",
                 transform=axes[1].transAxes, ha="right", va="center", fontsize=8,
                 bbox=dict(facecolor="white", edgecolor="none", alpha=.9))
fig.tight_layout(pad=1.0,h_pad=2.0); fig.savefig(OUTPUT,dpi=300,bbox_inches="tight"); plt.close(fig); print(OUTPUT)
