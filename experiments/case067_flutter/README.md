# FCC case-67 MKAERO1 diagnostic

Research question: how did the tracked-point damping summaries change when the
four reduced-frequency hard points were replaced by the 18-point grid while
the declared SOL 145 setup was held fixed?

```powershell
matlab -batch "addpath('matlab'); reproduce_case067_flutter(fullfile(pwd,'generated','case067_flutter'))"
```

Input: `data/diagnostics/fcc_case067/old_vs_18_point_all20.csv`. Expected: 20
tracked points, each summarizing 37 velocities. For point 3, the maximum stored
damping changes from `2.2834729e-5` to `-8.5449944e-6`.

The result is a controlled numerical sensitivity check, not experimental
flutter validation and not a fresh SOL 145 solve.
