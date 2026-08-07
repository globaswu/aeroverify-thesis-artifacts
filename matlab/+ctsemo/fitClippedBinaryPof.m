function [model, diagnostics] = fitClippedBinaryPof( ...
        XNormalized, isFeasible, options)
%FITCLIPPEDBINARYPOF Fit an exact clipped binary-feasibility GP mean.
%   MODEL = ctsemo.fitClippedBinaryPof(X,LABELS,OPTIONS) fits an exact,
%   zero-noise GP interpolant to logical aggregate feasibility labels.
%   X contains normalized design points, one point per row. LABELS uses
%   true for feasible and false for infeasible.
%
%   The default raw targets are -0.25 and 1.25, the prior mean is 0.5, and
%   clipping is deferred to prediction. A smooth density/purity field
%   enlarges the scalar characteristic length only around clusters of
%   infeasible observations. OPTIONS may be either the PoF options struct
%   or a parent struct containing an options.pof field.
%
%   [MODEL,DIAGNOSTICS] reports duplicate consolidation, local-length
%   statistics, numerical jitter, conditioning, and interpolation error.

arguments
    XNormalized (:,:) double {mustBeReal, mustBeFinite}
    isFeasible logical
    options (1,1) struct = struct()
end

if isempty(XNormalized)
    error("ctsemo:fitClippedBinaryPof:EmptyTrainingSet", ...
        "At least one training observation is required.");
end
if ~isvector(isFeasible) || numel(isFeasible) ~= size(XNormalized, 1)
    error("ctsemo:fitClippedBinaryPof:LabelCountMismatch", ...
        "isFeasible must contain one logical label per row of XNormalized.");
end
isFeasible = reshape(isFeasible, [], 1);

pofOptions = resolvePofOptions(options);
settings = parseSettings(pofOptions);
validateNormalizedPoints(XNormalized, settings.duplicateTolerance);

[fitX, fitLabels, groupIndex, representativeIndex, groupCounts] = ...
    consolidateDuplicates(XNormalized, isFeasible, ...
    settings.duplicateTolerance);
fitTargets = settings.targets(1) + ...
    diff(settings.targets) .* double(fitLabels);
anchorTargets = settings.targets(1) + ...
    diff(settings.targets) .* double(isFeasible);

if isempty(settings.baseLength)
    baseLength = adaptiveBaseLength(fitX, fitLabels, ...
        settings.lengthBounds);
else
    baseLength = settings.baseLength;
end
if isempty(settings.densityBandwidth)
    densityBandwidth = adaptiveDensityBandwidth( ...
        fitX, baseLength, settings.localNeighbors);
else
    densityBandwidth = settings.densityBandwidth;
end

densityState = makeDensityState( ...
    fitX, fitLabels, densityBandwidth);
trainingSupport = localInfeasibleSupport( ...
    fitX, densityState, settings.purityExponent);
trainingMultiplier = min(settings.maxLengthScaleMultiplier, ...
    1 + settings.localStrength .* trainingSupport);
trainingLength = baseLength .* trainingMultiplier;

kernel = ctsemo.localMatern32( ...
    fitX, trainingLength, fitX, trainingLength);
