"""Reproduce Figure 2.4 from figure_2_4.csv only (NumPy and Matplotlib).

Static figure contract: compare four observed/reconstructed mesh-preparation
behaviours. Orange = beam centre-lines; grey = skin edges; blue = receiving
facets. Open/filled and dashed/solid distinguish states without colour alone.
Geometry uses orthonormal local bases, equal length scales and explicit units.
This is local postprocessing, not a solver run; no other data source is opened.
"""
import argparse
import csv
from pathlib import Path
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

OUT=Path(__file__).resolve().parent
BLUE="#31639e"; ORANGE="#c7611f"; GREY="#929aA1"; INK="#2c3035"
plt.rcParams.update({"font.family":"DejaVu Sans","font.size":11,"text.color":INK,
                     "axes.titlecolor":INK,"figure.facecolor":"white"})


def subset(rows,**conditions):
    return [r for r in rows if all(r[k]==str(v) for k,v in conditions.items())]


def xyz(rows):
    return np.asarray([[float(r[c]) for c in ["x_m","y_m","z_m"]] for r in rows])


def one(rows,role,state):
    return subset(rows,entity="node",role=role,state=state)[0]


def point(rows,role,state):
    return xyz([one(rows,role,state)])[0]


def grouped(rows,entity):
    chosen=subset(rows,entity=entity)
    return [sorted(subset(chosen,element_id=e),key=lambda r:int(r["vertex_index"]))
            for e in sorted({r["element_id"] for r in chosen},key=int)]


def basis(rows,role="B",direction=None):
    r=one(rows,role,"original");p=point(rows,role,"projection")
    v=xyz(subset(rows,entity="skin_vertex",element_id=r["element_id"]))
    n=np.cross(v[1]-v[0],v[2]-v[0]);n/=np.linalg.norm(n)
    if np.dot(p-point(rows,role,"original"),n)<0:n=-n
    if direction is None:direction=point(rows,"C","original")-point(rows,"A","original")
    t=direction-np.dot(direction,n)*n;t/=np.linalg.norm(t)
    b=np.column_stack([t,np.cross(n,t),n])
    assert np.allclose(b.T@b,np.eye(3),atol=1e-12)
    return p,b


def label(ax,q,text,offset=(0.,-.3),color=INK):
    ax.text(q[0]+offset[0],q[1]+offset[1],text,color=color,fontsize=12,weight="bold")


def upper(data):
    fig=plt.figure(figsize=(14,6.8))
    axes=np.array([[fig.add_axes([.055+.475*c,.56-.45*r,.4,.30]) for c in range(2)] for r in range(2)])
    names=["single_B_A_ordinary_C_beyond","B_rejected_length"]
    titles=["(a) Single-node repair: original","(b) Single-node repair: final",
            "(c) Length guard: proposed correction","(d) Length guard: retained mesh"]
    for row,name in enumerate(names):
        d=subset(data,example=name);p,b=basis(d)
        transform=lambda a:(a-p)@b[:,[0,2]]*1000
        old=transform(np.array([point(d,r,"original") for r in "ABC"]))
        bounds=[old[:,0].min()-.75,old[:,0].max()+.75,old[:,1].min()-.7,.85]
        for col in range(2):
            ax=axes[row,col]
            for face in grouped(d,"skin_vertex"):
                q=transform(xyz(face));q=np.vstack([q,q[0]])
                receiving=any(r and "proposed_not_receiving" not in r for r in face[0]["receiving_for"].split(";"))
                ax.plot(*q.T,color=BLUE if receiving else GREY,lw=1.4 if receiving else .55,zorder=1)
            state="original" if row==0 and col==0 else "final"
            proposal=row==1 and col==0
            if proposal:state="all_proposals"
            q=transform(np.array([point(d,r,state) for r in "ABC"]))
            ax.plot(*q.T,"--" if proposal else "-",color=ORANGE,lw=3,zorder=3)
            ax.scatter(q[[0,2],0],q[[0,2],1],s=50,c=INK,edgecolor="white",zorder=4)
            if proposal:ax.scatter(q[1,0],q[1,1],s=70,marker="x",color=ORANGE,linewidth=1.5,zorder=5)
            else:ax.scatter(q[1,0],q[1,1],s=70,marker="o",facecolor=ORANGE if row==0 and col==1 else "white",edgecolor=ORANGE,linewidth=1.5,zorder=5)
            label(ax,q[0],"A",(-.3,-.22));label(ax,q[2],"C",(.1,-.1))
            label(ax,q[1],"B*" if proposal else ("B'" if row==0 and col==1 else "B"),(.12,-.4) if proposal else (-.42,-.12),ORANGE)
            ax.set_aspect("equal");ax.set_xlim(bounds[:2]);ax.set_ylim(bounds[2:]);ax.axis("off")
            ax.set_title(titles[row*2+col],fontsize=13,pad=15)
            x,y=bounds[0]+.15,bounds[2]+.2
            ax.plot([x,x+1],[y,y],color=INK,lw=1)
            ax.text(x+.5,y-.25,"1 mm",ha="center",fontsize=9)
    d=subset(data,example=names[0]);br=one(d,"B","original");cr=one(d,"C","original")
    note=f"B moves {float(br['coordinate_correction_m'])*1e3:.3f} mm; A remains coupled; C is outside repair reach ({float(cr['projection_distance_m'])*1e3:.3f} > {float(cr['snap_tolerance_m'])*1e3:.3f} mm)."
    fig.text(.055,.475,note,fontsize=11)
    d=subset(data,example=names[1]);ids={one(d,r,"original")["grid_id"] for r in "AB"}
    members=grouped(subset(d,state="all_proposals"),"beam_endpoint")
    ab=next(e for e in members if {r["grid_id"] for r in e}==ids)
    guard=float(next(r["value"] for r in data if r["metric"]=="snap_max_beam_length_change_fraction"))
    fig.text(.06,.025,f"B* is rejected: AB would lengthen by {float(ab[0]['fractional_length_change'])*100:.1f}%, exceeding the {guard*100:.0f}% guard. B remains unchanged.",fontsize=11)
    return fig


