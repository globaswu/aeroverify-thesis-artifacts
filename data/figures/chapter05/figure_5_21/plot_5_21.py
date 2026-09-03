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
CSV_FILE = HERE / "figure_5_21.csv"
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
    parser=argparse.ArgumentParser(); parser.add_argument("--output",type=Path,default=HERE/"plot_5_21.png")
    return parser.parse_args().output
def finish(fig):
    out=parse_output(); out.parent.mkdir(parents=True,exist_ok=True); fig.savefig(out,dpi=180,bbox_inches="tight"); plt.close(fig); print(out)

def main():
    d=load_rows(); obs=select(d,"observed"); ref=select(d,"reference"); ar=num(ref,"AR"); taper=num(ref,"TaperRatio"); chosen=np.asarray([6.,9.,12.]); fig,axes=plt.subplots(3,1,figsize=(7.2,10),constrained_layout=True)
    feas=flag(obs,"Feasible"); axes[0].scatter(num(obs,"TaperRatio")[feas],1000*num(obs,"CDitrim")[feas],c=num(obs,"AR")[feas],cmap="viridis",s=32,label="Feasible"); axes[0].scatter(num(obs,"TaperRatio")[~feas],1000*num(obs,"CDitrim")[~feas],marker="x",c=GREY,s=30,label="Infeasible"); pf=flag(obs,"Pareto"); axes[0].scatter(num(obs,"TaperRatio")[pf],1000*num(obs,"CDitrim")[pf],s=60,facecolors="none",edgecolors=INK); axes[0].set_ylabel("Trim induced drag, 1000 CDi")
    for value in chosen:
        m=np.isclose(ar,value); order=np.argsort(taper[m]); axes[1].plot(taper[m][order],num(ref,"RigidSpanEfficiency")[m][order],label=f"Rigid LLT, AR={value:g}")
    axes[1].scatter(num(obs,"TaperRatio")[feas],num(obs,"TorsionCorrectedE")[feas],c=num(obs,"AR")[feas],cmap="viridis",s=30); axes[1].scatter(num(obs,"TaperRatio")[~feas],num(obs,"TorsionCorrectedE")[~feas],marker="x",c=GREY,s=28); axes[1].set_ylabel("Span efficiency"); axes[1].legend(frameon=False,ncol=3)
    ut=np.unique(taper); lo=[]; hi=[]
    for t in ut:
        vals=num(ref,"TaperOnlyCDiPenaltyPct")[np.isclose(taper,t)]; lo.append(vals.min()); hi.append(vals.max())
    axes[2].fill_between(ut,lo,hi,color=LIGHT,label="Rigid LLT envelope, AR=6-12"); m=np.isclose(ar,9); order=np.argsort(taper[m]); axes[2].plot(taper[m][order],num(ref,"TaperOnlyCDiPenaltyPct")[m][order],color=BLUE,label="Rigid LLT, AR=9"); axes[2].scatter(num(obs,"TaperRatio")[feas],num(obs,"TaperOnlyCDiPenaltyPct")[feas],c=num(obs,"AR")[feas],cmap="viridis",s=30); axes[2].scatter(num(obs,"TaperRatio")[~feas],num(obs,"TaperOnlyCDiPenaltyPct")[~feas],marker="x",c=GREY,s=28); axes[2].set_ylabel("Taper-only CDi penalty (%)"); axes[2].legend(frameon=False)
    for ax in axes: ax.set_xlabel("Taper ratio")
    fig.suptitle("Taper-ratio theory and observed-result consistency checks"); finish(fig)

if __name__ == "__main__":
    main()
