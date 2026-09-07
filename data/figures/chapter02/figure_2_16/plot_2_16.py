"""Draw the complete W2GJ box-detail diagram from one adjacent CSV."""
from pathlib import Path
import argparse
import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle


def main(output: Path):
    folder = Path(__file__).resolve().parent
    data = np.genfromtxt(folder/'figure_2_16.csv',delimiter=',',names=True)
    assert len(data)==4001 and np.all(np.isfinite(data['x_over_c']))
    controls = data[data['box_j_zero_based']>=0]
    assert len(controls)==50
    assert np.max(np.abs(controls['control_x_over_c']-(controls['box_j_zero_based']+.75)/50))<1e-12
    assert np.max(np.abs(controls['control_W2GJ']+controls['control_dzc_dx']))<1e-12
    assert np.max(np.abs(data['z_camber_over_c']-.5*(data['z_upper_over_c']+data['z_lower_over_c'])))<1e-12
    selected = controls[(controls['box_j_zero_based']>=35)&(controls['box_j_zero_based']<=39)]
    xstar=selected['control_x_over_c']; zstar=selected['control_z_camber_over_c']
    slopes=selected['control_dzc_dx']; w2gj=selected['control_W2GJ']
    assert np.max(np.abs(slopes+w2gj))<1e-12
    M,N=110,50
    mpl.rcParams.update({'font.family':'Times New Roman','font.size':9,
        'mathtext.fontset':'stix','axes.labelsize':9,'axes.titlesize':10,
        'axes.spines.top':False,'axes.spines.right':False,'pdf.fonttype':42})
    ink='#252A30'; grey='#687079'; blue='#006FA3'; gold='#B98200'; pale='#FFF3D2'
    fig=plt.figure(figsize=(8.27,10.4),dpi=400,facecolor='white')
    fig.suptitle('W2GJ at individual aerodynamic-box control points',
                 x=.075,y=.982,ha='left',fontsize=15,fontweight='bold',color=ink)
    fig.text(.075,.951,'NACA 65-210 mean-camber input to a planar lifting surface',
             fontsize=10,color=grey)

    grid=fig.add_axes([.075,.655,.325,.325*8.27/10.4])
    grid.set_xlim(0,1);grid.set_ylim(0,1)
    grid.set_aspect('equal',adjustable='box')
    for i in range(N+1): grid.axvline(i/N,color='#C3CBD0',lw=.28,zorder=0)
    for i in range(M+1): grid.axhline(i/M,color='#C3CBD0',lw=.28,zorder=0)
    grid.add_patch(Rectangle((.7,0),.1,1,facecolor=pale,alpha=.7,edgecolor=gold,lw=.8,zorder=1))
    for j in range(35,40):
        grid.add_patch(Rectangle((j/N,55/M),1/N,1/M,facecolor=gold,edgecolor='white',lw=.4,zorder=3))
    grid.set_xticks([0,.2,.4,.6,.8,1]);grid.set_yticks([0,.5,1])
    grid.set_xlabel(r'Local chord coordinate $\xi=x/c$')
    grid.set_ylabel(r'Normalized span coordinate $\eta=y/s$')
    grid.set_title('A. Planar aerodynamic-box grid',loc='left',pad=12,fontweight='bold')
    grid.annotate('five adjacent chord panels',xy=(.75,.51),xytext=(.13,.77),
        color=ink,fontsize=8.5,ha='left',va='center',
        bbox=dict(fc='white',ec='none',pad=2),
        arrowprops=dict(arrowstyle='->',color=gold,lw=1.1))
    fig.text(.445,.885,r'$M=N_{\mathrm{span}}=110$'+'\n'+r'$N=N_{\mathrm{chord}}=50$',
             fontsize=12,color=ink,linespacing=1.7)
    fig.text(.445,.827,'50 chordwise values repeat\nacross 110 spanwise strips.\nChordwise index varies fastest.',
             fontsize=9,color=ink,linespacing=1.45)
    fig.text(.445,.758,r'Planar CAERO1 surface: $z=0$'+'\n'+
             'Grid shown in local coordinates.',
             fontsize=9,color=grey,linespacing=1.3)
    fig.text(.445,.718,r'For every box $j=0,\ldots,N-1$:',fontsize=9,color=ink)
    fig.text(.445,.676,r'$\xi_j^{*}=\dfrac{j+0.75}{N}$',fontsize=12,color=ink)
    fig.text(.445,.624,r'$\mathrm{W2GJ}_{j}=-\left.\dfrac{\mathrm{d}\zeta_c}{\mathrm{d}\xi}\right|_{\xi_j^{*}}$',
             fontsize=12,color=ink)

    left=.7;right=.8
    mask=(data['x_over_c']>=left)&(data['x_over_c']<=right)
    xx=data['x_over_c'][mask];zu=data['z_upper_over_c'][mask]
    zl=data['z_lower_over_c'][mask];zc=data['z_camber_over_c'][mask]
    ax=fig.add_axes([.075,.313,.405,.255])
    ax.fill_between(xx,zl,zu,color='#EDF1F3',zorder=0)
    ax.plot(xx,zu,color=ink,lw=1.1,label='Upper/lower section')
    ax.plot(xx,zl,color=ink,lw=1.1)
    ax.plot(xx,zc,'--',color=gold,lw=1.2,label='Mean camber')
    ax.axhline(0,color=blue,lw=1.0,label='Planar aerodynamic surface')
    for j in range(35,41): ax.axvline(j/N,color='#A5ADB3',ls=':',lw=.6)
    for x,z,s in zip(xstar,zstar,slopes):
        ax.plot([x,x],[0,z],':',color=gold,lw=.8)
        delta=np.array([-.007,.007]); ax.plot(x+delta,z+s*delta,color=gold,lw=1.5)
    ax.scatter(xstar,np.zeros(5),s=20,c=blue,zorder=5)
    ax.scatter(xstar,zstar,s=22,facecolor='white',edgecolor=gold,zorder=5)
    ax.set_xlim(left,right);ax.set_ylim(-.030,.050);ax.set_aspect('equal',adjustable='box')
    ax.set_xticks(np.arange(.7,.801,.02));ax.set_yticks([-.02,0,.02,.04])
    ax.set_xlabel(r'$\xi=x/c$');ax.set_ylabel(r'$\zeta=z/c$')
    ax.set_title('B. Source section and control locations\nEqual chordwise/vertical geometric scales',
                 loc='left',pad=12,fontweight='bold',fontsize=9.5)
    ax.text(.703,.034,'upper surface',color=grey,fontsize=8)
    ax.text(.703,-.028,'lower surface',color=grey,fontsize=8)
    ax.text(.703,.003,'planar control points',color=blue,fontsize=8)
    for j in range(35,40):ax.text((j+.5)/N,.047,f'$j={j}$',ha='center',fontsize=7.7,color=ink)

    detail_position=[.575,.355,.375,.185]
    detail=fig.add_axes(detail_position)
    detail.set_xlim(left,right);detail.set_ylim(.00865,.01035)
    for j in range(35,41):detail.axvline(j/N,color='#A5ADB3',ls=':',lw=.6)
    detail.plot(xx,zc,'--',color=gold,lw=1.1)
    for j,x,z,s in zip(range(35,40),xstar,zstar,slopes):
        delta=np.array([-.0075,.0075])
        detail.plot(x+delta,z+s*delta,color=gold,lw=1.9)
        detail.annotate(str(j),xy=(x,z),xytext=(-2,10),textcoords='offset points',
                        ha='center',fontsize=8,color=ink)
    detail.scatter(xstar,zstar,s=24,facecolor='white',edgecolor=gold,zorder=5)
    detail.set_xticks(np.arange(.7,.801,.02))
    detail.set_yticks([.009,.0095,.01])
    detail.ticklabel_format(axis='y',style='plain',useOffset=False)
    detail.set_xlabel(r'$\xi=x/c$');detail.set_ylabel(r'Mean camber $\zeta_c=z_c/c$')
    magnification=(detail_position[3]*10.4/(.01035-.00865))/(detail_position[2]*8.27/(right-left))
    detail.set_title(f'C. Mean-camber tangents\nVertical scale magnified ×{magnification:.1f}',
                     loc='left',pad=14,fontweight='bold',fontsize=9.5)
    fig.text(.575,.308,'Open circles: mean-camber samples\nSolid gold segments: local tangents\nBlue circles in B: planar application points',
             fontsize=8.3,color=grey,linespacing=1.4,va='top')
    fig.text(.075,.260,r'$\zeta_c=(\zeta_{\mathrm{upper}}+\zeta_{\mathrm{lower}})/2$;  '+
             r'$\mathrm{d}\zeta_c/\mathrm{d}\xi=\mathrm{d}z_c/\mathrm{d}x$.',fontsize=10,color=ink)

    table_ax=fig.add_axes([.075,.111,.875,.117]);table_ax.set_axis_off()
    row_labels=[r'Box index $j$',r'Control $\xi_j^{*}$',r'Slope $\mathrm{d}z_c/\mathrm{d}x$',r'$\mathrm{W2GJ}_{j}$']
    table_rows=[[row_labels[0]]+[str(j) for j in range(35,40)],
                [row_labels[1]]+[f'{x:.3f}' for x in xstar],
                [row_labels[2]]+[f'{s:+.7f}' for s in slopes],
                [row_labels[3]]+[f'{w:+.7f}' for w in w2gj]]
    tab=table_ax.table(cellText=table_rows,cellLoc='center',colWidths=[.25]+[.15]*5,
                       bbox=[0,0,1,1])
    tab.auto_set_font_size(False);tab.set_fontsize(9)
    for (r,c),cell in tab.get_celld().items():
        cell.set_edgecolor('#D2D7DB');cell.set_linewidth(.6)
        cell.set_facecolor('#F1F4F5' if r==0 else 'white')
        if c==0:cell.set_text_props(ha='left',color=ink)
        elif r==3:cell.set_text_props(color=blue)
    fig.text(.075,.238,'Calculated values for the five selected chordwise boxes',fontsize=10,fontweight='bold',color=ink)
    fig.text(.075,.070,'Mean camber supplies a normal-flow boundary-condition correction; it does not deform the planar surface.',
             fontsize=8.7,color=ink)
    fig.text(.075,.044,'These box control points are separate from the quarter-chord lifting line and its ten spanwise stations.',
             fontsize=8.7,color=grey)
    output=output.resolve();output.parent.mkdir(parents=True,exist_ok=True)
    fig.savefig(output,dpi=400,facecolor='white')
    plt.close(fig)
    print(output)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,default=Path(__file__).with_name('figure_2_16.png'))
    main(parser.parse_args().output)
