function model = fitObjectiveGP(X, y, options)
%FITOBJECTIVEGP Fit an exact anisotropic Matern-3/2 objective GP.
%   MODEL = ctsemo.fitObjectiveGP(X,Y,OPTIONS) fits a zero-mean GP after
%   optional output standardization. X is expected in the unit hypercube
%   unless OPTIONS.inputLowerBound and OPTIONS.inputUpperBound are given.
%
%   Canonical OPTIONS.objectiveGP fields are:
%       kernel          - must be 'matern32'
%       nFeatures       - default feature count for Thompson draws
%       jitter          - initial numerical diagonal regularizer
%       standardizeY    - standardize the objective before fitting
%       noiseLower      - lower bound on the observation noise std.
%       noiseUpper      - upper bound on the observation noise std.
%
%   The returned structure contains only serializable MATLAB values.

if nargin < 3 || isempty(options)
    options = struct();
end
options = localUnwrapOptions(options);

validateattributes(X, {'numeric'}, {'2d', 'real', 'finite', 'nonempty'}, ...
    mfilename, 'X');
validateattributes(y, {'numeric'}, {'column', 'real', 'finite', 'nonempty'}, ...
    mfilename, 'y');
if size(X, 1) ~= size(y, 1)
    error('ctsemo:ObjectiveGP:SizeMismatch', ...
        'X and y must contain the same number of observations.');
end

kernelName = lower(char(localOption(options, 'kernel', 'matern32')));
if ~strcmp(kernelName, 'matern32')
    error('ctsemo:ObjectiveGP:UnsupportedKernel', ...
        'Only the anisotropic Matern-3/2 kernel is supported.');
end

[XNormalized, inputTransform] = localPrepareInputs(X, options);
[yStandardized, outputTransform] = localPrepareOutput(y, options);
[observationCount, dimension] = size(XNormalized);

settings.nFeatures = localPositiveInteger(options, 'nFeatures', 512);
settings.jitter = localPositiveScalar(options, 'jitter', 1e-10);
settings.noiseLower = localPositiveScalar(options, 'noiseLower', 1e-8);
settings.noiseUpper = localPositiveScalar(options, 'noiseUpper', 0.25);
if settings.noiseUpper < settings.noiseLower
    error('ctsemo:ObjectiveGP:NoiseBounds', ...
        'objectiveGP.noiseUpper must be at least noiseLower.');
end
settings.lengthScaleLower = localBoundVector( ...
    localOption(options, 'lengthScaleLower', 0.02), dimension, ...
    'lengthScaleLower');
settings.lengthScaleUpper = localBoundVector( ...
    localOption(options, 'lengthScaleUpper', 5), dimension, ...
    'lengthScaleUpper');
if any(settings.lengthScaleUpper <= settings.lengthScaleLower)
    error('ctsemo:ObjectiveGP:LengthScaleBounds', ...
        'Every upper length-scale bound must exceed its lower bound.');
end
settings.signalLower = localPositiveScalar(options, 'signalLower', 1e-4);
settings.signalUpper = localPositiveScalar(options, 'signalUpper', 10);
if settings.signalUpper <= settings.signalLower
    error('ctsemo:ObjectiveGP:SignalBounds', ...
        'signalUpper must exceed signalLower.');
end
settings.optimize = localLogical(options, 'optimizeHyperparameters', true);
settings.maxIterations = localPositiveInteger(options, ...
    'maxHyperparameterIterations', 120);
settings.maxFunctionEvaluations = localPositiveInteger(options, ...
    'maxHyperparameterEvaluations', 500);
settings.numberOfStarts = localPositiveInteger(options, ...
    'nHyperparameterStarts', 2);
settings.baseSeed = localNonnegativeInteger(options, 'baseSeed', 1);

initialLengthScale = localInitialLengthScale(XNormalized, ...
    settings.lengthScaleLower, settings.lengthScaleUpper);
initialSignal = min(max(std(yStandardized, 0), ...
    settings.signalLower), settings.signalUpper);
if ~isfinite(initialSignal) || initialSignal <= settings.signalLower
    initialSignal = min(max(1, settings.signalLower), settings.signalUpper);
end
initialNoise = min(max(1e-3, 10 * settings.noiseLower), ...
    settings.noiseUpper);
