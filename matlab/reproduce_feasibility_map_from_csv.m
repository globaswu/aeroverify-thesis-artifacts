function outputFile = reproduce_feasibility_map_from_csv(figureId, outputFile)
%REPRODUCE_FEASIBILITY_MAP_FROM_CSV Refit thesis score maps from public X,C.
%   reproduce_feasibility_map_from_csv("5.3") reads only repository CSV
%   files, normalizes the design-variable input matrix X, fits the bundled
%   clipped binary-feasibility model to binary labels C, and renders the
%   requested field. Objective outputs Y remain in the same evaluated-case
%   CSVs for objective-space plots, but are deliberately not supplied to the
%   feasibility fit.
%
%   Supported figures are 5.3, 5.5, 5.10, 5.15, and 5.18. Figure 5.5
%   reconstructs observed and hypothetical labels both before continuation
%   and through case 71. The routine does not read MAT, Nastran, nTop, log,
%   archive, or network files.

arguments
    figureId (1,1) string {mustBeMember(figureId, ...
        ["5.3","5.5","5.10","5.15","5.18"])}
    outputFile (1,1) string = ""
end

repositoryRoot = artifact_repository_root();
addpath(fullfile(repositoryRoot, "matlab"));
if outputFile == ""
    safeId = replace(figureId, ".", "_");
    outputFile = fullfile(repositoryRoot, "reproduced", ...
        "thesis_figure_" + safeId + "_refit.png");
end
outputFolder = fileparts(outputFile);
if outputFolder ~= "" && ~isfolder(outputFolder)
    mkdir(outputFolder);
end

switch figureId
    case "5.3"
        points = readtable(fullfile(repositoryRoot, "data", "figures", ...
            "chapter05", "figures_5_3_and_5_5_fcc_points.csv"), ...
            "VariableNamingRule", "preserve");
        grid = readtable(fullfile(repositoryRoot, "data", "figures", ...
            "chapter05", "figures_5_3_and_5_5_fcc_feasibility_score_grids.csv"), ...
            "VariableNamingRule", "preserve");
        makeSingle(points, grid, toLogical(points.feasible_observed), 71, ...
            "score_after_observed", "FCC through case 71", outputFile);
    case "5.5"
        points = readtable(fullfile(repositoryRoot, "data", "figures", ...
            "chapter05", "figures_5_3_and_5_5_fcc_points.csv"), ...
            "VariableNamingRule", "preserve");
        grid = readtable(fullfile(repositoryRoot, "data", "figures", ...
            "chapter05", "figures_5_3_and_5_5_fcc_feasibility_score_grids.csv"), ...
            "VariableNamingRule", "preserve");
        observed = toLogical(points.feasible_observed);
        hypothetical = points.constraint_hypothetical < 0;
        scenarios = {
            hypothetical, 51, "score_before_cases_8_29_feasible", "Before continuation: hypothetical C";
            hypothetical, 71, "score_after_cases_8_29_feasible", "Through case 71: hypothetical C"};
        figure("Color", "w", "Position", [100 100 760 1000]);
        layout = tiledlayout(2, 1, "TileSpacing", "compact", "Padding", "compact");
        for index = 1:size(scenarios, 1)
            ax = nexttile(layout);
            plotRefit(ax, points.a_m, points.t1_over_a, scenarios{index,1}, ...
                points.case_id <= scenarios{index,2}, grid.a_m, grid.t1_over_a, ...
                grid.(scenarios{index,3}), scenarios{index,4});
        end
        title(layout, "Figure 5.5: feasibility fields refitted from public X and C");
        exportgraphics(gcf, outputFile, "Resolution", 220);
        close(gcf);
    case "5.10"
        points = readtable(fullfile(repositoryRoot, "data", "bcc", ...
            "evaluations_cases001_071.csv"), "VariableNamingRule", "preserve");
        grid = readtable(fullfile(repositoryRoot, "data", "figures", ...
            "chapter05", "figure_5_10_bcc_feasibility_score_grid.csv"), ...
            "VariableNamingRule", "preserve");
        makeSingle(points, grid, toLogical(points.feasible), 71, ...
            "feasibility_score", "BCC through case 71", outputFile);
    case "5.15"
        points = readtable(fullfile(repositoryRoot, "data", "sc", ...
            "evaluations_cases001_071.csv"), "VariableNamingRule", "preserve");
        grid = readtable(fullfile(repositoryRoot, "data", "figures", ...
            "chapter05", "figure_5_15_sc_feasibility_score_grid.csv"), ...
            "VariableNamingRule", "preserve");
        makeSingle(points, grid, toLogical(points.feasible), 71, ...
            "binary_feasibility_score", "SC through case 71", outputFile);
    case "5.18"
        points = readtable(fullfile(repositoryRoot, "data", "planform", ...
            "evaluations_cases001_050.csv"), "VariableNamingRule", "preserve");
        grid = readtable(fullfile(repositoryRoot, "data", "figures", ...
            "chapter05", "figure_5_18_planform_feasibility_score_grid.csv"), ...
            "VariableNamingRule", "preserve");
        points = renamevars(points, ["AR","taper_ratio","case"], ...
            ["a_m","t1_over_a","case_id"]);
        grid = renamevars(grid, ["aspect_ratio","taper_ratio"], ...
            ["a_m","t1_over_a"]);
        makeSingle(points, grid, toLogical(points.feasible), 50, ...
            "binary_feasibility_score", "Planform through case 50", outputFile, ...
            "Aspect ratio", "Taper ratio");
