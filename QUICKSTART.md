# Quick start

## 1. Download

Download the `thesis` source archive from the GitHub release and extract
it to a writable directory. Do not place generated files under `data/`.

## 2. Verify the release

From PowerShell in the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\verify_manifest.ps1
```

A successful run reports the number of listed files and confirms hashes,
sizes, excluded file types, machine-path screening, and file completeness.

## 3. Run all solver-free checks

```powershell
matlab -batch "addpath('matlab'); run_tests"
```

The tests check the packaged numerical records and create all public outputs in
a temporary directory. They do not call nTopology, MSC Nastran, or OpenFOAM.

## 4. Keep the generated outputs

```powershell
matlab -batch "addpath('matlab'); reproduce_all(fullfile(pwd,'generated'))"
```

Study-specific commands are also available:

```powershell
matlab -batch "addpath('matlab'); reproduce_topology('fcc',fullfile(pwd,'generated','fcc'))"
matlab -batch "addpath('matlab'); reproduce_planform(fullfile(pwd,'generated','planform'))"
matlab -batch "addpath('matlab'); reproduce_multiinput(fullfile(pwd,'generated','multiinput'))"
matlab -batch "addpath('matlab'); reproduce_mesh_convergence(fullfile(pwd,'generated','mesh_convergence'))"
matlab -batch "addpath('matlab'); reproduce_flutter_reassessment(fullfile(pwd,'generated','flutter_reassessment'))"
```

Expected filenames and numerical postconditions are listed in
[docs/EXPECTED_OUTPUTS.md](docs/EXPECTED_OUTPUTS.md).

## 5. Understand the boundary

The public commands reconstruct analyses from evaluated scalar records. A new
physical case needs licensed external software and project assets that are not
in this repository. Read [docs/REPRODUCIBILITY_SCOPE.md](docs/REPRODUCIBILITY_SCOPE.md)
before describing the package as a simulation rerun.
