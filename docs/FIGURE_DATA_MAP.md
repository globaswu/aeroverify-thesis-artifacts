# Thesis figure-data index

Every author-generated quantitative figure in the thesis has a direct data link in its caption. The linked CSV files contain the exact plotted observations, fields, or curves; author screenshots and schematics instead link to the relevant public method or provenance record. Externally reproduced literature figures retain their original citations and rights statements.

Detailed figure-to-file mappings are organized by chapter:

- [Chapters 2 and 4](FIGURE_DATA_CHAPTER02_04.md)
- [Chapter 3](FIGURE_DATA_CHAPTER03.md)
- [Chapter 5](FIGURE_DATA_CHAPTER05.md)
- [Chapter 6](FIGURE_DATA_CHAPTER06.md)

The public files are processed scientific outputs rather than raw commercial-solver archives. Native MSC Nastran files and proprietary nTop projects are intentionally excluded. Large dense fields remain ordinary CSV files below GitHub's per-file limit; no Git LFS dependency is required.

Use the [CSV-only figure dispatcher](CSV_FIGURE_REPRODUCTION.md) to recreate
any mapped figure without MAT files, solver outputs, or external data sources.
