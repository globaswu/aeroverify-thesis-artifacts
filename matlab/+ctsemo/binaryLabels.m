function [isFeasible, diagnostics] = binaryLabels(constraintValues, tolerance)
%BINARYLABELS Convert constraint values into aggregate feasibility labels.
%   ISFEASIBLE = ctsemo.binaryLabels(G) returns one logical label per row of
%   G. A row is feasible when every constraint is finite and no greater
%   than zero. ctsemo.binaryLabels(G,TOLERANCE) instead uses G <= TOLERANCE.
%
%   [ISFEASIBLE,DIAGNOSTICS] also reports the numbers of constraints,
%   feasible observations, and rows containing nonfinite values.

arguments
    constraintValues (:,:) double {mustBeReal}
    tolerance (1,1) double {mustBeReal, mustBeFinite} = 0
end

finiteRows = all(isfinite(constraintValues), 2);
isFeasible = finiteRows & all(constraintValues <= tolerance, 2);

diagnostics = struct( ...
    "constraintCount", size(constraintValues, 2), ...
    "observationCount", size(constraintValues, 1), ...
    "feasibleCount", nnz(isFeasible), ...
    "infeasibleCount", nnz(~isFeasible), ...
    "nonfiniteRowCount", nnz(~finiteRows), ...
    "tolerance", tolerance);
end
