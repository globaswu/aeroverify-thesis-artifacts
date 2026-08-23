# FCC, BCC, and SC lattice sizing

Research question: within each frozen 71-case record, which evaluated feasible
designs form the mass-compliance Pareto set, and what binary-label geometry
score is reconstructed from the complete record?

```powershell
matlab -batch "addpath('matlab'); reproduce_topology('fcc',fullfile(pwd,'generated','fcc'))"
```

Replace `fcc` with `bcc` or `sc`. Inputs are the corresponding `data/<topology>`
folder and `config/reproduction_config.json`. Expected count triples are FCC
71/33/26, BCC 71/27/17, and SC 71/32/8.

The command does not rerun geometry, finite element, or flutter solvers. It
does not convert the geometry score into a calibrated probability.
