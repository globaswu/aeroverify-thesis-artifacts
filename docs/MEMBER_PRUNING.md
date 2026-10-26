# Response-guided pruning of selected lattice wings

The member-pruning study examines whether material can be removed from lightly
loaded parts of an evaluated lattice wing while retaining its sampled static and
flutter acceptance. Cell-level sizing supplies the initial layout; the second
step uses the response of individual finite element members to construct a
lighter candidate. The selected starting cases are **FCC 70, FCC 26 and SC 53**.
The original campaign records remain unchanged.

**Implementation status, 26 October 2026:** the selection, deck checks and
result-assessment scripts are implemented. This addition documents the algorithm;
it does not report completed pruning outcomes or a measured mass reduction.
The licensed-solver calculations are separate from the solver-free public package.

## Relationship to ESO, BESO and SIMP

The implemented operation is **one deterministic, ESO-inspired pruning pass**.
Its relationship to established methods depends on the update rule:

| Update | Appropriate description |
|---|---|
| Remove selected low-demand members once, then reanalyse | The implemented response-guided pruning experiment |
| Repeatedly remove inefficient members and recompute the response | An ESO-like evolutionary topology procedure |
| Remove and restore or add members through a sensitivity-based evolution rule | A BESO-like procedure |
| Change the physical diameters of retained members | Member sizing optimization |
| Optimize material-density variables through penalized stiffness interpolation | SIMP |

The original ESO procedure progressively removes low-stressed material
[1]. BESO extends evolutionary removal with material addition [2]. SIMP instead
uses density variables and a penalized interpolation of element stiffness [3].
The present implementation neither iterates to convergence, restores deleted
members, nor changes their diameters. Consequently, its output is a candidate
topology reduction, rather than a completed ESO or BESO optimum.

## Baseline response and removal units

Selection requires the complete, completed SOL 144 response for the **unchanged
starting model**, over its nine incidence subcases from -4 to 12 degrees. Every
active CBEAM must have finite, nonnegative strain energy and a finite absolute
normal-stress measure in every subcase. Duplicate or missing element/subcase
records stop selection. Missing output is never assigned zero demand.

For these selected cases, the archived original `aerov144.f06` files were not
available. The retained source decks requested `ESE(PRINT,THRESH=1)`, which filters
printed energy output. The preparation step therefore regenerates the unchanged
model with complete beam stress output and `ESE(PRINT,THRESH=0)=ALL`. The physical
structural includes, trim conditions and loads are retained. If compatible,
complete original outputs are available, this recovery run can be omitted.

The extraction record hashes the submitted deck, its full INCLUDE closure and
the F06. Selection verifies those hashes against the baseline copies. Global
total-energy headers provide the total structural energy, including the skin;
all beam energies must be present. Missing non-beam energy rows remain recorded
as unknown and are not substituted into the global denominator.

A removal unit is a **maximal degree-two CBEAM chain**, ending at a beam junction
or a protected node. This groups subdivisions of a branch into a single removal
decision. A verified mapping from these FE chains to the original nTop physical
struts is **not found in available files**. Closed degree-two cycles are retained.

An entire chain is protected if any of its nodes participates in a shell or
solid, a retained nonbeam element, SPC/MPC constraints, spline-support SET1,
explicit load or mass, beam orientation reference, or another supported external
reference. Unrecognized bulk-card types stop the operation for explicit review.
These rules preserve the skin attachment and root/interface definitions.

The implemented parser supports constant circular PBEAML ROD sections, basic
GRID coordinates, `WTMASS=1`, and zero CBEAM offsets. Other section definitions,
coordinate transformations or offsets require explicit implementation before
selection can proceed.

## Selection algorithm

For chain \(c\) and subcase \(j\), define:

- \(U_{c,j}\): sum of its beam strain energies;
- \(U_{\mathrm{tot},j}\): total structural strain energy;
- \(m_c\): assembled FE mass of the chain, including any nonstructural mass per length;
- \(\sigma_c\): largest absolute recovered beam normal stress over all its elements
  and all nine subcases.

The stress candidate gate is

\[
\sigma_c\leq 0.02\,(220\ \mathrm{MPa})=4.4\ \mathrm{MPa}.
\]

The 4.4 MPa value is a selection threshold, separate from the 220 MPa physical
stress-screen limit. Eligible low-stress chains are ranked using

\[
r_c=\frac{1}{m_c}\max_{j=1,\ldots,9}
\left(\frac{U_{c,j}}{U_{\mathrm{tot},j}}\right).
\]

Thus, the score is the worst-subcase energy fraction per unit FE mass. The method
first preserves connectivity, then considers removal in ascending score order:

1. Join the endpoints of all noncandidate chains in a disjoint-set graph.
2. Visit candidate chains in descending \(r_c\), descending stress utilization,
   and ascending smallest element ID. Retain a chain whenever it joins two
   previously separate graph components. This constructs a maximum-importance
   connectivity forest around the already-retained chains.
3. Visit the remaining candidates in ascending \(r_c\), ascending stress
   utilization, and ascending smallest element ID.
4. Select a whole chain only if adding it respects **both cumulative budgets**:

\[
\sum_{c\in\mathcal R}m_c\leq0.05\,M_{\mathrm{beam,baseline}},
\qquad
\sum_{c\in\mathcal R}U_{c,j}\leq0.005\,U_{\mathrm{tot},j}
\quad\text{for every }j.
\]

Here \(\mathcal R\) is the selected set. The mass budget is **5% of baseline FE
beam mass**, not 5% of the whole wing mass. The energy budget is **0.5% separately
in each subcase**, rather than a budget averaged over the load cases. A chain
that exceeds a budget is skipped; later candidates are still considered.

