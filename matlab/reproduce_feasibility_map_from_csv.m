function outputFile = reproduce_feasibility_map_from_csv(figureId, outputFile)
%REPRODUCE_FEASIBILITY_MAP_FROM_CSV Dispatch to a self-contained figure package.
%   Supported figure IDs are 5.3, 5.5, 5.10, 5.15, and 5.18. Each delegated
%   MATLAB script reads only the single CSV beside it. The CSV retains the
%   sampled design inputs X, objective responses Y, binary labels C, and the
%   plotted field records required by that figure.

arguments
    figureId (1,1) string {mustBeMember(figureId, ...
        ["5.3","5.5","5.10","5.15","5.18"])}
    outputFile (1,1) string = ""
end

repositoryRoot = artifact_repository_root();
parts = split(figureId, ".");
stem = "figure_" + parts(1) + "_" + parts(2);
folder = fullfile(repositoryRoot, "data", "figures", "chapter05", stem);
functionName = "plot_" + parts(1) + "_" + parts(2);
if outputFile == ""
    outputFile = fullfile(folder, functionName + ".png");
end

oldPath = path;
cleanup = onCleanup(@() path(oldPath)); %#ok<NASGU>
addpath(folder);
plotFunction = str2func(functionName);
plotFunction(outputFile);
end
