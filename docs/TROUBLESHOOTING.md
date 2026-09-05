# Troubleshooting

## MATLAB is not found

Run MATLAB with its full local executable path or add it to `PATH`. Do not edit
repository files to store a personal installation path.

## A manifest check fails

First distinguish a failed **historical commit** from a failed check on the
release you downloaded. GitHub's file page shows the check status of the last
commit that modified that particular file. An old red cross can remain visible
after later repository-wide fixes. Inspect the commit SHA and the
[current workflow runs](https://github.com/globaswu/aeroverify-thesis-artifacts/actions/workflows/verify.yml).

The initial publication, commit `1a32055`, failed with
`Size mismatch for matlab/artifact_repository_root.m` because raw sizes were
sensitive to Windows line-ending conversion. Commit `d159aaa` introduced
portable text-byte comparison. The current verifier normalizes text to UTF-8
without a byte-order mark and with LF line endings before comparing sizes and
hashes; binary files are checked byte-for-byte. The portability regression test
also checks that changed content and missing files are still rejected.

If your **current local check** fails, do not use the affected data until the
mismatch is explained. Download and extract the complete tagged ZIP into a
fresh folder; do not mix revisions or download individual scripts in place of
the package. Keep generated files under `generated/`. Include the exact error,
filename, and release/commit when reporting a remaining failure.

Do not regenerate the manifest merely to make an unexplained mismatch pass.
Maintainers should update it only after reviewing the intentional changes and
rerunning the relevant validation checks.

## No figure window appears

The public plotting commands export images and close their hidden figures.
Open the PNG or PDF files in the requested output folder. For example,
`reproduce_topology('fcc',fullfile(pwd,'generated','fcc'))` writes
`generated/fcc/fcc_observed_pareto.png` and
`generated/fcc/fcc_feasibility_score.png`.

## MATLAB reports an unknown function or cannot find the data

Set MATLAB's Current Folder to the repository root containing `matlab`, `data`,
and `config`, then run `addpath('matlab')`. The `matlab -batch ...` examples are
terminal commands; do not paste the whole command into MATLAB's Command Window.

## A table column is reported as missing

Use the tagged release as a unit. Mixing data from `main` with scripts from a
tag can create a schema mismatch.

## Figure export warns about vector complexity

MATLAB may warn that a vector export is complex. This is not a numerical test
failure. Check the generated PDF and PNG visually; use the PNG for rapid
preview and the PDF for print-quality vector output.

## A commercial solver is requested

The public workflows should never request one. Stop and inspect the command.
New solver evaluations require a separate, locally reviewed configuration and
licensed assets described in `docs/FULL_SOLVER_WORKFLOW.md`.
