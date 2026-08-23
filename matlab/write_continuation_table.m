function outputPaths = write_continuation_table( ...
        topology, continuation, outputDirectory)
%WRITE_CONTINUATION_TABLE Write portable CSV and compact LaTeX tables.

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

fprintf(fileId, "\\begin{tabular}{rrrrrlll}\n");
fprintf(fileId, "\\hline\n");
header = ['Case & $a$ [mm] & $t_1/a$ & Mass [kg] & ' ...
    'Compliance [N m] & Pool & Feasibility & PF'];
fprintf(fileId, "%s %c%c\n", header, '\', '\');
fprintf(fileId, "\\hline\n");
for row = 1:height(continuation)
    source = upper(extractBetween(string( ...
        continuation.selection_source(row)), 1, 1));
    if continuation.feasible(row)
        result = "Pass";
    else
        result = "Fail";
    end
    if continuation.pareto_case071(row)
        pareto = "Yes";
    else
        pareto = "No";
    end
    line = sprintf( ...
        "%d & %.4f & %.6f & %.4f & %.4f & %s & %s & %s", ...
        continuation.case_id(row), 1000 * continuation.a_m(row), ...
        continuation.t1_over_a(row), continuation.mass_kg(row), ...
        continuation.compliance_Nm(row), source, result, pareto);
    fprintf(fileId, "%s %c%c\n", line, '\', '\');
end
fprintf(fileId, "\\hline\n");
fprintf(fileId, "\\end{tabular}\n");
end
