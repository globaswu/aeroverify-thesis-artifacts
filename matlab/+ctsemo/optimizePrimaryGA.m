function [xBest, bestScore, diagnostics] = optimizePrimaryGA( ...
        scoreFunction, seedPoints, seedScores, options, iteration)
%OPTIMIZEPRIMARYGA Maximize the primary acquisition with bounded GA.
%   [XBEST, BESTSCORE, DIAGNOSTICS] = ctsemo.optimizePrimaryGA(...)
%   uses the finite primary LHS/corner pool as the initial GA population.
%   The score function must accept an N-by-D matrix in the normalized unit
%   box and return one acquisition value per row. The caller's RNG state is
%   restored when this function returns.

    arguments
        scoreFunction (1,1) function_handle
        seedPoints double
        seedScores double
        options (1,1) struct
        iteration (1,1) double {mustBeInteger, mustBePositive}
    end

    options = cTSEMOOptions(options);
    validateSeedData(seedPoints, seedScores);
    seedScores = sanitizeScores(seedScores, size(seedPoints, 1));
    [seedBestScore, seedBestIndex] = max(seedScores);
    seedBestPoint = seedPoints(seedBestIndex, :);

    search = options.primarySearch;
    diagnostics = baseDiagnostics(search, size(seedPoints, 1), ...
        seedBestScore, iteration);

    if search.method == "pool"
        xBest = seedBestPoint;
        bestScore = seedBestScore;
        diagnostics.status = "pool";
        diagnostics.reason = "primary_pool_requested";
        diagnostics.initialPopulationCount = 0;
        return
    end

    if isempty(which("ga")) || ~license("test", "GADS_Toolbox")
        [xBest, bestScore, diagnostics] = handleFailure( ...
            seedBestPoint, seedBestScore, diagnostics, search, ...
            "cTSEMO:PrimaryGA:Unavailable", ...
            "The primary GA requires Global Optimization Toolbox.");
        return
    end

    [~, ranking] = sort(seedScores, "descend");
    initialCount = min(search.populationSize, numel(ranking));
    initialPopulation = seedPoints(ranking(1:initialCount), :);
    diagnostics.initialPopulationCount = initialCount;
    diagnostics.seed = ctsemo.componentSeed( ...
        options.seed, "primary-ga", iteration);

    gaOptions = optimoptions("ga", ...
        "PopulationSize", search.populationSize, ...
        "EliteCount", search.eliteCount, ...
        "MaxGenerations", search.maxGenerations, ...
        "MaxStallGenerations", search.maxStallGenerations, ...
        "FunctionTolerance", search.functionTolerance, ...
        "InitialPopulationMatrix", initialPopulation, ...
        "UseParallel", search.useParallel, ...
        "UseVectorized", true, ...
        "Display", "off");

    dimension = size(seedPoints, 2);
    lowerBound = zeros(1, dimension);
    upperBound = ones(1, dimension);
    rngCleanup = ctsemo.scopedRng(diagnostics.seed); %#ok<NASGU>

    try
        [xGa, ~, exitFlag, output] = ga( ...
            @(X) negativeScore(scoreFunction, X), dimension, ...
            [], [], [], [], lowerBound, upperBound, [], gaOptions);
        xGa = min(1, max(0, reshape(double(xGa), 1, [])));
        gaScore = sanitizeScores(scoreFunction(xGa), 1);

        % The best primary proposal may never be worse than the best point
        % supplied to GA, even if GA terminates unusually early.
        if gaScore >= seedBestScore
            xBest = xGa;
            bestScore = gaScore;
            diagnostics.returnedSeedBest = false;
        else
            xBest = seedBestPoint;
            bestScore = seedBestScore;
            diagnostics.returnedSeedBest = true;
        end

        diagnostics.status = "completed";
        diagnostics.reason = "ok";
        diagnostics.exitFlag = exitFlag;
        diagnostics.generations = numericOutput(output, "generations");
        diagnostics.functionCount = numericOutput(output, "funccount");
        diagnostics.message = textOutput(output, "message");
        diagnostics.bestScore = bestScore;
        diagnostics.improvementOverSeed = bestScore - seedBestScore;
    catch exception
        [xBest, bestScore, diagnostics] = handleFailure( ...
            seedBestPoint, seedBestScore, diagnostics, search, ...
            "cTSEMO:PrimaryGA:Failure", ...
            "Primary GA failed: " + string(exception.message), exception);
    end
end

function validateSeedData(seedPoints, seedScores)
    if ~(ismatrix(seedPoints) && ~isempty(seedPoints) && ...
            all(isfinite(seedPoints), "all") && ...
            all(seedPoints >= 0 & seedPoints <= 1, "all"))
        error("cTSEMO:PrimaryGA:InvalidSeeds", ...
            "seedPoints must be a finite, nonempty matrix in [0,1].");
    end
    if ~(isnumeric(seedScores) && isvector(seedScores) && ...
            numel(seedScores) == size(seedPoints, 1))
        error("cTSEMO:PrimaryGA:InvalidSeedScores", ...
            "seedScores must contain one value per seed point.");
    end
end

function score = sanitizeScores(score, expectedCount)
    if ~(isnumeric(score) || islogical(score))
        error("cTSEMO:PrimaryGA:InvalidScore", ...
            "The primary score function must return numeric values.");
    end
    score = reshape(double(score), [], 1);
    if numel(score) ~= expectedCount
        error("cTSEMO:PrimaryGA:ScoreCountMismatch", ...
            "The primary score function must return one value per row.");
    end
    score(~isfinite(score)) = 0;
    score = max(0, score);
end

function fitness = negativeScore(scoreFunction, X)
    score = sanitizeScores(scoreFunction(X), size(X, 1));
    fitness = -score;
end

function diagnostics = baseDiagnostics(search, seedCount, seedBest, iteration)
    diagnostics = struct( ...
        "method", search.method, ...
        "status", "notRun", ...
        "reason", "", ...
        "iteration", iteration, ...
        "seed", NaN, ...
        "seedCandidateCount", seedCount, ...
        "seedBestScore", seedBest, ...
        "initialPopulationCount", 0, ...
        "populationSize", search.populationSize, ...
        "eliteCount", search.eliteCount, ...
        "maxGenerations", search.maxGenerations, ...
        "maxStallGenerations", search.maxStallGenerations, ...
        "functionTolerance", search.functionTolerance, ...
        "useParallel", search.useParallel, ...
        "exitFlag", NaN, ...
        "generations", NaN, ...
        "functionCount", NaN, ...
        "message", "", ...
        "bestScore", seedBest, ...
        "improvementOverSeed", 0, ...
        "returnedSeedBest", true, ...
        "failurePolicy", search.failurePolicy);
end

function [xBest, bestScore, diagnostics] = handleFailure( ...
        seedBestPoint, seedBestScore, diagnostics, search, ...
        identifier, message, cause)
    if nargin < 8
        cause = [];
    end
    if search.failurePolicy == "pool"
        xBest = seedBestPoint;
        bestScore = seedBestScore;
        diagnostics.status = "poolFallback";
        diagnostics.reason = string(identifier);
        diagnostics.message = string(message);
        return
    end

    exception = MException(identifier, "%s", message);
    if ~isempty(cause)
        exception = addCause(exception, cause);
    end
    throw(exception)
end

function value = numericOutput(output, name)
    value = NaN;
    if isstruct(output) && isfield(output, name) && ...
            isnumeric(output.(name)) && isscalar(output.(name))
        value = double(output.(name));
    end
end

function value = textOutput(output, name)
    value = "";
    if isstruct(output) && isfield(output, name)
        value = string(output.(name));
    end
end
