#!/usr/bin/env python3
"""Render the public Chapter 3 ECDF curves without refitting or new probes."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
from matplotlib.lines import Line2D
import numpy as np


SOURCE = Path(__file__).resolve().parent
REPO = SOURCE.parents[2]
TOLERANCE = 1e-4
CLASSES = ("Truly feasible", "Truly infeasible")
COLORS = ((0.08, 0.43, 0.17), (0.78, 0.10, 0.12))
STYLES = ("-", "--")
CONFIGURATIONS = (
    ("COSSIN1", "COSSIN1"),
    ("COSSIN2", "COSSIN2"),
    ("BNH", "BNH"),
    ("SRN", "SRN"),
    ("C2DTLZ2_D3_R05", "C2-DTLZ2 (r = 0.5)"),
    ("WELDEDBEAM", "Welded-beam variant"),
    ("CF1_D4", "CF1"),
    ("CF1_D10", "CF1"),
    ("C2DTLZ2_D4_R02", "C2-DTLZ2 (r = 0.2)"),
    ("C2DTLZ2_D6_R02", "C2-DTLZ2 (r = 0.2)"),
    ("MW7_D4", "MW7"),
    ("MW7_D6", "MW7"),
)


def read_csv(path):
    with path.open(encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def step_evaluate(curve, query):
    """Previous-value evaluation: right-continuous and zero below first x."""
    x, y = curve
    index = np.searchsorted(x, query, side="right") - 1
    return np.where(index >= 0, y[np.maximum(index, 0)], 0.0)


def compress_cdf(x, y):
    """Match prepare_chapter03_ecdf.m's second, draw-only compression."""
    keep = [0]
    last = 0
    for index in range(1, len(x)):
        if y[index] - y[last] >= TOLERANCE or index == len(x) - 1:
            keep.append(index)
            last = index
    curve = (x[keep], y[keep])
    error = float(np.max(np.abs(y - step_evaluate(curve, x))))
    if error > TOLERANCE + 1e-12:
        raise ValueError(f"Median compression exceeds its error bound: {error}")
    return curve, error


