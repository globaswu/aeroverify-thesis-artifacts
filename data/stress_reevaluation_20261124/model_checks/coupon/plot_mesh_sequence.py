"""Reproduce the rod–plate mesh comparison from the archived planar edges."""
import argparse
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.collections import LineCollection
from matplotlib.lines import Line2D
import numpy as np

HERE = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--output", type=Path, default=Path("coupon_mesh_sequence.pdf"))
args = parser.parse_args()
plt.rcParams.update({"font.family":"serif","font.serif":["Times New Roman","DejaVu Serif"],
                     "font.size":9.5,"axes.edgecolor":"#4b5b63","axes.labelcolor":"#253a47",
                     "text.color":"#253a47","pdf.fonttype":42})
fig, axes = plt.subplots(2, 3, figsize=(7.25, 4.95), sharex=True, sharey=True)
names=("solid_coarse","solid_medium","solid_fine","mixed_014","mixed_056","mixed_224")
titles=("Solid, 0.90 mm target","Solid, 0.60 mm target","Solid, 0.40 mm target",
        "Shell, 14 patch triangles","Shell, 56 patch triangles","Shell, 224 patch triangles")
with np.load(HERE/"mesh_views.npz",allow_pickle=False) as data:
    for ax,case,title in zip(axes.flat,names,titles,strict=True):
        ax.add_collection(LineCollection(data[f"{case}_edges"],colors="#637780",
                                         linewidths=.34,alpha=.92))
        cut=data[f"{case}_footprint"]
        if cut.ndim==3:
            outline=cut
        else:
            outline=np.stack((cut,np.roll(cut,-1,axis=0)),axis=1)
        ax.add_collection(LineCollection(outline,colors="#b96018",linewidths=1.05,zorder=3))
        if case.startswith("mixed_"):
            p=data[f"{case}_octagon"]
            ax.plot(*np.r_[p,p[:1]].T,color="#2c5d92",linewidth=.85,linestyle="--",zorder=2)
        ax.set(xlim=(-8,8),ylim=(-8,8),aspect="equal",xticks=(-6,0,6),yticks=(-6,0,6))
        ax.set_title(title,pad=5)
        ax.tick_params(length=2.3,labelsize=8)
for ax in axes[:,0]:
    ax.set_ylabel(r"$y$ (mm)")
for ax in axes[-1,:]:
    ax.set_xlabel(r"$x$ (mm)")
legend=(
    Line2D([],[],color="#637780",linewidth=.6,label="Element edges"),
    Line2D([],[],color="#b96018",linewidth=1.05,label="Physical footprint"),
    Line2D([],[],color="#2c5d92",linestyle="--",linewidth=.85,label="Fitted octagon"),
)
fig.legend(handles=legend,ncol=3,loc="lower center",bbox_to_anchor=(.5,.008),frameon=False,fontsize=9)
fig.subplots_adjust(left=.085,right=.98,bottom=.15,top=.94,hspace=.24,wspace=.15)
fig.savefig(args.output,facecolor="white",dpi=400)
