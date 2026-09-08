"""Reconstruct actual faceted skin stress from only the adjacent source CSVs.

python plot.py --output /output/skin_stress.png --summary /output/peak_locations.csv
The plotted value is max of the two original shell-centroid surface values.
No nodal averaging, geometry smoothing, point-cloud replacement or solver run.
"""
from pathlib import Path
import argparse
import csv
import gc
import json
import os

for key in ("OMP_NUM_THREADS","OPENBLAS_NUM_THREADS","MKL_NUM_THREADS"):
    os.environ[key]="1"
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.collections import PolyCollection
from matplotlib.colors import LinearSegmentedColormap,Normalize
from matplotlib.cm import ScalarMappable

BASE=Path(__file__).resolve().parent
CASE_FILES={
    37:("case_37_vertices.csv","case_37_triangles.csv"),
    99:("case_99_vertices.csv","case_99_triangles.csv"),
}
COLORS=np.array([[.055,.13,.28],[.10,.32,.51],[.24,.52,.62],[.61,.70,.60],[.94,.82,.34]])
CMAP=LinearSegmentedColormap.from_list("skin_blue_gold",COLORS,N=256)
NORM=Normalize(0,220,clip=True)
AZIMUTH=-60.0
ELEVATION=40.0
az,el=np.deg2rad([AZIMUTH,ELEVATION])
VIEW=np.array([np.cos(el)*np.cos(az),np.cos(el)*np.sin(az),np.sin(el)])
RIGHT=np.array([-np.sin(az),np.cos(az),0.0])
UP=np.cross(VIEW,RIGHT)
BASIS=np.stack([RIGHT,UP,VIEW],axis=1)
OVERVIEW_MIN=np.array([-.035,-.04,-.055])
OVERVIEW_MAX=np.array([1.025,2.56,.075])
ROOT_OFFSET_MIN=np.array([-.028,-.002,-.008])
ROOT_OFFSET_MAX=np.array([.028,.018,.008])


def projected_limits(low,high,padding):
    corners=np.array([[x,y,z] for x in [low[0],high[0]] for y in [low[1],high[1]] for z in [low[2],high[2]]])
    uv=(corners@BASIS)[:,:2]
    return uv.min(axis=0)-padding,uv.max(axis=0)+padding


def read_case(meta):
    case=int(meta["case"])
    vertex_file,triangle_file=CASE_FILES[case]
    raw_v=np.loadtxt(BASE/vertex_file,delimiter=",",skiprows=1)
    raw_f=np.loadtxt(BASE/triangle_file,delimiter=",",skiprows=1)
    ids=raw_v[:,0].astype(np.int64)
    eid=raw_f[:,0].astype(np.int64)
    nodes=raw_f[:,1:4].astype(np.int64)
    assert np.all(np.diff(ids)>0) and np.all(np.diff(eid)>0)
    assert len(ids)==int(meta["vertices"]) and len(eid)==int(meta["triangles"])
    faces=np.searchsorted(ids,nodes)
    assert np.array_equal(ids[faces],nodes)
    vertices=raw_v[:,1:4]
    # Nine-digit decimals roundtrip to the original OP2 float32 values.
    surfaces=raw_f[:,4:6].astype(np.float32)
    assert np.isfinite(vertices).all() and np.isfinite(surfaces).all() and np.all(surfaces>=0)
    values=surfaces.max(axis=1)
    assert values.max()<=220e6
    peaks=int(np.argmax(values))
    centroid=vertices[faces[peaks]].mean(axis=0)
    s,cr,lam=[float(meta[k]) for k in ["semispan_m","root_chord_m","taper_ratio"]]
    eta=centroid[1]/s
    local_chord=cr*(1-(1-lam)*eta)
    quarter_x=cr/4
    leading_x=quarter_x-local_chord/4
    summary=dict(case=case,subcase=int(meta["subcase"]),anglea_rad=float(meta["anglea_rad"]),
        anglea_deg=float(meta["anglea_deg"]),peak_vm_Pa=float(values[peaks]),peak_element_id=int(eid[peaks]),
        peak_fiber_sign="plus" if surfaces[peaks,1]>=surfaces[peaks,0] else "minus",
        centroid_x_m=float(centroid[0]),centroid_y_m=float(centroid[1]),centroid_z_m=float(centroid[2]),
        normalized_semispan=float(eta),local_chord_m=local_chord,
        local_chord_fraction=float((centroid[0]-leading_x)/local_chord),
        offset_from_quarter_chord_m=float(centroid[0]-quarter_x),
        offset_from_quarter_chord_over_local_chord=float((centroid[0]-quarter_x)/local_chord),
        interpretation="Raw maximum over two shell-centroid surfaces; no nodal averaging")
    del raw_v,raw_f,nodes,surfaces
    return vertices,faces,values,centroid,summary


