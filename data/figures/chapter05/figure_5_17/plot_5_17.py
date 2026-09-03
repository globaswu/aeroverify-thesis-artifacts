from __future__ import annotations
import argparse
import csv
import math
from pathlib import Path
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
HERE = Path(__file__).resolve().parent
CSV_FILE = HERE / "figure_5_17.csv"
INK="#202124"; BLUE="#1769aa"; ORANGE="#e66101"; RED="#b2182b"; PURPLE="#7b3294"; GREY="#9aa0a6"; LIGHT="#d9e8f5"
plt.rcParams.update({"font.family":"Times New Roman","font.size":9,"axes.titlesize":11,"axes.labelsize":9,"legend.fontsize":8})
def load_rows():
    with CSV_FILE.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))
def select(rows, kind):
    return [r for r in rows if r.get("record_type", "") == kind]
def num(rows, name):
    out=[]
    for row in rows:
        value=row.get(name, "")
        out.append(float(value) if value not in ("", "nan", "NaN") else np.nan)
    return np.asarray(out, dtype=float)
def text(rows, name):
    return np.asarray([row.get(name, "") for row in rows], dtype=str)
def flag(rows, name):
    values=text(rows,name)
    return np.asarray([v.strip().lower() in {"1","true","yes"} for v in values], dtype=bool)
def gridify(rows, xname, yname, zname):
    x=num(rows,xname); y=num(rows,yname); z=num(rows,zname)
    xs=np.unique(x); ys=np.unique(y); image=np.full((len(ys),len(xs)),np.nan)
    ix=np.searchsorted(xs,x); iy=np.searchsorted(ys,y); image[iy,ix]=z
    return xs,ys,image
def observations(ax,x,y,feasible):
    ax.scatter(x[~feasible],y[~feasible],marker="x",c=RED,s=24,label="Infeasible",zorder=4)
    ax.scatter(x[feasible],y[feasible],facecolors="white",edgecolors=BLUE,s=25,label="Feasible",zorder=4)
def pareto_panel(ax,rows,xname,yname,feasname,pfname,casename):
    x=num(rows,xname); y=num(rows,yname); feas=flag(rows,feasname); pf=flag(rows,pfname)
    observations(ax,x,y,feas)
    ax.scatter(x[feas & ~pf],y[feas & ~pf],facecolors="white",edgecolors=BLUE,s=25)
    order=np.flatnonzero(pf)[np.argsort(x[pf])]
    ax.plot(x[order],y[order],color=INK,lw=0.9,zorder=2)
    ax.scatter(x[pf],y[pf],c=INK,s=30,label="Observed Pareto",zorder=5)
    cases=num(rows,casename)
    for i in np.flatnonzero(pf): ax.annotate(str(int(cases[i])),(x[i],y[i]),xytext=(3,3),textcoords="offset points",fontsize=6.5)
def score_panel(ax,grid,points,xname,yname,score,px,py,feasname,pfname,title):
    xs,ys,z=gridify(grid,xname,yname,score)
    image=ax.pcolormesh(xs,ys,z,shading="auto",cmap="cividis",vmin=0,vmax=1)
    if np.nanmin(z)<=0.5<=np.nanmax(z): ax.contour(xs,ys,z,levels=[0.5],colors="white",linewidths=1.0)
    xp=num(points,px); yp=num(points,py); feas=flag(points,feasname); pf=flag(points,pfname)
    observations(ax,xp,yp,feas); ax.scatter(xp[pf],yp[pf],s=45,facecolors="none",edgecolors=INK,lw=1.0,zorder=5)
    ax.set_box_aspect(1); ax.set_title(title)
    return image
def parse_output():
    parser=argparse.ArgumentParser(); parser.add_argument("--output",type=Path,default=HERE/"plot_5_17.png")
    return parser.parse_args().output
def finish(fig):
    out=parse_output(); out.parent.mkdir(parents=True,exist_ok=True); fig.savefig(out,dpi=180,bbox_inches="tight"); plt.close(fig); print(out)

def main():
    d=load_rows(); names=np.asarray([f"{g} case {int(float(c))}" for g,c in zip(text(d,"group"),num(d,"case"))]); x=np.arange(len(d)); skin=2*num(d,"skin_mass_single_kg"); lattice=2*num(d,"lattice_mass_single_kg")
    fig,axes=plt.subplots(2,1,figsize=(7,6),constrained_layout=True); axes[0].bar(x,skin,color=LIGHT,label="Skin"); axes[0].bar(x,lattice,bottom=skin,color=ORANGE,label="Lattice"); axes[0].set_ylabel("Two-wing mass (kg)"); axes[0].legend(frameon=False); axes[1].bar(x,num(d,"max_vm_MPa"),color=[BLUE,ORANGE,PURPLE]); axes[1].axhline(220,color=INK,ls="--",label="220 MPa screen"); axes[1].set_ylabel("Maximum stress (MPa)"); axes[1].legend(frameon=False)
    for ax in axes: ax.set_xticks(x,names)
    fig.suptitle("Material allocation and stress reserve of representative cells"); finish(fig)

if __name__ == "__main__":
    main()
