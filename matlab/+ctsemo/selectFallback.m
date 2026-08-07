function [index, fallbackScore, info] = selectFallback( ...
        Xcandidate, p_i, Xtrain, invalidMask, reason, options)
%SELECTFALLBACK Select a feasibility-novelty candidate after AF degeneracy.
%   [INDEX, SCORE, INFO] = ctsemo.selectFallback(XCANDIDATE, P_I,
%   XTRAIN, INVALIDMASK, REASON, OPTIONS) ranks valid candidates by
%
%       max(p_i(x), p_floor) * novelty(x).
%
%   Novelty is a bounded function of nearest design-space distance. Thus an
%   all-infeasible initial design remains operable even when clipping makes
%   p_i zero everywhere: the PoF floor reduces the rule to maximin
%   exploration. Empty or wholly invalid pools request candidate regeneration.

    if nargin < 6 || isempty(options)
        options = struct();
    end
    if nargin < 5 || isempty(reason)
        reason = "unspecified";
    end
    if nargin < 4 || isempty(invalidMask)
        invalidMask = false(size(Xcandidate, 1), 1);
    end
    if isempty(Xcandidate)
        Xcandidate = zeros(0, size(Xtrain, 2));
    end
    if ~(isnumeric(Xcandidate) && ismatrix(Xcandidate) && ...
            isnumeric(Xtrain) && ismatrix(Xtrain) && ...
            (isempty(Xtrain) || size(Xcandidate, 2) == size(Xtrain, 2)))
        error("cTSEMO:SelectFallback:InvalidDesignData", ...
            "Candidate and training designs must have equal column counts.");
    end
    candidateCount = size(Xcandidate, 1);
    if ~(islogical(invalidMask) || isnumeric(invalidMask)) || ...
            numel(invalidMask) ~= candidateCount
        error("cTSEMO:SelectFallback:InvalidMask", ...
            "invalidMask must contain one logical value per candidate.");
    end
    invalidMask = logical(reshape(invalidMask, [], 1));
    reason = string(reason);
    if ~isscalar(reason) || ismissing(reason)
        error("cTSEMO:SelectFallback:InvalidReason", ...
            "reason must be scalar text.");
    end

    p_i = evaluatePof(p_i, Xcandidate);
    if numel(p_i) ~= candidateCount
        error("cTSEMO:SelectFallback:PoFCountMismatch", ...
            "p_i must return one value per candidate.");
    end
    p_i = reshape(double(p_i), [], 1);
    p_i(~isfinite(p_i)) = 0;
    p_i = min(1, max(0, p_i));

    pofFloor = fallbackOption(options, "minPoF", NaN);
    if ~isfinite(pofFloor)
        pofFloor = fallbackOption(options, "pofFloor", 0.60);
    end
    distanceScale = fallbackOption(options, "distanceScale", 0.10);
    distanceWeight = fallbackOption(options, "distanceWeight", 1);
    validateattributes(pofFloor, {'numeric'}, ...
        {'scalar', 'real', 'finite', '>=', 0, '<=', 1}, ...
        mfilename, "options.fallback.minPoF");
    validateattributes(distanceScale, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'}, ...
        mfilename, "options.fallback.distanceScale");
    validateattributes(distanceWeight, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'nonnegative'}, ...
        mfilename, "options.fallback.distanceWeight");

    finiteCandidate = all(isfinite(Xcandidate), 2);
    finiteTraining = all(isfinite(Xtrain), 2);
    Xtrain = double(Xtrain(finiteTraining, :));
    nearestDistance = inf(candidateCount, 1);
    if ~isempty(Xtrain) && any(finiteCandidate)
        distances = pairwiseDistance( ...
            double(Xcandidate(finiteCandidate, :)), Xtrain);
        nearestDistance(finiteCandidate) = min(distances, [], 2);
    end

    if isempty(Xtrain)
        novelty = ones(candidateCount, 1);
    else
        novelty = 1 - exp(-nearestDistance ./ distanceScale);
        novelty = min(1, max(0, novelty));
    end
    if distanceWeight == 0
        novelty(:) = 1;
    else
        novelty = novelty .^ distanceWeight;
    end

    invalid = invalidMask | ~finiteCandidate;
    fallbackScore = max(p_i, pofFloor) .* novelty;
    fallbackScore(invalid | ~isfinite(fallbackScore)) = -Inf;

    index = [];
    requiresCandidateRegeneration = candidateCount == 0 || ...
        ~any(isfinite(fallbackScore));
    if ~requiresCandidateRegeneration
        [~, index] = max(fallbackScore);
    end

    if reason == "no_feasible_front"
        phase = "phase_i";
        policy = "maximin_feasibility_novelty";
    else
        phase = "fallback";
        policy = "pof_novelty";
    end
    if requiresCandidateRegeneration
        policy = "regenerate_candidate_pool";
    end

    info = struct( ...
        "reason", reason, ...
        "phase", phase, ...
        "policy", policy, ...
        "pofFloor", pofFloor, ...
        "distanceScale", distanceScale, ...
        "distanceWeight", distanceWeight, ...
        "nearestDistance", nearestDistance, ...
        "novelty", novelty, ...
        "requiresCandidateRegeneration", requiresCandidateRegeneration, ...
        "selectedIndex", index);
end

function p_i = evaluatePof(p_i, Xcandidate)
    if isa(p_i, "function_handle")
        p_i = p_i(Xcandidate);
    end
    if ~(isnumeric(p_i) || islogical(p_i))
        error("cTSEMO:SelectFallback:InvalidPoF", ...
            "p_i must be numeric or a function handle.");
    end
    if isscalar(p_i) && size(Xcandidate, 1) ~= 1
        p_i = repmat(p_i, size(Xcandidate, 1), 1);
    end
end

function value = fallbackOption(options, name, defaultValue)
    value = defaultValue;
    if isstruct(options) && isscalar(options) && ...
            isfield(options, "fallback") && ...
            isstruct(options.fallback) && ...
            isfield(options.fallback, name)
        value = options.fallback.(name);
    end
end

function distances = pairwiseDistance(A, B)
    squared = sum(A.^2, 2) + sum(B.^2, 2).' - 2 .* (A * B.');
    distances = sqrt(max(0, squared));
end
