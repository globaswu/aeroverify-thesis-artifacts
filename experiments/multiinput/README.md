# Four-input aerostructural campaign

Research question: within the evaluated four-dimensional domain, how do aspect
ratio, taper ratio, and two lattice-sizing ratios interact with induced drag,
compliance, mass, and stress feasibility?

```powershell
matlab -batch "addpath('matlab'); reproduce_multiinput(fullfile(pwd,'generated','multiinput'))"
```

Inputs are under `data/multiinput`. Expected: 100 evaluations, 70 feasible,
and 38 observed Pareto points. The initial design contains 16 corners and 14
Latin-hypercube points; 70 evaluations are adaptive. The recorded initial seed
is 20260809.

The record spans two mesh epochs and includes the accepted replacement for
case 65. The command does not rerun the historical sequential campaign.