def load_records():
    metric_rows = read_csv(SOURCE / "metrics.csv")
    expected_ids = {item[0] for item in CONFIGURATIONS}
    if {row["ProblemId"] for row in metric_rows} != expected_ids:
        raise ValueError("metrics.csv does not contain exactly the 12 configurations")
    records = []
    for ordinal, (problem_id, title) in enumerate(CONFIGURATIONS):
        rows = [row for row in metric_rows if row["ProblemId"] == problem_id]
        metrics = {int(row["Replicate"]): row for row in rows}
        expected_reps = list(range(1, 2 if ordinal < 5 else 6))
        if len(metrics) != len(rows) or sorted(metrics) != expected_reps:
            raise ValueError(f"Unexpected or duplicated replicate metrics: {problem_id}")
        first = metrics[1]
        for row in rows:
            for key in ("Dimension", "TrainingCount", "ProbeCount", "FeasibleCount", "InfeasibleCount"):
                if row[key] != first[key]:
                    raise ValueError(f"Inconsistent {key}: {problem_id}")
            if int(row["FeasibleCount"]) + int(row["InfeasibleCount"]) != int(row["ProbeCount"]):
                raise ValueError(f"Class counts do not sum to probe count: {problem_id}")
            if min(int(row["FeasibleCount"]), int(row["InfeasibleCount"])) <= 0:
                raise ValueError(f"An ECDF class is empty: {problem_id}")
            if not all(np.isfinite(float(row[key])) for key in ("KS", "MedianGap", "AUC")):
                raise ValueError(f"Nonfinite panel metric: {problem_id}")
        grouped = {}
        for row in read_csv(SOURCE / "curves" / f"{problem_id}_draw_curves.csv"):
            key = (int(row["Replicate"]), row["TrueClass"])
            grouped.setdefault(key, []).append((float(row["Score"]), float(row["ECDF"])))
        expected_keys = {(rep, cls) for rep in expected_reps for cls in CLASSES}
        # Replicate 0, if supplied by a later compatible export, means median;
        # it must never be included as a sixth run in a pointwise median.
        optional_keys = {(0, cls) for cls in CLASSES} if len(expected_reps) > 1 else set()
        if not expected_keys.issubset(grouped) or set(grouped) - expected_keys - optional_keys:
            raise ValueError(f"Unexpected curve groups: {problem_id}")
        if any(key in grouped for key in optional_keys) and not optional_keys.issubset(grouped):
            raise ValueError(f"Incomplete median classes: {problem_id}")
        curves = {}
        for key, pairs in grouped.items():
            x, y = np.asarray(pairs, dtype=float).T
            valid = (
                len(x) >= 2 and np.all(np.isfinite(x)) and np.all(np.isfinite(y))
                and np.all(np.diff(x) > 0) and np.all(np.diff(y) >= -1e-12)
                and np.all((x >= 0) & (x <= 1)) and np.all((y >= 0) & (y <= 1))
                and x[0] == 0 and x[-1] == 1 and abs(y[-1] - 1) <= 1e-12
            )
            if not valid:
                raise ValueError(f"Invalid ordered ECDF: {problem_id}, {key}")
            curves[key] = (x, y)
        medians, errors = {}, {}
        for cls in CLASSES:
            if len(expected_reps) == 1:
                medians[cls], errors[cls] = curves[(1, cls)], 0.0
                continue
            union = np.unique(np.concatenate([curves[(rep, cls)][0] for rep in expected_reps]))
            pointwise = np.median(np.column_stack([
                step_evaluate(curves[(rep, cls)], union) for rep in expected_reps
            ]), axis=1)
            if (0, cls) in curves:
                # Check all breakpoints of both the source and supplied median.
                check_x = np.union1d(union, curves[(0, cls)][0])
                exact_display_median = np.median(np.column_stack([
                    step_evaluate(curves[(rep, cls)], check_x) for rep in expected_reps
                ]), axis=1)
                error = float(np.max(np.abs(
                    step_evaluate(curves[(0, cls)], check_x) - exact_display_median
                )))
                if error > TOLERANCE + 1e-12:
                    raise ValueError(f"Supplied median disagrees: {problem_id}, {cls}")
                medians[cls], errors[cls] = curves[(0, cls)], error
            else:
                medians[cls], errors[cls] = compress_cdf(union, pointwise)
        records.append(dict(id=problem_id, title=title, metrics=metrics,
                            curves=curves, medians=medians, median_errors=errors,
                            dimension=int(first["Dimension"]),
                            training=int(first["TrainingCount"]),
                            feasible=int(first["FeasibleCount"]),
                            infeasible=int(first["InfeasibleCount"])))
    return records


def draw_steps(ax, curve, cls_index, faint=False):
    x, y = curve
    color = np.asarray(COLORS[cls_index])
    if faint:
        color = 0.78 + 0.22 * color
    ax.step(np.r_[0.0, x], np.r_[0.0, y], where="post", color=color,
            linestyle=STYLES[cls_index], linewidth=0.55 if faint else 1.5,
            zorder=3 if faint else 4)
    if not faint:
        ax.plot([0, 1], [y[0], 1], linestyle="none", marker="o", markersize=3.2,
                markerfacecolor="white", markeredgecolor=color, markeredgewidth=0.8,
                clip_on=False, zorder=5)


