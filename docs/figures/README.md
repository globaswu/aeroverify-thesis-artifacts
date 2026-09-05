# Workflow diagram sources

The thesis uses the accompanying 300 dpi PNGs. The corresponding TikZ sources
provide editable versions of the diagrams and require XeLaTeX, the standalone
document class, TikZ, and Times New Roman.

- `overall_evaluation_workflow.tex`: geometry generation, structural/aerodynamic
  coupling, the analysis sequence, result reduction, and bounded recovery.
- `mkaero_pk_iteration.tex`: aerodynamic matrix sampling and frequency
  consistency in the PK flutter calculation.

For example, run `xelatex overall_evaluation_workflow.tex` in this directory
to compile the diagram. These are method diagrams and contain no simulation
dataset. Their numerical assumptions and implementation are described in
Chapter 2 and in [the solver workflow](../FULL_SOLVER_WORKFLOW.md).
