#!/usr/bin/env python3
"""Verify and plot the exported discovery-policy observations; no optimizer calls."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
from pathlib import Path
import sys

import numpy as np


HERE = Path(__file__).resolve().parent
PROBLEMS = ("C2DTLZ2_D6_R02", "MW7_D6")
POLICIES = ("current", "uniform", "mixed")
N_INITIAL, N_TOTAL = 20, 150
OBJECTIVE_RTOL = 1e-12
INPUT_FILES = (
    "evaluations.csv", "run_summary.csv", "policy_summary.csv",
    "paired_checks.csv", "archive_replay_checks.csv", "source_manifest.csv",
    "source_provenance.csv", "trial_source_manifest.csv",
)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read_csv(name):
    with (HERE / name).open(newline="", encoding="utf-8-sig") as stream:
        return list(csv.DictReader(stream))


def integer(value):
    number = float(value)
    require(math.isfinite(number) and number == int(number), f"Invalid integer: {value}")
    return int(number)


def first_index(value):
    return None if value.strip().lower() in ("", "nan", "none") else integer(value)


def same_number(actual, expected, context):
    require(math.isclose(float(actual), float(expected), rel_tol=1e-12, abs_tol=1e-14),
            f"{context}: computed {actual}, recorded {expected}")


def key(row):
    return row["ProblemId"], integer(row["Replicate"]), row["Policy"]


def indexed(rows, key_function, name):
    result = {key_function(row): row for row in rows}
    require(len(result) == len(rows), f"Duplicate records in {name}")
    return result


def objective_and_margins(problem, x):
    """Transcribe retained getBenchmarkProblem.m:423-438,471-492,539-540.

    Both problems are dimensionless, with six inputs bounded by [0, 1].
    All finite margins <= 0 are feasible; no feasibility tolerance is added.
    """
    if problem == "C2DTLZ2_D6_R02":
        g = np.sum((x[:, 1:] - 0.5) ** 2, axis=1)
        angle = x[:, 0] * np.pi / 2
        y = np.column_stack(((1 + g) * np.cos(angle), (1 + g) * np.sin(angle)))
        square_sum = np.sum(y ** 2, axis=1)
        axis_centered = (y - 1) ** 2 + square_sum[:, None] - y ** 2 - 0.2 ** 2
        diagonal_centered = np.sum((y - 1 / np.sqrt(2)) ** 2, axis=1) - 0.2 ** 2
        margins = np.minimum(np.min(axis_centered, axis=1), diagonal_centered)[:, None]
    elif problem == "MW7_D6":
        a = x[:, :-1] - 0.5
        g = 1 + np.sum(2 * (x[:, 1:] + a ** 2 - 1) ** 2, axis=1)
        y = np.column_stack((g * x[:, 0], g * np.sqrt(np.maximum(0, 1 - x[:, 0] ** 2))))
        theta = np.arctan2(y[:, 1], y[:, 0])
        outer_wave = 0.4 * np.sin(4 * theta) ** 16
        inner_wave = 0.2 * np.sin(4 * theta) ** 8
        radius_squared = y[:, 0] ** 2 + y[:, 1] ** 2
        margins = np.column_stack((
            radius_squared - (1.2 + np.abs(outer_wave)) ** 2,
            (1.15 - inner_wave) ** 2 - radius_squared,
        ))
    else:
        raise ValueError(f"Unknown benchmark: {problem}")
    return y, margins


def observed_pareto(y, feasible):
    # Match updatePareto.m: equal objective rows remain nondominated.
    mask = np.zeros(len(y), dtype=bool)
    candidates = np.flatnonzero(feasible)
    fy = y[candidates]
    for index, values in zip(candidates, fy):
        mask[index] = not np.any(np.all(fy <= values, axis=1) & np.any(fy < values, axis=1))
    return mask


def verify_inputs():
    tables = {name: read_csv(name) for name in INPUT_FILES}
    hashes = {name: hashlib.sha256((HERE / name).read_bytes()).hexdigest() for name in INPUT_FILES}
    for row in tables["source_provenance.csv"]:
        require(row["PublicPath"] in hashes, "Unexpected public path in source provenance")
        require(hashes[row["PublicPath"]] == row["PublicSHA256"].lower(),
                f"Public SHA-256 mismatch: {row['PublicPath']}")

    summaries = indexed(tables["run_summary.csv"], key, "run_summary.csv")
    expected_keys = {(p, r, q) for p in PROBLEMS for r in range(1, 6) for q in POLICIES}
    require(set(summaries) == expected_keys, "Expected exactly 30 matched run summaries")
    run_ids = indexed(tables["run_summary.csv"], lambda row: row["RunId"], "run IDs")
    trial_sources = indexed(tables["trial_source_manifest.csv"], lambda row: row["RunId"],
                            "trial_source_manifest.csv")
    require(set(trial_sources) == set(run_ids), "Trial-source run IDs differ from run summaries")
    for row in trial_sources.values():
        require(integer(row["Evaluations"]) == N_TOTAL, "Unexpected trial-source evaluation count")

    observations = {run_id: [] for run_id in run_ids}
    require(len(tables["evaluations.csv"]) == 30 * N_TOTAL, "Expected exactly 4,500 evaluations")
    for row in tables["evaluations.csv"]:
        require(row["RunId"] in observations, f"Unknown evaluation run ID: {row['RunId']}")
        require(key(row) == key(run_ids[row["RunId"]]), "Evaluation metadata differs from summary")
        observations[row["RunId"]].append(row)

    runs, verified = {}, []
    max_objective_error = 0.0
    for run_key in sorted(expected_keys):
        summary = summaries[run_key]
        run_id = summary["RunId"]
        rows = sorted(observations[run_id], key=lambda row: integer(row["Evaluation"]))
        require([integer(row["Evaluation"]) for row in rows] == list(range(1, N_TOTAL + 1)),
                f"{run_id}: evaluation indices must be exactly 1..150")
        require([integer(row["IsInitial"]) for row in rows] == [1] * N_INITIAL + [0] * 130,
                f"{run_id}: initial batch must contain exactly the first 20 evaluations")
        x = np.array([[float(row[f"X{i}"]) for i in range(1, 7)] for row in rows])
        y = np.array([[float(row[f"Y{i}"]) for i in range(1, 3)] for row in rows])
        require(np.all(np.isfinite(x)) and np.all((x >= 0) & (x <= 1)), f"{run_id}: invalid bounds")
        require(np.all(np.isfinite(y)), f"{run_id}: nonfinite objectives")
        flags = {}
        for field in ("IsFeasible", "ConstraintLabel", "ObservedPareto"):
            values = np.array([integer(row[field]) for row in rows])
            require(np.all((values == 0) | (values == 1)), f"{run_id}: invalid {field}")
            flags[field] = values.astype(bool)
        feasible = flags["IsFeasible"]
        require(np.array_equal(feasible, flags["ConstraintLabel"]), f"{run_id}: label mismatch")
        calculated_y, margins = objective_and_margins(run_key[0], x)
        error = float(np.max(np.abs(calculated_y - y)))
        max_objective_error = max(max_objective_error, error)
        require(np.allclose(calculated_y, y, rtol=OBJECTIVE_RTOL, atol=0),
                f"{run_id}: analytical objectives differ (maximum absolute error {error:g})")
        analytical_feasible = np.all(np.isfinite(margins) & (margins <= 0), axis=1)
        require(np.array_equal(analytical_feasible, feasible), f"{run_id}: analytical labels differ")
        pareto = observed_pareto(y, feasible)
        require(np.array_equal(pareto, flags["ObservedPareto"]), f"{run_id}: observed Pareto mask differs")
        hits = np.flatnonzero(feasible)
        first = int(hits[0] + 1) if hits.size else None
        initial_count = int(np.count_nonzero(feasible[:N_INITIAL]))
        discovery = 0 if initial_count else (first if first is not None else N_TOTAL) - N_INITIAL
        computed = {
            "RunId": run_id, "ProblemId": run_key[0], "Replicate": run_key[1], "Policy": run_key[2],
            "Seed": integer(summary["Seed"]), "InitialFeasible": initial_count,
            "TotalEvaluations": N_TOTAL, "FinalFeasible": int(np.count_nonzero(feasible)),
            "FirstFeasibleEvaluation": first, "FinalParetoCount": int(np.count_nonzero(pareto)),
            "DiscoveryEvaluations": discovery,
        }
        require(summary["Status"] == "completed" and not summary["Error"], f"{run_id}: not completed")
        for field in ("InitialFeasible", "TotalEvaluations", "FinalFeasible", "FinalParetoCount",
                      "DiscoveryEvaluations"):
            require(computed[field] == integer(summary[field]), f"{run_id}: {field} differs")
        require(first == first_index(summary["FirstFeasibleEvaluation"]), f"{run_id}: discovery index differs")
        if run_key[0] == "C2DTLZ2_D6_R02":
            necessary_region = np.sum((x[:, 1:] - 0.5) ** 2, axis=1) <= 0.2
            for field, count in (
                ("C2NecessaryRegionInitialCount", np.count_nonzero(necessary_region[:N_INITIAL])),
                ("C2NecessaryRegionDiscoveryCount", np.count_nonzero(necessary_region[N_INITIAL:N_INITIAL + discovery])),
            ):
                computed[field] = int(count)
                require(int(count) == integer(summary[field]), f"{run_id}: {field} differs")
        else:
            computed["C2NecessaryRegionInitialCount"] = None
            computed["C2NecessaryRegionDiscoveryCount"] = None
        uniform = integer(summary["UniformDiscoveryEvaluations"])
        require(0 <= uniform <= discovery, f"{run_id}: invalid retained uniform count")
        require(0 <= integer(summary["RecoveryEvaluations"]) <= N_TOTAL - N_INITIAL - discovery,
                f"{run_id}: invalid retained recovery count")
        require(run_key[2] != "current" or uniform == 0, f"{run_id}: current uniform count is nonzero")
        require(run_key[2] != "uniform" or uniform == discovery, f"{run_id}: uniform count differs")
        require(integer(summary["PostFeasibleUniformViolations"]) == 0, f"{run_id}: retained intervention violation")
        runs[run_key] = {"x": x, "y": y, "feasible": feasible, "pareto": pareto, "computed": computed}
        verified.append(computed)

    paired = indexed(tables["paired_checks.csv"], key, "paired_checks.csv")
    require(set(paired) == expected_keys, "Expected exactly 30 paired checks")
    inactive_groups = 0
    for problem in PROBLEMS:
        for replicate in range(1, 6):
            baseline = runs[(problem, replicate, "current")]
            inactive = baseline["computed"]["InitialFeasible"] > 0
            inactive_groups += int(inactive)
            for policy in POLICIES:
                run_key = (problem, replicate, policy)
                run = runs[run_key]
                require(run["computed"]["Seed"] == baseline["computed"]["Seed"], "Paired seeds differ")
                for field in ("x", "y", "feasible"):
                    require(np.array_equal(run[field][:N_INITIAL], baseline[field][:N_INITIAL]),
                            f"{run_key}: paired initial {field} differs")
                    if inactive:
                        require(np.array_equal(run[field], baseline[field]),
                                f"{run_key}: inactive-discovery trajectory differs")
                record = paired[run_key]
                require(integer(record["SameInitialData"]) == 1, f"{run_key}: recorded initial check differs")
                require(integer(record["DiscoveryInactive"]) == int(inactive), f"{run_key}: inactivity differs")
                same_number(np.max(np.abs(run["x"] - baseline["x"])),
                            record["MaxCoordinateDifferenceFromCurrent"], f"{run_key}: paired coordinates")
                require(run["computed"]["FinalFeasible"] - baseline["computed"]["FinalFeasible"] ==
                        integer(record["FinalFeasibleChangeFromCurrent"]), f"{run_key}: paired final count differs")

    policy_rows = indexed(tables["policy_summary.csv"], lambda row: (row["ProblemId"], row["Policy"]),
                          "policy_summary.csv")
    require(set(policy_rows) == {(p, q) for p in PROBLEMS for q in POLICIES}, "Policy-summary groups differ")
    verified_policy = []
    for problem in PROBLEMS:
        for policy in POLICIES:
            group = [runs[(problem, r, policy)]["computed"] for r in range(1, 6)]
            record = policy_rows[(problem, policy)]
            calculated = {
                "ProblemId": problem, "Policy": policy, "Trials": len(group),
                "InitiallyFeasibleTrials": sum(row["InitialFeasible"] > 0 for row in group),
                "FoundFeasibleTrials": sum(row["FirstFeasibleEvaluation"] is not None for row in group),
                "FirstFeasibleEvaluationsByTrial": ", ".join(str(row["FirstFeasibleEvaluation"])
                    if row["FirstFeasibleEvaluation"] is not None else "none" for row in group),
                "FinalFeasibleCountsByTrial": ", ".join(str(row["FinalFeasible"]) for row in group),
                "MedianFinalFeasibleCount": float(np.median([row["FinalFeasible"] for row in group])),
                "TotalDiscoveryEvaluations": sum(row["DiscoveryEvaluations"] for row in group),
            }
            for field, value in calculated.items():
                if isinstance(value, (float, int)):
                    same_number(value, record[field], f"{problem}/{policy}: {field}")
                else:
                    require(value == record[field], f"{problem}/{policy}: {field} differs")
            # Iteration origins are absent: check agreement between retained summaries only.
            retained_uniform_total = sum(integer(summaries[(problem, r, policy)]["UniformDiscoveryEvaluations"])
                                         for r in range(1, 6))
            require(retained_uniform_total == integer(record["TotalUniformDiscoveryEvaluations"]),
                    f"{problem}/{policy}: retained uniform counts disagree")
            verified_policy.append(calculated)

    archive = tables["archive_replay_checks.csv"]
    archive_index = indexed(archive, lambda row: (row["ProblemId"], integer(row["Replicate"])),
                            "archive_replay_checks.csv")
    require(set(archive_index) == {(p, r) for p in PROBLEMS for r in range(1, 6)}, "Archive-check groups differ")
    for (problem, replicate), row in archive_index.items():
        require(integer(row["FreshFinalFeasible"]) == runs[(problem, replicate, "current")]["computed"]["FinalFeasible"],
                "Retained archive check has inconsistent fresh final count")

    report = {
        "status": "passed", "runs_verified": len(runs), "evaluations_verified": 30 * N_TOTAL,
        "objective_relative_tolerance": OBJECTIVE_RTOL, "objective_absolute_tolerance": 0,
        "maximum_objective_absolute_error": max_objective_error,
        "feasibility_margin_tolerance": 0,
        "matched_initial_groups_verified": 10,
        "initially_feasible_complete_trajectory_groups_verified": inactive_groups,
        "recomputed": ["analytical objectives and feasibility", "initial batches and matched seeds",
                       "first feasible indices", "final feasible counts", "observed Pareto masks and counts",
                       "discovery evaluation counts", "C2 necessary-region counts", "paired checks",
                       "policy summaries excluding uniform-origin counts"],
        "retained_checks_not_recomputed": [
            "archive discovery-prefix and full-trajectory differences: archived trajectories are absent",
            "uniform/mixed branch origins, recovery counts and post-feasibility intervention checks: iteration records are absent",
            "retained upstream source and MAT-file hashes: original files are not redistributed here",
        ],
        "input_sha256": hashes,
    }
    return runs, verified, verified_policy, report


def write_csv(path, rows):
    with path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def make_figures(runs, output):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    colors = {"current": "#174A7E", "uniform": "#B95514", "mixed": "#25816D"}
    styles = {"current": "-", "uniform": "--", "mixed": ":"}
    files = []
    for problem in PROBLEMS:
        fig, axes = plt.subplots(5, 1, figsize=(8.27, 11.69), sharex=True, sharey=True)
        largest_count = max(runs[(problem, r, q)]["computed"]["FinalFeasible"]
                            for r in range(1, 6) for q in POLICIES)
        upper_count = 10 * math.ceil(1.05 * largest_count / 10)
        title = "C2-DTLZ2, six inputs, radius 0.2" if problem.startswith("C2") else "MW7, six inputs"
        fig.suptitle(title + "\nCumulative observed feasible evaluations", y=0.984, fontsize=14)
        handles = []
        for replicate, ax in enumerate(axes, start=1):
            discoveries = []
            ax.axvspan(1, N_INITIAL, color="#E8E8E8", zorder=0)
            ax.axvline(N_INITIAL, color="#777777", linewidth=0.7)
            for policy in POLICIES:
                run = runs[(problem, replicate, policy)]
                line, = ax.step(np.arange(1, N_TOTAL + 1), np.cumsum(run["feasible"]), where="post",
                                color=colors[policy], linestyle=styles[policy], linewidth=1.7, label=policy.capitalize())
                if replicate == 1:
                    handles.append(line)
                first = run["computed"]["FirstFeasibleEvaluation"]
                discoveries.append(f"{policy}: {first}" if first is not None else f"{policy}: none by 150")
            ax.set_title(f"Replicate {replicate} | First feasible - " + "; ".join(discoveries),
                         loc="left", fontsize=9, pad=9)
            ax.set_ylabel("Feasible count", fontsize=9)
            ax.grid(axis="y", alpha=0.25)
            ax.set_xlim(1, N_TOTAL)
            ax.set_ylim(0, max(10, upper_count))
            ax.spines[["top", "right"]].set_visible(False)
        axes[-1].set_xlabel("Evaluation index (20 initial + 130 sequential)")
        fig.legend(handles=handles, loc="upper center", bbox_to_anchor=(0.5, 0.943), ncol=3, frameon=False)
        fig.text(0.08, 0.026,
                 "Source: retained matched discovery-policy evaluations; counts and indices recalculated.\n"
                 "The shaded interval is the common initial batch. Curves include all five matched replicates.\n"
                 "An unsuccessful discovery has no assigned index; 'none by 150' retains that outcome.",
                 fontsize=8, va="bottom")
        fig.tight_layout(rect=(0.02, 0.069, 0.99, 0.929), h_pad=1.3)
        for extension in ("png", "pdf"):
            name = f"{problem}_cumulative_feasible.{extension}"
            fig.savefig(output / name, dpi=180)
            files.append(name)
        plt.close(fig)
    return files


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path,
                        default=HERE.parents[2] / "generated" / "discovery_policy_20260921",
                        help="Output directory (default: repository generated/discovery_policy_20260921)")
    args = parser.parse_args()
    output = args.output.resolve()
    data_root = HERE.parents[1]
    require(output != data_root and data_root not in output.parents, "Derived output must be outside data/")
    runs, verified, policies, report = verify_inputs()
    output.mkdir(parents=True, exist_ok=True)
    write_csv(output / "verified_run_summary.csv", verified)
    write_csv(output / "verified_policy_summary.csv", policies)
    report["figures"] = make_figures(runs, output)
    (output / "verified_summary.json").write_text(json.dumps(report, indent=2, allow_nan=False) + "\n", encoding="utf-8")
    print(f"PASS: {len(runs)} runs / {30 * N_TOTAL:,} evaluations; outputs: {output}")
    print(f"Maximum analytical objective absolute error: {report['maximum_objective_absolute_error']:.3g}")
    print("Archive-prefix and iteration-origin checks are retained evidence, not recomputed from this export.")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, OSError) as error:
        print(f"Verification failed: {error}", file=sys.stderr)
        raise SystemExit(1) from error
