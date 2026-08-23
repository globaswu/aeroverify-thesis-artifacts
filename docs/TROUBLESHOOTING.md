# Troubleshooting

## MATLAB is not found

Run MATLAB with its full local executable path or add it to `PATH`. Do not edit
repository files to store a personal installation path.

## A manifest check fails

Do not use the data until the mismatch is explained. Re-download the tagged
release first. Maintainers should update the manifest only after reviewing the
intentional file change and rerunning all MATLAB tests.

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
