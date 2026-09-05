# Reproducibility scope

## Supported claims

The repository independently recomputes finite-sample feasibility counts,
observed Pareto membership, selected summary statistics, and publication-ready
plots from frozen compact records. It also runs the binary-label score fitting
used by the two-input public visualizations and verifies exact interpolation at
the evaluated labels. The harmonized SOL 145 table additionally supports a
solver-free consistency check of 65 strict-screen outcomes while preserving
the historical optimization labels separately.

The seven-solver benchmark supplies the evaluated input vectors, objectives,
binary labels, observed Pareto sets, empirical reference fronts, and metric
tables for all 49 solver/problem trajectories. Figures 3.7 and 3.8 can be
replotted from their adjacent CSV files. cTSEMO and HyperMapper received binary
labels; the other five methods received continuous constraint margins.
Post hoc audit margins in the released binary-method rows do not change that
information boundary. One trajectory per solver/problem cannot establish a
statistical ranking or isolate an effect caused by the constraint information.

The thesis shows nTop screenshots in Figure 2.8. Its CSV supports a point-cloud
reconstruction of the mode shape, not nTop's precise shading or camera view.

This is a post-processing and record-consistency result. It establishes that
the released scalar evidence supports the reported tabulations and plotted
relationships under the stored labels.

## Claims not supported by the public package alone

The package does not:

- recreate nTopology geometry or meshes;
- rerun MSC Nastran SOL 103, 144, or 145;
- regenerate the OpenFOAM reference polar;
- validate physical-model fidelity against experiment or higher-fidelity data;
- establish optimizer superiority from the expensive single trajectories;
- reconstruct missing historical acquisition settings;
- rewrite historical topology flutter labels or acquisition histories; or
- recover field-level output for records retained only as scalar summaries.

The public harmonized table supports the bounded statement that all 65 targeted
reruns passed the implemented 18-value-grid screen. It does not support
reduced-frequency convergence, automatic mode/root correspondence, a causal
topology comparison, or certification-level flutter clearance.

## Three levels

| Level | Meaning | Public status |
|---|---|---|
| A | Recompute tables and plots from compact evaluated outputs | Fully executable here |
| B | Inspect and test the modular cTSEMO core | Source included; analytical campaign archive is separate |
| C | Generate new coupled physical evaluations | Documented interface only; licensed tools and omitted assets required |

When citing an output, state its level. Do not call Level A a full simulation
rerun.