kernel = 0.5 .* (kernel + kernel');
centeredTargets = fitTargets - settings.priorMean;
[coefficient, factorDiagnostics] = factorAndSolve( ...
    kernel, centeredTargets, settings);

anchorSupport = localInfeasibleSupport( ...
    XNormalized, densityState, settings.purityExponent);
anchorMultiplier = min(settings.maxLengthScaleMultiplier, ...
    1 + settings.localStrength .* anchorSupport);
anchorLength = baseLength .* anchorMultiplier;
anchorCrossCovariance = ctsemo.localMatern32( ...
    fitX, trainingLength, XNormalized, anchorLength);
rawAnchorMean = settings.priorMean + ...
    anchorCrossCovariance' * coefficient;
anchorResidual = rawAnchorMean - anchorTargets;
maximumAnchorError = max(abs(anchorResidual));
if maximumAnchorError > settings.anchorTolerance
    error("ctsemo:fitClippedBinaryPof:InterpolationTolerance", ...
        "Numerical interpolation error %.3g exceeds the requested " + ...
        "anchor tolerance %.3g.", ...
        maximumAnchorError, settings.anchorTolerance);
end

clippedAnchorMean = min(1, max(0, rawAnchorMean));
clippedAnchorError = max(abs( ...
    clippedAnchorMean - double(isFeasible)));
diagnostics = struct( ...
    "observationCount", size(XNormalized, 1), ...
    "uniqueObservationCount", size(fitX, 1), ...
    "consolidatedDuplicateCount", ...
        size(XNormalized, 1) - size(fitX, 1), ...
    "groupCounts", groupCounts, ...
    "representativeIndex", representativeIndex, ...
    "groupIndex", groupIndex, ...
    "feasibleCount", nnz(fitLabels), ...
    "infeasibleCount", nnz(~fitLabels), ...
    "baseLength", baseLength, ...
    "densityBandwidth", densityBandwidth, ...
    "localStrength", settings.localStrength, ...
    "localNeighbors", settings.localNeighbors, ...
    "maxLengthScaleMultiplier", settings.maxLengthScaleMultiplier, ...
    "trainingSupportMinimum", min(trainingSupport), ...
    "trainingSupportMaximum", max(trainingSupport), ...
    "trainingLengthMinimum", min(trainingLength), ...
    "trainingLengthMaximum", max(trainingLength), ...
    "jitterUsed", factorDiagnostics.jitterUsed, ...
    "jitterAttempts", factorDiagnostics.jitterAttempts, ...
    "attemptedAnchorErrors", factorDiagnostics.attemptedAnchorErrors, ...
    "kernelReciprocalCondition", rcond(kernel), ...
    "regularizedReciprocalCondition", ...
        factorDiagnostics.regularizedReciprocalCondition, ...
    "maximumAnchorErrorBeforeSnap", maximumAnchorError, ...
    "maximumClippedAnchorErrorBeforeSnap", clippedAnchorError, ...
    "anchorTolerance", settings.anchorTolerance, ...
    "interpolationWithinTolerance", ...
        maximumAnchorError <= settings.anchorTolerance);

model = struct( ...
    "construction", "exact_clipped_local_binary_gp_mean", ...
    "dimension", size(fitX, 2), ...
    "X", fitX, ...
    "labels", fitLabels, ...
    "rawTargets", fitTargets, ...
    "anchorX", XNormalized, ...
    "anchorLabels", isFeasible, ...
    "anchorTargets", anchorTargets, ...
    "groupIndex", groupIndex, ...
    "priorMean", settings.priorMean, ...
    "baseLength", baseLength, ...
    "localStrength", settings.localStrength, ...
    "maxLengthScaleMultiplier", settings.maxLengthScaleMultiplier, ...
    "purityExponent", settings.purityExponent, ...
    "densityState", densityState, ...
    "trainingSupport", trainingSupport, ...
    "trainingLength", trainingLength, ...
    "coefficient", coefficient, ...
    "duplicateTolerance", settings.duplicateTolerance, ...
    "settings", settings, ...
    "diagnostics", diagnostics);
end

function options = resolvePofOptions(options)
if isfield(options, "pof")
    options = options.pof;
elseif isfield(options, "PoF")
    options = options.PoF;
end
if ~isstruct(options) || ~isscalar(options)
    error("ctsemo:fitClippedBinaryPof:InvalidOptions", ...
        "The PoF options must be a scalar struct.");
end
end

function settings = parseSettings(options)
settings = struct();
settings.targets = targetOption(options);
settings.priorMean = scalarOption(options, ...
    ["priorMean", "PoFPriorMean", "pofPriorMean"], 0.5);
settings.baseLength = optionalScalarOption(options, ...
    ["baseLengthScale", "baseLength", ...
    "PoFBaseLength", "pofBaseLength"], []);
settings.localStrength = scalarOption(options, ...
    ["localStrength", "PoFLocalStrength", "pofLocalStrength"], 1);
settings.localNeighbors = optionalScalarOption(options, ...
    ["localNeighbors", "PoFLocalNeighbors", "pofLocalNeighbors"], []);
settings.maxLengthScaleMultiplier = scalarOption(options, ...
    ["maxLengthScaleMultiplier", "PoFMaxLengthScaleMultiplier", ...
    "pofMaxLengthScaleMultiplier"], 3);
settings.densityBandwidth = optionalScalarOption(options, ...
    ["densityBandwidth", "PoFDensityBandwidth", ...
    "pofDensityBandwidth"], []);
settings.purityExponent = scalarOption(options, ...
    ["purityExponent", "PoFPurityExponent", "pofPurityExponent"], 2);
settings.jitter = scalarOption(options, ...
    ["jitter", "PoFJitter", "pofJitter"], 1e-12);
settings.maxJitter = scalarOption(options, ...
    ["maxJitter", "PoFMaxJitter", "pofMaxJitter"], 1e-4);
settings.duplicateTolerance = scalarOption(options, ...
    ["duplicateTolerance", "PoFDuplicateTolerance", ...
    "pofDuplicateTolerance"], 1e-12);
settings.anchorTolerance = scalarOption(options, ...
    ["anchorTolerance", "PoFAnchorTolerance", ...
    "pofAnchorTolerance"], 1e-8);
settings.lengthBounds = rowOption(options, ...
    ["lengthBounds", "PoFLengthBounds", "pofLengthBounds"], ...
    [0.03, 1.5]);
settings.clipBounds = rowOption(options, ...
    ["clipBounds", "PoFClipBounds", "pofClipBounds"], [0, 1]);

if numel(settings.targets) ~= 2 || ...
        settings.targets(1) > 0 || settings.targets(2) < 1 || ...
        settings.targets(1) >= settings.targets(2)
    error("ctsemo:fitClippedBinaryPof:InvalidTargets", ...
        "targets must be [infeasible feasible], with the infeasible " + ...
        "target <= 0 and the feasible target >= 1.");
end
if settings.priorMean <= settings.targets(1) || ...
        settings.priorMean >= settings.targets(2)
    error("ctsemo:fitClippedBinaryPof:InvalidPriorMean", ...
        "priorMean must lie strictly between the two raw targets.");
end
if ~isempty(settings.baseLength) && settings.baseLength <= 0
    error("ctsemo:fitClippedBinaryPof:InvalidBaseLength", ...
        "baseLength must be empty or a positive finite scalar.");
end
if settings.localStrength < 0
    error("ctsemo:fitClippedBinaryPof:InvalidLocalStrength", ...
        "localStrength must be a nonnegative finite scalar.");
end
if ~isempty(settings.localNeighbors) && ...
        (settings.localNeighbors < 1 || ...
        fix(settings.localNeighbors) ~= settings.localNeighbors)
    error("ctsemo:fitClippedBinaryPof:InvalidLocalNeighbors", ...
        "localNeighbors must be empty or a positive integer.");
end
if settings.maxLengthScaleMultiplier < 1
    error("ctsemo:fitClippedBinaryPof:InvalidMaximumLengthMultiplier", ...
        "maxLengthScaleMultiplier must be at least one.");
end
if ~isempty(settings.densityBandwidth) && ...
        settings.densityBandwidth <= 0
    error("ctsemo:fitClippedBinaryPof:InvalidDensityBandwidth", ...
        "densityBandwidth must be empty or a positive finite scalar.");
end
if settings.purityExponent <= 0
    error("ctsemo:fitClippedBinaryPof:InvalidPurityExponent", ...
        "purityExponent must be positive.");
end
if settings.jitter < 0 || settings.maxJitter < settings.jitter
    error("ctsemo:fitClippedBinaryPof:InvalidJitter", ...
        "Require 0 <= jitter <= maxJitter.");
end
if settings.duplicateTolerance < 0 || settings.anchorTolerance <= 0
    error("ctsemo:fitClippedBinaryPof:InvalidTolerance", ...
        "duplicateTolerance must be nonnegative and anchorTolerance " + ...
        "must be positive.");
end
if numel(settings.lengthBounds) ~= 2 || ...
        settings.lengthBounds(1) <= 0 || ...
        settings.lengthBounds(2) < settings.lengthBounds(1)
    error("ctsemo:fitClippedBinaryPof:InvalidLengthBounds", ...
        "lengthBounds must contain two ordered positive values.");
end
if ~isequal(settings.clipBounds, [0, 1])
    error("ctsemo:fitClippedBinaryPof:InvalidClipBounds", ...
        "The shipped clipped feasibility field requires clipBounds [0,1].");
end
end

function targets = targetOption(options)
if isfield(options, "targets") || isfield(options, "PoFTargets") || ...
        isfield(options, "pofTargets")
    targets = rowOption(options, ...
        ["targets", "PoFTargets", "pofTargets"], [-0.25, 1.25]);
    return
end
rawInfeasible = scalarOption(options, ...
    ["rawInfeasible", "PoFRawInfeasible", "pofRawInfeasible"], -0.25);
rawFeasible = scalarOption(options, ...
    ["rawFeasible", "PoFRawFeasible", "pofRawFeasible"], 1.25);
targets = [rawInfeasible, rawFeasible];
end

function value = scalarOption(options, aliases, fallback)
value = optionValue(options, aliases, fallback);
if ~(isnumeric(value) && isreal(value) && isscalar(value) && ...
        isfinite(value))
    error("ctsemo:fitClippedBinaryPof:InvalidOption", ...
        "%s must be a finite real scalar.", aliases(1));
end
value = double(value);
end

function value = optionalScalarOption(options, aliases, fallback)
value = optionValue(options, aliases, fallback);
if isempty(value)
    value = [];
    return
end
if ~(isnumeric(value) && isreal(value) && isscalar(value) && ...
        isfinite(value))
    error("ctsemo:fitClippedBinaryPof:InvalidOption", ...
        "%s must be empty or a finite real scalar.", aliases(1));
end
value = double(value);
end

function value = rowOption(options, aliases, fallback)
value = optionValue(options, aliases, fallback);
if ~(isnumeric(value) && isreal(value) && isvector(value) && ...
        all(isfinite(value)))
    error("ctsemo:fitClippedBinaryPof:InvalidOption", ...
        "%s must be a finite real vector.", aliases(1));
end
value = reshape(double(value), 1, []);
end

function value = optionValue(options, aliases, fallback)
value = fallback;
for alias = aliases
    name = char(alias);
    if isfield(options, name)
        value = options.(name);
        return
    end
end
end

function validateNormalizedPoints(X, tolerance)
boundTolerance = max(tolerance, 100 .* eps);
if any(X < -boundTolerance, "all") || ...
        any(X > 1 + boundTolerance, "all")
    error("ctsemo:fitClippedBinaryPof:UnnormalizedInput", ...
        "XNormalized must lie in the normalized unit hypercube [0,1]^D.");
end
end

function [fitX, fitLabels, groupIndex, representativeIndex, groupCounts] = ...
        consolidateDuplicates(X, labels, tolerance)
observationCount = size(X, 1);
fitX = zeros(observationCount, size(X, 2));
fitLabels = false(observationCount, 1);
representativeIndex = zeros(observationCount, 1);
groupIndex = zeros(observationCount, 1);
groupCount = 0;

for observation = 1:observationCount
    if groupCount == 0
        matchingGroup = [];
    else
        maximumDifference = max(abs( ...
            fitX(1:groupCount,:) - X(observation,:)), [], 2);
        matchingGroup = find(maximumDifference <= tolerance, 1, "first");
    end
    if isempty(matchingGroup)
        groupCount = groupCount + 1;
        fitX(groupCount,:) = X(observation,:);
        fitLabels(groupCount) = labels(observation);
        representativeIndex(groupCount) = observation;
        groupIndex(observation) = groupCount;
    else
        if fitLabels(matchingGroup) ~= labels(observation)
            error("ctsemo:fitClippedBinaryPof:ConflictingDuplicateLabels", ...
                "Observations %d and %d coincide within duplicateTolerance " + ...
                "but have conflicting feasibility labels.", ...
                representativeIndex(matchingGroup), observation);
        end
        groupIndex(observation) = matchingGroup;
    end
end

fitX = fitX(1:groupCount,:);
fitLabels = fitLabels(1:groupCount);
representativeIndex = representativeIndex(1:groupCount);
groupCounts = accumarray(groupIndex, 1, [groupCount, 1]);
end

function baseLength = adaptiveBaseLength(X, labels, bounds)
observationCount = size(X, 1);
if observationCount < 2
    baseLength = min(bounds(2), max(bounds(1), 0.25));
    return
end

distance = sqrt(pairwiseSquaredDistance(X, X));
distance(1:observationCount+1:end) = Inf;
nearestSpacing = min(distance, [], 2);
localSpacing = median(nearestSpacing(isfinite(nearestSpacing)));

if any(labels) && any(~labels)
    oppositeDistance = distance;
    oppositeDistance(labels == labels') = Inf;
    nearestOpposite = min(oppositeDistance, [], 2);
    nearestOpposite = nearestOpposite(isfinite(nearestOpposite));
    if isempty(nearestOpposite)
        boundarySpacing = localSpacing;
    else
        boundarySpacing = median(nearestOpposite);
    end
else
    boundarySpacing = localSpacing;
end

baseLength = sqrt(max(eps, localSpacing .* boundarySpacing));
baseLength = min(bounds(2), max(bounds(1), baseLength));
end

function bandwidth = adaptiveDensityBandwidth(X, fallback, localNeighbors)
observationCount = size(X, 1);
if observationCount < 2
    bandwidth = fallback;
    return
end

distance = sqrt(pairwiseSquaredDistance(X, X));
distance(1:observationCount+1:end) = Inf;
if isempty(localNeighbors)
    neighborIndex = max(1, ceil(sqrt(observationCount)));
else
    neighborIndex = localNeighbors;
end
neighborIndex = min(observationCount - 1, neighborIndex);
sortedDistance = sort(distance, 2, "ascend");
kthDistance = sortedDistance(:,neighborIndex);
validDistance = kthDistance(isfinite(kthDistance) & kthDistance > 0);
if isempty(validDistance)
    bandwidth = fallback;
else
    bandwidth = median(validDistance);
end
bandwidth = max(bandwidth, sqrt(eps));
end

function state = makeDensityState(X, labels, bandwidth)
infeasibleX = X(~labels,:);
feasibleX = X(labels,:);
if size(infeasibleX, 1) >= 2
    weights = exp(-0.5 .* pairwiseSquaredDistance(X, infeasibleX) ./ ...
        bandwidth.^2);
    supportSum = sum(weights, 2);
    pairMass = 0.5 .* ...
        (supportSum.^2 - sum(weights.^2, 2));
    positivePairMass = pairMass(pairMass > sqrt(eps));
    if isempty(positivePairMass)
        pairReference = 1;
    else
        pairReference = median(positivePairMass);
    end
else
    pairReference = 1;
end

state = struct( ...
    "infeasibleX", infeasibleX, ...
    "feasibleX", feasibleX, ...
    "bandwidth", bandwidth, ...
    "pairReference", max(pairReference, sqrt(eps)), ...
    "infeasibleCount", size(infeasibleX, 1), ...
    "feasibleCount", size(feasibleX, 1));
end

function support = localInfeasibleSupport(query, state, purityExponent)
queryCount = size(query, 1);
if state.infeasibleCount == 0
    support = zeros(queryCount, 1);
    return
end

infeasibleWeight = exp(-0.5 .* pairwiseSquaredDistance( ...
    query, state.infeasibleX) ./ state.bandwidth.^2);
infeasibleSum = sum(infeasibleWeight, 2);
pairMass = 0.5 .* ...
    (infeasibleSum.^2 - sum(infeasibleWeight.^2, 2));
absoluteSupport = 1 - exp(-max(0, pairMass) ./ state.pairReference);

if state.feasibleCount == 0
    feasibleSum = zeros(queryCount, 1);
else
    feasibleWeight = exp(-0.5 .* pairwiseSquaredDistance( ...
        query, state.feasibleX) ./ state.bandwidth.^2);
    feasibleSum = sum(feasibleWeight, 2);
end

normalizedInfeasible = infeasibleSum ./ max(1, state.infeasibleCount);
normalizedFeasible = feasibleSum ./ max(1, state.feasibleCount);
normalizedDifference = (normalizedInfeasible - normalizedFeasible) ./ ...
    (normalizedInfeasible + normalizedFeasible + eps);
purity = max(0, min(1, normalizedDifference)).^purityExponent;
support = max(0, min(1, absoluteSupport .* purity));
end

function [coefficient, diagnostics] = factorAndSolve( ...
        kernel, centeredTargets, settings)
observationCount = size(kernel, 1);
identity = eye(observationCount);
jitterCandidate = 0;
jitterAttempts = zeros(0, 1);
attemptedAnchorErrors = zeros(0, 1);

while true
    regularizedKernel = kernel + jitterCandidate .* identity;
    jitterAttempts(end + 1, 1) = jitterCandidate; %#ok<AGROW>
    [factor, flag] = chol(regularizedKernel, "lower");
    if flag == 0
        candidateCoefficient = factor' \ (factor \ centeredTargets);
        candidateMean = settings.priorMean + ...
            kernel * candidateCoefficient;
        candidateError = max(abs(candidateMean - ...
            (centeredTargets + settings.priorMean)));
    else
        candidateCoefficient = [];
        candidateError = Inf;
    end
    attemptedAnchorErrors(end + 1, 1) = candidateError; %#ok<AGROW>

    if flag == 0 && all(isfinite(candidateCoefficient)) && ...
            candidateError <= settings.anchorTolerance
        coefficient = candidateCoefficient;
        regularizedReciprocalCondition = rcond(regularizedKernel);
        break
    end

    if jitterCandidate >= settings.maxJitter
        error("ctsemo:fitClippedBinaryPof:FactorizationFailure", ...
            "The local covariance could not meet the interpolation " + ...
            "tolerance before maxJitter was exceeded.");
    end
    if jitterCandidate == 0
        nextJitter = max(settings.jitter, eps);
    else
        nextJitter = 10 .* jitterCandidate;
    end
    jitterCandidate = min(nextJitter, settings.maxJitter);
end

diagnostics = struct( ...
    "jitterUsed", jitterCandidate, ...
    "jitterAttempts", jitterAttempts, ...
    "attemptedAnchorErrors", attemptedAnchorErrors, ...
    "regularizedReciprocalCondition", ...
        regularizedReciprocalCondition);
end

function distanceSquared = pairwiseSquaredDistance(X1, X2)
distanceSquared = sum(X1.^2, 2) + sum(X2.^2, 2)' - 2 .* (X1 * X2');
distanceSquared = max(0, distanceSquared);
end
