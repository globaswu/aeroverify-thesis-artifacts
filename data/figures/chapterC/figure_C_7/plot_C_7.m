function plot_C_7(outputFile)
% Standalone renderer for a single thesis figure-data CSV.
scriptPath = mfilename('fullpath');
[scriptFolder, scriptName] = fileparts(scriptPath);
% Preserve the original renderer selection after chapter reorganization.
figureNumber = 12;
csvFile = fullfile(scriptFolder, 'figure_C_7.csv');
if nargin < 1 || strlength(string(outputFile)) == 0
    outputFile = fullfile(scriptFolder, 'plot_C_7.png');
else
    outputFile = char(outputFile);
end
data = readtable(csvFile, 'TextType', 'string', ...
    'VariableNamingRule', 'preserve');
set(groot, 'DefaultFigureVisible', 'off');

switch figureNumber
    case 1
        fig = plotFinalPof(data);
    case 2
        fig = plotClassification(data);
    case 3
        fig = plotLearning(data, "COSSIN1");
    case 4
        fig = plotLearning(data, "COSSIN2");
    case 5
        fig = plotAcquisition(data);
    case 6
        fig = plotWbFront(data);
    case 7
        fig = plotHvHistories(data);
    case 8
        fig = plotSolverFronts(data);
    case {9, 10, 11, 12}
        fig = plotConditional(data);
    case 13
        fig = plotPairwise(data);
    otherwise
        error('Unsupported Chapter 3 figure number: %d', figureNumber);
end

outputFolder = fileparts(outputFile);
if ~isempty(outputFolder) && ~isfolder(outputFolder)
    mkdir(outputFolder);
end
exportgraphics(fig, outputFile, 'Resolution', 300);
close(fig);
fprintf('%s\n', outputFile);
end

function fig = plotFinalPof(data)
problems = ["COSSIN1", "COSSIN2", "BNH", "SRN"];
fig = newFigure([900, 850]);
layout = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(layout, 'Final clipped binary-feasibility fields');
axesHandles = gobjects(4, 1);
for index = 1:4
    axesHandles(index) = nexttile(layout);
    problem = problems(index);
    grid = data(data.record_type == "grid" & data.problem_id == problem, :);
    evaluations = data(data.record_type == "evaluation" & data.problem_id == problem, :);
    [x, y, score] = gridMatrix(grid, 'normalized_x1', 'normalized_x2', 'pof_score');
    [~, ~, truth] = gridMatrix(grid, 'normalized_x1', 'normalized_x2', 'exact_feasible');
    imagesc(axesHandles(index), x, y, score);
    axis(axesHandles(index), 'xy');
    clim(axesHandles(index), [0, 1]);
    hold(axesHandles(index), 'on');
    contour(axesHandles(index), x, y, truth, [0.5, 0.5], 'k--', 'LineWidth', 0.8);
    scatterEvaluations(axesHandles(index), evaluations);
    hold(axesHandles(index), 'off');
    formatDomain(axesHandles(index));
    title(axesHandles(index), sprintf('%s: %d evaluations', problem, ...
        grid.total_evaluations(1)), 'Interpreter', 'none');
end
colormap(fig, turbo(256));
bar = colorbar(axesHandles(end));
bar.Layout.Tile = 'east';
bar.Label.String = 'Binary-feasibility score, p_i';
end

function fig = plotClassification(data)
problems = ["COSSIN1", "COSSIN2", "BNH", "SRN"];
colors = [0.12, 0.17, 0.24; 0.82, 0.18, 0.13; ...
    0.18, 0.48, 0.82; 0.95, 0.62, 0.12];
fig = newFigure([900, 850]);
layout = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(layout, 'Spatial classification outcomes at p_i >= 0.5');
axesHandles = gobjects(4, 1);
for index = 1:4
    axesHandles(index) = nexttile(layout);
    grid = data(data.record_type == "grid" & data.problem_id == problems(index), :);
    [x, y, values] = gridMatrix(grid, 'normalized_x1', 'normalized_x2', 'error_class');
    imagesc(axesHandles(index), x, y, values);
    axis(axesHandles(index), 'xy');
    clim(axesHandles(index), [-0.5, 3.5]);
    formatDomain(axesHandles(index));
    title(axesHandles(index), problems(index), 'Interpreter', 'none');
end
colormap(fig, colors);
bar = colorbar(axesHandles(end));
bar.Layout.Tile = 'east';
bar.Ticks = 0:3;
bar.TickLabels = {'correct violating', 'false feasible', ...
    'false infeasible', 'correct feasible'};
end

