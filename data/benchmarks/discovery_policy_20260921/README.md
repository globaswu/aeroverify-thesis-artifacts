# Discovery-only policy comparison: exported numerical replay

This package contains the evaluated observations from 30 matched trials on
two six-dimensional analytical benchmarks: `C2DTLZ2_D6_R02` and `MW7_D6`.
Each problem has five retained initial designs and solver seeds, and each
seed is evaluated under three discovery policies. A trial contains 20
initial observations followed by 130 sequential evaluations. Both
objectives are minimized; inputs, objectives and constraint margins are
dimensionless, with all six inputs bounded by `[0, 1]`.

The experiment changes selection only while there is no observed feasible
design. After feasibility is observed, the original acquisition and
recovery paths apply. The three policies are:

- **Current:** the archived discovery rule, which combines a floored
  feasibility score with distance novelty. The clipped local binary-Gaussian-process
  feasibility score is not treated as a calibrated posterior probability.
- **Uniform:** a uniform proposal in the input domain, with duplicate
  rejection, selected directly before the first feasible observation.
  Predicted score does not filter the selected proposal.
- **Mixed:** an independent 50/50 coin at each active discovery iteration
  chooses uniform or current selection. Private reproducible random
  streams are used; the policy does not alternate or force equal totals.

The five matched seeds are `2026073301` through `2026073305`. The C2-DTLZ2
replicate 1 and MW7 replicate 2 initial batches already contain feasibility;
their complete trajectories agree across policies. They are controls for
inactive discovery intervention, not evidence of an intervention benefit.
The original experiment description is the retained
`ctsemo_discovery_policy_20260921/README.md`; the public tables below retain
its numerical evidence without private machine paths or binary run files.

## Reproduce the numerical checks and figures

From the repository root, install the figure dependencies and run:

```console
python -m pip install -r requirements-figures.txt
python data/benchmarks/discovery_policy_20260921/reproduce.py
```

The default output is `generated/discovery_policy_20260921/`, independent
of the working directory. A custom output directory is also supported:

```console
python data/benchmarks/discovery_policy_20260921/reproduce.py --output generated/my_policy_replay
```

The script reads only the adjacent CSV files. It creates
`verified_run_summary.csv`, `verified_policy_summary.csv`,
`verified_summary.json`, and one cumulative-feasible-count figure per
problem in PNG and PDF formats. Each figure shows all five matched
replicates and identifies the 20-point initial batch. Unsuccessful trials
remain visible as “none by 150”; no failure is assigned an invented
discovery index. Derived files are never written into `data/`.

Checks cover all 4,500 rows: bounds and finite values; complete evaluation
indices; the 30 corresponding run summaries; exact paired initial
inputs/objectives/labels and seeds; exact complete trajectories for the
initially feasible controls; analytical objectives and feasibility; first
feasible indices; final feasible counts; observed Pareto membership and
counts; discovery evaluation counts; the C2 necessary-region counts; the
paired-check table; and the derived policy summaries. Objective agreement
uses relative tolerance `1e-12` and absolute tolerance zero. Analytical
feasibility uses finite constraint margins at most zero, with no tolerance.
The script also checks the public-file hashes in `source_provenance.csv`.

The analytical functions are transcribed from the retained upstream
`solver/benchmarks/getBenchmarkProblem.m`: C2-DTLZ2 objectives and margin
at lines 423–438; MW7 objectives and margins at lines 471–492; feasibility
at lines 539–540. For C2-DTLZ2, the objective-space constraint is the union
of radius-0.2 balls centered at `(1,0)`, `(0,1)`, and
`(1/sqrt(2),1/sqrt(2))`. Its necessary input-region condition
`sum((X2..X6 - 0.5)^2) <= 0.2` is checked separately and is not a substitute
for the full feasibility test. MW7 uses adjacent-variable contributions
`2*(x[i+1] + (x[i]-0.5)^2 - 1)^2`, summed for the five adjacent pairs.

## Files and field definitions

| File | Contents and replay scope |
|---|---|
| `evaluations.csv` | All 4,500 evaluated input vectors, objectives, labels and final observed Pareto flags; the basis for numerical replay. |
| `run_summary.csv` | Thirty retained trial summaries. The original result-file path field is replaced by `RunId`; numerical cell strings are unchanged. |
| `policy_summary.csv` | Six retained problem/policy summaries, each covering five replicates. |
| `paired_checks.csv` | Thirty retained checks against the freshly evaluated current-policy control. These are recomputed from the export. |
| `archive_replay_checks.csv` | Ten retained comparisons with the earlier current-policy archive. Archived trajectories are absent, so prefix and full-trajectory differences are not recomputed. |
| `source_manifest.csv` | Recorded original and experimental upstream solver-file SHA-256 values. This attests to the retained source comparison; it is not redistribution of those files. |
| `source_provenance.csv` | Source identifiers, retained source hashes and sizes, public-copy hashes, and the documented path-text transformation. |
| `trial_source_manifest.csv` | The 30 retained binary trial-source hashes and sizes, linked by `RunId` to the numerical export. Original MAT files are not distributed here. |

