function pools = makeCandidatePools( ...
        lb, ub, options, iteration, evaluatedX)
%MAKECANDIDATEPOOLS Create deterministic primary and challenger LHS pools.
%   POOLS = ctsemo.makeCandidatePools(LB,UB,OPTIONS,ITERATION,EVALUATEDX)
%   creates candidate locations only; it never evaluates an objective or a
%   constraint. Separate deterministic streams are used for the primary and
%   challenger pools, and the caller's global random stream is unchanged.
%
%   When enabled and dimensionally reasonable, hyperrectangle corners are
%   included in the primary pool. Previously evaluated locations are removed
%   using the normalized duplicate tolerance.

    if nargin < 3 || isempty(options)
        options = cTSEMOOptions();
    else
        options = cTSEMOOptions(options);
    end
    if nargin < 4 || isempty(iteration)
        iteration = 1;
    end

    [lb, ub] = canonicalBounds(lb, ub);
    dimension = numel(lb);
    if nargin < 5 || isempty(evaluatedX)
        evaluatedX = zeros(0, dimension);
    end
    validateattributes(iteration, {'numeric'}, ...
        {'scalar', 'integer', 'positive', 'finite'}, ...
        mfilename, "iteration");
    validateattributes(evaluatedX, {'numeric'}, ...
        {'2d', 'real', 'finite'}, mfilename, "evaluatedX");
    if size(evaluatedX, 2) ~= dimension
        error("cTSEMO:Candidates:DimensionMismatch", ...
            "evaluatedX must have one column per design variable.");
    end

    evaluatedUnit = (double(evaluatedX) - lb) ./ (ub - lb);
    tolerance = options.candidates.duplicateTolerance;

    primarySeed = iterationSeed(options.seed, iteration, 104729);
    challengerSeed = iterationSeed(options.seed, iteration, 130363);

    useCorners = options.candidates.includeCorners && ...
        dimension <= options.candidates.maxCornerDimension;
    [primaryUnit, primaryOrigin] = buildPool( ...
        options.candidates.primaryCount, dimension, evaluatedUnit, ...
        tolerance, primarySeed, useCorners);

    if options.challengers.enabled
        challengerExclusions = evaluatedUnit;
        [challengerUnit, challengerOrigin] = buildPool( ...
            options.challengers.count, dimension, challengerExclusions, ...
            tolerance, challengerSeed, false);

        duplicatePrimary = ismember(challengerUnit, primaryUnit, "rows");
        if any(duplicatePrimary)
            challengerUnit(duplicatePrimary, :) = [];
            challengerUnit = refillPool( ...
                challengerUnit, options.challengers.count, dimension, ...
                [evaluatedUnit; primaryUnit], tolerance, ...
                challengerSeed + 1);
            challengerOrigin = repmat("lhs", size(challengerUnit, 1), 1);
        end
    else
        challengerUnit = zeros(0, dimension);
        challengerOrigin = strings(0, 1);
    end

    primaryX = lb + primaryUnit .* (ub - lb);
    challengerX = lb + challengerUnit .* (ub - lb);
    primarySource = repmat("primary", size(primaryX, 1), 1);
    challengerSource = repmat("challenger", size(challengerX, 1), 1);

    pools = struct();
    pools.primary = struct( ...
        "X", primaryX, ...
        "XUnit", primaryUnit, ...
        "source", primarySource, ...
        "origin", primaryOrigin);
    pools.challenger = struct( ...
        "X", challengerX, ...
        "XUnit", challengerUnit, ...
        "source", challengerSource, ...
        "origin", challengerOrigin);
    pools.X = [primaryX; challengerX];
    pools.XUnit = [primaryUnit; challengerUnit];
    pools.source = [primarySource; challengerSource];
    pools.origin = [primaryOrigin; challengerOrigin];
    pools.seed = struct( ...
        "primary", primarySeed, ...
        "challenger", challengerSeed);
