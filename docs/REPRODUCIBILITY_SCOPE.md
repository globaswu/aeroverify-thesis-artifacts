# Reproducibility scope

## Supported claims

The repository independently recomputes finite-sample feasibility counts,
observed Pareto membership, selected summary statistics, and publication-ready
plots from frozen compact records. It also runs the binary-label score fitting
used by the two-input public visualizations and verifies exact interpolation at
the evaluated labels.

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
- make topology-specific flutter labels directly interchangeable; or
- recover field-level output for records retained only as scalar summaries.

## Three levels

| Level | Meaning | Public status |
|---|---|---|
| A | Recompute tables and plots from compact evaluated outputs | Fully executable here |
| B | Inspect and test the modular cTSEMO core | Source included; analytical campaign archive is separate |
| C | Generate new coupled physical evaluations | Documented interface only; licensed tools and omitted assets required |

When citing an output, state its level. Do not call Level A a full simulation
rerun.
