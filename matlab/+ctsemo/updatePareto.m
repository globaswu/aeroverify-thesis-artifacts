function pareto = updatePareto(X, Y, isFeasible, referencePoint)
%UPDATEPARETO Return the feasible nondominated set and two-objective HV.
%   PARETO = ctsemo.updatePareto(X,Y,ISFEASIBLE) derives a finite
%   minimization reference point from the current feasible observations.
%   Supplying REFERENCEPOINT keeps the hypervolume reference fixed.

    arguments
        X (:,:) double {mustBeReal, mustBeFinite}
        Y (:,2) double {mustBeReal, mustBeFinite}
        isFeasible (:,1) logical
        referencePoint double {mustBeReal, mustBeFinite} = zeros(0, 2)
    end

    if size(X, 1) ~= size(Y, 1) || numel(isFeasible) ~= size(Y, 1)
        error("cTSEMO:Pareto:RowMismatch", ...
            "X, Y, and isFeasible must have the same number of rows.");
    end
    if ~(isempty(referencePoint) || isequal(size(referencePoint), [1, 2]))
        error("cTSEMO:Pareto:ReferenceShape", ...
            "referencePoint must be empty or a two-element row vector.");
    end

    feasibleIndex = find(isFeasible);
    if isempty(feasibleIndex)
        pareto = emptyPareto(size(X, 2), referencePoint);
        return
    end

    feasibleY = Y(feasibleIndex, :);
    nondominated = nondominatedMask(feasibleY);
    frontIndex = feasibleIndex(nondominated);
    frontY = Y(frontIndex, :);
    [frontY, order] = sortrows(frontY, [1, 2]);
    frontIndex = frontIndex(order);
    frontX = X(frontIndex, :);

    if isempty(referencePoint)
        referencePoint = derivedReference(feasibleY);
    end
    if any(referencePoint <= max(frontY, [], 1))
        error("cTSEMO:Pareto:InvalidReferencePoint", ...
            "The reference point must be worse than every Pareto objective.");
    end

    pareto = struct();
    pareto.X = frontX;
    pareto.Y = frontY;
    pareto.index = frontIndex;
    pareto.referencePoint = referencePoint;
    pareto.hypervolume = hypervolume2d(frontY, referencePoint);
    pareto.nPoints = size(frontY, 1);
end

function pareto = emptyPareto(dimension, referencePoint)
    pareto = struct();
    pareto.X = zeros(0, dimension);
    pareto.Y = zeros(0, 2);
    pareto.index = zeros(0, 1);
    pareto.referencePoint = referencePoint;
    pareto.hypervolume = 0;
    pareto.nPoints = 0;
end

function selected = nondominatedMask(Y)
    observationCount = size(Y, 1);
    selected = true(observationCount, 1);
    for row = 1:observationCount
        dominatesRow = all(Y <= Y(row, :), 2) & ...
            any(Y < Y(row, :), 2);
        selected(row) = ~any(dominatesRow);
    end
end

function referencePoint = derivedReference(Y)
    lower = min(Y, [], 1);
    upper = max(Y, [], 1);
    span = upper - lower;
    minimumMargin = 0.1 .* max(1, abs(upper));
    margin = max(0.1 .* span, minimumMargin);
    referencePoint = upper + margin;
end

function value = hypervolume2d(front, referencePoint)
    if isempty(front)
        value = 0;
        return
    end

    front = front(all(front < referencePoint, 2), :);
    if isempty(front)
        value = 0;
        return
    end
    front = sortrows(front, [1, 2]);

    value = 0;
    yBoundary = referencePoint(2);
    for row = 1:size(front, 1)
        width = max(0, referencePoint(1) - front(row, 1));
        height = max(0, yBoundary - front(row, 2));
        value = value + width .* height;
        yBoundary = min(yBoundary, front(row, 2));
    end
end