def lower(data):
    fig=plt.figure(figsize=(14,7.3))
    d=subset(data,example="two_node");p,b=basis(d)
    trans=lambda a:(a-p)@b*1000
    allq=trans(xyz([r for r in d if r["x_m"]]));limits=[(allq[:,0].min()-.3,allq[:,0].max()+.3),
        (allq[:,1].min()-.2,allq[:,1].max()+.2),(-3.15,.5)]
    for col,state in enumerate(["original","final"]):
        ax=fig.add_axes([.04+col*.5,.52,.42,.40],projection="3d",computed_zorder=False)
        for face in grouped(d,"skin_vertex"):
            receiving=bool(face[0]["receiving_for"]);q=trans(xyz(face))
            poly=Poly3DCollection([q],facecolor=BLUE if receiving else "#dce0e4",
                edgecolor=BLUE if receiving else GREY,alpha=.22 if receiving else .1,
                linewidth=1.2 if receiving else .7,zorder=1)
            ax.add_collection3d(poly)
            if receiving:
                centre=q.mean(axis=0);role=face[0]["receiving_for"]
                centre[2]+=.30 if role=="B" else -.60
                ax.text(*centre,"$T_"+role+"$",color=BLUE,fontsize=11,ha="center",zorder=5)
        for beam in grouped(subset(d,state=state),"beam_endpoint"):
            q=trans(xyz(beam));ax.plot(*q.T,color=ORANGE,lw=3.2,zorder=3)
        for role in "ABC":
            q=trans(point(d,role,state));marker="d" if role=="C" else "o"
            fill=INK if role=="A" else (ORANGE if state=="final" else "white")
            ax.scatter(*q,c=fill,edgecolor=ORANGE,s=45,marker=marker,depthshade=False,zorder=4)
            dz=-.4 if role=="B" and state=="final" else .2
            if role=="C" and state=="original":dz=-.2
            ax.text(q[0]+.08,q[1],q[2]+dz,role+("'" if state=="final" and role!="A" else ""),fontsize=12,weight="bold",zorder=5)
        if state=="original":
            q=trans(np.array([point(d,r,"projection") for r in "BC"]))
            ax.scatter(*q.T,c=BLUE,marker="x",s=30,depthshade=False,zorder=4)
        ax.set_xlim(limits[0]);ax.set_ylim(limits[1]);ax.set_zlim(limits[2])
        ax.set_box_aspect([hi-lo for lo,hi in limits],zoom=1.65);ax.set_proj_type("ortho")
        ax.view_init(elev=25,azim=-80);ax.set_axis_off()
        ax.plot([-2.4,-1.4],[0,0],[-2.7,-2.7],color=INK,lw=1.2)
        ax.text(-1.9,0,-2.97,"1 mm",fontsize=9,ha="center")
        ax.set_title("(e) Two adjacent nodes: before repair" if col==0 else "(f) Both nodes moved to their receiving facets",fontsize=13,pad=0)
    corrections=[float(one(d,r,"original")["coordinate_correction_m"])*1000 for r in "BC"]
    fig.text(.055,.475,f"B correction: {corrections[0]:.3f} mm; C correction: {corrections[1]:.3f} mm. Two receiving triangles are highlighted.",fontsize=11)
    d=subset(data,example="finite_offset");r=one(d,"Q","original");gid=r["grid_id"]
    ends=subset(d,entity="beam_endpoint",state="original")
    other=xyz([e for e in ends if e["grid_id"]!=gid]);p,b=basis(d,"Q",other[1]-other[0])
    transform=lambda a:(a-p)@b[:,[0,2]]*1e6
    gap=float(r["projection_distance_m"])*1e6
    for col,state in enumerate(["original","final"]):
        ax=fig.add_axes([.07+.5*col,.105,.365,.29])
        for face in grouped(d,"skin_vertex"):
            q=transform(xyz(face));q=np.vstack([q,q[0]]);ax.plot(*q.T,color=BLUE,lw=1.5)
        for beam in grouped(subset(d,state=state),"beam_endpoint"):
            ax.plot(*transform(xyz(beam)).T,color=ORANGE,lw=3.2)
        q=transform(point(d,"Q",state));ax.scatter(*q,facecolor="white",edgecolor=ORANGE,s=60,zorder=5)
        ax.scatter(0,0,c=BLUE,marker="x",s=45,zorder=5)
        ax.text(-3.2,-9,"Q",fontsize=13,weight="bold");ax.text(1,1.6,"Projection p",color=BLUE,fontsize=10)
        ax.text(-21,3.7,"Receiving skin element, edge-on",color=BLUE,fontsize=10)
        ax.text(4,-5.8,f"Gap: {gap:.3f} μm",fontsize=10)
        ax.plot([-21,-16],[-13,-13],color=INK,lw=1.3);ax.text(-18.5,-14.6,"5 μm",ha="center",fontsize=9)
        ax.set_aspect("equal");ax.set_xlim(-23,23);ax.set_ylim(-15,7);ax.axis("off")
        ax.set_title("(g) Near-skin node before coupling" if col==0 else "(h) Ordinary MPC: coordinates unchanged",fontsize=13,pad=15)
    fig.text(.055,.025,f"Uniform side-view crop: the {gap:.3f} μm gap remains below the 10 μm coupling tolerance. Beam segments are cropped.",fontsize=10)
    return fig


