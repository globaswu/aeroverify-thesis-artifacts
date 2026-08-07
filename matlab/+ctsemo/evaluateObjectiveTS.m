function sampleValue = evaluateObjectiveTS(draw, XQuery)
%EVALUATEOBJECTIVETS Evaluate a stored objective Thompson sample.
%   SAMPLEVALUE = ctsemo.evaluateObjectiveTS(DRAW,XQUERY) returns the
%   sampled objective in its original physical units.

if ~isstruct(draw) || ~isfield(draw, 'kind') || ...
        ~strcmp(draw.kind, 'ctsemoObjectiveTSDraw-v1')
    error('ctsemo:ObjectiveTS:InvalidDraw', ...
        'draw must be returned by ctsemo.drawObjectiveTS.');
end
validateattributes(XQuery, {'numeric'}, ...
    {'2d', 'real', 'finite'}, mfilename, 'XQuery');
if size(XQuery, 2) ~= draw.dimension
    error('ctsemo:ObjectiveTS:QueryDimension', ...
        'XQuery has the wrong number of input dimensions.');
end
if isempty(XQuery)
    sampleValue = zeros(0, 1);
    return
end

XNormalized = localNormalizeQuery(draw, XQuery);
features = sqrt(2 .* draw.signalStd.^2 ./ draw.nFeatures) .* ...
    cos(XNormalized * draw.frequencies.' + draw.phases.');
priorSample = features * draw.featureWeights;
crossCovariance = localMatern32(XNormalized, draw.XNormalized, ...
    draw.lengthScale, draw.signalStd);
sampleStandardized = priorSample + ...
    crossCovariance * draw.correctionWeights;
sampleValue = draw.outputMean + draw.outputScale .* sampleStandardized;
end

function XNormalized = localNormalizeQuery(draw, XQuery)
if draw.inputIsNormalized
    XNormalized = double(XQuery);
else
    XNormalized = (double(XQuery) - draw.inputLowerBound) ./ ...
        draw.inputRange;
end
tolerance = 1e-9;
if any(XNormalized(:) < -tolerance) || any(XNormalized(:) > 1 + tolerance)
    error('ctsemo:ObjectiveTS:QueryOutsideUnitCube', ...
        'Objective TS query points must lie inside the fitted bounds.');
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
