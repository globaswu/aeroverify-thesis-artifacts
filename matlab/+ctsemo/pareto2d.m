function [front, indices] = pareto2d(Y)
%PARETO2D Return the unique nondominated front for two-objective minimization.
%   FRONT = ctsemo.pareto2d(Y) removes nonfinite and dominated rows from
%   the N-by-2 objective matrix Y. FRONT is sorted by increasing first
%   objective; its second objective is therefore strictly decreasing.
%
%   [FRONT, INDICES] also returns the corresponding row indices in Y.
%   For duplicate objective rows, the first original row is retained.

    if isempty(Y)
        front = zeros(0, 2);
        indices = zeros(0, 1);
        return
    end
    if ~(isnumeric(Y) && ismatrix(Y) && size(Y, 2) == 2)
        error("cTSEMO:Pareto2D:InvalidObjectives", ...
            "Y must be a numeric N-by-2 matrix.");
    end

    finiteRows = all(isfinite(Y), 2);
    indices = find(finiteRows);
    points = double(Y(finiteRows, :));
    if isempty(points)
        front = zeros(0, 2);
        indices = zeros(0, 1);
        return
    end

    % Sorting by the original index makes duplicate retention deterministic.
    sorted = sortrows([points, double(indices)], [1, 2, 3]);
    points = sorted(:, 1:2);
    indices = sorted(:, 3);

    keep = false(size(points, 1), 1);
    bestSecondObjective = Inf;
    for row = 1:size(points, 1)
        if points(row, 2) < bestSecondObjective
            keep(row) = true;
            bestSecondObjective = points(row, 2);
        end
    end

    front = points(keep, :);
    indices = indices(keep);
end
