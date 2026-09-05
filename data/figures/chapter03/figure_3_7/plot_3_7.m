function plot_3_7(outputFile)
if nargin < 1, outputFile = fullfile(fileparts(mfilename('fullpath')), 'plot_3_7.png'); end
% Reproduce four benchmark panels using only the adjacent CSV.
% C is the aggregate binary feasibility label; audit margins were retained
% for verification, not provided online to cTSEMO or HyperMapper.
% Uses base MATLAB graphics and readtable; no solver is called.
root = fileparts(mfilename('fullpath'));
T = readtable(fullfile(root, 'figure_3_7.csv'), ...
    'TextType', 'string', 'VariableNamingRule', 'preserve');
T = T(T.is_pareto == 1, :);
problems = ["CF1_D4", "CF1_D10", "C2DTLZ2_D4_R02", "C2DTLZ2_D6_R02"];
names = ["(a) CF1, D = 4", "(b) CF1, D = 10", ...
    "(c) C2-DTLZ2, D = 4", "(d) C2-DTLZ2, D = 6"];
solvers = ["ctsemo", "hypermapper", "botorch", "trieste", "usemoc", "comboo", "pac-moo"];
labels = ["cTSEMO (binary)", "HyperMapper (binary)", "BoTorch", ...
    "Trieste", "USeMOC", "COMBOO", "PAC-MOO", "Empirical GA reference"];
colors = [0 114 178; 213 94 0; 60 60 60; 88 88 88; 115 115 115; 144 144 144; 85 85 85] / 255;
markers = {'o', '<', 's', '^', 'd', 'v', '>'};
fig = figure('Visible', 'off', 'Color', 'w', 'Units', 'inches', ...
    'Position', [1 1 7 7.25]);
cleanup = onCleanup(@() close(fig));
t = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(t, 'Observed feasible Pareto sets', 'FontSize', 11, 'FontWeight', 'normal');
subtitle(t, '150 evaluations per solver: 20 shared initial + 130 adaptive; one run', 'FontSize', 8);
handles = gobjects(8, 1);
for p = 1:4
    ax = nexttile(t); hold(ax, 'on');
    P = T(T.problem == problems(p), :);
    G = P(P.solver == "ga_reference", :);
    handles(8) = scatter(ax, G.normalized_Y1, G.normalized_Y2, 3, [0.08 0.08 0.08], '.');
    for s = 7:-1:1
        S = P(P.solver == solvers(s), :);
        if s == 1
            face = colors(s, :); sizeValue = 22;
        else
            face = 'none'; sizeValue = 19;
        end
        handles(s) = scatter(ax, S.normalized_Y1, S.normalized_Y2, sizeValue, ...
            'Marker', markers{s}, 'MarkerEdgeColor', colors(s, :), ...
            'MarkerFaceColor', face, 'LineWidth', 0.85);
    end
    title(ax, names(p), 'FontSize', 9, 'FontWeight', 'normal');
    xlabel(ax, 'Normalized objective 1'); ylabel(ax, 'Normalized objective 2');
    set(ax, 'FontName', 'Arial', 'FontSize', 8, 'Box', 'off', ...
        'GridColor', [.87 .87 .87], 'GridAlpha', .6);
    grid(ax, 'on'); pbaspect(ax, [1 1 1]); axis(ax, 'padded');
end
leg = legend(handles, labels, 'NumColumns', 4, 'Box', 'off', 'FontSize', 7.5);
leg.Layout.Tile = 'south';
xlabel(t, 'Normalization uses the empirical GA front; it is not a true Pareto front.', 'FontSize', 7.5);
exportgraphics(fig, outputFile, 'Resolution', 300);
end
