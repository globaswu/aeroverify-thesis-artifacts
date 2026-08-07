function outputPaths = write_continuation_table( ...
        topology, continuation, outputDirectory)
%WRITE_CONTINUATION_TABLE Write CSV and compact LaTeX continuation tables.

topology = lower(string(topology));
if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end

stem = topology + "_continuation_table";
outputPaths = struct( ...
    "csv", fullfile(outputDirectory, stem + ".csv"), ...
    "tex", fullfile(outputDirectory, stem + ".tex"));
writetable(continuation, outputPaths.csv);

fileId = fopen(outputPaths.tex, "w");
if fileId < 0
    error("artifacts:Table:OpenFailed", ...
        "Could not open %s for writing.", outputPaths.tex);
end
cleanup = onCleanup(@() fclose(fileId));

fprintf(fileId, "\\begin{tabular}{rrrrrrrlll}\n");
fprintf(fileId, "\\hline\n");
fprintf(fileId, "%s%s%s\n", ...
    "Case & $a$ [mm] & $t_1/a$ & Mass [kg] & Compliance [N m] & ", ...
    "$\sigma_{\max}$ [MPa] & $10^6 g_{\max}$ & Pool & ", ...
    "Feasibility & PF \\");
fprintf(fileId, "\\hline\n");
for row = 1:height(continuation)
    source = upper(extractBetween(continuation.selection_source(row), 1, 1));
    if continuation.feasible(row)
        result = "Pass";
    else
        failed = erase(continuation.feasibility_result(row), "fail_");
        failed = replace(failed, "_", " ");
        result = "Fail: " + failed;
    end
    if continuation.pareto_case071(row)
        pareto = "Yes";
    else
        pareto = "No";
    end
    fprintf(fileId, ...
        "%d & %.4f & %.6f & %.4f & %.4f & %.4f & %.3f & %s & %s & %s %s\n", ...
        continuation.case_id(row), 1000 * continuation.a_m(row), ...
        continuation.t1_over_a(row), continuation.mass_kg(row), ...
        continuation.compliance_Nm(row), ...
        continuation.max_stress_MPa(row), ...
        1e6 * continuation.max_flutter_damping(row), ...
        source, result, pareto, "\\");
end
fprintf(fileId, "\\hline\n");
fprintf(fileId, "\\end{tabular}\n");
end