end
end

function values = toLogical(column)
if islogical(column)
    values = column;
elseif isnumeric(column)
    values = column ~= 0;
else
    text = lower(strtrim(string(column)));
    values = ismember(text, ["1","true","yes","feasible"]);
end
end

function makeSingle(points, grid, labels, lastCase, storedFieldName, ...
        plotTitle, outputFile, xLabel, yLabel)
if nargin < 8
    xLabel = "Cell size, a (m)";
    yLabel = "Primary-member ratio, t_1/a";
end
figure("Color", "w", "Position", [100 100 760 650]);
ax = axes();
mask = points.case_id <= lastCase;
plotRefit(ax, points.a_m, points.t1_over_a, labels, mask, ...
    grid.a_m, grid.t1_over_a, grid.(storedFieldName), plotTitle);
xlabel(ax, xLabel);
ylabel(ax, yLabel);
exportgraphics(gcf, outputFile, "Resolution", 220);
close(gcf);
end

function plotRefit(ax, x1, x2, labels, observationMask, gridX1, gridX2, ...
        storedField, plotTitle)
lower = [min(gridX1), min(gridX2)];
upper = [max(gridX1), max(gridX2)];
scale = upper - lower;
X = ([x1(observationMask), x2(observationMask)] - lower) ./ scale;
C = logical(labels(observationMask));
query = ([gridX1, gridX2] - lower) ./ scale;
model = ctsemo.fitClippedBinaryPof(X, C, struct());
refitted = ctsemo.predictClippedBinaryPof(model, query);

xUnique = unique(gridX1, "sorted");
yUnique = unique(gridX2, "sorted");
field = nan(numel(yUnique), numel(xUnique));
[~, xi] = ismember(gridX1, xUnique);
[~, yi] = ismember(gridX2, yUnique);
field(sub2ind(size(field), yi, xi)) = refitted;
imagesc(ax, xUnique, yUnique, field);
set(ax, "YDir", "normal");
axis(ax, "square");
hold(ax, "on");
contour(ax, xUnique, yUnique, field, [0.5 0.5], "w", "LineWidth", 1.2);
scatter(ax, x1(observationMask & labels), x2(observationMask & labels), ...
    30, "o", "MarkerFaceColor", "w", "MarkerEdgeColor", "k");
scatter(ax, x1(observationMask & ~labels), x2(observationMask & ~labels), ...
    32, "x", "MarkerEdgeColor", [0.75 0.1 0.1]);
colorbar(ax);
clim(ax, [0 1]);
title(ax, plotTitle + sprintf(" (max |refit-stored| = %.3g)", ...
    max(abs(refitted - storedField))));
xlabel(ax, "Cell size, a (m)");
ylabel(ax, "Primary-member ratio, t_1/a");
grid(ax, "on");
end