function fig = plotLearning(data, problem)
milestones = unique(data.total_evaluations(data.record_type == "grid"), 'sorted');
assert(numel(milestones) == 4);
fig = newFigure([900, 850]);
layout = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(layout, problem + " feasibility-score learning", 'Interpreter', 'none');
axesHandles = gobjects(4, 1);
for index = 1:4
    axesHandles(index) = nexttile(layout);
    milestone = milestones(index);
    grid = data(data.record_type == "grid" & ...
        data.total_evaluations == milestone, :);
    evaluations = data(data.record_type == "evaluation" & ...
        data.total_evaluations == milestone, :);
    [x, y, score] = gridMatrix(grid, 'normalized_x1', 'normalized_x2', 'pof_score');
    [~, ~, truth] = gridMatrix(grid, 'normalized_x1', 'normalized_x2', 'exact_feasible');
    imagesc(axesHandles(index), x, y, score);
    axis(axesHandles(index), 'xy');
    clim(axesHandles(index), [0, 1]);
    hold(axesHandles(index), 'on');
    contour(axesHandles(index), x, y, score, [0.5, 0.5], 'w-', 'LineWidth', 1.1);
    contour(axesHandles(index), x, y, truth, [0.5, 0.5], 'k--', 'LineWidth', 0.9);
    scatterEvaluations(axesHandles(index), evaluations);
    hold(axesHandles(index), 'off');
    formatDomain(axesHandles(index));
    title(axesHandles(index), sprintf('%s, N = %d', problem, milestone), ...
        'Interpreter', 'none');
end
colormap(fig, turbo(256));
bar = colorbar(axesHandles(end));
bar.Layout.Tile = 'east';
bar.Label.String = 'Binary-feasibility score, p_i';
end

function fig = plotAcquisition(data)
grid = data(data.record_type == "grid", :);
evaluations = data(data.record_type == "evaluation", :);
selected = data(data.record_type == "selected_point", :);
assert(height(selected) == 1);
fields = {'pof_score', 'sampled_hvi', 'pof_times_sampled_hvi', ...
    'final_acquisition'};
titles = {'(a) Feasibility score p_i', '(b) Sampled HVI', ...
    '(c) p_i times sampled HVI', '(d) Final acquisition'};
[~, ~, truth] = gridMatrix(grid, 'normalized_x1', 'normalized_x2', 'exact_feasible');
fig = newFigure([900, 820]);
layout = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(layout, 'COSSIN2 iteration-20 acquisition decomposition');
for index = 1:4
    ax = nexttile(layout);
    [x, y, values] = gridMatrix(grid, 'normalized_x1', 'normalized_x2', fields{index});
    imagesc(ax, x, y, values);
    axis(ax, 'xy');
    hold(ax, 'on');
    contour(ax, x, y, truth, [0.5, 0.5], 'w--', 'LineWidth', 0.8);
    scatterEvaluations(ax, evaluations);
    scatter(ax, selected.normalized_x1, selected.normalized_x2, 85, '*', ...
        'MarkerFaceColor', [0.21, 0.95, 1], 'MarkerEdgeColor', 'k');
    hold(ax, 'off');
    formatDomain(ax);
    title(ax, titles{index});
    colorbar(ax);
    if index == 1
        colormap(ax, viridisMap());
    else
        colormap(ax, hot(256));
    end
end
end

function fig = plotWbFront(data)
fig = newFigure([900, 1000]);
layout = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
title(layout, 'WB150 replicate-2 Pareto front after 150 evaluations');
top = nexttile(layout);
drawWbPanel(top, data, true, false);
title(top, 'Complete objective space');
bottom = nexttile(layout);
handles = drawWbPanel(bottom, data, false, true);
title(bottom, 'Fixed Pareto-region view');
legend(bottom, handles, {'Violating', 'Feasible, dominated', ...
    'Feasible Pareto front', 'Evaluation 150'}, 'NumColumns', 2, ...
    'Location', 'northoutside');
end

function handles = drawWbPanel(ax, data, logScale, zoomed)
violating = data(data.feasible == 0, :);
dominated = data(data.feasible == 1 & data.final_pareto == 0, :);
pareto = sortrows(data(data.final_pareto == 1, :), ...
    'objective_f1_fabrication_cost');
newest = data(data.is_evaluation_150 == 1, :);
hold(ax, 'on');
handles(1) = scatter(ax, violating.objective_f1_fabrication_cost, ...
    violating.objective_f2_end_deflection, 28, 'x', ...
    'MarkerEdgeColor', [0.55, 0.55, 0.55]);