if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output",type=Path,default=OUT/"figure_2_4.png",
                        help="Single stacked-atlas output: PNG, PDF or SVG.")
    parser.add_argument("--panels",action="store_true",
                        help="Also save separate a-d and e-h panel PNGs beside the output.")
    args=parser.parse_args()
    with (OUT/"figure_2_4.csv").open(newline="",encoding="utf-8") as f:DATA=list(csv.DictReader(f))
    for metric in ["move_classification_mismatch_count","mpc_classification_mismatch_count"]:
        assert float(next(r["value"] for r in DATA if r["metric"]==metric))==0
    panels=[upper(DATA),lower(DATA)]
    rendered=[]
    for panel in panels:
        panel.set_dpi(220);panel.canvas.draw()
        rendered.append(np.asarray(panel.canvas.buffer_rgba()).copy())
    # Keep both source figures' geometry and scale intact: stack their native
    # raster canvases without stretching. PDF/SVG embed this same HD bitmap.
    width=max(image.shape[1] for image in rendered)
    height=sum(image.shape[0] for image in rendered)
    atlas=np.full((height,width,4),255,dtype=np.uint8)
    top=0
    for raster in rendered:
        atlas[top:top+raster.shape[0],:raster.shape[1]]=raster
        top+=raster.shape[0]
    composite=plt.figure(figsize=(width/220,height/220),dpi=220)
    ax=composite.add_axes([0,0,1,1]);ax.imshow(atlas);ax.axis("off")
    args.output.parent.mkdir(parents=True,exist_ok=True)
    composite.savefig(args.output,dpi=220,pad_inches=0)
    if args.panels:
        for suffix,panel in zip(["a","b"],panels):
            panel.savefig(args.output.with_name(args.output.stem+suffix+".png"),dpi=220)
    for panel in panels+[composite]:plt.close(panel)
    print(f"Rendered {args.output.name} from figure_2_4.csv only.")
