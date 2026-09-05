function plot_3_8(outputFile)
if nargin < 1, outputFile = fullfile(fileparts(mfilename('fullpath')), 'plot_3_8.png'); end
% Reproduce three benchmark panels using only the adjacent CSV.
% All observed X/Y/C records are retained in the CSV. Only the feasible
% nondominated objective pairs and the empirical GA reference are plotted.
% Uses base MATLAB graphics and readtable; no solver is called.
root = fileparts(mfilename('fullpath'));
T = readtable(fullfile(root, 'figure_3_8.csv'), ...
    'TextType', 'string', 'VariableNamingRule', 'preserve');
T = T(T.is_pareto == 1, :);
problems = ["WELDEDBEAM", "MW7_D4", "MW7_D6"];
names = ["(a) Welded beam, D = 4", "(b) MW7, D = 4", "(c) MW7, D = 6"];
solvers = ["ctsemo", "hypermapper", "botorch", "trieste", "usemoc", "comboo", "pac-moo"];
labels = ["cTSEMO (binary)", "HyperMapper (binary)", "BoTorch", ...
    "Trieste", "USeMOC", "COMBOO", "PAC-MOO", "Empirical GA reference"];
colors = [0 114 178; 213 94 0; 60 60 60; 88 88 88; 115 115 115; 144 144 144; 85 85 85] / 255;
markers = {'o', '<', 's', '^', 'd', 'v', '>'};
fig = figure('Visible', 'off', 'Color', 'w', 'Units', 'inches', 'Position', [1 1 7 7]);
cleanup = onCleanup(@() close(fig));
t = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(t, 'Observed feasible Pareto sets', 'FontSize', 11, 'FontWeight', 'normal');
subtitle(t, '150 evaluations per solver: 20 shared initial + 130 adaptive; one run', 'FontSize', 8);
for p = 1:3
    ax = nexttile(t); hold(ax, 'on');
    P = T(T.problem == problems(p), :);
    G = P(P.solver == "ga_reference", :);
    scatter(ax, G.normalized_Y1, G.normalized_Y2, 3, [0.08 0.08 0.08], '.');
    for s = 7:-1:1
        S = P(P.solver == solvers(s), :);
        if s == 1
            face = colors(s, :); sizeValue = 22;
        else
            face = 'none'; sizeValue = 19;
        end
        scatter(ax, S.normalized_Y1, S.normalized_Y2, sizeValue, ...
            'Marker', markers{s}, 'MarkerEdgeColor', colors(s, :), ...
            'MarkerFaceColor', face, 'LineWidth', 0.85);
    end
    title(ax, names(p), 'FontSize', 9, 'FontWeight', 'normal');
    xlabel(ax, 'Normalized objective 1'); ylabel(ax, 'Normalized objective 2');
    set(ax, 'FontName', 'Arial', 'FontSize', 8, 'Box', 'off', ...
        'GridColor', [.87 .87 .87], 'GridAlpha', .6);
    grid(ax, 'on'); pbaspect(ax, [1 1 1]); axis(ax, 'padded');
end
ax = nexttile(t); hold(ax, 'on'); axis(ax, 'off');
handles = gobjects(8, 1);
for s = 1:7
    face = 'none';
    if s == 1, face = colors(s, :); end
    handles(s) = plot(ax, NaN, NaN, 'LineStyle', 'none', 'Marker', markers{s}, ...
        'Color', colors(s, :), 'MarkerFaceColor', face, 'MarkerSize', 5);
end
handles(8) = plot(ax, NaN, NaN, '.', 'Color', [.08 .08 .08]);
legend(ax, handles, labels, 'Location', 'northwest', 'Box', 'off', 'FontSize', 8);
text(ax, .04, .02, {'cTSEMO and HyperMapper use binary labels.', ...
    'Other solvers use continuous margins.', '', ...
    'The pooled GA reference is empirical;', 'it is not a true Pareto front.'}, ...
    'Units', 'normalized', 'VerticalAlignment', 'bottom', 'FontSize', 8);
exportgraphics(fig, outputFile, 'Resolution', 300);
end