def render_panel(ax,vertices,faces,values,peak,zoom=False):
    projected=vertices@BASIS
    if zoom:
        root_min=peak+ROOT_OFFSET_MIN
        root_max=peak+ROOT_OFFSET_MAX
        triangle_points=vertices[faces]
        keep=(triangle_points.max(axis=1)>=root_min).all(axis=1)&(triangle_points.min(axis=1)<=root_max).all(axis=1)
        faces=faces[keep]
        values=values[keep]
        del triangle_points
    # Stable depth ordering renders the original opaque triangle faces.
    # There is no interpolation between element stress values.
    order=np.argsort(projected[faces,2].mean(axis=1),kind="stable")
    polygons=projected[faces[order],:2]
    collection=PolyCollection(polygons,facecolors=CMAP(NORM(values[order]/1e6)),
        edgecolors="none",linewidths=0,antialiaseds=False,rasterized=True)
    ax.add_collection(collection)
    low,high=projected_limits(root_min,root_max,.002) if zoom else projected_limits(OVERVIEW_MIN,OVERVIEW_MAX,.03)
    ax.set(xlim=(low[0],high[0]),ylim=(low[1],high[1]),aspect="equal")
    ax.set_axis_off()
    marker=peak@BASIS
    ax.plot(marker[0],marker[1],marker="o",markersize=7 if zoom else 5,
        markerfacecolor="none",markeredgecolor="white",markeredgewidth=2,zorder=10)
    ax.plot(marker[0],marker[1],marker="o",markersize=7 if zoom else 5,
        markerfacecolor="none",markeredgecolor=".15",markeredgewidth=.65,zorder=11)
    length=.01 if zoom else .5
    start=low+np.array([.05,.065])*(high-low)
    ax.plot([start[0],start[0]+length],[start[1],start[1]],color=".15",linewidth=1.3)
    ax.text(start[0]+length/2,start[1]-.035*(high[1]-low[1]),"10 mm" if zoom else "0.5 m",
        ha="center",va="top",fontsize=8.5)
    del projected,polygons,order


parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument("--output",required=True)
parser.add_argument("--summary",help="Optional derived peak CSV output path")
args=parser.parse_args()
output=Path(args.output).resolve()
assert output.suffix.lower() in [".png",".pdf",".svg"]
assert output.parent.is_dir()
with (BASE/"cases.csv").open(encoding="utf-8",newline="") as stream:
    cases=list(csv.DictReader(stream))
assert [int(r["case"]) for r in cases]==[37,99]
plt.rcParams.update({"font.family":"serif","font.serif":["Times New Roman","DejaVu Serif"],
                     "font.size":10,"mathtext.fontset":"stix"})
fig=plt.figure(figsize=(7.48,6.40),facecolor="white")
axes=[fig.add_axes([.035,.515,.43,.355]),fig.add_axes([.52,.515,.43,.355]),
      fig.add_axes([.035,.17,.43,.25]),fig.add_axes([.52,.17,.43,.25])]
summaries=[]
for index,meta in enumerate(cases):
    print(f"Reading and rendering case {meta['case']}",flush=True)
    vertices,faces,values,peak,summary=read_case(meta)
    summaries.append(summary)
    render_panel(axes[index],vertices,faces,values,peak)
    render_panel(axes[index+2],vertices,faces,values,peak,zoom=True)
    axes[index].set_title(f"({'ab'[index]}) Case {meta['case']}: overview",fontsize=11,pad=9)
    axes[index+2].set_title(f"({'cd'[index]}) Case {meta['case']}: peak-root vicinity",fontsize=11,pad=9)
    axes[index+2].text(.5,-.04,f"Raw maximum {summary['peak_vm_Pa']/1e6:.3f} MPa; element {summary['peak_element_id']}",
        transform=axes[index+2].transAxes,ha="center",va="top",fontsize=9)
    del vertices,faces,values
    gc.collect()
bar_axes=fig.add_axes([.215,.092,.58,.023])
bar=fig.colorbar(ScalarMappable(norm=NORM,cmap=CMAP),cax=bar_axes,orientation="horizontal",ticks=[0,55,110,165,220])
bar.ax.tick_params(labelsize=9)
bar.set_label("Shell von Mises surface envelope [MPa]",fontsize=10,labelpad=2)
fig.text(.5,.963,r"Skin stress at nominal $\alpha=12^\circ$",ha="center",va="top",fontsize=13)
fig.text(.5,.932,"SOL 144 subcase 9; stored ANGLEA = 0.20944 rad",ha="center",va="top",fontsize=9)
fig.text(.5,.015,"Actual undeformed triangles; maximum of two centroid surfaces; no nodal averaging.",
    ha="center",va="bottom",fontsize=8.7)
fig.savefig(output,dpi=500,facecolor="white")
plt.close(fig)
if args.summary:
    target=Path(args.summary).resolve()
    assert target.parent.is_dir()
    with target.open("w",encoding="utf-8",newline="") as stream:
        writer=csv.DictWriter(stream,fieldnames=list(summaries[0]),lineterminator="\n")
        writer.writeheader();writer.writerows(summaries)
print(json.dumps(summaries,indent=2),flush=True)
print(f"Saved {output}",flush=True)
