# Thesis figure-data index

This index follows the revised thesis numbering. Each of the 53 linked folders
contains one CSV, one independent Python plotting script, and one independent
MATLAB plotting script. Either script reads its adjacent CSV alone.

## Chapter 2

| Figure | Content |
|---|---|
| [2.7](../data/figures/chapter02/figure_2_7) | FCC case 67: tracked mode and MKAERO1 settings |
| [2.8](../data/figures/chapter02/figure_2_8) | FCC case 67: nTop mode-shape screenshots and point-cloud reconstruction |
| [2.9](../data/figures/chapter02/figure_2_9) | FCC case 67: all 20 tracked flutter points |
| [2.10](../data/figures/chapter02/figure_2_10) | Structural-mesh sensitivity |
| [2.11](../data/figures/chapter02/figure_2_11) | Mesh-sensitive positive-damping diagnostic |

## Chapter 3

| Figure | Content |
|---|---|
| [3.1](../data/figures/chapter03/figure_3_1) | Final two-input feasibility fields |
| [3.2](../data/figures/chapter03/figure_3_2) | Two-input classification diagnostics |
| [3.3](../data/figures/chapter03/figure_3_3) | CosSin2 acquisition field |
| [3.4](../data/figures/chapter03/figure_3_4) | Higher-dimensional hypervolume histories |
| [3.5](../data/figures/chapter03/figure_3_5) | WB150 Pareto evolution |
| [3.6](../data/figures/chapter03/figure_3_6) | WB150 pairwise hypervolume-improvement views |
| [3.7](../data/figures/chapter03/figure_3_7) | Seven-solver observed fronts: CF1 and C2-DTLZ2 |
| [3.8](../data/figures/chapter03/figure_3_8) | Seven-solver observed fronts: welded beam and MW7 |

## Chapter 4

| Figure | Content |
|---|---|
| [4.1](../data/figures/chapter04/figure_4_1) | Representative fixed-area planforms |
| [4.2](../data/figures/chapter04/figure_4_2) | Selection of FCC case 40 |

## Chapter 5

| Figure | Content |
|---|---|
| [5.1](../data/figures/chapter05/figure_5_1) | Completed 213-design topology comparison |
| [5.2](../data/figures/chapter05/figure_5_2) | FCC observed Pareto front |
| [5.3](../data/figures/chapter05/figure_5_3) | FCC feasibility field |
| [5.4](../data/figures/chapter05/figure_5_4) | FCC failure mechanisms |
| [5.5](../data/figures/chapter05/figure_5_5) | BCC observed Pareto front |
| [5.6](../data/figures/chapter05/figure_5_6) | BCC feasibility field |
| [5.7](../data/figures/chapter05/figure_5_7) | BCC failure mechanisms |
| [5.8](../data/figures/chapter05/figure_5_8) | SC observed Pareto front |
| [5.9](../data/figures/chapter05/figure_5_9) | SC feasibility field |
| [5.10](../data/figures/chapter05/figure_5_10) | SC failure mechanisms |
| [5.11](../data/figures/chapter05/figure_5_11) | BCC stress-tail comparison |
| [5.12](../data/figures/chapter05/figure_5_12) | BCC root stress concentrations |
| [5.13](../data/figures/chapter05/figure_5_13) | Topology material and stress comparison |
| [5.14](../data/figures/chapter05/figure_5_14) | Planform feasibility field |
| [5.15](../data/figures/chapter05/figure_5_15) | Planform observed Pareto front |
| [5.16](../data/figures/chapter05/figure_5_16) | Planform structural and objective trends |
| [5.17](../data/figures/chapter05/figure_5_17) | Taper-ratio interpretation |

## Chapter 6

| Figure | Content |
|---|---|
| [6.1](../data/figures/chapter06/figure_6_1) | Four-input observed Pareto front |
| [6.2](../data/figures/chapter06/figure_6_2) | Four-input feasibility mechanisms |
| [6.3](../data/figures/chapter06/figure_6_3) | Pairwise design-space views |
| [6.4](../data/figures/chapter06/figure_6_4) | Representative static-response decomposition |
| [6.5](../data/figures/chapter06/figure_6_5) | Representative dynamic-response decomposition |
| [6.6](../data/figures/chapter06/figure_6_6) | Parallel-coordinate design comparison |
| [6.7](../data/figures/chapter06/figure_6_7) | Mass and compliance |
| [6.8](../data/figures/chapter06/figure_6_8) | Optimization progress |

## Appendix C

| Figure | Content |
|---|---|
| [C.1](../data/figures/chapterC/figure_C_1) | CosSin1 feasibility learning |
| [C.2](../data/figures/chapterC/figure_C_2) | CosSin2 feasibility learning |
| [C.3](../data/figures/chapterC/figure_C_3) | Earlier WB150 solver comparison |
| [C.4](../data/figures/chapterC/figure_C_4) | WB150 conditional improvement: input 1 |
| [C.5](../data/figures/chapterC/figure_C_5) | WB150 conditional improvement: input 2 |
| [C.6](../data/figures/chapterC/figure_C_6) | WB150 conditional improvement: input 3 |
| [C.7](../data/figures/chapterC/figure_C_7) | WB150 conditional improvement: input 4 |

## Appendix D

| Figure | Content |
|---|---|
| [D.1](../data/figures/chapterD/figure_D_1) | Earlier topology fronts |
| [D.2](../data/figures/chapterD/figure_D_2) | FCC label-sensitivity diagnostic |
| [D.3](../data/figures/chapterD/figure_D_3) | Four-input conditional improvement: aspect ratio |
| [D.4](../data/figures/chapterD/figure_D_4) | Four-input conditional improvement: taper ratio |
| [D.5](../data/figures/chapterD/figure_D_5) | Four-input conditional improvement: lattice ratio 1 |
| [D.6](../data/figures/chapterD/figure_D_6) | Four-input conditional improvement: lattice ratio 2 |

Figure 2.8 displays nTop screenshots in the thesis. The released node data
and scripts reconstruct the mode shape as a point cloud; they do not duplicate
nTop's surface rendering. The displayed modal amplitude has arbitrary
normalization.

The [seven-solver benchmark dataset](../data/benchmarks/seven_solver_comparison/README.md)
contains the full evaluated X/Y/C records, observed Pareto points, empirical GA
reference fronts, and [hypervolume-ratio table](../data/benchmarks/seven_solver_comparison/hv_ratio_table.csv)
used in Chapter 3. Figures 3.7 and 3.8 each consolidate their required rows into
one CSV.

The linked records support plot reproduction. Native MSC Nastran OP2/F06
outputs and proprietary nTop projects are not included.
