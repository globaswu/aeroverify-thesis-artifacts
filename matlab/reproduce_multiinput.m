function summary = reproduce_multiinput(outputDirectory)
%REPRODUCE_MULTIINPUT Rebuild four-input results from the frozen 100 rows.

if nargin < 1 || strlength(string(outputDirectory)) == 0
    outputDirectory = fullfile(artifact_repository_root(), ...
        "generated", "multiinput");
end
if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end

root = artifact_repository_root();
data = readtable(fullfile(root, "data", "multiinput", ...
    "evaluations_cases001_100.csv"), TextType="string", ...
    VariableNamingRule="preserve");
data.Feasible = to_logical_column(data.Feasible);
data.Pareto = to_logical_column(data.Pareto);
pareto = observed_pareto_mask([data.CDitrim, data.Ctrim], data.Feasible);
assert(isequal(pareto, data.Pareto), ...
    "Stored and recomputed multi-input Pareto masks differ.");

plotMultiinputObjectives(data, pareto, outputDirectory);
plotMultiinputDesignSpace(data, pareto, outputDirectory);
plotMultiinputProgress(root, outputDirectory);

summary = table("FOUR-INPUT", height(data), nnz(data.Feasible), ...
    nnz(pareto), 'VariableNames', ...
    ["Study", "Evaluations", "Feasible", "Pareto"]);
writetable(summary, fullfile(outputDirectory, "multiinput_summary.csv"));
end

function plotMultiinputObjectives(data, pareto, outputDirectory)
figureHandle = figure(Visible="off", Color="white", ...
    Position=[100, 100, 900, 650]);
axesHandle = axes(figureHandle);
hold(axesHandle, "on");
scatter(axesHandle, data.CDitrim(~data.Feasible), data.Ctrim(~data.Feasible), ...
    46, "x", MarkerEdgeColor=[0.42, 0.45, 0.48], LineWidth=1.1, ...
    DisplayName=sprintf("Infeasible (%d)", nnz(~data.Feasible)));
scatter(axesHandle, data.CDitrim(data.Feasible & ~pareto), ...
    data.Ctrim(data.Feasible & ~pareto), 40, "o", ...
    MarkerFaceColor=[0.70, 0.73, 0.76], MarkerEdgeColor="white", ...
    DisplayName=sprintf("Feasible, dominated (%d)", ...
    nnz(data.Feasible & ~pareto)));
scatter(axesHandle, data.CDitrim(pareto), data.Ctrim(pareto), 66, "d", ...
    MarkerFaceColor=[0.85, 0.36, 0.05], MarkerEdgeColor="white", ...
    DisplayName=sprintf("Observed Pareto (%d)", nnz(pareto)));
xlabel(axesHandle, "Trim induced-drag coefficient [-]");
ylabel(axesHandle, "Two-wing trim compliance [N m]");
title(axesHandle, "Four-input observed finite-sample Pareto set");
legend(axesHandle, Location="best", Box="off");
grid(axesHandle, "on"); box(axesHandle, "on");
set(axesHandle, FontName="Times New Roman", FontSize=10);
exportBoth(figureHandle, outputDirectory, "multiinput_observed_pareto");
end

function plotMultiinputDesignSpace(data, pareto, outputDirectory)
names = ["AR", "lambda", "r1", "r2"];
labels = ["AR", "lambda", "r_1", "r_2"];
bounds = [6, 12; 0.2, 0.8; 0.05, 0.40; 0.15, 0.50];
pairs = nchoosek(1:4, 2);
figureHandle = figure(Visible="off", Color="white", ...
    Position=[100, 100, 1100, 720]);
layout = tiledlayout(figureHandle, 2, 3, ...
    TileSpacing="compact", Padding="compact");