initialParameters = [initialLengthScale, initialSignal, initialNoise];
lowerBounds = [settings.lengthScaleLower, settings.signalLower, ...
    settings.noiseLower];
upperBounds = [settings.lengthScaleUpper, settings.signalUpper, ...
    settings.noiseUpper];

isConstantObjective = outputTransform.isConstant;
canOptimize = settings.optimize && observationCount >= 2 && ...
    ~isConstantObjective;
fitInfo = struct('attempted', canOptimize, 'converged', false, ...
    'exitFlag', 0, 'negativeLogLikelihood', NaN, ...
    'usedFallback', ~canOptimize, 'startsTried', 0);
parameters = initialParameters;

if canOptimize
    [candidate, candidateValue, optimizationInfo] = ...
        localOptimizeHyperparameters(XNormalized, yStandardized, ...
        initialParameters, lowerBounds, upperBounds, settings);
    fitInfo = optimizationInfo;
    if all(isfinite(candidate)) && isfinite(candidateValue)
        parameters = candidate;
        fitInfo.usedFallback = false;
    end
elseif isConstantObjective
    parameters(dimension + 1) = settings.signalLower;
    parameters(dimension + 2) = settings.noiseLower;
end

lengthScale = parameters(1:dimension);
signalStd = parameters(dimension + 1);
noiseStd = parameters(dimension + 2);
latentKernel = localMatern32(XNormalized, XNormalized, ...
    lengthScale, signalStd);
[cholLower, actualJitter] = localSafeCholesky( ...
    latentKernel + noiseStd.^2 .* eye(observationCount), settings.jitter);
alpha = cholLower' \ (cholLower \ yStandardized);

if ~isfinite(fitInfo.negativeLogLikelihood)
    fitInfo.negativeLogLikelihood = localNegativeLogLikelihood( ...
        parameters, XNormalized, yStandardized, settings.jitter);
end

model = struct();
model.kind = 'ctsemoObjectiveGP-v1';
model.kernel = kernelName;
model.dimension = dimension;
model.observationCount = observationCount;
model.XNormalized = XNormalized;
model.yStandardized = yStandardized;
model.inputIsNormalized = inputTransform.inputIsNormalized;
model.inputLowerBound = inputTransform.lowerBound;
model.inputRange = inputTransform.range;
model.outputMean = outputTransform.mean;
model.outputScale = outputTransform.scale;
model.standardizeY = outputTransform.standardize;
model.isConstantObjective = isConstantObjective;
model.lengthScale = lengthScale;
model.signalStd = signalStd;
model.noiseStd = noiseStd;
model.jitter = actualJitter;
model.cholLower = cholLower;
model.alpha = alpha;
model.nFeaturesDefault = settings.nFeatures;
model.spectralDegreesOfFreedom = 3;
model.baseSeed = settings.baseSeed;
model.fitInfo = fitInfo;
end

function options = localUnwrapOptions(options)
if ~isstruct(options) || ~isscalar(options)
    error('ctsemo:ObjectiveGP:InvalidOptions', ...
        'Options must be a scalar structure.');
end
if isfield(options, 'objectiveGP')
    nested = options.objectiveGP;
    if ~isstruct(nested) || ~isscalar(nested)
        error('ctsemo:ObjectiveGP:InvalidOptions', ...
            'options.objectiveGP must be a scalar structure.');
    end
    topLevelFields = {'inputLowerBound', 'inputUpperBound', 'baseSeed'};
    for fieldIndex = 1:numel(topLevelFields)
        fieldName = topLevelFields{fieldIndex};
        if ~isfield(nested, fieldName) && isfield(options, fieldName)
            nested.(fieldName) = options.(fieldName);
        end
    end
    options = nested;
end
end

function [XNormalized, transform] = localPrepareInputs(X, options)
hasLower = isfield(options, 'inputLowerBound') && ...
    ~isempty(options.inputLowerBound);
hasUpper = isfield(options, 'inputUpperBound') && ...
    ~isempty(options.inputUpperBound);
if xor(hasLower, hasUpper)
    error('ctsemo:ObjectiveGP:IncompleteInputBounds', ...
        'Supply both inputLowerBound and inputUpperBound, or neither.');
end

