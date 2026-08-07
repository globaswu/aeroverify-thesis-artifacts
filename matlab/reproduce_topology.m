function summary = reproduce_topology(topology, outputDirectory)
%REPRODUCE_TOPOLOGY Reproduce one topology's public analysis artifacts.

topology = lower(string(topology));
[evaluations, continuation, config] = load_topology_data(topology);
if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end

plot_observed_pareto(topology, evaluations, outputDirectory, ...
    config.continuation_first_case);
[~, fitDiagnostics] = plot_feasibility_score( ...
    topology, evaluations, config, outputDirectory);
write_continuation_table(topology, continuation, outputDirectory);

initial = evaluations.case_id < config.continuation_first_case;
continued = ~initial;
summary = table();
summary.topology = upper(topology);
summary.total_evaluations = height(evaluations);
summary.initial_evaluations = nnz(initial);
summary.continuation_evaluations = nnz(continued);
summary.total_feasible = nnz(evaluations.feasible);
summary.initial_feasible = nnz(evaluations.feasible & initial);
summary.continuation_feasible = nnz(evaluations.feasible & continued);
summary.total_pareto = nnz(evaluations.pareto_case071);
summary.initial_pareto = nnz(evaluations.pareto_case071 & initial);
summary.continuation_pareto = ...
    nnz(evaluations.pareto_case071 & continued);
summary.primary_selections = nnz(continuation.selection_source == "primary");
summary.challenger_selections = ...
    nnz(continuation.selection_source == "challenger");
summary.fallback_selections = nnz(continuation.fallback_used);
summary.pof_base_length = fitDiagnostics.baseLength;
summary.pof_density_bandwidth = fitDiagnostics.densityBandwidth;
summary.pof_maximum_anchor_error = ...
    fitDiagnostics.maximumAnchorErrorBeforeSnap;

writetable(summary, fullfile(outputDirectory, ...
    char(topology + "_continuation_summary.csv")));
end

