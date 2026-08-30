# Harmonized topology flutter reassessment

Run the solver-free consistency check with:

```powershell
matlab -batch "addpath('matlab'); reproduce_flutter_reassessment(fullfile(pwd,'generated','flutter_reassessment'))"
```

The command reads `data/flutter/harmonized_sol145_results.csv`, verifies the
65-case schema and strict-pass outcome, and writes a topology-level summary.
It does not launch MSC Nastran or contact an archive or license service.

Expected result:

| Topology | Cases | Strict pass | Least-negative maximum g | Case |
|---|---:|---:|---:|---:|
| BCC | 15 | 15 | -3.6565278e-7 | 25 |
| FCC | 32 | 32 | -4.0452300e-7 | 54 |
| SC | 18 | 18 | -4.2481376e-6 | 35 |
| Total | 65 | 65 | -3.6565278e-7 | BCC 25 |

Positive values in the historical coarse-grid records motivated the
reassessment; they are not interpreted here as physical flutter onset. The
least-negative values are numerical screening results, not engineering safety
margins.