Table source: the adjacent files and their CSV headers.

`RunId` identifies one problem/replicate/policy combination. `Replicate`
ranges from 1 to 5 and `Evaluation` from 1 to 150 within a run.
`IsInitial` is 1 for evaluations 1–20. `X1`–`X6` and `Y1`–`Y2` retain the
evaluated double-precision numbers. `IsFeasible` and `ConstraintLabel` both
use **1 for feasible and 0 for infeasible**; the latter contains the
solver's retained binary labels, not continuous constraint margins.

`ObservedPareto` identifies feasible evaluated rows not strictly dominated
in the completed 150-observation history. A competing row must be no worse
in both objectives and strictly better in at least one to dominate.
Equal objective duplicates are retained, matching the original
`updatePareto.m` behavior. No surrogate Pareto front is used.

`FirstFeasibleEvaluation` is a one-based index in the complete history,
including the initial batch. `NaN` in a retained summary means no feasible
point was found within 150 evaluations. The derived per-run CSV uses an
empty cell. `DiscoveryEvaluations` includes
the sequential evaluation that first discovers feasibility: it is zero
for an initially feasible run, otherwise `first_index - 20`, or 130 when
discovery is unsuccessful.

`UniformDiscoveryEvaluations`, `RecoveryEvaluations`, and
`PostFeasibleUniformViolations` are retained iteration-log summaries.
The export contains no per-iteration selection origins, so the script
checks uniform-count aggregation, count bounds, and the recorded zero
post-feasibility violations rather than reconstructing the mixed-policy
coin sequence or intervention history. Likewise, source
and MAT-file hashes identify retained originals; their contents cannot
be rehashed from this public export.

## Observed outcomes and interpretation

| Problem | Policy | Feasibility found | First feasible evaluation, replicates 1–5 | Final feasible counts, replicates 1–5 |
|---|---|---:|---|---|
| C2-DTLZ2, D=6, r=0.2 | Current | 3/5 | 4, none, 94, none, 141 | 57, 0, 48, 0, 10 |
| C2-DTLZ2, D=6, r=0.2 | Uniform | 5/5 | 4, 81, 69, 110, 99 | 57, 62, 62, 34, 47 |
| C2-DTLZ2, D=6, r=0.2 | Mixed | 5/5 | 4, 89, 85, 110, 141 | 57, 53, 60, 37, 7 |
| MW7, D=6 | Current | 5/5 | 117, 18, 129, 26, 25 | 17, 60, 13, 42, 26 |
| MW7, D=6 | Uniform | 4/5 | none, 18, 145, 104, 80 | 0, 60, 2, 28, 31 |
| MW7, D=6 | Mixed | 4/5 | none, 18, 129, 28, 102 | 0, 60, 10, 35, 16 |

Table source: `policy_summary.csv` and `run_summary.csv`; independently
recomputed from `evaluations.csv` by the command above. “None” means no
feasibility by evaluation 150.

Among the four initially infeasible replicates per problem, C2-DTLZ2
discovery succeeds in 2/4 current-policy trials and 4/4 trials for both
uniform and mixed. MW7 discovery succeeds in 4/4 current-policy trials
and 3/4 trials for both alternatives. Uniform discovers feasibility
earlier in each active C2-DTLZ2 pair and later, or not within budget, in
each active MW7 pair. These observations support a problem-dependent
comparison within the five retained seeds; they do not establish a
universal policy ranking. Final feasible counts also depend on the
evaluation budget remaining after discovery and do not isolate an
improvement in the unchanged acquisition rule. No hypervolume ranking or
controlled runtime comparison is made.

The retained archive table records matching discovery prefixes for all
ten current-policy controls, while eight completed trajectories later
differ from the earlier archive. This package compares the freshly
evaluated current controls against uniform and mixed. The archive checks
do not identify the cause of those later differences.

This is an **exported numerical replay**: it verifies the saved evaluated
data, summaries and figures, including independently recalculated
analytical responses. The data alone cannot rerun the optimizer to obtain
the full trajectories, reconstruct acquisition candidates or mixed-policy
coin decisions, or repeat the archived-prefix comparison. The upstream
source hash manifest records provenance and does not imply that the
retained solver tree is included or licensed for redistribution here.
