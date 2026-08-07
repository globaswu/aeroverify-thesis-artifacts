function [meanPrediction, variancePrediction] = predictObjectiveGP(model, XQuery)
%PREDICTOBJECTIVEGP Evaluate the latent exact-GP posterior.
%   [MEANPREDICTION,VARIANCEPREDICTION] =
%   ctsemo.predictObjectiveGP(MODEL,XQUERY) returns values in the original
%   objective units. Observation noise is not included in the variance.

if ~isstruct(model) || ~isfield(model, 'kind') || ...
        ~strcmp(model.kind, 'ctsemoObjectiveGP-v1')
    error('ctsemo:ObjectiveGP:InvalidModel', ...
        'model must be returned by ctsemo.fitObjectiveGP.');
end
validateattributes(XQuery, {'numeric'}, ...
    {'2d', 'real', 'finite'}, mfilename, 'XQuery');
if size(XQuery, 2) ~= model.dimension
    error('ctsemo:ObjectiveGP:QueryDimension', ...
        'XQuery has the wrong number of input dimensions.');
end
if isempty(XQuery)
    meanPrediction = zeros(0, 1);
    variancePrediction = zeros(0, 1);
    return
end

XNormalized = localNormalizeQuery(model, XQuery);
crossCovariance = localMatern32(XNormalized, model.XNormalized, ...
    model.lengthScale, model.signalStd);
meanStandardized = crossCovariance * model.alpha;
projected = model.cholLower \ crossCovariance.';
varianceStandardized = model.signalStd.^2 - ...
    sum(projected.^2, 1).';
varianceStandardized = max(varianceStandardized, 0);

meanPrediction = model.outputMean + ...
    model.outputScale .* meanStandardized;
variancePrediction = model.outputScale.^2 .* varianceStandardized;
end

function XNormalized = localNormalizeQuery(model, XQuery)
if model.inputIsNormalized
    XNormalized = double(XQuery);
else
    XNormalized = (double(XQuery) - model.inputLowerBound) ./ ...
        model.inputRange;
end
tolerance = 1e-9;
if any(XNormalized(:) < -tolerance) || any(XNormalized(:) > 1 + tolerance)
    error('ctsemo:ObjectiveGP:QueryOutsideUnitCube', ...
        'Objective-GP query points must lie inside the fitted bounds.');
end
XNormalized = min(max(XNormalized, 0), 1);
end

function covariance = localMatern32(X1, X2, lengthScale, signalStd)
scaledX1 = X1 ./ lengthScale;
scaledX2 = X2 ./ lengthScale;
squaredDistance = sum(scaledX1.^2, 2) + ...
    sum(scaledX2.^2, 2).' - 2 .* (scaledX1 * scaledX2.');
squaredDistance = max(squaredDistance, 0);
scaledDistance = sqrt(3 .* squaredDistance);
covariance = signalStd.^2 .* (1 + scaledDistance) .* ...
    exp(-scaledDistance);
end