handles(2) = scatter(ax, dominated.objective_f1_fabrication_cost, ...
    dominated.objective_f2_end_deflection, 30, 'o', ...
    'MarkerFaceColor', 'w', 'MarkerEdgeColor', [0.25, 0.48, 0.68]);
handles(3) = plot(ax, pareto.objective_f1_fabrication_cost, ...
    pareto.objective_f2_end_deflection, '-o', 'Color', [0, 0.35, 0.65], ...
    'MarkerFaceColor', [0, 0.35, 0.65], 'LineWidth', 1.7);
handles(4) = scatter(ax, newest.objective_f1_fabrication_cost, ...
    newest.objective_f2_end_deflection, 70, 'd', ...
    'MarkerFaceColor', [0.95, 0.45, 0.08], ...
    'MarkerEdgeColor', [0.75, 0.25, 0.02]);
hold(ax, 'off');
grid(ax, 'on'); box(ax, 'on');
if logScale, set(ax, 'YScale', 'log'); end
if zoomed
    xlim(ax, paddedLimits(pareto.objective_f1_fabrication_cost, 0.10, true));
    ylim(ax, paddedLimits(pareto.objective_f2_end_deflection, 0.12, true));
end
xlabel(ax, 'Objective f_1 (benchmark cost index)');
ylabel(ax, 'Objective f_2 (benchmark deflection index)');
end

function fig = plotHvHistories(data)
curves = data(data.record_type == "curve", :);
problems = unique(curves.problem_id, 'stable');
fig = newFigure([1200, 750]);
layout = tiledlayout(fig, 2, 4, 'TileSpacing', 'compact', 'Padding', 'compact');
title(layout, 'Feasible-front hypervolume histories');
for problemIndex = 1:numel(problems)
    ax = nexttile(layout);
    rows = sortrows(curves(curves.problem_id == problems(problemIndex), :), ...
        'sequential_evaluations');
    hold(ax, 'on');
    for seed = 1:5
        plot(ax, rows.sequential_evaluations, ...
            rows.(sprintf('seed_%d_normalized_hv', seed)), 'LineWidth', 0.8);
    end
    plot(ax, rows.sequential_evaluations, rows.median_normalized_hv, ...
        'k-', 'LineWidth', 2.0);
    hold(ax, 'off');
    xlim(ax, [0, 130]); grid(ax, 'on'); box(ax, 'on');
    xlabel(ax, 'Sequential evaluations');
    ylabel(ax, 'Normalized hypervolume');
    title(ax, rows.display_name(1), 'Interpreter', 'none');
end
hiddenAxis = nexttile(layout, 8);
hiddenAxis.Visible = 'off';
end

function fig = plotSolverFronts(data)
labels = unique(data.solver_label, 'stable');
fig = newFigure([1050, 520]);
layout = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(layout, 'Historical WB150 external-solver pilot');
axesHandles = [nexttile(layout), nexttile(layout)];
legendHandles = gobjects(numel(labels), 1);
for labelIndex = 1:numel(labels)
    rows = sortrows(data(data.solver_label == labels(labelIndex), :), ...
        'pareto_point_index');
    for axisIndex = 1:2
        hold(axesHandles(axisIndex), 'on');
        h = plot(axesHandles(axisIndex), rows.objective_f1_fabrication_cost, ...
            rows.objective_f2_end_deflection, '-o', 'MarkerSize', 3, ...
            'LineWidth', 1.2);
        if axisIndex == 1, legendHandles(labelIndex) = h; end
    end
end
set(axesHandles(1), 'YScale', 'log');
xlim(axesHandles(1), [0, 350]); ylim(axesHandles(1), [3e-4, 5e-2]);
xlim(axesHandles(2), [0, 65]); ylim(axesHandles(2), [0, 0.0132]);
title(axesHandles(1), 'Complete solver-owned feasible fronts');
title(axesHandles(2), 'Established trade-off region');
for axisIndex = 1:2
    hold(axesHandles(axisIndex), 'off'); grid(axesHandles(axisIndex), 'on');
    box(axesHandles(axisIndex), 'on');
    xlabel(axesHandles(axisIndex), 'Fabrication cost objective, f_1');
    ylabel(axesHandles(axisIndex), 'End deflection objective, f_2');
end
legend(axesHandles(1), legendHandles, labels, 'NumColumns', 2, ...
    'Location', 'southoutside', 'Interpreter', 'none');
end

function fig = plotConditional(data)
% Compare the fixed iteration-130 HVI field across one physical input.
% Retain the survival grid, four profiles, support curves and selected point.
survival = data(data.record_type == "survival_grid", :);
profile = sortrows(data(data.record_type == "profile_station", :), ...
    'input_physical');