dimension = size(X, 2);
if hasLower
    lowerBound = reshape(double(options.inputLowerBound), 1, []);
    upperBound = reshape(double(options.inputUpperBound), 1, []);
    if numel(lowerBound) ~= dimension || numel(upperBound) ~= dimension
        error('ctsemo:ObjectiveGP:InputBoundsSize', ...
            'Input bounds must have one element per input dimension.');
    end
    inputRange = upperBound - lowerBound;
    if any(~isfinite(lowerBound)) || any(~isfinite(upperBound)) || ...
            any(inputRange <= 0)
        error('ctsemo:ObjectiveGP:InputBoundsValue', ...
            'Input bounds must be finite and strictly ordered.');
    end
    XNormalized = (double(X) - lowerBound) ./ inputRange;
    inputIsNormalized = false;
else
    XNormalized = double(X);
    lowerBound = zeros(1, dimension);
    inputRange = ones(1, dimension);
    inputIsNormalized = true;
end

tolerance = 1e-10;
if any(XNormalized(:) < -tolerance) || any(XNormalized(:) > 1 + tolerance)
    error('ctsemo:ObjectiveGP:InputOutsideUnitCube', ...
        ['Normalized objective-GP inputs must lie in [0,1]. ', ...
         'Supply physical input bounds when passing unscaled inputs.']);
end
XNormalized = min(max(XNormalized, 0), 1);
transform = struct('inputIsNormalized', inputIsNormalized, ...
    'lowerBound', lowerBound, 'range', inputRange);
end

function [yStandardized, transform] = localPrepareOutput(y, options)
standardize = localLogical(options, 'standardizeY', true);
y = double(y);
dataMagnitude = max(1, max(abs(y)));
constantTolerance = sqrt(eps) * dataMagnitude;
isConstant = (max(y) - min(y)) <= constantTolerance;

if standardize
    outputMean = mean(y);
    outputScale = std(y, 0);
    if ~isfinite(outputScale) || outputScale <= constantTolerance
        outputScale = 1;
    end
else
    outputMean = 0;
    outputScale = 1;
end
yStandardized = (y - outputMean) ./ outputScale;
transform = struct('mean', outputMean, 'scale', outputScale, ...
    'standardize', standardize, 'isConstant', isConstant);
end

function [bestParameters, bestValue, info] = localOptimizeHyperparameters( ...
        X, y, initialParameters, lowerBounds, upperBounds, settings)
startParameters = localStartPoints(initialParameters, lowerBounds, ...
    upperBounds, settings.numberOfStarts);
optimizerOptions = optimset('Display', 'off', ...
    'MaxIter', settings.maxIterations, ...
    'MaxFunEvals', settings.maxFunctionEvaluations, ...
    'TolX', 1e-4, 'TolFun', 1e-5);

bestParameters = initialParameters;
bestValue = Inf;
bestExitFlag = 0;
for startIndex = 1:size(startParameters, 1)
    transformedStart = localToUnbounded(startParameters(startIndex, :), ...
        lowerBounds, upperBounds);
    objective = @(z) localNegativeLogLikelihood( ...
        localFromUnbounded(z, lowerBounds, upperBounds), ...
        X, y, settings.jitter);
    try
        [zCandidate, value, exitFlag] = fminsearch( ...
            objective, transformedStart, optimizerOptions);
        candidate = localFromUnbounded(zCandidate, ...
            lowerBounds, upperBounds);
    catch
        candidate = startParameters(startIndex, :);
        value = localNegativeLogLikelihood(candidate, X, y, ...
            settings.jitter);
        exitFlag = -1;
    end
    if isfinite(value) && value < bestValue
        bestParameters = candidate;
        bestValue = value;
        bestExitFlag = exitFlag;
    end
end

info = struct('attempted', true, 'converged', bestExitFlag > 0, ...
    'exitFlag', bestExitFlag, 'negativeLogLikelihood', bestValue, ...
    'usedFallback', ~isfinite(bestValue), ...
    'startsTried', size(startParameters, 1));
end

function starts = localStartPoints(initial, lowerBounds, upperBounds, count)
starts = zeros(count, numel(initial));
starts(1, :) = initial;
if count >= 2
    starts(2, :) = sqrt(lowerBounds .* upperBounds);
