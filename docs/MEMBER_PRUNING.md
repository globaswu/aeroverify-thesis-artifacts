# Response-guided pruning of selected lattice wings

The member-pruning study examines whether material can be removed from lightly
loaded parts of an evaluated lattice wing while retaining its sampled static and
flutter acceptance. Cell-level sizing supplies the initial layout; the second
step uses the response of individual finite element members to construct a
lighter candidate. The selected starting cases are **FCC 70, FCC 26 and SC 53**.
The original campaign records remain unchanged.

**Implementation status, 27 October 2026:** the selection, deck checks and
result-assessment scripts are implemented. This addition documents the algorithm;
it does not report completed pruning outcomes or a measured mass reduction.
The licensed-solver calculations are separate from the solver-free public package.

## Relationship to ESO, BESO and SIMP

The implemented operation is **one deterministic, stress-based, ESO-inspired
pruning pass**. Stress-only selection is the default; an energy-guarded variant
is available explicitly.
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

Selection requires complete SOL 144 beam stresses for the **unchanged
starting model**, over its nine incidence subcases from -4 to 12 degrees. Every
active CBEAM must have a finite, nonnegative absolute normal-stress measure in
every subcase. Duplicate or missing stress records stop selection. The default
does not require member strain energies: missing energies remain unknown,
represented by blank CSV fields or JSON `null`, rather than zero.

A compatible baseline can be recovered from **F06, OP2, or previously extracted
tables with verified provenance and coverage**. The absence of an F06 file does
not require another solver run. The retained OP2 inventories for FCC 70, FCC 26
and SC 53 contain both `OES1X1` stress and `ONRGY1` energy table families. Reuse
requires checking the stress element IDs, all nine subcases, recovered values
and source-model correspondence; table-family presence alone does not establish
completeness. Energy completeness is additionally required only for the optional
energy-guarded selection and for response metrics that use energy.

The original printed-energy controls also differ: FCC 26 requests
`ESE(PRINT,THRESH=0)`, whereas FCC 70 and SC 53 request `ESE(PRINT,THRESH=1)`.
These PRINT controls do not by themselves establish the contents or completeness
of the retained OP2. The F06 extractor is implemented, and an OP2-to-table adapter
is being verified against the same selection-input contract. A new unchanged
baseline run is required only when compatible complete response evidence cannot
be recovered, or when a deliberately controlled paired comparison requires a
new baseline. Such a run requests complete stresses and
`ESE(PRINT,THRESH=0)=ALL`, retaining the physical structural model, trim
conditions and loads. Missing energies alone do not require a new baseline for
the default stress-only selection.

The extraction record identifies the source result and hashes the consumed
evidence, submitted deck and full INCLUDE closure. The F06 route hashes the
whole source file. For an archived OP2 inspected through selected table blocks,
the adapter records file identity and hashes of the consumed blocks; it does
not imply that the whole OP2 has been hashed. Selection verifies the response
provenance against the baseline copies. When energy-guarded selection is requested, all
beam energies must be present and the total structural energy must include the
skin. The F06 route uses global total-energy headers; an OP2 route must recover
an equivalent verified quantity. Missing non-beam energy rows remain recorded
as unknown and are not substituted into that denominator.

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

## Default stress-only selection

For chain \(c\), define \(m_c\) as its assembled FE mass, including any
nonstructural mass per length, and \(\sigma_c\) as the largest absolute recovered
beam normal stress over all its elements, reported recovery locations and all
nine subcases. Its stress utilization is

\[
q_c=\frac{\sigma_c}{220\ \mathrm{MPa}}.
\]

The candidate gate is

\[
\sigma_c\leq 0.02\,(220\ \mathrm{MPa})=4.4\ \mathrm{MPa}.
\]

The 4.4 MPa value is a selection threshold, separate from the 220 MPa physical
stress-screen limit. It does **not** assume uniform stress in a member. CBEAM
normal stress includes axial and bending contributions and can differ between
its ends and cross-section recovery points. The maximum is a scalar envelope
used for selection, not a uniform stress field or an inferred strain energy.
It also does not constitute a beam shear/torsion check.

Using the maximum rather than the mean makes this candidate gate conservative
with respect to averaging: for the same reported absolute stresses and the same
threshold, every chain satisfying the maximum-stress gate also satisfies the
mean-stress gate, while the converse need not hold. A local high-stress recovery
point or demanding load case therefore cannot be hidden by averaging it with
lightly loaded values. This set-inclusion property concerns candidate selection;
it does not prove that the selected deletion is the safest possible or that it
removes the minimum necessary number of members. Reanalysis tests the resulting
load redistribution and aeroelastic response.

The method first preserves connectivity, then removes the lowest-stress eligible
chains:

1. Join the endpoints of all noncandidate chains in a disjoint-set graph.
2. Visit candidate chains in descending \(q_c\), ascending \(m_c\), and ascending
   smallest element ID. Retain a chain whenever it joins two previously separate
   graph components. The forest therefore favors higher-stress candidates;
   exact stress ties favor the lighter chain.
