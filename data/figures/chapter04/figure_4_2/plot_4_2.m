function plot_4_2(outputFile)
%PLOT_4_2 Reproduce thesis Figure 4.2 from the sibling CSV file.

scriptDir = fileparts(mfilename('fullpath'));
if nargin < 1 || strlength(string(outputFile)) == 0
    outputFile = fullfile(scriptDir, 'plot_4_2.png');
end
outputFile = char(outputFile);
[outputDir, ~, outputExtension] = fileparts(outputFile);
assert(~isempty(outputExtension), ...
    'The output file must include a file-format suffix.');
if ~isempty(outputDir) && ~isfolder(outputDir)
    mkdir(outputDir);
end

data = readtable(fullfile(scriptDir, 'figure_4_2.csv'), ...
    'TextType', 'string', 'VariableNamingRule', 'preserve');
groups = ["FCC", "BCC", "SC"];
rows = zeros(numel(groups), 1);
for k = 1:numel(groups)
    match = find(data.topology == groups(k));
    assert(isscalar(match), 'The CSV must contain one row for %s.', groups(k));
    rows(k) = match;
end
selected = data(rows, :);

mass = selected.two_wing_mass_kg;
compliance = selected.trim_compliance_Nm;
cellSizeMm = selected.cell_size_mm;
r1 = selected.t1_over_a;
caseNumber = selected.case_id;
utilization = [selected.skin_stress_utilization, ...
    selected.beam_stress_utilization];

colors = [0.00, 0.45, 0.70; 0.85, 0.33, 0.10; 0.47, 0.67, 0.19];
fig = figure('Color', 'w', 'Units', 'inches', ...
    'Position', [1, 1, 7.5, 7.4], 'Visible', 'off');
layout = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', ...
    'Padding', 'compact');

ax1 = nexttile(layout, 1);
hold(ax1, 'on');
for k = 1:numel(groups)
    scatter(ax1, mass(k), compliance(k), 78, colors(k, :), 'filled', ...
        'MarkerEdgeColor', 'k', 'LineWidth', 0.7);
end
grid(ax1, 'on');
box(ax1, 'on');
xlabel(ax1, 'Two-wing mass, kg');
ylabel(ax1, 'Trim compliance, N m');
title(ax1, 'A. Frozen observed representatives');
xlim(ax1, [min(mass) - 1.2, max(mass) + 1.6]);
ylim(ax1, [min(compliance) - 0.13, max(compliance) + 0.18]);

offsets = [0.28, 0.04; 0.22, 0.04; -1.55, -0.09];
for k = 1:numel(groups)
    label = sprintf('%s %d\na = %.2f mm, r_1 = %.3f', ...
        groups(k), caseNumber(k), cellSizeMm(k), r1(k));
    text(ax1, mass(k) + offsets(k, 1), compliance(k) + offsets(k, 2), ...
        label, 'Color', [0.12, 0.12, 0.12], 'FontSize', 9.5, ...
        'VerticalAlignment', 'middle', 'FontName', 'Times New Roman', ...
        'Interpreter', 'tex');
end

ax2 = nexttile(layout, 2);
bars = bar(ax2, utilization, 'grouped');
bars(1).FaceColor = [0.30, 0.30, 0.30];
bars(2).FaceColor = [0.65, 0.65, 0.65];
bars(1).EdgeColor = 'none';
bars(2).EdgeColor = 'none';
hold(ax2, 'on');
yline(ax2, 1, '--', '220 MPa screen', 'Color', [0.75, 0.12, 0.12], ...
    'LineWidth', 1.2, 'LabelHorizontalAlignment', 'right', ...
    'LabelVerticalAlignment', 'bottom', 'FontName', 'Times New Roman', ...
    'Interpreter', 'none');
grid(ax2, 'on');
box(ax2, 'on');
xticks(ax2, 1:numel(groups));
xticklabels(ax2, cellstr(groups(:) + " " + string(caseNumber(:))));
ylabel(ax2, 'Stress utilization, \sigma_{max}/220 MPa', ...
    'Interpreter', 'tex');
title(ax2, 'B. Retained stress-channel comparison');
ylim(ax2, [0, 1.12]);
legend(ax2, {'Shell von Mises', 'CBEAM max. normal'}, ...
    'Location', 'southwest', 'Box', 'off', 'Interpreter', 'none');

allAxes = findall(fig, 'Type', 'axes');
set(allAxes, 'FontName', 'Times New Roman', 'FontSize', 10.5, ...
    'LineWidth', 0.8, 'TickDir', 'out', 'TickLabelInterpreter', 'none');
for k = 1:numel(allAxes)
    allAxes(k).XLabel.Interpreter = 'none';
    allAxes(k).YLabel.Interpreter = 'none';
    allAxes(k).Title.Interpreter = 'none';
end
ax2.YLabel.Interpreter = 'tex';

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
