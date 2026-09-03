function plot_2_8(outputFile)
%PLOT_2_8 Reproduce thesis Figure 2.8 from the sibling CSV only.
scriptFile = mfilename('fullpath');
figureDirectory = fileparts(scriptFile);
dataFile = fullfile(figureDirectory, 'figure_2_8.csv');
if nargin < 1 || strlength(string(outputFile)) == 0
    outputFile = fullfile(figureDirectory, 'plot_2_8.png');
else
    outputFile = char(string(outputFile));
end
outputDirectory = fileparts(outputFile);
if ~isempty(outputDirectory) && ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end

data = readtable(dataFile, 'TextType', 'string', ...
    'VariableNamingRule', 'preserve');
required = ["configuration", "root", "velocity_mps", ...
    "damping_g", "positive"];
assert(all(ismember(required, string(data.Properties.VariableNames))), ...
    'Figure 2.8 CSV has an unexpected schema.');
assert(height(data) == 1480, 'Expected 1,480 valid V-g samples.');
assert(isequal(unique(data.root, 'sorted').', 1:20), ...
    'Expected retained roots 1 through 20.');

configurationNames = ["coarse_edge_length_2p5_mm", ...
    "geometry_tolerance_2p0_mm"];
configurationTitles = ["Coarse edge length: 2.5 mm", ...
    "Geometry tolerance: 2.0 mm"];
panelLetters = ["a", "b"; "c", "d"];

figureHandle = figure('Visible', 'off', 'Color', 'white', ...
    'Units', 'inches', 'Position', [0.5, 0.35, 7.25, 10.75], ...
    'Renderer', 'painters');
layout = tiledlayout(figureHandle, 2, 2, ...
    'TileSpacing', 'loose', 'Padding', 'loose');
title(layout, 'Case 64 V-g diagnostic', 'FontName', 'Times New Roman', ...
    'FontSize', 13, 'FontWeight', 'bold', 'Interpreter', 'none');

for rowIndex = 1:2
    rows = data(data.configuration == configurationNames(rowIndex), :);
    assert(height(rows) == 740, ...
        'Expected 740 samples for each Figure 2.8 configuration.');
    plotAllRoots(nexttile(layout), rows, ...
        panelLetters(rowIndex, 1) + '. ' + ...
        configurationTitles(rowIndex) + ', all roots');
    plotRoot19(nexttile(layout), rows, ...
        panelLetters(rowIndex, 2) + '. ' + ...
        configurationTitles(rowIndex) + ', root 19');
end

exportgraphics(figureHandle, outputFile, 'Resolution', 220, ...
    'BackgroundColor', 'white');
close(figureHandle);
fprintf('%s\n', outputFile);
end

function plotAllRoots(ax, data, panelTitle)
roots = unique(data.root, 'sorted').';
colors = lines(numel(roots));
hold(ax, 'on');
for index = 1:numel(roots)
    rows = data(data.root == roots(index), :);
    rows = sortrows(rows, 'velocity_mps', 'ascend');
    plot(ax, rows.velocity_mps, rows.damping_g, '-', ...
        'Color', colors(index, :), 'LineWidth', 0.85, ...
        'HandleVisibility', 'off');
end
drawZeroLine(ax);
hold(ax, 'off');
formatAxes(ax, panelTitle, false);
end

function plotRoot19(ax, data, panelTitle)
rows = data(data.root == 19, :);
rows = sortrows(rows, 'velocity_mps', 'ascend');
positive = logical(rows.positive);
hold(ax, 'on');
plot(ax, rows.velocity_mps, rows.damping_g, '-', ...
    'Color', [0.00, 0.31, 0.55], 'LineWidth', 1.15, ...
    'DisplayName', 'Root 19');
scatter(ax, rows.velocity_mps(positive), rows.damping_g(positive), 28, ...
    'o', 'MarkerFaceColor', [0.80, 0.16, 0.12], ...
    'MarkerEdgeColor', [0.80, 0.16, 0.12], ...
    'DisplayName', 'Positive sample');
drawZeroLine(ax);
hold(ax, 'off');
formatAxes(ax, panelTitle, true);
legend(ax, 'Location', 'southwest', 'FontName', 'Times New Roman', ...
    'FontSize', 8.5, 'Interpreter', 'none', 'Box', 'off');
end

function drawZeroLine(ax)
yline(ax, 0, '-', 'Color', [0.10, 0.10, 0.10], 'LineWidth', 1.1, ...
    'HandleVisibility', 'off');
end

function formatAxes(ax, panelTitle, scientificTicks)
xlim(ax, [30, 150]);
grid(ax, 'on');
box(ax, 'on');
title(ax, panelTitle, 'FontName', 'Times New Roman', 'FontSize', 10, ...
    'FontWeight', 'normal', 'Interpreter', 'none');
xlabel(ax, 'Velocity, V [m/s]', 'FontName', 'Times New Roman', ...
    'FontSize', 9.5, 'Interpreter', 'none');
ylabel(ax, 'Damping, g [-]', 'FontName', 'Times New Roman', ...
    'FontSize', 9.5, 'Interpreter', 'none');
set(ax, 'FontName', 'Times New Roman', 'FontSize', 9, ...
    'TickLabelInterpreter', 'none', 'TickDir', 'out', 'LineWidth', 0.8, ...
    'Layer', 'top', 'XGrid', 'on', 'YGrid', 'on', ...
    'GridLineStyle', ':', 'GridAlpha', 0.18);
ax.YAxis.Exponent = 0;
if scientificTicks
    ytickformat(ax, '%.1e');
else
    ytickformat(ax, '%.2f');
end
end
