# Licensed-solver workflow boundary

This document describes the interface needed for a new coupled evaluation. It
is not an executable historical campaign archive.

## Conceptual sequence

1. Map optimizer variables to a fixed-area planform and lattice parameters.
2. Supply the mapped parameters to a versioned nTopology project.
3. Export shell and beam geometry and build the structural/aerodynamic deck.
4. Run MSC Nastran static, modal, and flutter solutions.
5. Extract trim, compliance, component stress, modal, and damping fields.
6. Apply the declared simulation, trim, stress, and flutter checks.
7. Store a compact evaluated row and immutable provenance receipt.
8. Update the optimizer only after the evaluation is finalized.

## Geometry input interface

The physical adapter receives an 18-column row:

```matlab
Input = [zeros(1,11), s, croot, lambda, tskin, a, r1, r2];
```

| Columns | Quantity | Definition and units |
|---|---|---|
| 1–11 | Reserved PARSEC inputs | Zero throughout the thesis; these do not define the airfoil used in the calculations. |
| 12 | `s` | Wing semispan (m). |
| 13 | `croot` | Root chord (m). |
| 14 | `lambda` | Tip chord divided by root chord. |
| 15 | `tskin` | Skin thickness (m). |
| 16 | `a` | Periodic lattice cell size before warping and trimming (m). |
| 17 | `r1` | Root-end geometric strut diameter divided by cell size, `t1/a`. |
| 18 | `r2` | Tip-to-root geometric strut diameter ratio, `t2/t1`. |

The fixed NACA 65-210 airfoil is supplied by a coordinate file, not generated
from the reserved PARSEC inputs. The available interface does not establish
individual physical names for those inactive slots. Airfoil shape is not
optimized in the thesis.

The geometric strut diameter is `t1 = a*r1` at the root and `t2 = t1*r2` at the
tip. It varies linearly with spanwise coordinate: `t(y) = t1 + (t2-t1)*y/s`,
for `0 <= y <= s`. These geometric diameters are distinct from the beam
section properties exported for structural analysis. At fixed full-wing
area `S`, the planform mapping uses `b = sqrt(AR*S)`, `s = b/2`,
`croot = S/(s*(1+lambda))`, and `ctip = lambda*croot`.

SC, BCC, and FCC are separate lattice-model choices, not additional numeric
columns in this row. Chapter 4 states which inputs vary in each campaign.

## Required external assets

- a rights-cleared, versioned nTopology project matching the selected campaign;
- nTopology CLI authentication;
- MSC Nastran 2019.0 and a valid local license configuration;
- material, flight-condition, mesh, CAERO1, SPLINE1, MKAERO1, and modal settings;
- the reference polar or the OpenFOAM environment needed to regenerate it;
- case-specific input templates and an output directory with adequate storage.

These assets are not in this repository. Several historical nTopology projects
exceed GitHub's ordinary file limit, and redistribution permission was not
established from the available files.

## User-owned local configuration

This repository intentionally contains no licence-server endpoint, credential,
remote-archive address, or user-specific host path. Each user must establish
these settings for their own installation:

1. Copy `config/external_tools.example.json` to
   `config/external_tools.local.json`; the local file is ignored by Git.
2. Configure nTop and MSC Nastran licensing through the vendor-supported local
   environment or a private wrapper. Do not place licence endpoints or
   credentials in tracked files.
3. Leave `remote_archive_enabled` set to `false` unless an archive is required.
   If enabled, configure an archive backend owned by the user through the
   untracked local configuration or a secret manager.
4. Remote archiving is optional and is not required to perform a local solver
   evaluation.

Published examples must retain placeholders only. Before committing, verify
that configuration files contain no server names, IP addresses, usernames,
tokens, network shares, or machine-specific absolute paths.
## Why raw launchers are absent

The research launchers contain machine-specific executable paths, private
archive locations, internal license information, checkpoint assumptions, and
source-hash guards for dated campaign states. The physical adapter also calls
legacy third-party optimizer components for which a clean redistribution grant
was not established. Publishing those files verbatim would be neither portable
nor a reliable one-command reproduction route.

`config/external_tools.example.json` shows the neutral configuration fields
required by a future rights-cleared wrapper. Remote archiving defaults to
disabled. No public command should silently attempt a commercial solve.

## Historical limitations

- Exact original bytes for all topology templates were not recovered under
  stable canonical names.
- The final four-input trajectory includes a corrected checkpoint, case-65
  replacement, and a later mesh epoch.
- A fresh result should therefore be described as a new evaluation under a
  documented configuration, not as a bitwise replay, unless every pinned asset
  and source hash is available.
