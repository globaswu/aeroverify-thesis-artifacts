function summary = reproduce_representative_physics(outputDirectory)
%REPRODUCE_REPRESENTATIVE_PHYSICS Replay compact LLT and mass checks.

if nargin < 1 || strlength(string(outputDirectory)) == 0
    outputDirectory = fullfile(artifact_repository_root(), ...
        "generated", "representative_physics");
end
if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end
root = artifact_repository_root();
dataDirectory = fullfile(root, "data", "representative_physics");
exact = readtable(fullfile(dataDirectory, ...
    "exact_trim_cdi_cases001_150.csv"), TextType="string", ...
    VariableNamingRule="preserve");
mass = readtable(fullfile(dataDirectory, ...
    "mass_reconstruction_cases004_037_064_065_099.csv"), ...
    TextType="string", VariableNamingRule="preserve");

plotExactTrim(exact, outputDirectory);
plotMassComparison(mass, outputDirectory);
summary = table("REPRESENTATIVE-PHYSICS", height(exact), NaN, NaN, ...
    'VariableNames', ["Study", "Evaluations", "Feasible", "Pareto"]);
writetable(summary, fullfile(outputDirectory, ...
    "representative_physics_summary.csv"));
end

function plotExactTrim(data, outputDirectory)
studies = unique(data.Study, "stable");
colors = lines(numel(studies));
figureHandle = figure(Visible="off", Color="white", ...
    Position=[100, 100, 800, 700]);
axesHandle = axes(figureHandle);
hold(axesHandle, "on");
for index = 1:numel(studies)
    rows = data.Study == studies(index);
    scatter(axesHandle, data.InterpolatedCDi(rows), ...
        data.ExactTrimCDi(rows), 28, "o", ...
        MarkerFaceColor=colors(index, :), MarkerEdgeColor="white", ...
        DisplayName=studies(index));
end
limits = [min([data.InterpolatedCDi; data.ExactTrimCDi]), ...
    max([data.InterpolatedCDi; data.ExactTrimCDi])];
plot(axesHandle, limits, limits, "--", Color=[0.2, 0.2, 0.2], ...
    HandleVisibility="off");
xlim(axesHandle, limits); ylim(axesHandle, limits);
pbaspect(axesHandle, [1, 1, 1]);
xlabel(axesHandle, "Stored interpolation-defined C_{D_i,trim}", ...
    Interpreter="tex");
ylabel(axesHandle, "Direct LLT C_{D_i,trim}", Interpreter="tex");
title(axesHandle, "Exact-trim LLT reconstruction");
legend(axesHandle, Location="best", Box="off");
grid(axesHandle, "on"); box(axesHandle, "on");
set(axesHandle, FontName="Times New Roman", FontSize=10);
exportBoth(figureHandle, outputDirectory, "exact_trim_cdi_comparison");
end

function plotMassComparison(data, outputDirectory)
figureHandle = figure(Visible="off", Color="white", ...
    Position=[100, 100, 900, 620]);
axesHandle = axes(figureHandle);
bar(axesHandle, categorical(string(data.Case)), ...
    [data.IntendedOptimizationMassHalf_kg, data.DeckTotalMassHalf_kg]);
xlabel(axesHandle, "Representative case");
ylabel(axesHandle, "Half-wing mass [kg]");
title(axesHandle, "Optimization and reconstructed deck mass conventions");
legend(axesHandle, ["Optimization convention", "Deck reconstruction"], ...
    Location="best", Box="off");
grid(axesHandle, "on"); box(axesHandle, "on");
set(axesHandle, FontName="Times New Roman", FontSize=10);
exportBoth(figureHandle, outputDirectory, "representative_mass_comparison");
end

function exportBoth(figureHandle, outputDirectory, stem)
exportgraphics(figureHandle, fullfile(outputDirectory, stem + ".png"), ...
    Resolution=220);
exportgraphics(figureHandle, fullfile(outputDirectory, stem + ".pdf"), ...
    ContentType="vector");
close(figureHandle);
end
