# Fixed-area planform study

Research question: how do evaluated aspect ratio and taper ratio trade trim
induced drag against two-wing trim compliance for the fixed FCC reference cell?

```powershell
matlab -batch "addpath('matlab'); reproduce_planform(fullfile(pwd,'generated','planform'))"
```

Input: `data/planform/evaluations_cases001_050.csv`. Expected: 50 evaluations,
39 feasible, and 14 observed Pareto points. The final ten cases contain eight
primary and two challenger selections.

The exact candidate-selection mechanism for cases 1-40 is not fully
reconstructed. The command replays the frozen evaluated record only.
