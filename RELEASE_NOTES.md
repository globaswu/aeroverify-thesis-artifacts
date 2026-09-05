# Thesis reproducibility package

This update aligns the companion data with the revised thesis structure. The
stable `thesis` release provides the current manuscript and the per-figure
source data linked from its captions.

## Updated content

- 53 self-contained figure folders follow the current numbering in Chapters
  2–6 and Appendices C–D. Each contains one consolidated CSV and independent
  Python and MATLAB plotting scripts.
- The FCC case-67 reduced-frequency and mode-shape diagnostics are now in
  Chapter 2. Figure 2.8 displays nTop screenshots; the public reconstruction
  shows the mode shape as a point cloud.
- Chapter 3 includes the completed seven-problem, seven-solver comparison.
  The dataset provides all 49 trajectory summaries, 7,350 recorded X/Y/C
  observations, observed Pareto sets, empirical reference fronts, and the
  hypervolume-ratio table. Figures 3.7 and 3.8 have self-contained plot packages.
- Figure 5.1 presents the completed 213-design FCC/BCC/SC comparison. The
  supporting CSV preserves the original feasibility labels and distinguishes
  within-topology and pooled observed Pareto membership.
- Supplementary learning, label-sensitivity, and acquisition-profile figures
  have their own packages under Appendices C and D.
- The thesis uses raster figure assets for mobile PDF viewing.

The [figure index](docs/FIGURE_DATA_MAP.md) and
[experiment register](experiments.json) give the current file mapping. File
integrity is recorded in `manifest.json`; run `tools/verify_manifest.ps1`
after downloading the source archive.

## Retained flutter evidence

The separate harmonized dataset records the 65 targeted SOL 145 reruns:
BCC 15, FCC 32, and SC 18. All 65 pass the implemented numerical screen.
Together with the FCC case-67 diagnostic and 26 BCC/SC continuation cases
already assessed with that configuration, the 92 static-admissible topology
cases through case 71 pass the common screen. These retrospective results
preserve the historical labels and candidate-selection histories.

This is a numerical screen over 20 roots and 37 velocities from 30 to 150 m/s.
It does not establish reduced-frequency convergence or independent physical
flutter validation.

## Benchmark interpretation

cTSEMO and HyperMapper use aggregate binary feasibility labels, while the
other five methods use individual continuous constraint margins. The observed
fronts show outcomes under these information conditions and the recorded
budget. One trajectory per solver/problem does not establish a general
statistical ranking or isolate an effect of binary feedback. The empirical GA
front is a higher-budget reference rather than an equal-budget competitor.

## Attached documents

`main.pdf` is the current revised thesis. Previously attached Paper 2 and
Paper 3 PDFs remain separate manuscripts; this thesis revision does not imply
that their content was revised in parallel. The reference-verification report
is a separate earlier audit and is not a certification of every sentence in
the revised thesis.
