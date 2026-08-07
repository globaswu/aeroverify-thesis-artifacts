function [pof, rawMean, diagnostics] = predictClippedBinaryPof( ...
        model, XNormalized)
%PREDICTCLIPPEDBINARYPOF Evaluate a clipped binary-feasibility GP mean.
%   POF = ctsemo.predictClippedBinaryPof(MODEL,X) evaluates the raw exact
%   GP interpolant stored in MODEL and clips the result to [0,1].
%
%   [POF,RAWMEAN,DIAGNOSTICS] also returns the unbounded interpolant and
%   local-length diagnostics. Exact stored anchors are snapped to their raw
%   targets after evaluation; the unsnapped numerical error is retained in
%   the fitted model diagnostics.

arguments
    model (1,1) struct
    XNormalized (:,:) double {mustBeReal, mustBeFinite}
end

requiredFields = ["construction", "dimension", "X", "rawTargets", ...
    "anchorX", "anchorTargets", "priorMean", "baseLength", ...
    "localStrength", "maxLengthScaleMultiplier", ...
    "purityExponent", "densityState", ...
    "trainingLength", "coefficient", "duplicateTolerance"];
if ~all(isfield(model, requiredFields)) || ...
        string(model.construction) ~= ...
        "exact_clipped_local_binary_gp_mean"
    error("ctsemo:predictClippedBinaryPof:InvalidModel", ...
        "model must be returned by ctsemo.fitClippedBinaryPof.");
end

if isvector(XNormalized) && numel(XNormalized) == model.dimension
    XNormalized = reshape(XNormalized, 1, model.dimension);
end
if size(XNormalized, 2) ~= model.dimension
    error("ctsemo:predictClippedBinaryPof:DimensionMismatch", ...
        "XNormalized must have %d columns.", model.dimension);
end
validateNormalizedPoints(XNormalized, model.duplicateTolerance);

querySupport = localInfeasibleSupport( ...
    XNormalized, model.densityState, model.purityExponent);
queryMultiplier = min(model.maxLengthScaleMultiplier, ...
    1 + model.localStrength .* querySupport);
queryLength = model.baseLength .* queryMultiplier;
crossCovariance = ctsemo.localMatern32( ...
    model.X, model.trainingLength, XNormalized, queryLength);
rawMeanBeforeSnap = model.priorMean + ...
    crossCovariance' * model.coefficient;
rawMean = rawMeanBeforeSnap;

[isAnchor, anchorIndex] = ismember(XNormalized, model.anchorX, "rows");
rawMean(isAnchor) = model.anchorTargets(anchorIndex(isAnchor));
pof = min(1, max(0, rawMean));

diagnostics = struct( ...
    "queryCount", size(XNormalized, 1), ...
    "localSupport", querySupport, ...
    "localLength", queryLength, ...
    "anchorMask", isAnchor, ...
    "rawMeanBeforeAnchorSnap", rawMeanBeforeSnap, ...
    "anchorSnapCount", nnz(isAnchor), ...
    "clippedLowCount", nnz(rawMean < 0), ...
    "clippedHighCount", nnz(rawMean > 1));
end

function validateNormalizedPoints(X, tolerance)
boundTolerance = max(tolerance, 100 .* eps);
if any(X < -boundTolerance, "all") || ...
        any(X > 1 + boundTolerance, "all")
    error("ctsemo:predictClippedBinaryPof:UnnormalizedInput", ...
        "XNormalized must lie in the normalized unit hypercube [0,1]^D.");
end
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

function distanceSquared = pairwiseSquaredDistance(X1, X2)
distanceSquared = sum(X1.^2, 2) + sum(X2.^2, 2)' - 2 .* (X1 * X2');
distanceSquared = max(0, distanceSquared);
end
