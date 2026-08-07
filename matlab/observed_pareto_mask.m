function mask = observed_pareto_mask(objectives, feasible)
%OBSERVED_PARETO_MASK Nondominated mask for feasible minimization samples.

arguments
    objectives (:,2) double {mustBeReal, mustBeFinite}
    feasible (:,1) logical
end

if size(objectives, 1) ~= numel(feasible)
    error("artifacts:Pareto:RowMismatch", ...
        "Objectives and feasibility labels must have equal row counts.");
end

mask = false(size(objectives, 1), 1);
feasibleIndices = find(feasible);
tolerance = 1e-12;
for index = feasibleIndices(:)'
    competitors = feasibleIndices(feasibleIndices ~= index);
    dominated = any( ...
        all(objectives(competitors, :) <= ...
            objectives(index, :) + tolerance, 2) & ...
        any(objectives(competitors, :) < ...
            objectives(index, :) - tolerance, 2));
    mask(index) = ~dominated;
end
end