metadata = data(data.record_type == "metadata", :);
assert(height(metadata) == 1);
[x, thresholds, logProbability] = gridMatrix(survival, ...
    'input_physical', 'threshold_normalized', ...
    'log10_conditional_exceedance_probability');
[~, ~, probability] = gridMatrix(survival, ...
    'input_physical', 'threshold_normalized', ...
    'conditional_exceedance_probability');
floorProbability = 1 / 2048;

fig = newFigure([900, 1050]);
annotation(fig, 'textbox', [0.055, 0.955, 0.89, 0.035], ...
    'String', sprintf('WB150 iteration-130 conditional sampled HVI versus %s', ...
    metadata.input_name), 'EdgeColor', 'none', 'HorizontalAlignment', 'center', ...
    'FontName', 'Times New Roman', 'FontSize', 13, 'Interpreter', 'none');
ax1 = axes(fig, 'Position', [0.13, 0.69, 0.68, 0.235]);
ax2 = axes(fig, 'Position', [0.13, 0.40, 0.68, 0.235]);
ax3 = axes(fig, 'Position', [0.13, 0.11, 0.68, 0.235]);
surf(ax1, x, thresholds, zeros(size(logProbability)), logProbability, ...
    'EdgeColor', 'none');
view(ax1, 2); hold(ax1, 'on');
[contourMatrix, contourHandle] = contour(ax1, x, thresholds, probability, ...
    [0.01, 0.1, 0.5], 'k-', 'LineWidth', 0.7);
clabel(contourMatrix, contourHandle, 'FontName', 'Times New Roman', ...
    'FontSize', 9, 'Color', 'k');
hold(ax1, 'off');
clim(ax1, [log10(floorProbability), 0]);
colormap(ax1, viridisMap());
bar = colorbar(ax1);
bar.Position = [0.835, 0.69, 0.018, 0.235];
ax1.Position = [0.13, 0.69, 0.68, 0.235];
bar.Ticks = log10([floorProbability, 1e-3, 1e-2, 1e-1, 1]);
bar.TickLabels = {'<=1/2048', '1e-3', '1e-2', '1e-1', '1'};
bar.Label.String = 'Conditional exceedance probability [-]';
bar.FontName = 'Times New Roman';
bar.FontSize = 9;
ylabel(ax1, 'Normalized HVI threshold, \eta [-]');
title(ax1, 'A. Conditional HVI survival', 'FontSize', 12);

% Nonpositive profile values remain absent on logarithmic axes.
fields = {'p90_normalized_hvi', 'p99_normalized_hvi', ...
    'mean_normalized_hvi', 'sampled_profile_maximum_normalized_hvi'};
colors = [0.835, 0.627, 0.063; 0.91, 0.43, 0.09; ...
    0.09, 0.41, 0.67; 0.133, 0.133, 0.133];
styles = {'-', '-', '--', '-'};
hold(ax2, 'on');
for index = 1:numel(fields)
    values = profile.(fields{index});
    values(values <= 0) = NaN;
    plot(ax2, profile.input_physical, values, styles{index}, ...
        'Color', colors(index, :), 'LineWidth', 1.5);
end
scatter(ax2, metadata.selected_input_physical, metadata.selected_hvi_normalized, ...
    85, 'p', 'MarkerFaceColor', [0.7, 0.2, 0.2], ...
    'MarkerEdgeColor', 'w', 'LineWidth', 0.65, 'Clipping', 'off');
hold(ax2, 'off');
ylabel(ax2, 'Normalized HVI [-]');
title(ax2, 'B. Conditional quantiles and profile', 'FontSize', 12);
legend(ax2, {'90th percentile', '99th percentile', 'Conditional mean', ...
    'Sampled profile maximum', 'Selected design'}, 'NumColumns', 2, ...
    'Location', 'southwest', 'FontName', 'Times New Roman', 'FontSize', 9);

positiveFraction = profile.positive_hvi_fraction;
positiveFraction(positiveFraction <= 0) = NaN;
conditionalMean = profile.mean_normalized_hvi;
conditionalMean(conditionalMean <= 0) = NaN;
hold(ax3, 'on');
plot(ax3, profile.input_physical, positiveFraction, ...
    'Color', colors(2, :), 'LineWidth', 1.6);
plot(ax3, profile.input_physical, conditionalMean, '--', ...
    'Color', colors(3, :), 'LineWidth', 1.5);
hold(ax3, 'off');
ylabel(ax3, 'Conditional domain-volume statistic [-]');
title(ax3, 'C. Positive-HVI support and conditional mean', 'FontSize', 12);
legend(ax3, {'Positive-HVI fraction', 'Mean HVI / global maximum HVI'}, ...
    'Location', 'southwest', 'FontName', 'Times New Roman', 'FontSize', 9);

