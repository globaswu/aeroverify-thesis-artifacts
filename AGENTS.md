# Guidance for human and AI assistants

1. Run `tools/verify_manifest.ps1` before using any numerical file.
2. Treat `data/` as immutable. Write derived material only beneath
   `generated/` or a user-specified output directory.
3. Use evaluated objectives, stored constraints, and observed Pareto masks.
   Never replace these with surrogate predictions or a surrogate Pareto front.
4. Describe the geometry feasibility field as an uncalibrated deterministic
   binary-label score, not as a posterior probability.
5. Preserve campaign provenance. Do not reinterpret the FCC, BCC, and SC
   flutter labels under one common rule.
6. Do not infer missing stresses, damping histories, acquisition fields, or
   solver settings. Report `Not found in available files.`
7. Do not launch nTopology, MSC Nastran, OpenFOAM, or any remote archive action
   automatically. The repository contains no authorized commercial-solver
   execution configuration.
8. When reporting a value, give the repository file and the command or
   calculation that produced it.
9. Keep normalized two-dimensional domain plots square.
10. Record exact commands, release tag, and manifest verification result in any
    derived report.
