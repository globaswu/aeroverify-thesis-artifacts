"""Render the analytical spanwise profile from the accompanying CSV only.

Usage: python plot_2_1.py [--csv PATH] [--output PATH]
Requires Python 3 and matplotlib. The nTop image is not reconstructed.
"""

from pathlib import Path
import argparse
import csv
import math

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


def main():
    folder = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--csv", type=Path, default=folder / "figure_2_1.csv")
    parser.add_argument("--output", type=Path, default=folder / "figure_2_1.png")
    args = parser.parse_args()
    with args.csv.open(newline="", encoding="utf-8-sig") as stream:
        rows = [{key: float(value) for key, value in row.items()} for row in csv.DictReader(stream)]
    assert len(rows) == 51, "Expected 51 profile samples"
    for row in rows:
        assert all(math.isfinite(value) for value in row.values())
        assert abs(row["y_m"] - row["eta"] * row["s_m"]) < 1e-12
        assert abs(row["t_m"] - (row["t1_m"] + (row["t2_m"]-row["t1_m"])*row["eta"])) < 1e-12
        assert abs(row["t_mm"] - 1e3*row["t_m"]) < 1e-10
        assert abs(row["t_over_t1"] - row["t_m"]/row["t1_m"]) < 1e-12
    assert rows[0]["eta"] == 0 and rows[-1]["eta"] == 1
    assert abs(rows[0]["t_m"]-rows[0]["t1_m"]) < 1e-12
    assert abs(rows[-1]["t_m"]-rows[-1]["t2_m"]) < 1e-12
    eta = [row["eta"] for row in rows]
    diameter = [row["t_mm"] for row in rows]
    ink, navy = "#1c2630", "#1a4266"
    plt.rcParams.update({"font.family": "serif", "font.serif": ["Times New Roman", "DejaVu Serif"], "mathtext.fontset": "stix", "font.size": 12})
    fig = plt.figure(figsize=(8.5, 4.4), facecolor="white")
    ax = fig.add_axes((0.11, 0.20, 0.84, 0.57))
    ax.plot(eta, diameter, color=navy, linewidth=1.8)
    ax.plot([eta[0], eta[-1]], [diameter[0], diameter[-1]], "o", color=navy, markerfacecolor="white", markersize=6, markeredgewidth=1.5, clip_on=False)
    ax.set(xlim=(0, 1), ylim=(0, 5), xlabel="Normalized spanwise position, $y/s$", ylabel="Geometric strut diameter, $t$ (mm)")
    ax.set_xticks([0, 0.2, 0.4, 0.6, 0.8, 1])
    ax.set_yticks([0, 1, 2, 3, 4, 5])
    ax.grid(axis="y", color="#bfc7cc", alpha=0.45)
    ax.spines[["top", "right"]].set_visible(False)
    ax.text(0.02, diameter[0]+0.18, f"$t_1$ = {diameter[0]:.4f} mm (root)", color=navy)
    ax.text(0.98, diameter[-1]-0.43, f"$t_2$ = {diameter[-1]:.4f} mm (tip)", ha="right", color=navy)
    fig.text(0.11, 0.92, "Linear spanwise lattice-strut diameter: case 55", fontsize=15, color=ink)
    fig.text(0.11, 0.82, rf"$t(y)=t_1+(t_2-t_1)y/s$;   $s$ = {rows[0]['s_m']:.5f} m;   $0\leq y\leq s$", color=ink)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(args.output, dpi=300, facecolor="white")
    plt.close(fig)
    print(f"PROFILE_PYTHON: {args.output}")
    print("VERIFIED: 51 rows, finite values, endpoints, linear law, SI conversions and normalization")


if __name__ == "__main__":
    main()
