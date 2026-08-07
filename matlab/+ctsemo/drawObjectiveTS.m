function draw = drawObjectiveTS(model, options)
%DRAWOBJECTIVETS Draw a serializable approximate objective-GP sample.
%   DRAW = ctsemo.drawObjectiveTS(MODEL,OPTIONS) uses Bradford-style
%   random Fourier features. Matern-3/2 spectral frequencies are sampled
%   from an anisotropically scaled multivariate Student-t distribution
%   with three degrees of freedom. Exact-GP conditioning is applied by
%   Matheron's rule using the model's observation-size Cholesky factor.
%
%   The caller's RNG state is restored before this function returns.

if nargin < 2 || isempty(options)
    options = struct();
end
if ~isstruct(model) || ~isfield(model, 'kind') || ...
        ~strcmp(model.kind, 'ctsemoObjectiveGP-v1')
    error('ctsemo:ObjectiveTS:InvalidModel', ...
        'model must be returned by ctsemo.fitObjectiveGP.');
end
options = localUnwrapOptions(options);

nFeatures = localOption(options, 'nFeatures', model.nFeaturesDefault);
validateattributes(nFeatures, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'integer', 'positive'}, ...
    mfilename, 'nFeatures');
nFeatures = double(nFeatures);

baseSeed = localOption(options, 'baseSeed', model.baseSeed);
objectiveIndex = localOption(options, 'objectiveIndex', 1);
drawIndex = localOption(options, 'drawIndex', 1);
validateattributes(baseSeed, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'integer', 'nonnegative'}, ...
    mfilename, 'baseSeed');
validateattributes(objectiveIndex, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'integer', 'positive'}, ...
    mfilename, 'objectiveIndex');
validateattributes(drawIndex, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'integer', 'positive'}, ...
    mfilename, 'drawIndex');

if isfield(options, 'seed') && ~isempty(options.seed)
    seed = options.seed;
    validateattributes(seed, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'integer', 'positive'}, ...
        mfilename, 'seed');
else
    seed = ctsemo.componentSeed(baseSeed, 'objective-ts', ...
        [objectiveIndex, drawIndex]);
end
rngCleanup = ctsemo.scopedRng(seed); %#ok<NASGU>

dimension = model.dimension;
degreesFreedom = model.spectralDegreesOfFreedom;
unitDesign = localLatinHypercube(nFeatures, dimension + 2);
normalProbabilities = unitDesign(:, 1:dimension);
chiSquaredProbabilities = unitDesign(:, dimension + 1);
normalQuantiles = sqrt(2) .* erfinv(2 .* normalProbabilities - 1);
chiSquaredQuantiles = 2 .* gammaincinv( ...
    chiSquaredProbabilities, degreesFreedom ./ 2, 'lower');
studentScale = sqrt(degreesFreedom ./ chiSquaredQuantiles);
frequencies = normalQuantiles .* studentScale ./ model.lengthScale;
phases = 2 .* pi .* unitDesign(:, dimension + 2);
featureWeights = randn(nFeatures, 1);

trainingFeatures = localFeatureMatrix(model.XNormalized, frequencies, ...
    phases, model.signalStd);
priorAtTraining = trainingFeatures * featureWeights;
noiseAtTraining = model.noiseStd .* ...
    randn(model.observationCount, 1);
conditioningResidual = model.yStandardized - priorAtTraining - ...
    noiseAtTraining;
correctionWeights = model.cholLower' \ ...
    (model.cholLower \ conditioningResidual);

draw = struct();
draw.kind = 'ctsemoObjectiveTSDraw-v1';
draw.kernel = model.kernel;
draw.dimension = dimension;
draw.inputIsNormalized = model.inputIsNormalized;
draw.inputLowerBound = model.inputLowerBound;
draw.inputRange = model.inputRange;
draw.outputMean = model.outputMean;
draw.outputScale = model.outputScale;
draw.XNormalized = model.XNormalized;
draw.lengthScale = model.lengthScale;
draw.signalStd = model.signalStd;
draw.noiseStd = model.noiseStd;
draw.nFeatures = nFeatures;
draw.spectralDegreesOfFreedom = degreesFreedom;
draw.frequencies = frequencies;
draw.phases = phases;
draw.featureWeights = featureWeights;
draw.correctionWeights = correctionWeights;
draw.seed = double(seed);
draw.objectiveIndex = double(objectiveIndex);
draw.drawIndex = double(drawIndex);
end

function options = localUnwrapOptions(options)
if ~isstruct(options) || ~isscalar(options)
    error('ctsemo:ObjectiveTS:InvalidOptions', ...
        'Options must be a scalar structure.');
end
if isfield(options, 'objectiveGP')
    nested = options.objectiveGP;
    if ~isstruct(nested) || ~isscalar(nested)
        error('ctsemo:ObjectiveTS:InvalidOptions', ...
            'options.objectiveGP must be a scalar structure.');
    end
    transferableFields = {'baseSeed', 'objectiveIndex', 'drawIndex'};
    for fieldIndex = 1:numel(transferableFields)
        fieldName = transferableFields{fieldIndex};
        if ~isfield(nested, fieldName) && isfield(options, fieldName)
            nested.(fieldName) = options.(fieldName);
        end
    end
    options = nested;
end
end

function design = localLatinHypercube(pointCount, dimension)
design = zeros(pointCount, dimension);
for dimensionIndex = 1:dimension
    strata = randperm(pointCount).';
    design(:, dimensionIndex) = ...
        (strata - rand(pointCount, 1)) ./ pointCount;
end
probabilityTolerance = sqrt(eps);
design = min(max(design, probabilityTolerance), ...
    1 - probabilityTolerance);
end

function features = localFeatureMatrix(X, frequencies, phases, signalStd)
features = sqrt(2 .* signalStd.^2 ./ size(frequencies, 1)) .* ...
    cos(X * frequencies.' + phases.');
end

function value = localOption(options, fieldName, defaultValue)
if isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end