end

function [lb, ub] = canonicalBounds(lb, ub)
    validateattributes(lb, {'numeric'}, ...
        {'vector', 'real', 'finite', 'nonempty'}, mfilename, "lb");
    validateattributes(ub, {'numeric'}, ...
        {'vector', 'real', 'finite', 'nonempty'}, mfilename, "ub");
    lb = reshape(double(lb), 1, []);
    ub = reshape(double(ub), 1, []);
    if numel(lb) ~= numel(ub) || any(lb >= ub)
        error("cTSEMO:Candidates:InvalidBounds", ...
            "lb and ub must have equal length with lb strictly below ub.");
    end
end

function seed = iterationSeed(baseSeed, iteration, offset)
    maximumSeed = 2^32 - 1;
    seed = mod(double(baseSeed) + double(offset) * double(iteration), ...
        maximumSeed);
end

function [points, origin] = buildPool( ...
        count, dimension, exclusions, tolerance, seed, useCorners)
    points = zeros(0, dimension);
    origin = strings(0, 1);

    if useCorners
        corners = hyperrectangleCorners(dimension);
        corners = filterCandidates(corners, exclusions, tolerance);
        if size(corners, 1) > count
            corners = corners(1:count, :);
        end
        points = corners;
        origin = repmat("corner", size(corners, 1), 1);
    end

    nNeeded = count - size(points, 1);
    if nNeeded > 0
        lhsPoints = refillPool( ...
            zeros(0, dimension), nNeeded, dimension, ...
            [exclusions; points], tolerance, seed);
        points = [points; lhsPoints];
        origin = [origin; repmat("lhs", size(lhsPoints, 1), 1)];
    end
end

function points = refillPool( ...
        points, targetCount, dimension, exclusions, tolerance, seed)
    attempt = 0;
    while size(points, 1) < targetCount && attempt < 12
        attempt = attempt + 1;
        nNeeded = targetCount - size(points, 1);
        nDraw = max(nNeeded + 32, ceil(1.2 * nNeeded));
        drawSeed = mod(seed + 7919 * (attempt - 1), 2^32 - 1);
        candidates = latinHypercube(nDraw, dimension, drawSeed);
        candidates = filterCandidates( ...
            candidates, [exclusions; points], tolerance);
        if ~isempty(candidates)
            nTake = min(nNeeded, size(candidates, 1));
            points = [points; candidates(1:nTake, :)]; %#ok<AGROW>
        end
    end

    if size(points, 1) < targetCount
        error("cTSEMO:Candidates:PoolConstructionFailed", ...
            "Unable to construct %d distinct candidates after excluding " + ...
            "evaluated locations. Reduce the candidate count or tolerance.", ...
            targetCount);
    end
end

function points = latinHypercube(nPoints, dimension, seed)
    stream = RandStream("mt19937ar", "Seed", seed);
    points = zeros(nPoints, dimension);
    for column = 1:dimension
        order = randperm(stream, nPoints);
        points(:, column) = ...
            (reshape(order, [], 1) - rand(stream, nPoints, 1)) / nPoints;
    end
end

function corners = hyperrectangleCorners(dimension)
    nCorners = 2^dimension;
    corners = zeros(nCorners, dimension);
    indices = uint64((0:(nCorners - 1)).');
    for column = 1:dimension
        corners(:, column) = bitget(indices, column);
    end
end

function candidates = filterCandidates(candidates, exclusions, tolerance)
    if isempty(candidates)
        return
    end

    [~, uniqueIndices] = unique(candidates, "rows", "stable");
    candidates = candidates(sort(uniqueIndices), :);
    if isempty(exclusions)
        return
    end

    keep = true(size(candidates, 1), 1);
    for row = 1:size(exclusions, 1)
        separation = max(abs(candidates - exclusions(row, :)), [], 2);
        keep = keep & separation > tolerance;
    end
    candidates = candidates(keep, :);
end