end
for startIndex = 3:count
    fraction = (startIndex - 1) / count;
    starts(startIndex, :) = exp(log(lowerBounds) + ...
        fraction .* (log(upperBounds) - log(lowerBounds)));
end
end

function value = localNegativeLogLikelihood(parameters, X, y, jitter)
dimension = size(X, 2);
lengthScale = parameters(1:dimension);
signalStd = parameters(dimension + 1);
noiseStd = parameters(dimension + 2);

try
    covariance = localMatern32(X, X, lengthScale, signalStd) + ...
        noiseStd.^2 .* eye(size(X, 1));
    cholLower = localSafeCholesky(covariance, jitter);
    alpha = cholLower' \ (cholLower \ y);
    value = 0.5 .* (y' * alpha) + sum(log(diag(cholLower))) + ...
        0.5 .* size(X, 1) .* log(2 .* pi);
    if ~isfinite(value)
        value = realmax('double');
    end
catch
    value = realmax('double');
end
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

function [cholLower, actualJitter] = localSafeCholesky(covariance, jitter)
covariance = (covariance + covariance.') ./ 2;
actualJitter = max(jitter, eps(class(covariance)));
for attempt = 1:10
    [cholLower, status] = chol( ...
        covariance + actualJitter .* eye(size(covariance)), 'lower');
    if status == 0
        return
    end
    actualJitter = 10 .* actualJitter;
end
error('ctsemo:ObjectiveGP:CholeskyFailure', ...
    'The objective-GP covariance matrix is not positive definite.');
end

function initial = localInitialLengthScale(X, lowerBounds, upperBounds)
dimension = size(X, 2);
initial = zeros(1, dimension);
for dimensionIndex = 1:dimension
    differences = abs(X(:, dimensionIndex) - X(:, dimensionIndex).');
    upperValues = differences(triu(true(size(differences)), 1));
    positiveValues = upperValues(upperValues > sqrt(eps));
    if isempty(positiveValues)
        estimate = 0.5;
    else
        estimate = median(positiveValues);
    end
    initial(dimensionIndex) = min(max(estimate, ...
        lowerBounds(dimensionIndex)), upperBounds(dimensionIndex));
end
end

function bounded = localFromUnbounded(unbounded, lowerBounds, upperBounds)
logistic = 1 ./ (1 + exp(-max(min(unbounded, 40), -40)));
bounded = lowerBounds + (upperBounds - lowerBounds) .* logistic;
end

function unbounded = localToUnbounded(bounded, lowerBounds, upperBounds)
fraction = (bounded - lowerBounds) ./ (upperBounds - lowerBounds);
fraction = min(max(fraction, 1e-12), 1 - 1e-12);
unbounded = log(fraction ./ (1 - fraction));
end

function value = localOption(options, fieldName, defaultValue)
if isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end

function value = localPositiveScalar(options, fieldName, defaultValue)
value = localOption(options, fieldName, defaultValue);
validateattributes(value, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'positive'}, mfilename, fieldName);
value = double(value);
end

function value = localPositiveInteger(options, fieldName, defaultValue)
value = localOption(options, fieldName, defaultValue);
validateattributes(value, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'integer', 'positive'}, ...
    mfilename, fieldName);
value = double(value);
end

function value = localNonnegativeInteger(options, fieldName, defaultValue)
value = localOption(options, fieldName, defaultValue);
validateattributes(value, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'integer', 'nonnegative'}, ...
    mfilename, fieldName);
value = double(value);
end

function value = localLogical(options, fieldName, defaultValue)
value = localOption(options, fieldName, defaultValue);
if ~(islogical(value) && isscalar(value)) && ...
        ~(isnumeric(value) && isscalar(value) && any(value == [0, 1]))
    error('ctsemo:ObjectiveGP:LogicalOption', ...
        '%s must be a scalar logical value.', fieldName);
end
value = logical(value);
end

function value = localBoundVector(value, dimension, fieldName)
validateattributes(value, {'numeric'}, ...
    {'vector', 'real', 'finite', 'positive'}, mfilename, fieldName);
if isscalar(value)
    value = repmat(double(value), 1, dimension);
else
    value = reshape(double(value), 1, []);
end
if numel(value) ~= dimension
    error('ctsemo:ObjectiveGP:BoundSize', ...
        '%s must be scalar or have one element per dimension.', fieldName);
end
end
