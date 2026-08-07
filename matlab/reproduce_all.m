function summary = reproduce_all(outputDirectory)
%REPRODUCE_ALL Reproduce FCC and BCC figures, tables, and summary.

if nargin < 1 || strlength(string(outputDirectory)) == 0
    outputDirectory = fullfile(artifact_repository_root(), "generated");
end
outputDirectory = string(outputDirectory);
if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end

fccSummary = reproduce_topology( ...
    "fcc", fullfile(outputDirectory, "fcc"));
bccSummary = reproduce_topology( ...
    "bcc", fullfile(outputDirectory, "bcc"));
summary = [fccSummary; bccSummary];
writetable(summary, fullfile(outputDirectory, ...
    "reproduction_summary.csv"));

disp(summary);
end

