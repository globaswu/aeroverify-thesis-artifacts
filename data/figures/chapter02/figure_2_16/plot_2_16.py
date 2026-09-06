"""Reproduce the five lift curves and signed dihedral differences from one CSV."""
from pathlib import Path
import argparse
import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt


def main(output: Path):
    folder=Path(__file__).resolve().parent
    data=np.genfromtxt(folder/'figure_2_16.csv',delimiter=',',names=True,dtype=None,encoding='utf-8')
    alpha=data['alpha_deg'].astype(float)
    assert np.array_equal(alpha,np.arange(-4,13,2)), 'Expected nine verified incidence values.'
    fields=['CL_dihedral0_on','CL_dihedral3_on','CL_dihedral0_off','CL_dihedral3_off']
    for name in fields:
        assert np.all(np.isfinite(data[name])), f'Non-finite lift coefficients: {name}'
    reference=data['CL_Sivells_TableI_linear_reference']
    assert np.max(np.abs(reference-.085*(alpha+1.3)))<1e-12
    delta_on=data['CL_dihedral3_on']-data['CL_dihedral0_on']
    delta_off=data['CL_dihedral3_off']-data['CL_dihedral0_off']
    assert np.max(np.abs(delta_on-data['delta_CL_3deg_minus_0deg_ON']))<1e-12
    assert np.max(np.abs(delta_off-data['delta_CL_3deg_minus_0deg_OFF']))<1e-12
    assert np.all(data['aerodynamic_boxes']==5500) and np.allclose(data['Mach'],.17)
    mpl.rcParams.update({'font.family':'Times New Roman','font.size':10,
        'mathtext.fontset':'stix','axes.spines.top':False,'axes.spines.right':False,
        'axes.labelsize':11,'axes.titlesize':11,'legend.fontsize':9.5,'pdf.fonttype':42})
    blue='#006FA3';orange='#C96A00';ink='#252A30';grey='#666D75'
    fig=plt.figure(figsize=(8.27,7.6),dpi=400,facecolor='white')
    fig.suptitle('Effect of dihedral and W2GJ on rigid-wing lift',
                 x=.115,y=.985,ha='left',fontweight='bold',fontsize=15,color=ink)
    fig.text(.115,.948,'Four matched rigid DLM cases; Mach 0.17; 5500 aerodynamic boxes',
             fontsize=10,color=grey)
    ax=fig.add_axes([.115,.405,.845,.485])
    handles={}
    specs=[('CL_dihedral3_on',blue,'--','o','white',6.7,'3° / W2GJ on'),
           ('CL_dihedral3_off',orange,'--','s','white',6.7,'3° / W2GJ off'),
           ('CL_dihedral0_on',blue,'-','o',blue,3.8,'0° / W2GJ on (optimization convention)'),
           ('CL_dihedral0_off',orange,'-','s',orange,3.8,'0° / W2GJ off')]
    for field,color,style,marker,face,size,label in specs:
        handles[field],=ax.plot(alpha,data[field],color=color,ls=style,lw=1.25,
            marker=marker,ms=size,mfc=face,mec=color,mew=1.0,label=label,zorder=3)
    paper,=ax.plot(alpha,reference,color=ink,lw=1.45,ls='-.',
        label='Sivells Table I reconstruction',zorder=2)
    ax.set_xlim(-4.5,12.5);ax.set_ylim(-.42,1.27)
    ax.set_xticks(np.arange(-4,13,2));ax.set_yticks(np.arange(-.4,1.21,.2))
    ax.tick_params(axis='x',labelbottom=False)
    ax.set_ylabel(r'Lift coefficient $C_L$')
    ax.grid(True,color='#DCE1E4',lw=.5,zorder=0)
    ax.set_title('A. Lift curves',loc='left',pad=9,fontweight='bold')
    ax.legend(handles=[handles['CL_dihedral0_on'],handles['CL_dihedral3_on'],
        handles['CL_dihedral0_off'],handles['CL_dihedral3_off'],paper],
        loc='upper left',bbox_to_anchor=(.008,.99),frameon=False,handlelength=3.1,labelspacing=.55)
    ax.text(.42,.07,r'Table I line: $C_L=0.085(\alpha_{\mathrm{deg}}+1.3)$'+'\n'+
        'Reconstructed from slope and zero-lift angle;\nnot individual measured points.',
        transform=ax.transAxes,color=grey,fontsize=9,va='bottom',linespacing=1.35)

    diff=fig.add_axes([.115,.151,.845,.185],sharex=ax)
    diff.axhline(0,color=ink,lw=.9,zorder=1)
    diff.plot(alpha,delta_on*1e3,'-o',color=blue,ms=4.2,lw=1.3,label='W2GJ on')
    diff.plot(alpha,delta_off*1e3,'--s',color=orange,mfc='white',ms=4.5,lw=1.3,label='W2GJ off')
    diff.set_ylim(-1.03,.41);diff.set_yticks([-1,-.5,0])
    diff.set_xlabel(r'Incidence $\alpha$ (deg)');diff.set_ylabel(r'$\Delta C_L\;(10^{-3})$')
    diff.grid(True,color='#DCE1E4',lw=.5,zorder=0)
    diff.set_title(r'B. Dihedral difference: $\Delta C_L=C_L(3^\circ)-C_L(0^\circ)$',
                   loc='left',pad=10,fontweight='bold')
    diff.legend(loc='upper right',frameon=False,ncol=2,handlelength=2.3,fontsize=9)
    maximum_on=np.max(np.abs(delta_on));maximum_off=np.max(np.abs(delta_off))
    max_angle=alpha[np.argmax(np.abs(delta_on))]
    diff.text(.018,.065,fr'Max. $|\Delta C_L|$ at {max_angle:g}°: on ${maximum_on*1e3:.3f}\times10^{{-3}}$; off ${maximum_off*1e3:.3f}\times10^{{-3}}$',
              transform=diff.transAxes,fontsize=8.5,color=grey,va='bottom')
    fig.text(.115,.074,'Fit statistics use −2° ≤ α ≤ 8°; all nine computed incidences are displayed.',
             fontsize=8.8,color=grey)
    fig.text(.115,.044,'All numerical curves are rigid benchmarks using the same historical 600-point airfoil. The 0° case follows',
             fontsize=8.6,color=ink)
    fig.text(.115,.024,'the optimization geometry/camber convention; these are not full flexible-optimization results.',
             fontsize=8.6,color=ink)
    output=output.resolve();output.parent.mkdir(parents=True,exist_ok=True)
    fig.savefig(output,dpi=400,facecolor='white')
    plt.close(fig)
    print(output)
    use=(alpha>=-2)&(alpha<=8)
    assert np.count_nonzero(use)==6
    for name in fields:
        slope,intercept=np.polyfit(alpha[use],data[name][use],1)
        rmse=np.sqrt(np.mean((data[name][use]-reference[use])**2))
        print(f"{name}: fit -2..8 deg; slope={slope:.12g}/deg; "
              f"fitted alpha0={-intercept/slope:.12g} deg; reference RMSE={rmse:.12g}")


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,default=Path(__file__).with_name('figure_2_16.png'))
    main(parser.parse_args().output)
