"""Visualize native beam-element stress with a supported planform interpolation."""
import argparse
import csv
import json
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import PowerNorm
from matplotlib.path import Path as PolygonPath
import numpy as np
from scipy.ndimage import distance_transform_edt, gaussian_filter
from scipy.spatial import ConvexHull

DATA = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--output", type=Path, required=True, help="Destination PDF or PNG")
args = parser.parse_args()
CASES = (18, 33, 66)
DESCRIPTIONS = {18: "FCC 18a", 33: "BCC 33a", 66: "SC 66a"}
STEP_M = 0.0025
SIGMA_M = 0.010
SUPPORT_M = 0.030
LIMIT_MPA = 200
GAMMA = 0.55


def read_inputs():
    with (DATA / "peak_locations.csv").open(encoding="utf-8-sig", newline="") as file:
        table = {int(row["case_id"]): row for row in csv.DictReader(file)}
    entries = {}
    for case in CASES:
        row = table[case]
        assert int(row["subcase"]) == 9 and float(row["incidence_deg"]) == 12
        with np.load(DATA / f"case_{case:03}_cbeam_planform.npz", allow_pickle=False) as file:
            beams = file["span_chord_endpoints_m"]
            stress = file["peak_normal_stress_MPa"]
            ids = file["element_id"]
        peak = int(stress.argmax())
        assert beams.shape == (int(row["beam_elements"]), 2, 2)
        assert np.isfinite(beams).all() and np.isfinite(stress).all() and stress.min() >= 0
        assert np.isclose(stress[peak], float(row["peak_MPa"]), atol=1e-6, rtol=0)
        assert int(ids[peak]) == int(row["peak_element_id"])
        assert np.allclose(beams[peak].mean(axis=0), (float(row["peak_span_m"]), float(row["peak_chord_m"])),
                           atol=1e-8, rtol=0)
        entries[case] = (beams, stress, peak, ids)
    return entries


def interpolate(beams, stress, origin, nx, ny, inside_points, planform):
    """Rasterize beam stresses, then fill supported neighborhoods by normalized filtering."""
    raster = np.full(nx * ny, -np.inf)
    # Sample each beam at less than half a pixel in the projection.
    # Each populated pixel retains its highest native member stress.
    for start in range(0, len(beams), 8_000):
        part = beams[start:start + 8_000]
        vector = part[:, 1] - part[:, 0]
        steps = np.maximum(1, np.ceil(np.linalg.norm(vector, axis=1) / (STEP_M / 2)).astype(int))
        lengths = steps + 1
        owners = np.repeat(np.arange(len(part)), lengths)
        index = np.arange(lengths.sum()) - np.repeat(np.cumsum(lengths) - lengths, lengths)
        xy = part[owners, 0] + (index / steps[owners])[:, None] * vector[owners]
        pixel = np.floor((xy - origin) / STEP_M).astype(int)
        keep = (pixel[:, 0] >= 0) & (pixel[:, 0] < nx) & (pixel[:, 1] >= 0) & (pixel[:, 1] < ny)
        assert keep.all()
        flat = pixel[:, 1] * nx + pixel[:, 0]
        np.maximum.at(raster, flat, stress[start + owners])

    raster = raster.reshape(ny, nx)
    populated = np.isfinite(raster)
    assert np.isclose(raster[populated].max(), stress.max(), atol=1e-6, rtol=0)
    sigma_pixels = SIGMA_M / STEP_M
    weights = gaussian_filter(populated.astype(float), sigma_pixels, mode="constant", truncate=3)
    weighted = gaussian_filter(np.where(populated, raster, 0.0), sigma_pixels, mode="constant", truncate=3)
    distance = distance_transform_edt(~populated, sampling=STEP_M)
    hull_points = planform.reshape(-1, 2)
    hull = ConvexHull(hull_points)
    polygon = hull_points[hull.vertices]
    path = PolygonPath(np.vstack((polygon, polygon[0])), closed=True)
    inside = path.contains_points(inside_points, radius=STEP_M / 3).reshape(ny, nx)
    valid = inside & (distance <= SUPPORT_M) & (weights > 1e-7)
    field = np.full((ny, nx), np.nan)
    np.divide(weighted, weights, out=field, where=valid)
    assert valid.sum() > 0 and np.nanmax(field) <= stress.max() + 1e-6
    return field, valid, populated


