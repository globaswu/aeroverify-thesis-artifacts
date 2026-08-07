function [designMask, codomainMask, info] = crowdingMasks( ...
        Xcandidate, Xtrain, Ycandidate, Ytrain, options)
%CROWDINGMASKS Compact anti-clustering masks in design and objective space.
%   [MX, MY, INFO] = ctsemo.crowdingMasks(XCANDIDATE, XTRAIN,
%   YCANDIDATE, YTRAIN, OPTIONS) evaluates Wendland C2 exclusion masks:
%
%       phi(s) = (1-s)^4 (4s+1),  0 <= s < 1,
%       M(z)   = floor + (1-floor) (1-max_j phi(||z-z_j||/rho)).
%
%   X coordinates are expected to be scaled to the unit box. Y candidate
%   and training rows must share the standardized objective coordinates
%   used by the sampled-HVI calculation. Design-space hard duplicates are
%   always assigned zero masks, independently of the optional soft masks.

    if nargin < 5 || isempty(options)
        options = struct();
    end
    [Xcandidate, Xtrain] = validatePair( ...
        Xcandidate, Xtrain, "design variables");
    [Ycandidate, Ytrain] = validatePair( ...
        Ycandidate, Ytrain, "objective values");
    if size(Xcandidate, 1) ~= size(Ycandidate, 1)
        error("cTSEMO:CrowdingMasks:CandidateCountMismatch", ...
            "Xcandidate and Ycandidate must have the same number of rows.");
    end

    candidateCount = size(Xcandidate, 1);
    designEnabled = optionValue(options, ...
        {"masks", "design", "enabled"}, true);
    designRadius = optionValue(options, ...
        {"masks", "design", "radiusScale"}, 0.02);
    designFloor = optionValue(options, ...
        {"masks", "design", "floor"}, 0);
    codomainEnabled = optionValue(options, ...
        {"masks", "codomain", "enabled"}, true);
    codomainRadius = optionValue(options, ...
        {"masks", "codomain", "radiusScale"}, 0.05);
    codomainFloor = optionValue(options, ...
        {"masks", "codomain", "floor"}, 0);
    duplicateTolerance = firstAvailableOption(options, {
        {"masks", "duplicateTolerance"}
        {"candidates", "duplicateTolerance"}}, 1.0e-9);

    designEnabled = validateLogical(designEnabled, "design.enabled");
    codomainEnabled = validateLogical(codomainEnabled, "codomain.enabled");
    designRadius = validatePositive(designRadius, "design.radiusScale");
    codomainRadius = validatePositive(codomainRadius, ...
        "codomain.radiusScale");
    designFloor = validateUnitScalar(designFloor, "design.floor");
    codomainFloor = validateUnitScalar(codomainFloor, "codomain.floor");
    duplicateTolerance = validateNonnegative( ...
        duplicateTolerance, "duplicateTolerance");

    validDesignCandidate = all(isfinite(Xcandidate), 2);
    validObjectiveCandidate = all(isfinite(Ycandidate), 2);
    finiteXtrain = Xtrain(all(isfinite(Xtrain), 2), :);
    finiteYtrain = Ytrain(all(isfinite(Ytrain), 2), :);

    designMask = ones(candidateCount, 1);
    minimumDesignDistance = inf(candidateCount, 1);
    if ~isempty(finiteXtrain) && any(validDesignCandidate)
        distances = pairwiseDistance( ...
            Xcandidate(validDesignCandidate, :), finiteXtrain);
        minimumDesignDistance(validDesignCandidate) = min(distances, [], 2);
        if designEnabled
            designMask(validDesignCandidate) = compactMask( ...
                minimumDesignDistance(validDesignCandidate), ...
                designRadius, designFloor);
        end
    end

    hardDuplicate = minimumDesignDistance <= duplicateTolerance;
    designMask(hardDuplicate | ~validDesignCandidate) = 0;

    codomainMask = ones(candidateCount, 1);
    minimumCodomainDistance = inf(candidateCount, 1);
    if ~isempty(finiteYtrain) && any(validObjectiveCandidate)
        distances = pairwiseDistance( ...
            Ycandidate(validObjectiveCandidate, :), finiteYtrain);
        minimumCodomainDistance(validObjectiveCandidate) = ...
            min(distances, [], 2);
        if codomainEnabled
            codomainMask(validObjectiveCandidate) = compactMask( ...
                minimumCodomainDistance(validObjectiveCandidate), ...
                codomainRadius, codomainFloor);
        end
    end
    codomainMask(~validObjectiveCandidate) = 0;

    designMask = min(1, max(0, designMask));
    codomainMask = min(1, max(0, codomainMask));
    info = struct( ...
        "method", "wendland_c2_nearest_observation", ...
        "designEnabled", designEnabled, ...
        "codomainEnabled", codomainEnabled, ...
        "designRadius", designRadius, ...
        "codomainRadius", codomainRadius, ...
        "designFloor", designFloor, ...
        "codomainFloor", codomainFloor, ...
        "duplicateTolerance", duplicateTolerance, ...
        "hardDuplicate", hardDuplicate, ...
        "minimumDesignDistance", minimumDesignDistance, ...
        "minimumCodomainDistance", minimumCodomainDistance);
