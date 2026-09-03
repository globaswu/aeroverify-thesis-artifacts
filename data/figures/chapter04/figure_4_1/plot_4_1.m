function plot_4_1(outputFile)
%PLOT_4_1 Reproduce thesis Figure 4.1 from the sibling CSV file.

scriptDir = fileparts(mfilename('fullpath'));
if nargin < 1 || strlength(string(outputFile)) == 0
    outputFile = fullfile(scriptDir, 'plot_4_1.png');
end
outputFile = char(outputFile);
[outputDir, ~, outputExtension] = fileparts(outputFile);
assert(~isempty(outputExtension), ...
    'The output file must include a file-format suffix.');
if ~isempty(outputDir) && ~isfolder(outputDir)
    mkdir(outputDir);
end

data = readtable(fullfile(scriptDir, 'figure_4_1.csv'), ...
    'TextType', 'string', 'VariableNamingRule', 'preserve');
caseOrder = [45, 47, 20];
roleLabels = ["Minimum compliance", "Normalized-distance knee", ...
    "Minimum induced drag"];
colors = [43, 140, 190; 240, 162, 2; 230, 97, 1] ./ 255;

assert(isequal(sort(unique(data.case_id))', sort(caseOrder)), ...
    'The CSV must contain cases 45, 47, and 20 only.');
maximumSemispan = max(data.semispan_m);
maximumRootChord = max(data.root_chord_m);

fig = figure('Color', 'w', 'Units', 'inches', ...
    'Position', [1, 1, 9.0, 7.4], 'Visible', 'off');
layout = tiledlayout(fig, 3, 1, 'TileSpacing', 'compact', ...
    'Padding', 'compact');

for k = 1:numel(caseOrder)
    rows = find(data.case_id == caseOrder(k));
    [~, order] = sort(data.point_order(rows));
    rows = rows(order);
    assert(isequal(data.point_order(rows)', 1:6), ...
        'Each case must contain point_order 1 through 6.');

    span = data.spanwise_m(rows);
    chordwise = data.chordwise_m(rows);
    metadata = data(rows(1), :);

    ax = nexttile(layout, k);
    fill(ax, span, chordwise, colors(k, :), ...
        'FaceAlpha', 0.82, 'EdgeColor', [0.125, 0.129, 0.141], ...
        'LineWidth', 1.0);
    hold(ax, 'on');
    plot(ax, [0, 0], [chordwise(5), chordwise(2)], ...
        'Color', [0.125, 0.129, 0.141], 'LineWidth', 0.8);
    yline(ax, 0, ':', 'Color', [0.373, 0.388, 0.408], ...
        'LineWidth', 0.7);
    grid(ax, 'on');
    box(ax, 'on');
    axis(ax, 'equal');
    xlim(ax, 1.08 .* [-maximumSemispan, maximumSemispan]);
    ylim(ax, [-0.31 .* maximumRootChord, 0.81 .* maximumRootChord]);
    ylabel(ax, 'Chordwise [m]');
    title(ax, sprintf(['Case %d: %s | AR = %.2f | \\lambda = %.3f | ' ...
        'C_{D_i,trim} = %.5f | C_{trim} = %.2f N m'], ...
        caseOrder(k), roleLabels(k), metadata.aspect_ratio, ...
        metadata.taper_ratio, metadata.CDitrim, metadata.Ctrim_Nm), ...
        'Interpreter', 'tex', 'FontSize', 9.2);
end

xlabel(nexttile(layout, 3), 'Spanwise position [m]');
title(layout, ['Representative final Pareto planforms: fixed area and ' ...
    'unswept quarter-chord'], 'FontSize', 14);
set(findall(fig, 'Type', 'axes'), 'FontName', 'Times New Roman', ...
    'FontSize', 9, 'LineWidth', 0.8, 'TickDir', 'out');

switch lower(outputExtension)
    case {'.pdf', '.svg'}
        exportgraphics(fig, outputFile, 'ContentType', 'vector');
    case {'.png', '.jpg', '.jpeg', '.tif', '.tiff'}
        exportgraphics(fig, outputFile, 'Resolution', 240);
    otherwise
        close(fig);
        error('Unsupported output format: %s', outputExtension);
end
close(fig);
fprintf('%s\n', outputFile);
end
