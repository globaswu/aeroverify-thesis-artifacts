"""Reproduce the corrected microscopic single-node example from its CSV only.

Install NumPy and Matplotlib, then run: python plot_2_3.py
Use --output PATH for PNG, PDF or SVG; default: figure_2_3_python.png.
No solver, external archive, or extra data
source is used. Skin facets are thin blue/grey edges; beams are thick orange.
The skin closure at C is retained, rather than filtered out as non-coplanar.
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
BLUE="#31639e";ORANGE="#c7611f";INK="#2c3035";GREY="#a4adb5"
plt.rcParams.update({"font.family":"DejaVu Sans","font.size":11,"text.color":INK})


def main(output):
    with (OUT/"figure_2_3.csv").open(newline="",encoding="utf-8") as f:rows=list(csv.DictReader(f))
    def pick(**conditions):return [r for r in rows if all(r[k]==v for k,v in conditions.items())]
    def xyz(data):return np.array([[float(r[k]) for k in ["x_m","y_m","z_m"]] for r in data])
    def point(role,state="original"):return xyz(pick(entity="beam_node",receiver=role,state=state))[0]
    p=xyz(pick(entity="projection",receiver="B"))[0]
    v=xyz(pick(entity="receiving_vertex",receiver="B"))
    n=np.cross(v[1]-v[0],v[2]-v[0]);n/=np.linalg.norm(n)
    if np.dot(point("B","final")-point("B"),n)<0:n=-n
    t=point("C")-point("A");t-=np.dot(t,n)*n;t/=np.linalg.norm(t)
    basis=np.column_stack([t,np.cross(n,t),n]);assert np.allclose(basis.T@basis,np.eye(3),atol=1e-12)
    local=lambda data:(xyz(data)-p)@basis*1e3
    faces=[]
    for entity in ["context_vertex","receiving_vertex"]:
        for eid in sorted({r["element_id"] for r in pick(entity=entity)},key=int):
            face=sorted(pick(entity=entity,element_id=eid),key=lambda r:int(r["vertex_index"]))
            faces.append((local(face),face[0]["receiver"] if entity=="receiving_vertex" else ""))
    old=np.array([(point(r)-p)@basis*1e3 for r in "ABC"])
    final=np.array([(point(r,"final")-p)@basis*1e3 for r in "ABC"])
    focus=local(rows)
    margins=[(.7,.9),(.3,.3),(.7,.7)]
    limits=[(focus[:,i].min()-margins[i][0],focus[:,i].max()+margins[i][1]) for i in range(3)]
    fig=plt.figure(figsize=(14,10))
    fig.text(.055,.95,"Single-node repair within the surrounding skin mesh",fontsize=20,weight="bold")
    fig.text(.055,.91,"Only B moves. A and C retain their coordinates and couple to their own skin facets.",fontsize=12)
    for col,state in enumerate(["original","final"]):
        q=old if state=="original" else final
        ax=fig.add_axes([.04+.5*col,.53,.42,.32],projection="3d",computed_zorder=False)
        for vertices,role in faces:
            ax.add_collection3d(Poly3DCollection([vertices],facecolor=BLUE if role else "#e5e8eb",
                edgecolor=BLUE if role else GREY,linewidth=1.1 if role else .6,
                alpha=.24 if role=="B" else (.12 if role else .06),zorder=1))
        ax.plot(*q.T,color=ORANGE,lw=3.5,zorder=3)
        for i,role in enumerate("ABC"):
            ax.scatter(*q[i],s=60,c=ORANGE if role=="B" and state=="final" else ("white" if role=="B" else INK),
                edgecolor=ORANGE if role=="B" else "white",depthshade=False,zorder=4)
            ax.text(q[i,0]-.16,q[i,1],q[i,2]+(.28 if role!="B" else -.45),
                role+("'" if role=="B" and state=="final" else ""),fontsize=12,weight="bold",zorder=5)
        ax.set_xlim(limits[0]);ax.set_ylim(limits[1]);ax.set_zlim(limits[2]);ax.set_proj_type("ortho")
        ax.set_box_aspect([hi-lo for lo,hi in limits],zoom=1.35);ax.view_init(elev=28,azim=-80);ax.set_axis_off()
        ax.set_title("(a) Oblique view: original" if col==0 else "(b) Oblique view: repaired",fontsize=13,pad=10)
        ax=fig.add_axes([.06+.5*col,.18,.385,.27])
        for vertices,role in faces:
            v=vertices[:,[0,2]];v=np.vstack([v,v[0]])
            ax.plot(*v.T,color=BLUE if role else GREY,lw=1.3 if role else .6,zorder=1)
        ax.plot(q[:,0],q[:,2],color=ORANGE,lw=3.5,zorder=3)
        for i,role in enumerate("ABC"):
            ax.scatter(q[i,0],q[i,2],s=60,facecolor=ORANGE if role=="B" and state=="final" else ("white" if role=="B" else INK),
                edgecolor=ORANGE if role=="B" else "white",zorder=4)
            dx=-.42 if role=="B" else (-.2 if role=="A" else .12)
            ax.text(q[i,0]+dx,q[i,2]-.28,role+("'" if role=="B" and state=="final" else ""),fontsize=12,weight="bold",zorder=5)
        # An actual orthographic side view; equal in-plane and normal scales.
        ax.set_aspect("equal");ax.set_xlim(limits[0]);ax.set_ylim(limits[2]);ax.axis("off")
        ax.set_title("(c) Side view: original" if col==0 else "(d) Side view: repaired",fontsize=13,pad=12)
        x=limits[0][0]+.15;y=limits[2][0]+.15
        ax.plot([x,x+1],[y,y],color=INK,lw=1.3);ax.text(x+.5,y-.27,"1 mm",ha="center",fontsize=10)
    correction=np.linalg.norm(point("B","final")-point("B"))*1e3
    assert np.linalg.norm(point("A","final")-point("A"))==0
    assert np.linalg.norm(point("C","final")-point("C"))==0
    fig.text(.055,.13,f"B coordinate correction: {correction:.3f} mm. C is close to the turning skin closure, not far from the entire skin.",fontsize=12,weight="bold")
    fig.text(.055,.086,"Blue: receiving skin facets for A, B and C     |     Grey: neighbouring skin-element edges     |     Orange: beam centre-lines",fontsize=11)
    fig.text(.055,.044,"Coordinate repair before analysis; not load-induced deformation. True local geometry, with no vertical exaggeration or added beam.",fontsize=10)
    output.parent.mkdir(parents=True,exist_ok=True)
    fig.savefig(output,dpi=220);plt.close(fig)
    print(f"Rendered {output.name} from figure_2_3.csv only.")


if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output",type=Path,default=OUT/"figure_2_3_python.png",
                        help="Output PNG, PDF or SVG path.")
    main(parser.parse_args().output)
