"""Reconstruct microscopic shell-lattice coupling from the adjacent CSV only."""
from pathlib import Path
import argparse
import csv
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

HERE = Path(__file__).resolve().parent
BLUE, GOLD, INK = '#1a5282', '#b55c12', '#2b3036'


def select(rows, entity, state=None):
    return [r for r in rows if r['entity'] == entity and (state is None or r['state'] == state)]


def xyz(rows):
    return np.array([[float(r[n]) for n in ('local_s_m', 'local_t_m', 'local_n_m')] for r in rows])


def groups(rows):
    for element in dict.fromkeys(r['element_id'] for r in rows):
        yield [r for r in rows if r['element_id'] == element]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=HERE / 'figure_2_3.png')
    args = parser.parse_args()
    with (HERE / 'figure_2_3.csv').open(encoding='utf-8-sig', newline='') as stream:
        rows = list(csv.DictReader(stream))
    plt.rcParams.update({'font.family': 'sans-serif', 'font.sans-serif': ['Arial', 'DejaVu Sans'], 'font.size': 8})
    fig = plt.figure(figsize=(9.0, 7.0), facecolor='white')
    fig.text(.04, .97, 'Microscopic shell-lattice coupling: FCC case 55', fontsize=12, weight='bold', color=INK)
    fig.text(.04, .935, 'Actual skin triangles and incident beam centrelines; geometry shown at equal scale', fontsize=9)
    examples = []
    for idx, name in enumerate(('snap_repair', 'ordinary_mpc')):
        data = [r for r in rows if r['example'] == name]
        shell = select(data, 'shell_vertex')
        q = xyz(shell) * 1000
        b0 = xyz(select(data, 'beam_node', 'original'))[0] * 1000
        bf = xyz(select(data, 'beam_node', 'final'))[0] * 1000
        weights = np.linalg.solve(np.vstack((q[:, :2].T, np.ones(3))), [0., 0., 1.])
        assert abs(weights.sum()-1) < 1e-12
        examples.append((data, b0, bf, weights))
        ax = fig.add_axes([.025 + idx*.5, .395, .45, .45], projection='3d')
        shell_ids = {r['grid_id'] for r in shell}
        for tri in groups(select(data, 'context_shell_vertex')):
            if shell_ids.intersection(r['grid_id'] for r in tri):
                ax.add_collection3d(Poly3DCollection([xyz(tri)*1000], facecolors='#cad9e6', edgecolors='#a1b0bd', linewidths=.45, alpha=.30))
        ax.add_collection3d(Poly3DCollection([q], facecolors='#669ec4', edgecolors=BLUE, linewidths=1.0, alpha=.33))
        ax.scatter(*q.T, color=BLUE, s=12)
        for j, p in enumerate(q):
            ax.text(*(p+[.08, .04, .13]), f'i={j+1}', fontsize=8, color=BLUE)
        for beam in groups(select(data, 'beam_endpoint')):
            if idx == 0:
                ax.plot(*xyz([r for r in beam if r['state']=='original']).T*1000, '--', color=GOLD, lw=1.5)
            ax.plot(*xyz([r for r in beam if r['state']=='final']).T*1000, color=INK, lw=1.8)
        ax.scatter(0, 0, 0, marker='x', color=BLUE, s=45)
        if idx == 0:
            ax.scatter(*b0, facecolors='white', edgecolors=GOLD, s=32)
            ax.scatter(*bf, marker='s', color=INK, s=20)
            ax.quiver(*b0, *(-b0), color=GOLD, arrow_length_ratio=.2, linewidth=1.2)
            ax.text(*(b0+[.18,-.3,-.12]), '$b_0$', fontsize=10, color=GOLD)
            ax.text(.22,-.2,.22, '$b_1=p$', fontsize=9)
            ax.text(.27,.1,-.72, f'{np.linalg.norm(bf-b0):.3f} mm', color=GOLD)
        else:
            ax.scatter(*bf, facecolors='none', edgecolors=GOLD, s=45)
            ax.text(.23,-.16,.2, '$b,p$', fontsize=9)
        ax.set(xlim=(-3,3), ylim=(-2.8,3.2), zlim=(-3,.55), xlabel='s (mm)', ylabel='t (mm)', zlabel='n (mm)')
        ax.set_box_aspect((6,6,3.55))
        ax.set_xticks([-2,0,2]); ax.set_yticks([-2,0,2]); ax.set_zticks([-2,0])
        ax.view_init(elev=25, azim=-32)
        ax.grid(False)
        for axis in (ax.xaxis, ax.yaxis, ax.zaxis):
            axis.pane.fill = False
        title = '(a) Guarded mesh repair: node relocation' if idx == 0 else '(b) Ordinary MPC: node position retained'
        ax.set_title(title, pad=16, fontsize=9, weight='bold')
    data, _, bf, weights = examples[1]
    inset = fig.add_axes([.545,.095,.19,.215])
    inset.plot([-7,7],[0,0], color=BLUE, lw=1.4)
    for beam in groups(select(data,'beam_endpoint','final')):
        q = xyz(beam)*1e6
        inset.plot(q[:,0],q[:,2],color=INK,lw=1.6)
    b = bf*1000
    inset.scatter(0,0,marker='x',color=BLUE,s=30)
    inset.scatter(b[0],b[2],facecolors='white',edgecolors=GOLD,s=25,zorder=4)
    inset.annotate('',(b[0],b[2]),(0,0),arrowprops={'arrowstyle':'->','color':GOLD,'lw':1.2})
    inset.text(.7,1,'p',color=BLUE); inset.text(b[0]+.9,b[2]+.1,'b',color=GOLD)
    inset.text(-2.1,-4.2,'r',color=GOLD,style='italic')
    inset.set(xlim=(-6,6),ylim=(-11,3),xlabel='s (µm)',ylabel='n (µm)',title='Offset detail (s–n)')
    inset.set_aspect('equal'); inset.spines[['top','right']].set_visible(False)
    repaired = examples[0]
    assert abs(np.linalg.norm(repaired[2]-repaired[1])/1000-.001298153657195304)<1e-12
    assert np.linalg.norm(examples[1][2]-examples[1][1]) == 0
    assert abs(np.linalg.norm(b)-8.189147025740352)<1e-6
    fig.text(.055,.355,'GRID 491572  |  shell CTRIA3 448671',fontsize=8)
    fig.text(.055,.30,'Dashed: original incident beams\nSolid: final incident beams\nOriginal $b_0$ moves onto $p$ before MPC generation.',va='top',linespacing=1.8)
    fig.text(.055,.18,'$N_i$ = ['+', '.join(f'{w:.5f}' for w in repaired[3])+']\nFinal ‖r‖ < 0.1 nm (deck rounding).\nNode IDs and graph connections are retained.',va='top',linespacing=1.8)
    fig.text(.545,.355,'GRID 472299  |  shell CTRIA3 453875',fontsize=8)
    fig.text(.775,.29,'$r=x_b-x_p$\n‖r‖ = '+f'{np.linalg.norm(b):.3f}'+' µm\nCoordinate change: 0\n'+r'$p=\sum_i N_i x_i$',va='top',linespacing=1.8)
    fig.text(.775,.15,'$N_i$ = ['+f'{weights[0]:.5f},\n{weights[1]:.5f}, {weights[2]:.5f}'+']',va='top',linespacing=1.8)
    args.output.parent.mkdir(parents=True,exist_ok=True)
    fig.savefig(args.output,dpi=300,facecolor='white')
    plt.close(fig)
    print(args.output)


if __name__ == '__main__':
    main()