for ax = [ax1, ax2, ax3]
    set(ax, 'YScale', 'log', 'YLim', [1e-8, 1], ...
        'YTick', [1e-8, 1e-6, 1e-4, 1e-2, 1], ...
        'FontName', 'Times New Roman', 'FontSize', 10, ...
        'GridAlpha', 0.15, 'XMinorGrid', 'off', 'YMinorGrid', 'off', ...
        'Layer', 'top');
    xlim(ax, [min(x), max(x)]);
    xlabel(ax, sprintf('%s, %s [in]', metadata.input_name, metadata.input_symbol), ...
        'Interpreter', 'none');
    box(ax, 'on'); grid(ax, 'on');
end
ylim(ax2, [1e-8, 1.15]);
end

function fig = plotPairwise(data)
slices = data(data.record_type == "slice_grid", :);
pairs = unique(slices.pair_id, 'sorted');
positive = log10(slices.hvi_draw(slices.hvi_draw > 1e-12));
limits = [floor(2 * min(positive)) / 2, ceil(2 * max(positive)) / 2];
fig = newFigure([900, 1050]);
layout = tiledlayout(fig, 3, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(layout, 'WB150 pairwise slices of sampled HVI');
axesHandles = gobjects(6, 1);
for pairIndex = 1:numel(pairs)
    rows = slices(slices.pair_id == pairs(pairIndex), :);
    inputA = rows.input_a(1); inputB = rows.input_b(1);
    [x, y, hvi] = gridMatrix(rows, sprintf('x%d', inputA), ...
        sprintf('x%d', inputB), 'hvi_draw');
    axesHandles(pairIndex) = nexttile(layout);
    imagesc(axesHandles(pairIndex), x, y, log10(hvi + 1e-12));
    axis(axesHandles(pairIndex), 'xy');
    axis(axesHandles(pairIndex), 'square');
    clim(axesHandles(pairIndex), limits);
    xlabel(axesHandles(pairIndex), sprintf('x_%d', inputA));
    ylabel(axesHandles(pairIndex), sprintf('x_%d', inputB));
    title(axesHandles(pairIndex), sprintf('x_%d and x_%d', inputA, inputB));
end
colormap(fig, viridisMap());
bar = colorbar(axesHandles(end));
bar.Layout.Tile = 'south';
bar.Label.String = 'log10(sampled HVI + 1e-12)';
end

function fig = newFigure(position)
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [50, 50, position]);
set(fig, 'DefaultAxesFontName', 'Times New Roman', ...
    'DefaultTextFontName', 'Times New Roman');
end

function [x, y, z] = gridMatrix(rows, xName, yName, valueName)
rows = sortrows(rows, {xName, yName});
x = unique(rows.(xName), 'sorted');
y = unique(rows.(yName), 'sorted');
assert(height(rows) == numel(x) * numel(y));
z = reshape(rows.(valueName), numel(y), numel(x));
end

function scatterEvaluations(ax, rows)
feasible = rows(rows.feasible == 1, :);
violating = rows(rows.feasible == 0, :);
scatter(ax, feasible.normalized_x1, feasible.normalized_x2, 24, 'o', ...
    'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'LineWidth', 0.6);
scatter(ax, violating.normalized_x1, violating.normalized_x2, 26, 'x', ...
    'MarkerEdgeColor', [0.75, 0.05, 0.15], 'LineWidth', 0.9);
end

function formatDomain(ax)
xlim(ax, [0, 1]); ylim(ax, [0, 1]); axis(ax, 'square'); box(ax, 'on');
xlabel(ax, 'Normalized x_1'); ylabel(ax, 'Normalized x_2');
end

function limits = paddedLimits(values, fraction, positive)
low = min(values); high = max(values);
span = max([high - low, abs(high) * 0.05, 1e-12]);
limits = [low - fraction * span, high + fraction * span];
if positive, limits(1) = max(realmin, limits(1)); end
end

function map = viridisMap
anchors = [0.267, 0.005, 0.329; 0.283, 0.141, 0.458; ...
    0.254, 0.265, 0.530; 0.207, 0.372, 0.553; ...
    0.164, 0.471, 0.558; 0.128, 0.567, 0.551; ...
    0.135, 0.659, 0.518; 0.267, 0.749, 0.441; ...
    0.478, 0.821, 0.318; 0.741, 0.873, 0.150; ...
    0.993, 0.906, 0.144];
map = interp1(linspace(0, 1, size(anchors, 1)), anchors, ...
    linspace(0, 1, 256), 'linear');
end
