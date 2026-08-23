function summary = reproduce_mesh_convergence(outputDirectory)
%REPRODUCE_MESH_CONVERGENCE Plot the frozen 17-row mesh sensitivity record.

if nargin < 1 || strlength(string(outputDirectory)) == 0
    outputDirectory = fullfile(artifact_repository_root(), ...
        "generated", "mesh_convergence");
end
if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end
root = artifact_repository_root();
data = readtable(fullfile(root, "data", "mesh_convergence", ...
    "results_summary.csv"), TextType="string", VariableNamingRule="preserve");
plotPrimaryMetrics(data, outputDirectory);
plotCase64Vg(root, outputDirectory);
summary = table("MESH-CONVERGENCE", height(data), NaN, NaN, ...
    'VariableNames', ["Study", "Evaluations", "Feasible", "Pareto"]);
writetable(summary, fullfile(outputDirectory, ...
    "mesh_convergence_summary.csv"));
end

function plotPrimaryMetrics(data, outputDirectory)
metrics = ["RelativeCompliance", "RelativeMaxDeflection", ...
    "RelativeFirstFrequency"];
labels = ["Relative compliance", "Relative maximum displacement", ...
    "Relative first modal frequency"];
cases = unique(data.SourceCase, "stable");
colors = lines(numel(cases));
figureHandle = figure(Visible="off", Color="white", ...
    Position=[100, 100, 1250, 470]);
layout = tiledlayout(figureHandle, 1, 3, ...
    TileSpacing="compact", Padding="compact");
for metricIndex = 1:numel(metrics)
    axesHandle = nexttile(layout);
    hold(axesHandle, "on");
    for caseIndex = 1:numel(cases)
        rows = data.SourceCase == cases(caseIndex) & ...
            abs(data.GeometryToleranceM - 0.0015) < 1e-12;
        [x, order] = sort(1000 * data.MeshEdgeLengthM(rows));
        y = 100 * data.(metrics(metricIndex))(rows);
        y = y(order);
        plot(axesHandle, x, y, "-o", LineWidth=1.2, ...
            Color=colors(caseIndex, :), ...
            DisplayName="Case " + string(cases(caseIndex)));
    end
    xlabel(axesHandle, "Mesh edge length [mm]");
    ylabel(axesHandle, labels(metricIndex) + " [%]");
    grid(axesHandle, "on"); box(axesHandle, "on");
    set(axesHandle, FontName="Times New Roman", FontSize=9);
end
legend(nexttile(layout, 1), Location="northwest", Box="off");
title(layout, "Structural-mesh sensitivity relative to the finest tested mesh", ...
    FontName="Times New Roman", FontWeight="bold");
exportBoth(figureHandle, outputDirectory, "mesh_convergence_primary_metrics");
end

function plotCase64Vg(root, outputDirectory)
data = readtable(fullfile(root, "data", "mesh_convergence", ...
    "case64_positive_g_root19.csv"), TextType="string", ...
    VariableNamingRule="preserve");
data.positive = to_logical_column(data.positive);
configurations = unique(data.configuration, "stable");
colors = lines(numel(configurations));
figureHandle = figure(Visible="off", Color="white", ...
    Position=[100, 100, 900, 650]);
axesHandle = axes(figureHandle);
hold(axesHandle, "on");
for index = 1:numel(configurations)
    rows = data.configuration == configurations(index);
    plot(axesHandle, data.velocity_mps(rows), data.damping_g(rows), ...
        LineWidth=1.4, Color=colors(index, :), ...
        DisplayName=configurations(index));
end
yline(axesHandle, 0, "--", "g = 0", Color=[0.2, 0.2, 0.2]);
xlabel(axesHandle, "Velocity [m s^{-1}]");
ylabel(axesHandle, "Damping, g [-]");
title(axesHandle, "Case 64, tracked root 19 mesh sensitivity");
legend(axesHandle, Location="best", Box="off");
grid(axesHandle, "on"); box(axesHandle, "on");
set(axesHandle, FontName="Times New Roman", FontSize=10);
exportBoth(figureHandle, outputDirectory, "case64_positive_g_root19");
end

function exportBoth(figureHandle, outputDirectory, stem)
exportgraphics(figureHandle, fullfile(outputDirectory, stem + ".png"), ...
    Resolution=220);
exportgraphics(figureHandle, fullfile(outputDirectory, stem + ".pdf"), ...
    ContentType="vector");
close(figureHandle);
end