legendHandles = gobjects(3, 1);
for panel = 1:size(pairs, 1)
    first = pairs(panel, 1); second = pairs(panel, 2);
    x = (data.(names(first)) - bounds(first, 1)) ./ diff(bounds(first, :));
    y = (data.(names(second)) - bounds(second, 1)) ./ diff(bounds(second, :));
    axesHandle = nexttile(layout);
    hold(axesHandle, "on");
    infeasibleHandle = scatter(axesHandle, x(~data.Feasible), y(~data.Feasible), ...
        26, "x", MarkerEdgeColor=[0.42, 0.45, 0.48], ...
        HandleVisibility="off");
    feasibleHandle = scatter(axesHandle, x(data.Feasible & ~pareto), ...
        y(data.Feasible & ~pareto), 24, "o", ...
        MarkerFaceColor=[0.70, 0.73, 0.76], MarkerEdgeColor="white", ...
        HandleVisibility="off");
    paretoHandle = scatter(axesHandle, x(pareto), y(pareto), 38, "d", ...
        MarkerFaceColor=[0.85, 0.36, 0.05], MarkerEdgeColor="white", ...
        HandleVisibility="off");
    if panel == 1
        legendHandles = [infeasibleHandle; feasibleHandle; paretoHandle];
        set(legendHandles, HandleVisibility="on");
    end
    xlim(axesHandle, [0, 1]); ylim(axesHandle, [0, 1]);
    pbaspect(axesHandle, [1, 1, 1]);
    xlabel(axesHandle, labels(first) + " (normalized)", Interpreter="tex");
    ylabel(axesHandle, labels(second) + " (normalized)", Interpreter="tex");
    grid(axesHandle, "on"); box(axesHandle, "on");
    set(axesHandle, FontName="Times New Roman", FontSize=9);
end
title(layout, "Four-input evaluated-design coverage", ...
    FontName="Times New Roman", FontWeight="bold");
legendHandle = legend(legendHandles, ...
    ["Infeasible", "Feasible, dominated", "Observed Pareto"], ...
    Orientation="horizontal", Box="off");
legendHandle.Layout.Tile = "south";
exportBoth(figureHandle, outputDirectory, "multiinput_design_space");
end

function plotMultiinputProgress(root, outputDirectory)
history = readtable(fullfile(root, "data", "multiinput", ...
    "adaptive_hypervolume_stress.csv"), TextType="string", ...
    VariableNamingRule="preserve");
history.Feasible = to_logical_column(history.Feasible);
history.ParetoNow = to_logical_column(history.ParetoNow);
figureHandle = figure(Visible="off", Color="white", ...
    Position=[100, 100, 900, 700]);
layout = tiledlayout(figureHandle, 2, 1, ...
    TileSpacing="compact", Padding="compact");
firstAxes = nexttile(layout);
stairs(firstAxes, history.Case, cumsum(history.DeltaHV), ...
    Color=[0.12, 0.39, 0.63], LineWidth=1.7);
ylabel(firstAxes, "Cumulative normalized HV increment [-]");
grid(firstAxes, "on"); box(firstAxes, "on");
secondAxes = nexttile(layout);
hold(secondAxes, "on");
scatter(secondAxes, history.Case(history.Feasible), ...
    history.StressUtilization(history.Feasible), 32, "o", ...
    MarkerFaceColor=[0.12, 0.39, 0.63], MarkerEdgeColor="white");
scatter(secondAxes, history.Case(~history.Feasible), ...
    history.StressUtilization(~history.Feasible), 38, "x", ...
    MarkerEdgeColor=[0.75, 0.18, 0.16], LineWidth=1.2);
yline(secondAxes, 1, "--", "Stress limit", ...
    Color=[0.2, 0.2, 0.2], LabelHorizontalAlignment="left");
xlabel(secondAxes, "Case");
ylabel(secondAxes, "Governing stress utilization [-]");
grid(secondAxes, "on"); box(secondAxes, "on");
title(layout, "Four-input adaptive history");
set([firstAxes, secondAxes], FontName="Times New Roman", FontSize=10);
exportBoth(figureHandle, outputDirectory, "multiinput_adaptive_history");
end

function exportBoth(figureHandle, outputDirectory, stem)
exportgraphics(figureHandle, fullfile(outputDirectory, stem + ".png"), ...
    Resolution=220);
exportgraphics(figureHandle, fullfile(outputDirectory, stem + ".pdf"), ...
    ContentType="vector");
close(figureHandle);
end
