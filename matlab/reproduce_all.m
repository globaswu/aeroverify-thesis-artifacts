function summary = reproduce_all(outputDirectory)
%REPRODUCE_ALL Reproduce all solver-free thesis artifacts in this release.

if nargin < 1 || strlength(string(outputDirectory)) == 0
    outputDirectory = fullfile(artifact_repository_root(), "generated");
end
outputDirectory = string(outputDirectory);
if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end

summaries = cell(9, 1);
topologies = ["fcc", "bcc", "sc"];
for index = 1:numel(topologies)
    topology = topologies(index);
    summaries{index} = reproduce_topology( ...
        topology, fullfile(outputDirectory, topology));
end
summaries{4} = reproduce_planform(fullfile(outputDirectory, "planform"));
summaries{5} = reproduce_multiinput(fullfile(outputDirectory, "multiinput"));
summaries{6} = reproduce_mesh_convergence( ...
    fullfile(outputDirectory, "mesh_convergence"));
summaries{7} = reproduce_case067_flutter( ...
    fullfile(outputDirectory, "case067_flutter"));
summaries{8} = reproduce_representative_physics( ...
    fullfile(outputDirectory, "representative_physics"));
summaries{9} = reproduce_flutter_reassessment( ...
    fullfile(outputDirectory, "flutter_reassessment"));
summary = vertcat(summaries{:});
writetable(summary, fullfile(outputDirectory, ...
    "reproduction_summary.csv"));
disp(summary);
end