def draw_panel(ax, record, replicate=None, big=False):
    fs = 10.5 if big else 8.0
    ax.set(xlim=(0, 1), ylim=(0, 1), xticks=np.linspace(0, 1, 5), yticks=np.linspace(0, 1, 5))
    ax.set_aspect("equal", adjustable="box")
    ax.tick_params(labelsize=fs - 0.5, width=0.65, pad=2)
    for spine in ax.spines.values():
        spine.set_linewidth(0.65)
    ax.axvspan(0.4, 0.6, color=(0.94, 0.94, 0.94), zorder=0)
    ax.grid(color="0.88", linewidth=0.5, zorder=1)
    for threshold in (0.4, 0.6):
        ax.axvline(threshold, color="0.5", linestyle=":", linewidth=0.65, zorder=2)
    for cls_index, cls in enumerate(CLASSES):
        if replicate is None:
            if len(record["metrics"]) > 1:
                for rep in sorted(record["metrics"]):
                    draw_steps(ax, record["curves"][(rep, cls)], cls_index, faint=True)
            draw_steps(ax, record["medians"][cls], cls_index)
        else:
            draw_steps(ax, record["curves"][(replicate, cls)], cls_index)
    ax.set_xlabel("Predicted feasibility score", fontsize=fs, labelpad=3)
    ylabel = "Empirical cumulative probability" if big else "Empirical cumulative\nprobability"
    ax.set_ylabel(ylabel, fontsize=fs, labelpad=4)
    if replicate is None:
        ks = np.median([float(row["KS"]) for row in record["metrics"].values()])
        gap = np.median([float(row["MedianGap"]) for row in record["metrics"].values()])
        prefix = "5-run medians: " if len(record["metrics"]) > 1 else ""
        detail = f"{prefix}KS {ks:.3f} | gap {gap:+.3f}"
        title = detail if big else f"{record['title']}; d = {record['dimension']}\n{detail}"
    else:
        row = record["metrics"][replicate]
        title = (f"Replicate {replicate} | AUC {float(row['AUC']):.3f}\n"
                 f"KS {float(row['KS']):.3f} | gap {float(row['MedianGap']):+.3f}")
    ax.set_title(title, fontsize=fs + 0.3, pad=9, fontweight="normal")


def header(fig, title, subtitle):
    fig.text(0.09, 0.96, title, fontsize=14, weight="bold", va="top")
    fig.text(0.09, 0.921, subtitle, fontsize=10, va="top")


def legend(fig, y=0.111):
    handles = [Line2D([0], [0], color=COLORS[i], linestyle=STYLES[i],
                      linewidth=1.5, label=cls) for i, cls in enumerate(CLASSES)]
    fig.legend(handles=handles, loc="center", bbox_to_anchor=(0.5, y), ncol=2,
               frameon=False, fontsize=10, handlelength=3, columnspacing=4)


def foot(fig, lines):
    fig.text(0.09, 0.077, "\n".join(lines), fontsize=7.7, va="top", linespacing=1.4)


def record_foot(record, replicate_sheet=False):
    caption = (
        "Each panel shows one run; ECDFs use their own true-class counts."
        if replicate_sheet else
        "Bold: pointwise median ECDF; faint: individual runs (not confidence intervals)."
        if len(record["metrics"]) > 1 else
        "Each ECDF is normalized within its own true class."
    )
    return [
        f"Probe classes: {record['feasible']:,} feasible; {record['infeasible']:,} infeasible.",
        caption,
        "Gray: intermediate score band, 0.4 < p < 0.6.",
        "Source: retained analytical benchmark evaluations.",
    ]


def individual(record):
    fig = plt.figure(figsize=(17.8 / 2.54, 18.8 / 2.54), facecolor="white")
    draw_panel(fig.add_axes([0.18, 0.255, 0.72, 0.61]), record, big=True)
    header(fig, f"{record['title']} | d = {record['dimension']}",
           f"Final cTSEMO feasibility field | {record['training']} evaluations per run")
    legend(fig, 0.145)
    foot(fig, record_foot(record))
    return fig


def plate_axes(fig, rows):
    return fig.subplots(rows, 2, gridspec_kw=dict(
        left=0.12, right=0.96, bottom=0.172, top=0.848,
        wspace=0.5, hspace=0.85 if rows == 4 else 0.61,
    )).ravel()


def overview(records, group):
    fig = plt.figure(figsize=(21 / 2.54, 29.7 / 2.54), facecolor="white")
    header(fig, "Class-conditional feasibility-score ECDFs",
           "Integration problems" if group == 1 else "Higher-dimensional problems")
    axes = plate_axes(fig, 3 if group == 1 else 4)
    for ax, record in zip(axes, records):
        draw_panel(ax, record)
    for ax in axes[len(records):]:
        ax.set_axis_off()
    legend(fig)
    foot(fig, [
        "Four 2-D cases: retained 40,401-point grids; C2-DTLZ2 d3: 262,144-point LHS diagnostic."
        if group == 1 else
        "Seven configurations; 262,144 retained LHS probes and 150 evaluations per run.",
        "Each ECDF uses its own true-class count. Gray: intermediate band, 0.4 < p < 0.6.",
        "C2-DTLZ2 d3 is an offline final-field diagnostic; no new optimization run."
        if group == 1 else
        "Bold: pointwise median; faint: individual runs (not confidence intervals).",
        "Source: retained analytical benchmark evaluations.",
    ])
    return fig


