"""Reproduce Figure 2.5 using only the three CSV files beside this script.

Requirements: Python 3.10+, numpy, matplotlib. Run: python plot_2_5.py
The rigid frame, data selection, palette and six views match plot_2_5.m;
renderer-specific typography and 3-D depth ordering can differ.
"""
from pathlib import Path
import argparse
import csv
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.collections import LineCollection, PolyCollection
from matplotlib.lines import Line2D
from matplotlib.patches import Patch
from mpl_toolkits.mplot3d.art3d import Line3DCollection, Poly3DCollection

OUT = Path(__file__).resolve().parent

def read_csv(name):
    with (OUT/name).open(newline='',encoding='utf-8') as stream:
        return list(csv.DictReader(stream))

def main(output_path=None):
    nodes=read_csv('figure_2_5.csv'); beams=read_csv('chunk_beams.csv'); shell=read_csv('chunk_shell_vertices.csv')
    coords=lambda kind:np.array([[float(row[f'{kind}_{axis}_m']) for axis in 'xyz'] for row in nodes])
    original=coords('original'); final=coords('final')
    skin=np.array([[float(row[f'{axis}_m']) for axis in 'xyz'] for row in shell])
    categories=np.array([row['category'] for row in nodes]); snapped=categories=='snapped_to_shell_projection'
    assert (len(nodes),len(beams),len(shell))==(348,399,2139)
    assert tuple(np.sum(categories==kind) for kind in ['snapped_to_shell_projection','within_mpc_tolerance','rejected_snap_beam_length','beyond_snap_tolerance'])==(31,50,21,246)
    movement=np.linalg.norm(final-original,axis=1)
    assert np.all(movement[~snapped]==0)
    assert np.all(movement[snapped]>0)
    degrees=np.array([int(row['full_lattice_degree']) for row in nodes])
    assert ((degrees[snapped]==2).sum(),(degrees[snapped]==4).sum())==(29,2)
    lookup={int(row['grid_id']):i for i,row in enumerate(nodes)}
    endpoints=np.array([[lookup[int(row['grid_a'])],lookup[int(row['grid_b'])]] for row in beams])
    affected=snapped[endpoints].any(axis=1)
    assert affected.sum()==60
    assert all(int(row['local_vertex'])==i%3+1 for i,row in enumerate(shell))
    triangles=skin.reshape(-1,3,3)
    receiving=np.array([int(row['receiving_for_visible_node'])!=0 for row in shell[::3]])
    assert np.sum(receiving)==75
    normals=np.cross(triangles[:,1]-triangles[:,0],triangles[:,2]-triangles[:,0])
    normals[normals[:,2]<0]*=-1
    normal=normals.sum(axis=0);normal/=np.linalg.norm(normal)
    horizontal=np.array([1.,0.,0.])-normal[0]*normal;horizontal/=np.linalg.norm(horizontal)
    transverse=np.cross(normal,horizontal);basis=np.column_stack([horizontal,transverse,normal])
    origin=skin.mean(axis=0)
    assert np.linalg.norm(basis.T@basis-np.eye(3))<1e-12
    original=(original-origin)@basis*1000;final=(final-origin)@basis*1000;skin=(skin-origin)@basis*1000
    triangles=skin.reshape(-1,3,3)
    extent=np.vstack([original,final,skin]); limits=np.vstack([extent.min(axis=0)-[2.5,2.5,2],extent.max(axis=0)+[2.5,2.5,2]])
    # Rotate within the skin plane only. This separates depth-stacked lattice
    # rows without magnifying the movement or dropping any overview element.
    side_angle=np.deg2rad(5.)
    side_basis=np.column_stack([[np.cos(side_angle),np.sin(side_angle),0.],[0.,0.,1.]])
    original_side=original@side_basis; final_side=final@side_basis
    skin_side=skin@side_basis; triangles_side=skin_side.reshape(-1,3,2)
    side_extent=np.vstack([original_side,final_side,skin_side])
    side_limits=np.vstack([side_extent.min(0)-[2.5,2],side_extent.max(0)+[2.5,2]])
    zoom_limits=np.array([[-24.,-4.],[ -8.,.6]])
    visible_zoom=snapped & (original_side[:,0]>=zoom_limits[0,0]) & (original_side[:,0]<=zoom_limits[1,0])
    blue=(.10,.36,.67);orange=(.85,.32,.04);pale_orange=(.95,.74,.57);ink=(.19,.20,.22);outline=(.38,.17,.04)
    plt.rcParams.update({'font.family':'sans-serif','font.sans-serif':['Arial','DejaVu Sans'],'font.size':11,'text.color':ink,'axes.labelcolor':ink,'axes.edgecolor':(.55,.56,.57),'xtick.color':ink,'ytick.color':ink})
    fig=plt.figure(figsize=(16,15),facecolor='white')
    fig.text(.045,.972,'Local lattice patch before and after mesh repair',fontsize=20,weight='bold',va='top')
    fig.text(.045,.933,f'399 beams: 60 affected, 339 unchanged | 31 nodes move {movement[snapped].min()*1000:.3f}–{movement[snapped].max()*1000:.3f} mm | no added beams',fontsize=12.5,va='top')
    panel_positions=[(.045,.61,.43,.28),(.535,.61,.43,.28),(.065,.345,.39,.21),(.555,.345,.39,.21),(.065,.163,.39,.125),(.555,.163,.39,.125)]
    headings=['(a) Before nodal repair — oblique','(b) After nodal repair — oblique','(c) Before nodal repair — side','(d) After nodal repair — side','(e) Before — enlarged skin interface','(f) After — enlarged skin interface']
    for k,(position,heading) in enumerate(zip(panel_positions,headings)):
        state=original if k%2==0 else final
        marker_face='white' if k%2==0 else orange
        if k<2:
            ax=fig.add_axes(position,projection='3d',proj_type='ortho')
            ax.add_collection3d(Poly3DCollection(triangles,facecolors=(.74,.76,.78,.12),edgecolors=(.69,.71,.73,.42),linewidths=.3))
            ax.add_collection3d(Poly3DCollection(triangles[receiving],facecolors=(*blue,.36),edgecolors=(.55,.57,.59,.65),linewidths=.35))
            ax.add_collection3d(Line3DCollection(state[endpoints[~affected]],colors=pale_orange,linewidths=.75))
            ax.add_collection3d(Line3DCollection(state[endpoints[affected]],colors=orange,linewidths=1.4))
            ax.scatter(*state[snapped].T,s=30,facecolors=marker_face,edgecolors=outline,linewidths=1.25,depthshade=False)
            ax.set(xlim=limits[:,0],ylim=limits[:,1],zlim=limits[:,2],xlabel='Local x (mm)',ylabel='Local y (mm)',zlabel='Local normal (mm)')
            ax.set_box_aspect(limits[1]-limits[0],zoom=1.2);ax.view_init(elev=20,azim=-58)
            for axis in [ax.xaxis,ax.yaxis,ax.zaxis]:axis.pane.set_visible(False)
            ax.grid(False);ax.tick_params(labelsize=9,pad=0)
            ax.set_title(heading,fontsize=14,weight='bold',pad=7)
        else:
            ax=fig.add_axes(position)
            state_side=original_side if k%2==0 else final_side
            ax.add_collection(PolyCollection(triangles_side,facecolors=(.74,.76,.78,.12),edgecolors=(.69,.71,.73,.55),linewidths=.4))
            ax.add_collection(PolyCollection(triangles_side[receiving],facecolors=(*blue,.36),edgecolors=(*blue,.65),linewidths=.55))
            ax.add_collection(LineCollection(state_side[endpoints[~affected]],colors=pale_orange,linewidths=.8))
            ax.add_collection(LineCollection(state_side[endpoints[affected]],colors=orange,linewidths=1.5))
            ax.scatter(state_side[snapped,0],state_side[snapped,1],s=30 if k<4 else 45,facecolors=marker_face,edgecolors=outline,linewidths=1.25,zorder=4)
            bounds=side_limits if k<4 else zoom_limits
            ax.set(xlim=bounds[:,0],ylim=bounds[:,1],xlabel='In-plane position h (mm)',ylabel='Local normal (mm)')
            ax.set_aspect('equal',adjustable='box');ax.spines[['right','top']].set_visible(False)
            ax.set_title(heading,fontsize=14,weight='bold',pad=12)
            if k<4:
                ax.add_patch(plt.Rectangle(zoom_limits[0],*(zoom_limits[1]-zoom_limits[0]),fill=False,edgecolor=ink,linewidth=.8,linestyle='--',zorder=5))
    handles=[Line2D([],[],color=orange,lw=1.8,label='60 affected beams'),Line2D([],[],color=pale_orange,lw=1.3,label='339 unchanged beams'),Line2D([],[],color=(.64,.66,.68),lw=.7,label='Skin-element edges'),Patch(facecolor=blue,edgecolor=blue,label='Receiving skin elements'),Line2D([],[],marker='o',ls='none',markeredgecolor=outline,markerfacecolor='white',label='Node before repair'),Line2D([],[],marker='o',ls='none',markeredgecolor=outline,markerfacecolor=orange,label='Same node after repair')]
    fig.legend(handles=handles,loc='lower center',bbox_to_anchor=(.5,.083),ncol=3,frameon=False,fontsize=11)
    notes=['Identical exported connectivity before and after repair; repositioning retained nodes is not load-induced deformation.',
           'Overview panels retain all 399 beams. Dashed boxes locate the interface enlargements; lengths are unexaggerated.',
           'Side direction: h = x cos(5°) + y sin(5°). Other nodes already contact the skin; there is no uniform clearance.',
           'Data: accompanying node, beam and skin-element CSV files.']
    fig.text(.045,.065,'\n'.join(notes),fontsize=10.5,va='top',linespacing=1.4)
    output_path=Path(output_path) if output_path is not None else OUT/'figure_2_5_python.png'
    if output_path.suffix.lower() not in {'.png','.pdf','.svg'}:
        raise ValueError('Output must have a .png, .pdf, or .svg extension.')
    output_path.parent.mkdir(parents=True,exist_ok=True)
    fig.savefig(output_path,dpi=180,facecolor='white')
    plt.close(fig)
    print(f'Exported {output_path} from the three supplied CSV files.')
    print('Origin_m:',origin.tolist());print('Basis:',basis.tolist())
    print('Affected beams:',int(affected.sum()),'Unchanged beams:',int((~affected).sum()),'Moved nodes in enlargement:',int(visible_zoom.sum()))

if __name__=='__main__':
    arguments=argparse.ArgumentParser(description=__doc__)
    arguments.add_argument('--output',type=Path,help='Output PNG, PDF or SVG path; default: figure_2_5_python.png beside this script.')
    main(arguments.parse_args().output)
