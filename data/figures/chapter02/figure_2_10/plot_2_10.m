function plot_2_10(outputFile)
%PLOT_2_7 Reproduce thesis Figure 2.10 from the sibling CSV only.
scriptFile = mfilename('fullpath');
figureDirectory = fileparts(scriptFile);
dataFile = fullfile(figureDirectory, 'figure_2_10.csv');
if nargin < 1 || strlength(string(outputFile)) == 0
    outputFile = fullfile(figureDirectory, 'plot_2_10.png');
else
    outputFile = char(string(outputFile));
end
outputDirectory = fileparts(outputFile);
if ~isempty(outputDirectory) && ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end

data = readtable(dataFile, 'VariableNamingRule', 'preserve');
required = ["case_id", "geometry_tolerance_mm", "mesh_edge_length_mm", ...
    "two_wing_compliance_Nm", "maximum_vertical_deflection_m", ...
    "skin_vm_p9975_MPa", "cbeam_normal_stress_p9975_MPa", ...
    "first_modal_frequency_Hz"];
assert(all(ismember(required, string(data.Properties.VariableNames))), ...
    'Figure 2.10 CSV has an unexpected schema.');
assert(height(data) == 15, 'Expected 15 plotted observations.');
assert(all(abs(data.geometry_tolerance_mm - 1.5) < 1e-12), ...
    'Figure 2.10 requires a fixed 1.5 mm geometry tolerance.');
cases = unique(data.case_id, 'sorted').';
assert(isequal(cases, [4, 37, 64, 65, 99]), ...
    'Unexpected Figure 2.10 case set.');
colors = lines(numel(cases));

figureHandle = figure('Visible', 'off', 'Color', 'white', ...
    'Position', [100, 100, 900, 900]);
layout = tiledlayout(figureHandle, 2, 2, ...
    'TileSpacing', 'compact', 'Padding', 'compact');
plotMetric(nexttile(layout), data, cases, colors, ...
    'two_wing_compliance_Nm', 'Two-wing compliance at 10 deg [N m]');
plotMetric(nexttile(layout), data, cases, colors, ...
    'maximum_vertical_deflection_m', ...
    'Maximum vertical deflection at 10 deg [m]');
plotStress(nexttile(layout), data, cases, colors);
plotMetric(nexttile(layout), data, cases, colors, ...
    'first_modal_frequency_Hz', 'First retained modal frequency [Hz]');
title(layout, 'Aeroelastic mesh-convergence results', ...
    'FontName', 'Times New Roman', 'FontWeight', 'bold');
exportgraphics(figureHandle, outputFile, 'Resolution', 220, ...
    'BackgroundColor', 'white');
close(figureHandle);
fprintf('%s\n', outputFile);
end

function plotMetric(ax, data, cases, colors, variableName, yLabelText)
hold(ax, 'on');
for index = 1:numel(cases)
    rows = data(data.case_id == cases(index), :);
    rows = sortrows(rows, 'mesh_edge_length_mm', 'ascend');
    plot(ax, rows.mesh_edge_length_mm, rows.(variableName), '-o', ...
        'LineWidth', 1.4, 'Color', colors(index, :), ...
        'MarkerFaceColor', colors(index, :), ...
        'DisplayName', sprintf('Case %d', cases(index)));
end
hold(ax, 'off');
xlim(ax, [1.8, 2.5]);
xlabel(ax, 'Target mesh edge length [mm]');
ylabel(ax, yLabelText);
grid(ax, 'on');
box(ax, 'on');
legend(ax, 'Location', 'best');
set(ax, 'FontName', 'Times New Roman', 'FontSize', 9);
end

function plotStress(ax, data, cases, colors)
hold(ax, 'on');
for index = 1:numel(cases)
    rows = data(data.case_id == cases(index), :);
    rows = sortrows(rows, 'mesh_edge_length_mm', 'ascend');
    plot(ax, rows.mesh_edge_length_mm, rows.skin_vm_p9975_MPa, '-o', ...
        'LineWidth', 1.4, 'Color', colors(index, :), ...
        'MarkerFaceColor', colors(index, :), ...
        'DisplayName', sprintf('Case %d', cases(index)));
    plot(ax, rows.mesh_edge_length_mm, ...
        rows.cbeam_normal_stress_p9975_MPa, '--s', ...
        'LineWidth', 1.2, 'Color', colors(index, :), ...
        'HandleVisibility', 'off');
end
hold(ax, 'off');
xlim(ax, [1.8, 2.5]);
xlabel(ax, 'Target mesh edge length [mm]');
ylabel(ax, '99.75th-percentile stress [MPa]');
grid(ax, 'on');
box(ax, 'on');
legendHandle = legend(ax, 'Location', 'southoutside', 'NumColumns', 2);
legendHandle.Title.String = 'Solid: skin VM; dashed: CBEAM normal';
set(ax, 'FontName', 'Times New Roman', 'FontSize', 9);
end
