"""Plot verified rigid W2GJ on/off lift from adjacent figure_2_17.csv.

Usage: python plot_2_17.py --output PATH.png
Requirements: Python 3 and Matplotlib. No solver or external input is used.
All nine source points are retained in the CSV; the figure and reported fits
use -2 to 8 degrees. The Sivells line is reconstructed from experimental
Table I slope and zero-lift angle, not digitized individual measurements.
"""
from __future__ import annotations
import argparse
import csv
import math
from pathlib import Path
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import font_manager

HERE = Path(__file__).resolve().parent

def fit(xs: list[float], ys: list[float]) -> tuple[float, float]:
    xmean, ymean = sum(xs)/len(xs), sum(ys)/len(ys)
    slope = sum((x-xmean)*(y-ymean) for x,y in zip(xs,ys)) / sum((x-xmean)**2 for x in xs)
    return slope, ymean-slope*xmean

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=HERE/"figure_2_17.png")
    args = parser.parse_args()
    with (HERE/"figure_2_17.csv").open(newline="", encoding="utf-8-sig") as stream:
        all_rows = [{key:float(value) for key,value in row.items()} for row in csv.DictReader(stream)]
    assert [r["alpha_deg"] for r in all_rows] == list(range(-4,13,2))
    for row in all_rows:
        reconstructed = row["reference_slope_per_deg"]*(row["alpha_deg"]-row["reference_zero_lift_deg"])
        assert abs(reconstructed-row["CL_Sivells_tabulated_linear_reference"]) < 1e-12
        assert abs(row["CL_W2GJ_on"]-row["CL_on_independent_force_sum"]) < 1e-6
        assert abs(row["CL_W2GJ_off"]-row["CL_off_independent_force_sum"]) < 1e-6
    rows = [r for r in all_rows if -2 <= r["alpha_deg"] <= 8]
    alpha = [r["alpha_deg"] for r in rows]
    on, off = [r["CL_W2GJ_on"] for r in rows], [r["CL_W2GJ_off"] for r in rows]
    reference_slope = rows[0]["reference_slope_per_deg"]
    reference_zero = rows[0]["reference_zero_lift_deg"]
    dense_alpha = [-2+10*k/500 for k in range(501)]
    reference = [reference_slope*(a-reference_zero) for a in dense_alpha]
    fonts = {font.name for font in font_manager.fontManager.ttflist}
    family = "Times New Roman" if "Times New Roman" in fonts else "DejaVu Serif"
    plt.rcParams.update({"font.family":family, "font.size":10.5, "mathtext.fontset":"stix",
                         "axes.labelsize":11, "axes.linewidth":0.8, "xtick.labelsize":10,
                         "ytick.labelsize":10, "legend.fontsize":9.5, "svg.fonttype":"none"})
    fig, ax = plt.subplots(figsize=(7.087,4.75), facecolor="white")
    fig.subplots_adjust(left=0.12,right=0.975,bottom=0.145,top=0.83)
    ax.plot(dense_alpha,reference,color="#333333",linestyle=(0,(5,3)),linewidth=1.55,
            label="Sivells (1947), Table I: linear reconstruction",zorder=2)
    ax.plot(alpha,on,"-s",color="#2166AC",linewidth=1.6,markersize=5.6,
            markerfacecolor="white",markeredgewidth=1.2,label="Rigid W2GJ on",zorder=4)
    ax.plot(alpha,off,"-.o",color="#C66B18",linewidth=1.55,markersize=5.6,
            markerfacecolor="white",markeredgewidth=1.2,label="Rigid W2GJ off",zorder=3)
    ax.set_xlim(-2.25,8.25)
    ax.set_ylim(-0.24,0.94)
    ax.set_xticks(alpha)
    ax.set_yticks([-0.2,0,0.2,0.4,0.6,0.8])
    ax.set_xlabel(r"Root-chord incidence, $\alpha$ (deg)",labelpad=7)
    ax.set_ylabel(r"Wing lift coefficient, $C_L$",labelpad=7)
    ax.grid(True,color="#E0E0E0",linewidth=0.6)
    ax.set_axisbelow(True)
    ax.axhline(0,color="#A8A8A8",linewidth=0.7,zorder=1)
    ax.tick_params(direction="out",length=3.5,width=0.8)
    for spine in ax.spines.values(): spine.set_color("#555555")
    ax.legend(loc="upper left",frameon=True,facecolor="white",framealpha=0.97,
              edgecolor="none",borderpad=0.55,labelspacing=0.65,handlelength=2.9)
    fig.text(0.12,0.94,"Rigid-wing W2GJ camber control",fontsize=12.5,
             color="#202020",ha="left",va="center")
    fig.text(0.12,0.886,
             r"Matched on/off pair; $M=0.17$; $3^\circ$ dihedral; $110\times50$ aerodynamic boxes",
             fontsize=9.8,color="#505050",ha="left",va="center")
    args.output.parent.mkdir(parents=True,exist_ok=True)
    fig.savefig(args.output,dpi=600,facecolor="white")
    plt.close(fig)
    for name,values in [("on",on),("off",off)]:
        slope,intercept = fit(alpha,values)
        rmse = math.sqrt(sum((y-reference_slope*(a-reference_zero))**2
                             for a,y in zip(alpha,values))/len(alpha))
        print(f"W2GJ {name}: slope={slope:.12g}/deg; fitted alpha0={-intercept/slope:.12g} deg; "
              f"CL(0)={values[alpha.index(0)]:.12g}; RMSE to reconstructed line={rmse:.12g}")
    print(f"Wrote {args.output}")

if __name__ == "__main__": main()