def main():
    entries = read_inputs()
    screen = json.loads((DATA/"interpolation_outlier_screen.json").read_text(encoding="utf-8"))
    exclusions = screen["flagged"]
    assert all(row["case_id"] in entries for row in exclusions)
    xy = np.concatenate([x[0].reshape(-1, 2) for x in entries.values()])
    origin = np.floor((xy.min(axis=0) - (0.025, 0.04)) / STEP_M) * STEP_M
    last = xy.max(axis=0) + (0.058, 0.04)
    nx, ny = np.ceil((last - origin) / STEP_M).astype(int)
    cap = origin + STEP_M * np.array((nx, ny))
    X, Y = np.meshgrid(origin[0] + (np.arange(nx) + .5) * STEP_M,
                       origin[1] + (np.arange(ny) + .5) * STEP_M)
    queries = np.column_stack((X.ravel(), Y.ravel()))
    extent = (origin[0], cap[0], origin[1], cap[1])

    plt.rcParams.update({"font.family": "serif", "font.serif":["Times New Roman","DejaVu Serif"],
                         "font.size": 10, "axes.labelcolor": "#20343f", "text.color": "#20343f",
                         "axes.spines.top": False, "axes.spines.right": False, "pdf.fonttype": 42})
    fig, axes = plt.subplots(3, 1, figsize=(7.35, 8.60), sharex=True, sharey=True)
    fig.text(.5, .985, "Beam stress after joint refinement at 12° incidence", ha="center", va="top", fontsize=11)
    norm = PowerNorm(gamma=GAMMA, vmin=0, vmax=LIMIT_MPA, clip=True)
    cmap = plt.colormaps["turbo"].with_extremes(bad="white")
    for i, (ax, case) in enumerate(zip(axes, CASES, strict=True)):
        beams, stress, peak, ids = entries[case]
        excluded_ids = [row["element_id"] for row in exclusions if row["case_id"]==case]
        rejected = np.isin(ids, excluded_ids)
        assert int(rejected.sum())==len(excluded_ids)
        field, valid, populated = interpolate(beams[~rejected], stress[~rejected], origin, nx, ny,
                                              queries, beams)
        display = ax.imshow(field, extent=extent, origin="lower", norm=norm, cmap=cmap,
                            interpolation="bilinear", aspect="equal")
        position = beams[peak].mean(axis=0)
        if not rejected[peak]:
            ax.plot(*position, marker="o", markersize=6.1, markerfacecolor="white",
                    markeredgecolor="#20343f", markeredgewidth=.75, zorder=4)
        if rejected.any():
            flagged = beams[rejected].mean(axis=1)
            ax.scatter(*flagged.T,s=30,facecolor="#d71625",edgecolor="white",linewidth=.8,zorder=5)
        offset = {18: (12, -8), 33: (14, 9), 66: (12, 10)}[case]
        ax.annotate(f"{stress[peak]:.2f} MPa", xy=position, xytext=offset, textcoords="offset points",
                    ha="left", va="top" if case==18 else "bottom", fontsize=9, zorder=6,
                    bbox={"facecolor":"white", "edgecolor":"none", "alpha":.93, "pad":1.7},
                    arrowprops={"arrowstyle":"-", "color":"#20343f", "linewidth":.62})
        ax.set_title(f"({chr(97+i)}) {DESCRIPTIONS[case]}", loc="left", fontsize=10.5, pad=4)
        ax.set_ylabel("Chordwise position (m)")
        ax.tick_params(length=3,labelsize=8.5)
        print(f"Case {case}: {int(populated.sum()):,} occupied cells, "
              f"interpolated range {np.nanmin(field):.2f} to {np.nanmax(field):.2f} MPa, "
              f"native peak {stress[peak]:.2f} MPa; {int(rejected.sum())} excluded")
    axes[0].set_ylim(cap[1], origin[1])
    axes[-1].set_xlabel("Spanwise position (m)")
    fig.subplots_adjust(left=.115, right=.975, bottom=.167, top=.937, hspace=.29)
    color_ax = fig.add_axes((.24,.082,.56,.019))
    bar = fig.colorbar(display,cax=color_ax,orientation="horizontal",ticks=(0,10,25,50,100,150,200))
    bar.set_label("Interpolated absolute CBEAM normal stress (MPa)")
    bar.outline.set_linewidth(.65)
    color_ax.tick_params(labelsize=8.5,length=3)
    fig.text(.5,.019, "Red dots identify excluded elements. Labels show native peaks." if exclusions
             else "Open circles mark native element peaks. Colour uses a shared nonlinear scale.",
             ha="center", fontsize=8.5, color="#435763")
    fig.savefig(args.output, facecolor="white", dpi=400 if args.output.suffix==".pdf" else 240)
    plt.close(fig)


if __name__ == "__main__":
    main()
