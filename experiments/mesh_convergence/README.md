# Structural-mesh sensitivity

Research question: how sensitive are selected compliance, displacement,
stress-tail, modal-frequency, and flutter diagnostics to the tested structural
mesh edge lengths and geometric tolerances?

```powershell
matlab -batch "addpath('matlab'); reproduce_mesh_convergence(fullfile(pwd,'generated','mesh_convergence'))"
```

Inputs are the path-free 17-row summary and the case-64 root-19 velocity-damping
table under `data/mesh_convergence`.

This is a reconstruction of saved results. It does not generate a new mesh or
rerun Nastran, and it does not make raw maximum stress mesh-independent.
