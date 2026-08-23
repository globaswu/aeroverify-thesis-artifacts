function summary = reproduce_topology(topology, outputDirectory)
%REPRODUCE_TOPOLOGY Reproduce one topology's public analysis artifacts.

topology = lower(string(topology));
[evaluations, continuation, config] = load_topology_data(topology);
if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end

plot_observed_pareto(topology, evaluations, outputDirectory, ...
    config.continuation_first_case);
plot_feasibility_score(topology, evaluations, config, outputDirectory);
write_continuation_table(topology, continuation, outputDirectory);

summary = table(upper(topology), height(evaluations), ...
    nnz(evaluations.feasible), nnz(evaluations.pareto_case071), ...
    'VariableNames', ["Study", "Evaluations", "Feasible", "Pareto"]);
writetable(summary, fullfile(outputDirectory, ...
    char(topology + "_continuation_summary.csv")));
end
