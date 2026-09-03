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
CSV_FILE = HERE / "figure_5_7.csv"
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
    parser=argparse.ArgumentParser(); parser.add_argument("--output",type=Path,default=HERE/"plot_5_7.png")
    return parser.parse_args().output
def finish(fig):
    out=parse_output(); out.parent.mkdir(parents=True,exist_ok=True); fig.savefig(out,dpi=180,bbox_inches="tight"); plt.close(fig); print(out)

def main():
    d=load_rows(); xyz=np.column_stack([num(d,"x_m"),num(d,"y_m"),num(d,"z_m")]); disp=np.column_stack([num(d,"ux_mode3"),num(d,"uy_mode3"),num(d,"uz_mode3")]); mag=num(d,"displacement_magnitude"); deformed=xyz+disp
    stride=max(1,int(math.ceil(len(d)/160000))); take=np.arange(0,len(d),stride); ref=take[::5]
    fig=plt.figure(figsize=(10.5,7.7),constrained_layout=True); axes=[fig.add_subplot(2,2,1),fig.add_subplot(2,2,2,projection="3d"),fig.add_subplot(2,2,3),fig.add_subplot(2,2,4)]
    for ax,(i,j,title,xl,yl) in zip([axes[0],axes[2],axes[3]],[(0,1,"Top","x (m)","y (m)"),(0,2,"Front","x (m)","z (m)"),(1,2,"Right","y (m)","z (m)")]):
        ax.scatter(xyz[ref,i],xyz[ref,j],s=.05,c="#dddddd",rasterized=True); sc=ax.scatter(deformed[take,i],deformed[take,j],s=.09,c=mag[take],cmap="turbo",rasterized=True); ax.set_title(title); ax.set_xlabel(xl); ax.set_ylabel(yl); ax.set_aspect("equal",adjustable="datalim")
    a=axes[1]; a.scatter(xyz[ref,0],xyz[ref,1],xyz[ref,2],s=.03,c="#dddddd",rasterized=True); a.scatter(deformed[take,0],deformed[take,1],deformed[take,2],s=.07,c=mag[take],cmap="turbo",rasterized=True); a.view_init(elev=22,azim=-55); a.set_title("Oblique"); a.set_xlabel("x (m)"); a.set_ylabel("y (m)"); a.set_zlabel("z (m)")
    fig.colorbar(sc,ax=axes,pad=.02,shrink=.72,label="Normalized mode-3 displacement magnitude"); fig.suptitle(f"FCC case 67 SOL 103 mode 3 ({num(d,'frequency_hz')[0]:.6f} Hz)"); finish(fig)

if __name__ == "__main__":
    main()