def all_replicates(record):
    fig = plt.figure(figsize=(21 / 2.54, 29.7 / 2.54), facecolor="white")
    header(fig, f"{record['title']} | d = {record['dimension']}",
           f"All five final-model replicates | {record['training']} evaluations per run")
    axes = plate_axes(fig, 3)
    for ax, rep in zip(axes, sorted(record["metrics"])):
        draw_panel(ax, record, replicate=rep)
    axes[-1].set_axis_off()
    axes[-1].text(0.05, 0.91,
                 "Common independent probe set\n\n"
                 f"Truly feasible: {record['feasible']:,}\n"
                 f"Truly infeasible: {record['infeasible']:,}\n\n"
                 "Each ECDF is normalized\nwithin its own true class.\n\n"
                 "Infeasible: p <= 0.4\nFeasible: p >= 0.6\nGray: intermediate band",
                 transform=axes[-1].transAxes, va="top", fontsize=10, linespacing=1.4)
    legend(fig)
    foot(fig, record_foot(record, replicate_sheet=True))
    return fig


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path,
                        default=REPO / "generated" / "chapter03_ecdf_20260921",
                        help="Output directory; default: repository generated/chapter03_ecdf_20260921")
    parser.add_argument("--formats", nargs="+", choices=("png", "svg", "pdf"),
                        default=["png", "svg"], help="Individual figure formats (default: png svg)")
    args = parser.parse_args()
    output = args.output.expanduser().resolve()
    if output == SOURCE or SOURCE in output.parents:
        parser.error("Output must be outside the immutable source directory")
    records = load_records()
    output.mkdir(parents=True, exist_ok=True)
    plt.rcParams.update({"font.family": "DejaVu Serif", "axes.linewidth": 0.65,
                         "svg.fonttype": "none", "pdf.fonttype": 42,
                         "path.simplify": False, "savefig.facecolor": "white"})
    exported = []

    def export(fig, name):
        # No tight bounding box: the overview/replicate plates remain exact A4.
        for extension in dict.fromkeys(args.formats):
            path = output / f"{name}.{extension}"
            fig.savefig(path, dpi=220)
            exported.append(path.name)

    for record in records:
        fig = individual(record)
        export(fig, record["id"])
        plt.close(fig)
    booklet = output / "chapter03_ecdf_figure_booklet.pdf"
    with PdfPages(booklet) as pdf:
        pdf.infodict().update(Title="Chapter 3 class-conditional feasibility-score ECDFs",
                              Subject="Public plot-ready curves and archived metrics")
        for group, selected in ((1, records[:5]), (2, records[5:])):
            fig = overview(selected, group)
            export(fig, f"overview_{group}")
            pdf.savefig(fig)
            plt.close(fig)
        for record in records[5:]:
            fig = all_replicates(record)
            export(fig, f"{record['id']}_all_replicates")
            pdf.savefig(fig)
            plt.close(fig)
    exported.append(booklet.name)
    input_paths = [SOURCE / "metrics.csv"] + [
        SOURCE / "curves" / f"{record['id']}_draw_curves.csv" for record in records
    ]
    receipt = {
        "configuration_count": len(records),
        "model_count": sum(len(record["metrics"]) for record in records),
        "individual_class_curve_count": sum(2 * len(record["metrics"]) for record in records),
        "booklet_pages": 9,
        "median_rule": "pointwise median of right-continuous, class-conditional run ECDFs",
        "median_additional_compression_tolerance": TOLERANCE,
        "median_additional_errors": {record["id"]: record["median_errors"] for record in records[5:]},
        "input_file_sha256": {path.relative_to(SOURCE).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest()
                              for path in input_paths},
        "outputs": exported,
        "numpy_version": np.__version__,
        "matplotlib_version": matplotlib.__version__,
    }
    (output / "rendering_receipt.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    print(f"Rendered 12 configurations, 2 overviews, 7 replicate plates and a 9-page A4 booklet to {output}")


if __name__ == "__main__":
    main()
