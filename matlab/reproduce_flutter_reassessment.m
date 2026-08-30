function summary = reproduce_flutter_reassessment(outputDirectory)
%REPRODUCE_FLUTTER_REASSESSMENT Verify the sanitized 65-case SOL 145 table.

if nargin < 1 || strlength(string(outputDirectory)) == 0
    outputDirectory = fullfile(artifact_repository_root(), ...
        "generated", "flutter_reassessment");
end
if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end

root = artifact_repository_root();
data = readtable(fullfile(root, "data", "flutter", ...
    "harmonized_sol145_results.csv"), TextType="string", ...
    VariableNamingRule="preserve");
data.strict_pass = to_logical_column(data.strict_pass);

assert(height(data) == 65, "Expected 65 harmonized rerun rows.");
assert(numel(unique(data.topology + ":" + string(data.case_id))) == 65, ...
    "Topology/case keys must be unique.");
assert(all(data.strict_pass), "Every released rerun must pass.");
assert(all(data.maximum_damping <= 0), ...
    "A released maximum damping value is positive.");
assert(all(data.num_flutter_roots == 20));
assert(all(data.rows_per_root == 37));
assert(all(data.total_rows == 740));

names = ["BCC"; "FCC"; "SC"];
expectedCounts = [15; 32; 18];
statistics = table(strings(4, 1), zeros(4, 1), zeros(4, 1), ...
    zeros(4, 1), strings(4, 1), ...
    VariableNames=["Topology", "Cases", "StrictPass", ...
    "LeastNegativeMaximumDamping", "GoverningCase"]);

for index = 1:numel(names)
    rows = data.topology == names(index);
    subset = data(rows, :);
    [leastNegative, localIndex] = max(subset.maximum_damping);
    statistics.Topology(index) = names(index);
    statistics.Cases(index) = height(subset);
    statistics.StrictPass(index) = nnz(subset.strict_pass);
    statistics.LeastNegativeMaximumDamping(index) = leastNegative;
    statistics.GoverningCase(index) = string(subset.case_id(localIndex));
    assert(height(subset) == expectedCounts(index));
end

[leastNegative, governingIndex] = max(data.maximum_damping);
statistics.Topology(4) = "TOTAL";
statistics.Cases(4) = height(data);
statistics.StrictPass(4) = nnz(data.strict_pass);
statistics.LeastNegativeMaximumDamping(4) = leastNegative;
statistics.GoverningCase(4) = ...
    data.topology(governingIndex) + " " + string(data.case_id(governingIndex));

writetable(statistics, fullfile(outputDirectory, ...
    "flutter_reassessment_summary.csv"));
summary = table("HARMONIZED-SOL145", height(data), nnz(data.strict_pass), ...
    NaN, VariableNames=["Study", "Evaluations", "Feasible", "Pareto"]);
end