end

function mask = compactMask(distance, radius, floorValue)
    scaledDistance = distance ./ radius;
    kernel = zeros(size(scaledDistance));
    active = isfinite(scaledDistance) & scaledDistance < 1;
    s = max(0, scaledDistance(active));
    kernel(active) = (1 - s).^4 .* (4 .* s + 1);
    mask = floorValue + (1 - floorValue) .* (1 - kernel);
end

function distances = pairwiseDistance(A, B)
    squared = sum(A.^2, 2) + sum(B.^2, 2).' - 2 .* (A * B.');
    distances = sqrt(max(0, squared));
end

function [A, B] = validatePair(A, B, description)
    if isempty(A)
        if isempty(B)
            A = zeros(0, 0);
            B = zeros(0, 0);
            return
        end
        A = zeros(0, size(B, 2));
    end
    if isempty(B)
        B = zeros(0, size(A, 2));
    end
    if ~(isnumeric(A) && ismatrix(A) && ...
            isnumeric(B) && ismatrix(B) && size(A, 2) == size(B, 2))
        error("cTSEMO:CrowdingMasks:DimensionMismatch", ...
            "Candidate and training %s must be numeric matrices with equal column counts.", ...
            description);
    end
    A = double(A);
    B = double(B);
end

function value = firstAvailableOption(options, paths, defaultValue)
    value = defaultValue;
    for pathIndex = 1:numel(paths)
        [candidate, found] = nestedValue(options, paths{pathIndex});
        if found
            value = candidate;
            return
        end
    end
end

function value = optionValue(options, path, defaultValue)
    [value, found] = nestedValue(options, path);
    if ~found
        value = defaultValue;
    end
end

function [value, found] = nestedValue(container, path)
    value = container;
    found = true;
    for part = 1:numel(path)
        name = path{part};
        if ~(isstruct(value) && isscalar(value) && isfield(value, name))
            value = [];
            found = false;
            return
        end
        value = value.(name);
    end
end

function value = validateLogical(value, name)
    if ~(islogical(value) && isscalar(value))
        error("cTSEMO:CrowdingMasks:InvalidOption", ...
            "%s must be a logical scalar.", name);
    end
end

function value = validatePositive(value, name)
    if ~(isnumeric(value) && isscalar(value) && ...
            isreal(value) && isfinite(value) && value > 0)
        error("cTSEMO:CrowdingMasks:InvalidOption", ...
            "%s must be a positive finite scalar.", name);
    end
    value = double(value);
end

function value = validateNonnegative(value, name)
    if ~(isnumeric(value) && isscalar(value) && ...
            isreal(value) && isfinite(value) && value >= 0)
        error("cTSEMO:CrowdingMasks:InvalidOption", ...
            "%s must be a nonnegative finite scalar.", name);
    end
    value = double(value);
end

function value = validateUnitScalar(value, name)
    value = validateNonnegative(value, name);
    if value > 1
        error("cTSEMO:CrowdingMasks:InvalidOption", ...
            "%s must not exceed one.", name);
    end
end