3. Visit the remaining candidates in ascending \(q_c\), descending \(m_c\), and
   ascending smallest element ID. Exact stress ties favor the larger mass saving.
4. Select a whole chain only if the cumulative selected mass satisfies

\[
\sum_{c\in\mathcal R}m_c\leq0.05\,M_{\mathrm{beam,baseline}}.
\]

Here \(\mathcal R\) is the selected set. The mass budget is **5% of baseline FE
beam mass**, not 5% of the whole wing mass. A chain that exceeds the budget is
skipped; later candidates are still considered. Energy values do not affect
eligibility, ranking or the removal budget in this default mode.

Equivalent pseudocode is:

```text
require complete matching baseline beam stresses in all nine cases
form maximal degree-two chains; identify protected chains
candidate := unprotected chain whose all-case stress envelope <= 4.4 MPa
union all noncandidate chain endpoints
for candidate in descending stress order, then lighter mass, then minimum ID:
    if joining its endpoints connects two components: retain it
for remaining candidate in ascending stress order, then larger mass, then minimum ID:
    if cumulative beam-mass budget remains satisfied:
        select the whole chain
write a separate candidate model; reparse and verify retained references
run SOL 103, SOL 144 and SOL 145; assess actual candidate results
```

## Optional energy-guarded selection

The explicit `--selection-mode energy-guarded` option retains the same stress
candidate gate, protected chains and 5% beam-mass cap, but requires complete
beam energies and total structural energies for all nine subcases. For
\(U_{c,j}\), the chain energy, and \(U_{\mathrm{tot},j}\), the total structural
energy including the skin, its ranking is

\[
r_c=\frac{1}{m_c}\max_{j=1,\ldots,9}
\left(\frac{U_{c,j}}{U_{\mathrm{tot},j}}\right).
\]

Forest retention uses descending \(r_c\), descending stress utilization and
ascending smallest element ID. Removal uses ascending \(r_c\), ascending stress
utilization and ascending smallest element ID. The selected set must also obey

\[
\sum_{c\in\mathcal R}U_{c,j}\leq0.005\,U_{\mathrm{tot},j}
\quad\text{for every }j.
\]

This optional 0.5% budget is applied separately to each **baseline** subcase,
rather than to an average. It does not predict the exact response after load
redistribution or guarantee that reanalysed compliance increases by at most
0.5%. The finalizer reports the actual compliance change and does not impose
an additional compliance-increase acceptance limit in either mode.

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
| `pruning_plan.csv` | Every chain, its demand, ranking, protection or retention reason, and available energy evidence |
| `removed_elements.csv` | Exact removed element IDs, nodes, properties, lengths and FE masses |
| `pruning_summary.json` | Selection mode, thresholds, counts, optional energy budget, input hashes, unknown-energy counts and mass prediction |
| `pruning_result.json` | Completed paired assessment, or an explicit evidence/physical rejection |

## Reanalysis and mass accounting

A selected batch is accepted only after these checks:

- **SOL 103:** 40 requested clamped structural modes are recovered with positive
  eigenvalues, frequencies and generalized masses.
- **SOL 144:** complete all-nine-case structural stresses, authenticated global
  structural strain energies and wind-axis lift coefficients, plus assembled FE
  mass for the trim calculation; finite trim and compliance; and maximum sampled
  shell von Mises or beam absolute normal stress at most 220 MPa. The new candidate
  F06 also requires complete displacement fields.
- **SOL 145:** exactly 20 roots at each of 37 submitted velocities, giving 740
  valid PK samples; strict \(g\leq0\) at every sample; and every actual reduced
  frequency inside the submitted MKAERO1 range, allowing only the printed-\(k\)
  rounding tolerance. Missing, duplicate, nonfinite,
  zero-frequency or inconsistent rows are flagged.
- **Mass:** the predicted removed FE mass agrees with the difference between
  the two completed Nastran assembled masses. The comparison tolerance is
  \(\max(0.001\ \mathrm{kg},10^{-5}M_{\mathrm{before}})\), reflecting printed
  mass precision. A positive confirmed mass reduction is required.

Individual beam strain energies are not a physical acceptance requirement for
stress-only pruning. The optional energy-guarded selection requires complete
baseline member energies to verify its selection budget. In either mode,
compliance is evaluated from the independently verified **global structural
energy**, not by assigning zero to missing member-energy rows.

The paired trim calculation uses the assembled FE wing mass in both models,
the authenticated wind-axis lift coefficient, and the same reference conditions.
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
`assessment_data_error` for incomplete or inconsistent evidence. If the
selection rules retain every member, the assessment records `no_members_selected`
with zero removal; it is not a newly validated lighter design. The preparation
record calls this `no_removal_selected_baseline_unchanged` and requires no rerun
of an identical pruned copy. The sampled
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
259407beefb7821d0869f8d5bf784090a8768dba0e96844621595b74f02f871b
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
