function [score, components, status] = scoreCandidates( ...
        Xcandidate, Ycandidate, p_i, feasibleObjectives, ...
        referencePoint, Xtrain, Ytrain, options)
%SCORECANDIDATES Apply one acquisition definition to every candidate source.
%   SCORE = ctsemo.scoreCandidates(XCANDIDATE, YCANDIDATE, P_I,
%   YFEASIBLE, REFERENCEPOINT, XTRAIN, YTRAIN, OPTIONS) evaluates
%
%     A(x) = (HVI_TS(x) + epsilon) p_i(x)^alpha M_x(x) M_y(x),
%
%   where epsilon is a configured scale times an empirical quantile of the
%   positive sampled-HVI values. The caller should concatenate primary and
%   challenger pools before calling this function, so no source receives a
%   hidden multiplier or privileged selection rule.
%
%   If a feasible front or positive HVI is absent, STATUS requests an explicit
%   fallback. With a configured positive epsilon floor, SCORE can remain
%   positive so that a caller can evaluate a frozen pointwise acquisition
%   during continuous search. A hard design duplicate is always invalid.

    if nargin < 8 || isempty(options)
        options = struct();
    end
    if isempty(Xcandidate)
        Xcandidate = zeros(0, size(Xtrain, 2));
    end
    if ~(isnumeric(Xcandidate) && ismatrix(Xcandidate))
        error("cTSEMO:ScoreCandidates:InvalidCandidates", ...
            "Xcandidate must be a numeric matrix.");
    end
    if ~(isnumeric(Ycandidate) && ismatrix(Ycandidate) && ...
            (isempty(Ycandidate) || size(Ycandidate, 2) == 2))
        error("cTSEMO:ScoreCandidates:InvalidObjectives", ...
            "Ycandidate must be a numeric N-by-2 matrix.");
    end
    if size(Xcandidate, 1) ~= size(Ycandidate, 1)
        error("cTSEMO:ScoreCandidates:CandidateCountMismatch", ...
            "Xcandidate and Ycandidate must have the same number of rows.");
    end
    Xcandidate = double(Xcandidate);
    Ycandidate = reshape(double(Ycandidate), size(Xcandidate, 1), 2);

    p_i = evaluatePof(p_i, Xcandidate);
    if numel(p_i) ~= size(Xcandidate, 1)
        error("cTSEMO:ScoreCandidates:PoFCountMismatch", ...
            "p_i must return one value per candidate.");
    end
    p_i = reshape(double(p_i), [], 1);
    finitePof = isfinite(p_i);
    p_i(~finitePof) = 0;
    p_i = min(1, max(0, p_i));

    [hvi, hviInfo] = ctsemo.sampledHVI( ...
        Ycandidate, feasibleObjectives, referencePoint);
    [designMask, codomainMask, maskInfo] = ctsemo.crowdingMasks( ...
        Xcandidate, Xtrain, Ycandidate, Ytrain, options);

    pofPower = acquisitionOption(options, "pofPower", 1);
    backgroundScale = acquisitionOption(options, "backgroundScale", 0.25);
    backgroundQuantile = acquisitionOption( ...
        options, "backgroundQuantile", 0.25);
    minimumPositiveHVI = acquisitionOption( ...
        options, "minPositiveHVI", 1.0e-12);
    epsilonFloor = acquisitionOption(options, "epsilon", 0);
    validateattributes(pofPower, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'nonnegative'}, ...
        mfilename, "options.acquisition.pofPower");
    validateattributes(backgroundScale, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'nonnegative'}, ...
        mfilename, "options.acquisition.backgroundScale");
    validateattributes(backgroundQuantile, {'numeric'}, ...
        {'scalar', 'real', 'finite', '>=', 0, '<=', 1}, ...
        mfilename, "options.acquisition.backgroundQuantile");
    validateattributes(minimumPositiveHVI, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'nonnegative'}, ...
        mfilename, "options.acquisition.minPositiveHVI");
    validateattributes(epsilonFloor, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'nonnegative'}, ...
        mfilename, "options.acquisition.epsilon");

    positiveHVI = hvi(hvi > minimumPositiveHVI & isfinite(hvi));
    % Apply the configured floor even when this particular evaluation batch
    % contains no positive HVI. This makes a fixed epsilon a pointwise,
    % population-independent acquisition definition for continuous search.
    % STATUS still requests fallback when no positive-HVI reference exists.
    epsilon = epsilonFloor;
    reason = hviInfo.reason;
    requiresFallback = hviInfo.requiresFallback;
    if ~isempty(positiveHVI)
        quantileValue = empiricalQuantile( ...
            positiveHVI, backgroundQuantile);
        epsilon = max(epsilonFloor, backgroundScale * quantileValue);
        reason = "ok";
        requiresFallback = false;
    end

    invalid = ~all(isfinite(Xcandidate), 2) | ...
        ~all(isfinite(Ycandidate), 2) | ~finitePof | ...
        maskInfo.hardDuplicate;
    score = (hvi + epsilon) .* (p_i .^ pofPower) .* ...
        designMask .* codomainMask;
    score(invalid | ~isfinite(score)) = 0;

    % A pool containing positive HVI but no usable positive score is also a
    % structural fallback case (for example, all points are duplicates).
    if ~requiresFallback && ~any(score > 0)
        requiresFallback = true;
        if all(invalid)
            reason = "candidate_generation_failure";
        else
            reason = "no_positive_acquisition";
        end
    end

    components = struct( ...
        "hvi", hvi, ...
        "p_i", p_i, ...
        "epsilon", epsilon, ...
        "pofPower", pofPower, ...
        "designMask", designMask, ...
        "codomainMask", codomainMask, ...
        "invalid", invalid, ...
        "hardDuplicate", maskInfo.hardDuplicate, ...
        "hviInfo", hviInfo, ...
        "maskInfo", maskInfo);
    status = struct( ...
        "reason", reason, ...
        "requiresFallback", requiresFallback, ...
        "positiveHVISampleCount", numel(positiveHVI), ...
        "positiveScoreCount", nnz(score > 0), ...
        "epsilon", epsilon, ...
        "pofPower", pofPower);
end

function p_i = evaluatePof(p_i, Xcandidate)
    if isa(p_i, "function_handle")
        p_i = p_i(Xcandidate);
    end
    if ~(isnumeric(p_i) || islogical(p_i))
        error("cTSEMO:ScoreCandidates:InvalidPoF", ...
            "p_i must be numeric or a function handle.");
    end
    if isscalar(p_i) && size(Xcandidate, 1) ~= 1
        p_i = repmat(p_i, size(Xcandidate, 1), 1);
    end
end

function value = acquisitionOption(options, name, defaultValue)
    value = defaultValue;
    if isstruct(options) && isscalar(options) && ...
            isfield(options, "acquisition") && ...
            isstruct(options.acquisition) && ...
            isfield(options.acquisition, name)
        value = options.acquisition.(name);
    end
end

function value = empiricalQuantile(sample, probability)
    sample = sort(sample(:));
    if isscalar(sample)
        value = sample;
        return
    end
    position = 1 + probability * (numel(sample) - 1);
    lower = floor(position);
    upper = ceil(position);
    fraction = position - lower;
    value = sample(lower) + fraction * (sample(upper) - sample(lower));
end
