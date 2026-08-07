function [hypervolume, front] = hypervolume2d(Y, referencePoint)
%HYPERVOLUME2D Exact dominated hypervolume for two-objective minimization.
%   HV = ctsemo.hypervolume2d(Y, REFERENCEPOINT) measures the union of the
%   rectangles dominated by Y and bounded above by the 1-by-2 reference
%   point. Nonfinite, duplicate, dominated, and reference-exceeding points
%   do not contribute.
%
%   REFERENCEPOINT is deliberately an input rather than a hidden constant.
%   The optimizer may therefore update a dynamic reference point each
%   iteration in the same standardized objective coordinates as Y.

    referencePoint = validateReferencePoint(referencePoint);
    if isempty(Y)
        hypervolume = 0;
        front = zeros(0, 2);
        return
    end
    if ~(isnumeric(Y) && ismatrix(Y) && size(Y, 2) == 2)
        error("cTSEMO:Hypervolume2D:InvalidObjectives", ...
            "Y must be a numeric N-by-2 matrix.");
    end

    Y = double(Y);
    contributes = all(isfinite(Y), 2) & ...
        Y(:, 1) < referencePoint(1) & ...
        Y(:, 2) < referencePoint(2);
    [front, ~] = ctsemo.pareto2d(Y(contributes, :));
    if isempty(front)
        hypervolume = 0;
        return
    end

    previousSecondObjective = referencePoint(2);
    hypervolume = 0;
    for row = 1:size(front, 1)
        width = referencePoint(1) - front(row, 1);
        height = previousSecondObjective - front(row, 2);
        if width > 0 && height > 0
            hypervolume = hypervolume + width * height;
            previousSecondObjective = front(row, 2);
        end
    end
    hypervolume = max(0, hypervolume);
end

function referencePoint = validateReferencePoint(referencePoint)
    if ~(isnumeric(referencePoint) && isvector(referencePoint) && ...
            numel(referencePoint) == 2 && all(isfinite(referencePoint)))
        error("cTSEMO:Hypervolume2D:InvalidReferencePoint", ...
            "referencePoint must contain two finite numeric values.");
    end
    referencePoint = reshape(double(referencePoint), 1, 2);
end