Equivalent pseudocode is:

```text
require complete matching baseline stresses and beam energies in all nine cases
form maximal degree-two chains; identify protected chains
candidate := unprotected chain whose all-case stress envelope <= 4.4 MPa
union all noncandidate chain endpoints
for candidate in descending importance order:
    if joining its endpoints connects two components: retain it
for remaining candidate in ascending importance order:
    if cumulative beam-mass and all nine energy budgets remain satisfied:
        select the whole chain
write a separate candidate model; reparse and verify retained references
run SOL 103, SOL 144 and SOL 145; assess actual candidate results
```

The energy budget uses the **baseline response**. It does not predict the exact
response after load redistribution and is not a guarantee that compliance will
increase by at most 0.5%. The current finalizer reports the reanalysed compliance
change; it does not impose an additional compliance-increase acceptance limit.

## Model editing and verification

The selected CBEAM cards are removed from a new model copy. An internal GRID is
removed only when it no longer belongs to a retained beam and has no protected
reference. Retained cards are copied without changing their fields, properties,
coordinates or connectivity. The baseline files are not overwritten.

The saved model is reparsed and checked for the exact expected element and GRID
sets. Every original beam component must remain connected on its surviving nodes;
no whole component may disappear. All protected nodes must remain. The removed
mass calculated from the selected chains must agree with the difference between
the original and saved beam models. Input hashes are rechecked before and after
writing. Graph connectivity is a preparation check; solver reanalysis determines
the resulting stiffness and aeroelastic response.

The detailed record consists of:

| File | Contents |
|---|---|
| `pruning_plan.csv` | Every chain, its demand, ranking, protection or retention reason, and nine energies |
| `removed_elements.csv` | Exact removed element IDs, nodes, properties, lengths and FE masses |
| `pruning_summary.json` | Thresholds, selection counts, energy budgets, input hashes and mass prediction |
| `pruning_result.json` | Completed paired assessment, or an explicit evidence/physical rejection |

## Reanalysis and mass accounting

A selected batch is accepted only after these checks:

- **SOL 103:** 40 requested clamped structural modes are recovered with positive
  eigenvalues, frequencies and generalized masses.
- **SOL 144:** complete stress, displacement and energy evidence; finite trim and
  compliance; and maximum sampled shell von Mises or beam absolute normal stress
  at most 220 MPa.
- **SOL 145:** exactly 20 roots at each of 37 submitted velocities, giving 740
  valid PK samples; strict \(g\leq0\) at every sample; and every actual reduced
  frequency inside the submitted MKAERO1 range, allowing only the printed-\(k\)
  rounding tolerance. Missing, duplicate, nonfinite,
  zero-frequency or inconsistent rows are flagged.
- **Mass:** the predicted removed FE mass agrees with the difference between
  the two completed Nastran assembled masses. The comparison tolerance is
  \(\max(0.001\ \mathrm{kg},10^{-5}M_{\mathrm{before}})\), reflecting printed
  mass precision. A positive confirmed mass reduction is required.

The paired trim calculation uses the assembled FE wing mass in both models,
the printed final wind-axis lift coefficient, and the same reference conditions.
For the two-wing model, compliance is \(4U_{\mathrm{half}}\), interpolated at the
lift-equivalent trim condition. Changes in mass therefore also enter the required
lift and trim calculation.

FE beam mass is not the same quantity as nTop's implicit-union geometric mass.
The FE contribution uses \(\rho A L\) plus nonstructural mass, and may overlap
geometrically at joints. The procedure reports the exact paired FE mass change;
it does not subtract that number from the original nTop objective to invent a
new geometric mass. Geometric mass after reconstruction remains a separate task.

The outcome is `pruning_validated` when the required evidence and sampled checks
pass, `pruning_rejected` for a complete physical failure, or
`assessment_data_error` for incomplete or inconsistent evidence. The sampled
linear static/flutter checks do not evaluate skin or member buckling, joint
strength, manufacturing reconstruction, or a converged flutter-speed margin.
The before/after mass and compliance should therefore be compared together with
the same reference wing, rather than treating removal alone as an improvement.

## Implementation trace

This description was checked against the study implementation functions
`load_results`, `validate_result_provenance`, `make_chains`, `choose` and
`write_outputs` in `prune_members.py`, together with the static extractor and
paired-result finalizer. The selection-script SHA-256 at documentation review is:

```text
5b1da811c6554cb3f860dfcebb628695d14cda23385bd9f81df091840cc143fc
```

The local orchestration is deliberately not advertised as a portable public
solver launcher: it contains user-specific archive and licensed-solver setup.
This document supplies the complete selection rule and verification contract
without distributing private solver outputs or thesis recordings. The original
published campaign datasets and `thesis` release tag are unchanged.

## References

1. Xie, Y. M., and Steven, G. P. (1993). A simple evolutionary procedure for
   structural optimization. *Computers & Structures*, 49(5), 885-896.
   [doi:10.1016/0045-7949(93)90035-C](https://doi.org/10.1016/0045-7949(93)90035-C).
2. Huang, X., and Xie, Y. M. (2007). Convergent and mesh-independent solutions for
   the bi-directional evolutionary structural optimization method. *Finite
   Elements in Analysis and Design*, 43(14), 1039-1049.
   [doi:10.1016/j.finel.2007.06.006](https://doi.org/10.1016/j.finel.2007.06.006).
3. Sigmund, O. (2001). A 99 line topology optimization code written in Matlab.
   *Structural and Multidisciplinary Optimization*, 21, 120-127.
   [doi:10.1007/s001580050176](https://doi.org/10.1007/s001580050176).
