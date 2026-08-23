# Notice

This repository contains project-owned reproduction scripts and curated
numerical tables supporting Sen Wu's doctoral thesis.

The modular cTSEMO implementation in `matlab/+ctsemo` is a research derivative
of the TSEMO method reported by Eric Bradford, Artur M. Schweidtmann, and Alexei
A. Lapkin. The original authors do not endorse this derivative release and are
not responsible for its modifications or conclusions. The canonical upstream
TSEMO repository is <https://github.com/Eric-Bradford/TS-EMO>, pinned in the
related cTSEMO release at commit `9ec2aa2f54d1232f80d37494ac067f2ebc112688`.

The geometry feasibility field is a clipped zero-noise Gaussian-process
regression mean fitted to binary labels. It is an operational score and is not,
without separate calibration evidence, a posterior probability of feasibility.
