function [hvi, info] = sampledHVI( ...
        candidateObjectives, feasibleObjectives, referencePoint)
%SAMPLEDHVI Hypervolume improvement of objective Thompson-sample values.
%   HVI = ctsemo.sampledHVI(YCANDIDATE, YFEASIBLE, REFERENCEPOINT)
%   computes exact two-objective minimization HVI. YFEASIBLE must contain
%   only observed feasible objective values. Both objective matrices and the
%   dynamic reference point must use the same standardized coordinates.
%
%   [HVI, INFO] reports a structural fallback reason when there is no
%   feasible observed front, no usable candidate pool, or no positive HVI.
%   This function intentionally does not manufacture a positive background.

    referencePoint = validateReferencePoint(referencePoint);
    candidateObjectives = validateObjectives( ...
        candidateObjectives, "candidateObjectives", true);
    feasibleObjectives = validateObjectives( ...
        feasibleObjectives, "feasibleObjectives", true);

    candidateCount = size(candidateObjectives, 1);
    hvi = zeros(candidateCount, 1);
    validCandidate = all(isfinite(candidateObjectives), 2);
    finiteFeasible = all(isfinite(feasibleObjectives), 2);

    info = struct( ...
        "reason", "ok", ...
        "requiresFallback", false, ...
        "candidateCount", candidateCount, ...
        "validCandidateCount", nnz(validCandidate), ...
        "feasibleInputCount", nnz(finiteFeasible), ...
        "frontSize", 0, ...
        "positiveCount", 0, ...
        "baseHypervolume", 0, ...
        "referencePoint", referencePoint, ...
        "validCandidate", validCandidate);

    if candidateCount == 0 || ~any(validCandidate)
        info.reason = "candidate_generation_failure";
        info.requiresFallback = true;
        return
    end

    [info.baseHypervolume, feasibleFront] = ctsemo.hypervolume2d( ...
        feasibleObjectives(finiteFeasible, :), referencePoint);
    info.frontSize = size(feasibleFront, 1);
    if isempty(feasibleFront)
        info.reason = "no_feasible_front";
        info.requiresFallback = true;
        return
    end

    % The front defines a monotone step function. Integrating the part of
    % each candidate rectangle not already dominated gives exact HVI while
    % avoiding one Pareto sort per candidate.
    intervalLeft = [-Inf; feasibleFront(:, 1)].';
    intervalRight = [feasibleFront(:, 1); referencePoint(1)].';
    attainedSecond = [referencePoint(2); feasibleFront(:, 2)].';

    validRows = find(validCandidate);
    chunkSize = 20000;
    for first = 1:chunkSize:numel(validRows)
        last = min(first + chunkSize - 1, numel(validRows));
        rows = validRows(first:last);
        firstObjective = candidateObjectives(rows, 1);
        secondObjective = candidateObjectives(rows, 2);

        widths = max(0, intervalRight - ...
            max(intervalLeft, firstObjective));
        heights = max(0, attainedSecond - secondObjective);
        values = sum(widths .* heights, 2);
        hvi(rows) = max(0, values);
    end

    info.positiveCount = nnz(hvi > 0);
    if info.positiveCount == 0
        info.reason = "no_positive_hvi";
        info.requiresFallback = true;
    end
end

function Y = validateObjectives(Y, name, allowEmpty)
    if isempty(Y) && allowEmpty
        Y = zeros(0, 2);
        return
    end
    if ~(isnumeric(Y) && ismatrix(Y) && size(Y, 2) == 2)
        error("cTSEMO:SampledHVI:InvalidObjectives", ...
            "%s must be a numeric N-by-2 matrix.", name);
    end
    Y = double(Y);
end

function referencePoint = validateReferencePoint(referencePoint)
    if ~(isnumeric(referencePoint) && isvector(referencePoint) && ...
            numel(referencePoint) == 2 && all(isfinite(referencePoint)))
        error("cTSEMO:SampledHVI:InvalidReferencePoint", ...
            "referencePoint must contain two finite numeric values.");
    end
    referencePoint = reshape(double(referencePoint), 1, 2);
end
