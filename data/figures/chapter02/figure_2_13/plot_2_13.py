"""Reproduce Figure 2.13 from adjacent figure_2_13.csv; no CFD is run.

Requires Python 3 and Matplotlib. The CSV preserves all sampled iterations.
The history panel omits iterations 0-30 to display the retained later history.
Horizontal whiskers are observed iteration ranges, not confidence intervals.
"""
from __future__ import annotations
import csv
import argparse
from pathlib import Path
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import font_manager

HERE = Path(__file__).resolve().parent
MESHES = ["geom_coarse", "geom_medium", "geom_fine"]
COLORS = ["#666666", "#2166AC", "#C66B18"]
MARKERS = ["o", "s", "^"]
LABELS = ["Coarse", "Medium", "Fine"]

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=HERE / 'figure_2_13.png')
    args = parser.parse_args()
    with (HERE / "figure_2_13.csv").open(newline="", encoding="utf-8-sig") as stream:
        rows = [{key: value if key == "mesh_id" else float(value)
                 for key, value in r.items()} for r in csv.DictReader(stream)]
    groups = [[r for r in rows if r["mesh_id"] == mesh] for mesh in MESHES]
    assert len(rows) == 75 and all(len(g) == 25 for g in groups)
    assert all(r["monitor_reported_pass"] == 1 for r in rows)
    assert all(r["boundary_layer_extrusion_enabled"] == 0 for r in rows)
    font_names = {f.name for f in font_manager.fontManager.ttflist}
    font = "Times New Roman" if "Times New Roman" in font_names else "DejaVu Serif"
    plt.rcParams.update({"font.family": font, "font.size": 10,
                         "mathtext.fontset": "stix", "axes.linewidth": 0.8,
                         "axes.labelsize": 10.5, "svg.fonttype": "none"})
    fig = plt.figure(figsize=(7.087, 5.6), facecolor="white")
    history = fig.add_axes([0.105, 0.29, 0.465, 0.465])
    terminal = fig.add_axes([0.76, 0.29, 0.212, 0.465])
    fig.text(0.105, 0.945, "Archived full-wing CFD drag diagnostics", fontsize=12.5)
    fig.text(0.105, 0.894,
             r"NACA 65-210 coordinate input; $\alpha=7^\circ$; $U_\infty=98.68$ m s$^{-1}$",
             fontsize=10, color="#505050")
    fig.text(0.105, 0.815, "A  Total-drag history", fontsize=11)
    fig.text(0.66, 0.815, "B  Terminal mesh values", fontsize=11)
    history.axvspan(160, 240, color="#EAEAEA", alpha=0.65, linewidth=0, zorder=0)
    terminal_labels = []
    for index, (group, color, marker, label) in enumerate(zip(groups, COLORS, MARKERS, LABELS)):
        group.sort(key=lambda r: r["iteration"])
        last = group[-1]
        shown = [r for r in group if r["iteration"] >= 40]
        tail = [r for r in group if r["iteration"] >=
                last["iteration"]-last["monitor_window_iterations"]]
        history.plot([r["iteration"] for r in shown], [r["CD_total"] for r in shown],
                     color=color, linewidth=1.45, marker=marker, markersize=4.1,
                     markevery=4, markerfacecolor="white", markeredgewidth=1.0, label=label)
        lo, hi = min(r["CD_total"] for r in tail), max(r["CD_total"] for r in tail)
        cd = last["CD_total"]
        y = 2-index
        terminal.errorbar(cd, y, xerr=[[cd-lo], [hi-cd]], fmt=marker, color=color,
                          markersize=5.5, markerfacecolor="white", markeredgewidth=1.1,
                          elinewidth=1.3, capsize=3.5)
        terminal.text(cd, y+0.23, f"{cd:.5f}", color=color, fontsize=9.5,
                      ha="center", va="bottom")
        terminal_labels.append(f"{label}\n{last['cell_count']/1e6:.3f} M cells")
        print(f"{label}: {int(last['cell_count'])} cells; final CD={cd:.10f}; "
              f"last80 range=[{lo:.10f},{hi:.10f}]; original monitor passed")
    history.set_xlim(40, 248)
    history.set_ylim(0.0675, 0.079)
    history.set_xticks([40, 80, 120, 160, 200, 240])
    history.set_yticks([0.068, 0.070, 0.072, 0.074, 0.076, 0.078])
    history.set_xlabel("Steady-solver iteration", labelpad=7)
    history.set_ylabel(r"CFD total drag coefficient, $C_D$", labelpad=7)
    history.legend(loc="upper right", frameon=True, framealpha=0.95,
                   edgecolor="none", fontsize=9, handlelength=2.0)
    terminal.set_xlim(0.0675, 0.0785)
    terminal.set_ylim(-0.6, 2.65)
    terminal.set_yticks([2, 1, 0], terminal_labels)
    terminal.set_xticks([0.070, 0.075])
    terminal.set_xlabel(r"$C_D$ at iteration 240", labelpad=7)
    terminal.tick_params(axis="y", length=0, pad=6, labelsize=9.2)
    terminal.grid(axis="x", color="#E0E0E0", linewidth=0.6)
    for ax in [history, terminal]:
        ax.set_axisbelow(True)
        ax.tick_params(direction="out", width=0.8)
        for spine in ax.spines.values():
            spine.set_color("#555555")
    history.grid(True, color="#DDDDDD", linewidth=0.6)
    fig.text(0.105, 0.169,
             "Shading / whiskers: iterations 160-240 (nine samples); whiskers show ranges, not uncertainty.",
             fontsize=8.4, color="#404040")
    fig.text(0.105, 0.119,
             "All runs passed the original force-range monitor at iteration 240 (drag tolerance: 60 N).",
             fontsize=8.8, color="#303030")
    fig.text(0.105, 0.069,
             "Boundary-layer extrusion was disabled. Monitor acceptance is not experimental validation.",
             fontsize=8.8, color="#303030")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(args.output, dpi=600, facecolor="white")
    plt.close(fig)

if __name__ == "__main__":
    main()
