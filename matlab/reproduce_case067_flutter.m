function summary = reproduce_case067_flutter(outputDirectory)
%REPRODUCE_CASE067_FLUTTER Compare the two archived MKAERO1 grids.

if nargin < 1 || strlength(string(outputDirectory)) == 0
    outputDirectory = fullfile(artifact_repository_root(), ...
        "generated", "case067_flutter");
end
if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end
root = artifact_repository_root();
data = readtable(fullfile(root, "data", "diagnostics", "fcc_case067", ...
    "old_vs_18_point_all20.csv"), TextType="string", ...
    VariableNamingRule="preserve");

figureHandle = figure(Visible="off", Color="white", ...
    Position=[100, 100, 950, 650]);
axesHandle = axes(figureHandle);
hold(axesHandle, "on");
plot(axesHandle, data.point, data.oldMaxDamping, "o-", ...
    Color=[0.46, 0.49, 0.52], LineWidth=1.2, ...
    DisplayName="Four-point MKAERO1 grid");
plot(axesHandle, data.point, data.newMaxDamping, "s-", ...
    Color=[0.12, 0.39, 0.63], LineWidth=1.2, ...
    DisplayName="18-point MKAERO1 grid");
yline(axesHandle, 0, "--", "g = 0", Color=[0.2, 0.2, 0.2], ...
    HandleVisibility="off");
xlabel(axesHandle, "Tracked point");
ylabel(axesHandle, "Maximum damping, g [-]");
title(axesHandle, "FCC case 67 reduced-frequency-grid diagnostic");
legend(axesHandle, Location="best", Box="off");
grid(axesHandle, "on"); box(axesHandle, "on");
set(axesHandle, FontName="Times New Roman", FontSize=10);
exportgraphics(figureHandle, fullfile(outputDirectory, ...
    "case067_mkaero1_comparison.png"), Resolution=220);
exportgraphics(figureHandle, fullfile(outputDirectory, ...
    "case067_mkaero1_comparison.pdf"), ContentType="vector");
close(figureHandle);

summary = table("FCC-CASE067", height(data), NaN, NaN, ...
    'VariableNames', ["Study", "Evaluations", "Feasible", "Pareto"]);
writetable(summary, fullfile(outputDirectory, "case067_summary.csv"));
end
