from pathlib import Path

import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib.patches import Arc, FancyArrowPatch, FancyBboxPatch, Polygon
import numpy as np


def load_airfoil_data(script_dir: Path) -> np.ndarray:
    """Load the ordered normalized section outline from the adjacent CSV."""
    data = np.loadtxt(script_dir / "figure_2_4.csv", delimiter=",", skiprows=1)
    if data.ndim != 2 or data.shape[1] != 2 or len(data) < 6:
        raise ValueError("Expected ordered x_over_c,z_over_c coordinates.")
    if not np.all(np.isfinite(data)):
        raise ValueError("Airfoil coordinates must be finite.")
    if not (np.isclose(data[:, 0].min(), 0.0) and np.isclose(data[:, 0].max(), 1.0)):
        raise ValueError("Airfoil coordinates must span x/c=0 to x/c=1.")
    return data


def rotated_airfoil(alpha_deg: float, foil: np.ndarray) -> np.ndarray:
    """Rotate the repository profile about x/c=0.25 without changing geometry."""
    outline = foil.copy()
    outline[:, 0] -= 0.25
    angle = np.deg2rad(alpha_deg)
    rotation = np.array(
        [[np.cos(angle), -np.sin(angle)], [np.sin(angle), np.cos(angle)]]
    )
    return outline @ rotation.T


def add_flow_box(ax, x, width, text, edge, fill):
    box = FancyBboxPatch(
        (x, 0.20),
        width,
        0.60,
        boxstyle="round,pad=0.012,rounding_size=0.018",
        linewidth=0.9,
        edgecolor=edge,
        facecolor=fill,
        transform=ax.transAxes,
    )
    ax.add_patch(box)
    ax.text(
        x + width / 2,
        0.50,
        text,
        ha="center",
        va="center",
        fontsize=8.4,
        color=edge,
        transform=ax.transAxes,
    )


