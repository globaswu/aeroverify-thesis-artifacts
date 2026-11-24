"""Reproduce thesis Figure 6.5 from the two archived planform projections."""
import argparse
import csv
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

here = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--output", type=Path, default=Path("figure_6_5.png"))
args = parser.parse_args()

with (here / "peak_locations.csv").open(encoding="utf-8", newline="") as stream:
    peaks = {int(row["case"]): float(row["peak_MPa"]) for row in csv.DictReader(stream)}

plt.rcParams.update({"font.family":"serif","font.serif":["Times New Roman","DejaVu Serif"],
                     "font.size":11,"axes.labelcolor":"#182833","text.color":"#182833",
                     "axes.spines.top":False,"axes.spines.right":False})
fig, axes = plt.subplots(2, 1, figsize=(6.6, 4.75), sharex=True, sharey=True)
cmap = plt.colormaps["viridis"].with_extremes(bad="white")
for ax, n, letter in zip(axes, (37, 99), ("a", "b"), strict=True):
    with np.load(here / f"case_{n:03}_plot.npz") as data:
        field = data["stress_MPa"]
        bounds = data["extent_m"]
        x, y, z = data["peak_xyz_m"]
    img = ax.imshow(field, extent=bounds, origin="lower", aspect="equal",
                    interpolation="nearest", vmin=0, vmax=160, cmap=cmap)
    ax.scatter(y, x, s=22, facecolor="white", edgecolor="#182833", zorder=3, linewidth=0.85)
    ax.annotate(f"{peaks[n]:.2f} MPa", xy=(y,x), xytext=(14,13),
                textcoords="offset points", fontsize=10,
                bbox={"facecolor":"white","edgecolor":"none","alpha":0.92,"pad":1.9},
                arrowprops={"arrowstyle":"-","color":"#182833","lw":0.7}, zorder=4)
    ax.set_title(f"({letter}) Case {n}", loc="left", fontsize=11, pad=3)
    ax.set_ylabel("Chordwise position (m)")
    ax.tick_params(labelsize=9, length=3)
axes[-1].set_xlabel("Spanwise position (m)")
axes[0].invert_yaxis()
fig.subplots_adjust(left=.13, right=.97, top=.925, bottom=.237, hspace=.30)
color_ax = fig.add_axes((.24,.103,.54,.026))
color = fig.colorbar(img, cax=color_ax, orientation="horizontal", ticks=(0,40,80,120,160))
color.set_label("Skin von Mises stress (MPa)", fontsize=10)
color.ax.tick_params(labelsize=9,length=3)
color.outline.set_linewidth(.6)
fig.savefig(args.output, dpi=400, facecolor="white")
