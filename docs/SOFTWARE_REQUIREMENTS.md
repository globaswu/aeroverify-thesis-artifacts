# Software requirements

## Public solver-free workflows

- MATLAB R2025b: validated release.
- Minimum MATLAB release: Not found in available files.
- The cTSEMO objective Gaussian processes are implemented in repository code
  and do not require Statistics and Machine Learning Toolbox.
- Global Optimization Toolbox: used by the optional GA-primary path.
- Statistics and Machine Learning Toolbox: required only by the separate
  Introduction classifier comparison and random-forest diagnostic in the
  canonical cTSEMO repository.

The packaged figure replay and integrity tests do not intentionally call
nTopology, MSC Nastran, or OpenFOAM.

## New physical evaluations

The historical workspace used the following external stack:

- MSC Nastran 2019.0;
- nTopology CLI; an inspected current installation was 5.50.2, but the exact
  historical campaign version was not found in available files;
- MATLAB R2025b with Optimization, Statistics and Machine Learning, Global
  Optimization, and Parallel Computing Toolboxes;
- WSL Ubuntu 22.04 and OpenFOAM 13 for optional polar regeneration.

Exact Gmsh, MPI, and Python-package versions: Not found in available files.

These products and their license configuration are not part of the release.
`config/external_tools.example.json` is deliberately disabled and contains no
machine path or license-server setting.