def main(output_path: Path) -> None:
    script_dir = Path(__file__).resolve().parent
    foil = load_airfoil_data(script_dir)

    mpl.rcParams.update(
        {
            "font.family": "Times New Roman",
            "font.size": 9.4,
            "mathtext.fontset": "custom",
            "mathtext.rm": "Times New Roman",
            "mathtext.it": "Times New Roman:italic",
            "mathtext.bf": "Times New Roman:bold",
            "axes.unicode_minus": False,
            "pdf.fonttype": 42,
            "ps.fonttype": 42,
        }
    )

    ink = (0.12, 0.14, 0.16)
    grey = (0.42, 0.45, 0.48)
    light_grey = (0.73, 0.76, 0.78)
    blue = (0.00, 0.45, 0.70)
    gold = (0.90, 0.62, 0.00)
    fill_color = (0.90, 0.94, 0.96)
    pale_gold = (0.99, 0.96, 0.86)

    fig = plt.figure(figsize=(7.09, 5.90), dpi=300, facecolor="white")
    grid = fig.add_gridspec(
        3,
        1,
        height_ratios=[3.10, 2.05, 1.00],
        left=0.035,
        right=0.985,
        bottom=0.025,
        top=0.965,
        hspace=0.12,
    )
    planform_ax = fig.add_subplot(grid[0, 0])
    section_ax = fig.add_subplot(grid[1, 0])
    flow_ax = fig.add_subplot(grid[2, 0])

    # Panel A: implemented half-span collocation shown on the symmetric planform.
    span_coordinate = np.linspace(-1.0, 1.0, 501)
    chord = 0.28 + 0.34 * (1.0 - np.abs(span_coordinate))
    leading_edge = 0.25 * chord
    trailing_edge = -0.75 * chord
    planform_ax.fill_between(
        span_coordinate, trailing_edge, leading_edge, color=fill_color, linewidth=0
    )
    planform_ax.plot(span_coordinate, leading_edge, color=ink, linewidth=1.25)
    planform_ax.plot(span_coordinate, trailing_edge, color=ink, linewidth=1.25)
    planform_ax.plot(
        [-1.0, -1.0],
        [trailing_edge[0], leading_edge[0]],
        color=ink,
        linewidth=1.25,
    )
    planform_ax.plot(
        [1.0, 1.0],
        [trailing_edge[-1], leading_edge[-1]],
        color=ink,
        linewidth=1.25,
    )
    planform_ax.plot([-1.0, 1.0], [0.0, 0.0], "--", color=grey, linewidth=1.0)
    planform_ax.plot([0.0, 0.0], [-0.49, 0.18], ":", color=grey, linewidth=0.9)

    station_count = 10
    phi = np.arange(1, station_count + 1) * np.pi / (2 * station_count + 1)
    half_span_stations = np.cos(phi)
    for side in (-1.0, 1.0):
        station_span = side * half_span_stations
        station_chord = 0.28 + 0.34 * (1.0 - np.abs(station_span))
        for station, local_chord in zip(station_span, station_chord):
            station_color = blue if side > 0 else light_grey
            planform_ax.plot(
                [station, station],
                [-0.75 * local_chord, 0.25 * local_chord],
                color=station_color,
                alpha=0.46 if side > 0 else 0.32,
                linewidth=0.55,
            )
        if side > 0:
            planform_ax.scatter(
                station_span,
                np.zeros_like(station_span),
                s=18,
                color=blue,
                edgecolor="white",
                linewidth=0.4,
                zorder=4,
            )
        else:
            planform_ax.scatter(
                station_span,
                np.zeros_like(station_span),
                s=16,
                facecolor="white",
                edgecolor=light_grey,
                linewidth=0.8,
                zorder=4,
            )

    highlight_index = 5
    highlighted_span = half_span_stations[highlight_index]
    highlighted_chord = 0.28 + 0.34 * (1.0 - highlighted_span)
    local_chord_arrow = FancyArrowPatch(
        (highlighted_span, -0.75 * highlighted_chord),
        (highlighted_span, 0.25 * highlighted_chord),
        arrowstyle="<->",
        mutation_scale=8,
        color=gold,
        linewidth=1.7,
    )
    planform_ax.add_patch(local_chord_arrow)
    planform_ax.text(
        highlighted_span + 0.045,
        -0.18,
        r"$c_i=c(y_i)$",
        color=ink,
        va="center",
        ha="left",
    )

    planform_ax.annotate(
        "",
        xy=(-1.10, -0.31),
        xytext=(-1.10, 0.20),
        arrowprops={"arrowstyle": "-|>", "color": ink, "lw": 1.0},
    )
    planform_ax.text(-1.10, 0.24, r"$V_\infty$", ha="center", color=ink)
    planform_ax.text(-0.98, 0.035, "quarter-chord lifting line", color=grey, fontsize=8.2)
    planform_ax.text(0.025, 0.17, "root plane", color=grey, fontsize=8.0, rotation=90, va="top")

    dimension_y = -0.56
    planform_ax.plot([0.0, 1.0], [dimension_y, dimension_y], color=ink, linewidth=0.8)
    planform_ax.plot([0.0, 0.0], [dimension_y - 0.035, dimension_y + 0.035], color=ink, linewidth=0.8)
    planform_ax.plot([1.0, 1.0], [dimension_y - 0.035, dimension_y + 0.035], color=ink, linewidth=0.8)
    planform_ax.text(0.50, dimension_y - 0.055, r"$s=b/2$", ha="center", va="top")
    planform_ax.text(
        0.50,
        -0.70,
        r"$\phi_i=i\pi/(2N+1),\quad y_i=s\cos\phi_i,\quad i=1,\ldots,N,\quad N=10$",
        ha="center",
        va="top",
        fontsize=8.5,
    )
    planform_ax.text(
        0.55,
        0.34,
        "filled: implemented half-span stations; open: symmetry mirror",
        color=blue,
        fontsize=7.9,
        ha="center",
    )
    planform_ax.set_title(
        "A. Cosine-spaced planform collocation",
        loc="left",
        fontweight="bold",
        fontsize=9.6,
        pad=5,
    )
    planform_ax.set_xlim(-1.17, 1.10)
    planform_ax.set_ylim(-0.79, 0.43)
    planform_ax.set_axis_off()

    # Panel B: local section angle supplied to the Fourier system.
    alpha_global = 11.0
    alpha_effective = 6.0
    section = rotated_airfoil(alpha_effective, foil)
    section_ax.add_patch(
        Polygon(section, closed=True, facecolor=fill_color, edgecolor=ink, linewidth=1.2)
    )
    chord_start = np.array([-0.25, 0.0])
    chord_end = np.array([0.75, 0.0])
    angle_eff_rad = np.deg2rad(alpha_effective)
    rotation_eff = np.array(
        [[np.cos(angle_eff_rad), -np.sin(angle_eff_rad)], [np.sin(angle_eff_rad), np.cos(angle_eff_rad)]]
    )
    local_line = np.vstack([chord_start, chord_end]) @ rotation_eff.T
    section_ax.plot(local_line[:, 0], local_line[:, 1], color=blue, linewidth=1.1)

    angle_global_rad = np.deg2rad(alpha_global)
    global_end = np.array([0.72 * np.cos(angle_global_rad), 0.72 * np.sin(angle_global_rad)])
    section_ax.plot([0.0, global_end[0]], [0.0, global_end[1]], "--", color=grey, linewidth=1.0)
    section_ax.annotate(
        "",
        xy=(0.84, -0.12),
        xytext=(-0.32, -0.12),
        arrowprops={"arrowstyle": "-|>", "color": ink, "lw": 1.0},
    )
    section_ax.text(-0.30, -0.18, r"$V_\infty$", color=ink, ha="left", va="top")

    section_ax.add_patch(
        Arc((0.0, 0.0), 0.62, 0.62, theta1=0, theta2=alpha_global, color=grey, linewidth=1.0)
    )
    section_ax.add_patch(
        Arc((0.0, 0.0), 0.42, 0.42, theta1=0, theta2=alpha_effective, color=blue, linewidth=1.2)
    )
    section_ax.annotate(r"$\alpha_{\mathrm{global}}$", xy=(0.30, 0.045),
                        xytext=(0.23, 0.19), color=grey, fontsize=8.5,
                        arrowprops={"arrowstyle": "-", "color": grey, "lw": 0.7})
    section_ax.annotate(r"$\alpha_{\mathrm{eff},i}$", xy=(0.205, 0.011),
                        xytext=(0.18, -0.075), color=blue, fontsize=8.5,
                        arrowprops={"arrowstyle": "-", "color": blue, "lw": 0.7})
    section_ax.annotate(
        r"$s_\theta\theta_i$",
        xy=(0.53, 0.10),
        xytext=(0.66, 0.28),
        ha="center",
        color=gold,
        arrowprops={"arrowstyle": "->", "color": gold, "lw": 0.9},
    )
    section_ax.text(
        1.47,
        0.045,
        r"$\alpha_{\mathrm{eff},i}=\alpha_{\mathrm{global}}+s_\theta\theta(y_i),\qquad s_\theta=-1$",
        ha="center",
        va="center",
        fontsize=9.2,
        bbox={"boxstyle": "round,pad=0.25", "facecolor": pale_gold, "edgecolor": gold, "linewidth": 0.8},
    )
    section_ax.text(
        1.47,
        -0.105,
        "The section input is torsion-corrected; induced effects are resolved\nby the Fourier lifting-line system.",
        ha="center",
        va="center",
        color=grey,
        fontsize=8.2,
    )
    section_ax.set_title(
        "B. One-way torsion correction at station $i$",
        loc="left",
        fontweight="bold",
        fontsize=9.6,
        pad=5,
    )
    section_ax.set_xlim(-0.38, 2.16)
    section_ax.set_ylim(-0.36, 0.42, auto=True)
    section_ax.text(0.25, -0.30, "NACA 65-210 from coordinate file; angles illustrative",
                    ha="center", va="center", color=grey, fontsize=7.1)
    section_ax.set_aspect("equal", adjustable="datalim")
    section_ax.set_axis_off()

    # Compact evidence flow, aligned on the fixed figure canvas.
    flow_ax.set_axis_off()
    add_flow_box(
        flow_ax,
        0.015,
        0.28,
        r"Station inputs: $c_i$, $a_0$, $\alpha_{L=0}$" + "\n" + r"and $\alpha_{\mathrm{eff},i}$",
        ink,
        fill_color,
    )
    add_flow_box(
        flow_ax,
        0.36,
        0.28,
        r"Solve the $N=10$ odd Fourier system" + "\n" + r"for coefficients $A_n$",
        ink,
        (0.96, 0.97, 0.98),
    )
    add_flow_box(
        flow_ax,
        0.705,
        0.28,
        r"Integrated outputs: $C_L$, $C_{D_i}$" + "\n" + r"and span efficiency $e$",
        ink,
        pale_gold,
    )
    for start, end in ((0.295, 0.36), (0.64, 0.705)):
        flow_ax.annotate(
            "",
            xy=(end - 0.008, 0.50),
            xytext=(start + 0.008, 0.50),
            xycoords=flow_ax.transAxes,
            arrowprops={"arrowstyle": "-|>", "color": blue, "lw": 1.2},
        )

    output_path = output_path.resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, dpi=300, facecolor="white")
    plt.close(fig)
    print(output_path)


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Reproduce Figure 2.4 from its adjacent CSV.")
    parser.add_argument("--output", type=Path, default=Path(__file__).with_name("figure_2_4.png"))
    arguments = parser.parse_args()
    main(arguments.output)


