# Harmonized SOL 145 topology reassessment

`harmonized_sol145_results.csv` is a path-free projection of the completed
retrospective flutter campaign. It contains 65 targeted cases: 15 BCC, 32 FCC,
and 18 SC. All 65 pass the implemented strict numerical screen.

Each row reports:

- topology and case index;
- the maximum retained PK damping value over 20 roots and 37 velocities;
- strict pass status and expected row counts;
- completion time;
- receipt and evidence-fingerprint hashes; and
- a repository-logical evidence identifier.

No executable path, network share, license host, credential, native solver
file, or raw F06/OP2/H5 array is included.

The reassessment is a derived verification layer. It does not rewrite the
historical aggregate labels or candidate-selection histories in `data/fcc`,
`data/bcc`, or `data/sc`. Together with the prior FCC case-67 diagnostic and 26
static-admissible BCC/SC continuation cases already evaluated under the strict
configuration, it establishes common-screen evidence for all 92
static-admissible topology cases through case 71.

The result is bounded to the implemented 18-value MKAERO1 support, 20 tracked
roots, zero structural-damping assumption, and 30--150 m/s velocity interval.
It is not reduced-frequency convergence, independent physical validation, a
topology ranking, or certification-level flutter clearance.
