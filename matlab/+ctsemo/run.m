function result = run(problem, data, options)
%RUN Execute the lightweight sequential cTSEMO control loop.
%   This package function assumes inputs have been canonicalized by
%   ctsemo.validateInputs. It performs no plotting and does not open
%   interactive MATLAB windows.

    arguments
        problem (1,1) struct
        data (1,1) struct
        options (1,1) struct
    end

    startedAt = datetime("now", "TimeZone", "local");
    [outputDirectory, runId] = configureOutput(options, startedAt);
    data = initializeDataHistory(data);
    result = initializeResult( ...
        problem, data, options, startedAt, outputDirectory, runId);

    if options.logging.checkpoint
        ctsemo.saveCheckpoint(result, outputDirectory, "initialized");
    end

    activeContext = struct("iteration", 0, "stage", "initialization");
    try
        for iteration = 1:options.maxEvaluations
            iterationTimer = tic;
            activeContext = struct( ...
                "iteration", iteration, ...
                "stage", "modelFitting");

            XUnit = normalizeInputs(data.X, ...
                problem.lowerBound, problem.upperBound);
            [pofModel, pofFitDiagnostics, pofFitSeconds] = ...
                fitFeasibilityField(XUnit, data.isFeasible, options);

            candidateTimer = tic;
            [pools, generatorFailed] = makePoolsWithRecovery( ...
                problem, data.X, options, iteration);
            candidateSeconds = toc(candidateTimer);

            hasFeasibleObservation = any(data.isFeasible);
            objectiveModels = cell(1, 2);
            objectiveDraws = cell(1, 2);
            objectiveFitSeconds = 0;
            objectiveDrawSeconds = 0;

            if hasFeasibleObservation
                modelTimer = tic;
                for objectiveIndex = 1:2
                    fitOptions = options.objectiveGP;
                    fitOptions.baseSeed = ctsemo.componentSeed( ...
                        options.seed, "objective-fit", ...
                        [iteration, objectiveIndex]);
                    objectiveModels{objectiveIndex} = ...
                        ctsemo.fitObjectiveGP( ...
                        XUnit, data.Y(:, objectiveIndex), fitOptions);
                end
                objectiveFitSeconds = toc(modelTimer);

                drawTimer = tic;
                for objectiveIndex = 1:2
                    drawOptions = options.objectiveGP;
                    drawOptions.baseSeed = options.seed;
                    drawOptions.objectiveIndex = objectiveIndex;
                    drawOptions.drawIndex = iteration;
                    objectiveDraws{objectiveIndex} = ...
                        ctsemo.drawObjectiveTS( ...
                        objectiveModels{objectiveIndex}, drawOptions);
                end
                objectiveDrawSeconds = toc(drawTimer);
            end

            activeContext.stage = "candidateScoring";
            acquisitionTimer = tic;
            selection = selectNextPoint( ...
                pools, objectiveDraws, pofModel, data, problem, ...
                options, iteration, hasFeasibleObservation, ...
                generatorFailed);
            acquisitionSeconds = toc(acquisitionTimer);
            activeContext.selection = selection.summary;

            activeContext.stage = "objectiveEvaluation";
            evaluationTimer = tic;
            [newY, newConstraintValues, newIsFeasible] = ...
                evaluateExpensivePoint( ...
                problem, selection.selected.X, options, activeContext, ...
                result, outputDirectory);
            evaluationSeconds = toc(evaluationTimer);

            data = appendObservation( ...
                data, selection.selected.X, newY, ...
                newConstraintValues, newIsFeasible, ...
                selection.selectionSource, iteration);
            currentPareto = ctsemo.updatePareto( ...
                data.X, data.Y, data.isFeasible);

            timing = struct( ...
                "objectiveFitSeconds", objectiveFitSeconds, ...
                "objectiveDrawSeconds", objectiveDrawSeconds, ...
                "pofFitSeconds", pofFitSeconds, ...
                "candidateGenerationSeconds", candidateSeconds, ...
                "acquisitionSeconds", acquisitionSeconds, ...
                "expensiveEvaluationSeconds", evaluationSeconds, ...
                "iterationSeconds", toc(iterationTimer));

            record = makeIterationRecord( ...
                iteration, data, selection, newY, ...
                newConstraintValues, newIsFeasible, currentPareto, ...
                objectiveModels, objectiveDraws, pofModel, ...
                pofFitDiagnostics, timing, options);
            result.data = data;
            result.iterations(end + 1, 1) = record;
            result.pareto = currentPareto;
            result.meta.completedEvaluations = iteration;

            writeIterationRecord( ...
                record, outputDirectory, options.logging, iteration);
            if options.logging.checkpoint
                ctsemo.saveCheckpoint( ...
                    result, outputDirectory, "running");
            end
        end

        result = finalizeResult(result, startedAt);
        if strlength(outputDirectory) > 0
            saveFinalResult(result, outputDirectory);
        end
        if options.logging.checkpoint
            ctsemo.saveCheckpoint( ...
                result, outputDirectory, "completed");
        end
    catch exception
        result.meta.status = "failed";
        result.meta.finishedAt = timestamp(datetime("now", ...
            "TimeZone", "local"));
        errorInformation = exceptionRecord(exception, activeContext);
        result.meta.error = errorInformation;
        if options.logging.checkpoint && strlength(outputDirectory) > 0
            try
                ctsemo.saveCheckpoint( ...
                    result, outputDirectory, "failed", errorInformation);
            catch checkpointException
                warning("cTSEMO:Logging:FailureCheckpoint", ...
                    "The run failed and its failure checkpoint also failed: %s", ...
                    checkpointException.message);
            end
        end
        rethrow(exception)
    end
end

function result = initializeResult( ...
        problem, data, options, startedAt, outputDirectory, runId)
    publicProblem = rmfield(problem, ["objective", "constraint"]);
    publicProblem.objectiveFunction = func2str(problem.objective);
    if isempty(problem.constraint)
        publicProblem.constraintFunction = "";
    else
        publicProblem.constraintFunction = func2str(problem.constraint);
    end

    meta = struct();
    meta.algorithm = "cTSEMO";
    meta.version = "0.1.0";
    meta.status = "running";
    meta.runId = runId;
    meta.startedAt = timestamp(startedAt);
    meta.finishedAt = "";
    meta.completedEvaluations = 0;
    meta.matlabRelease = string(version("-release"));
    meta.matlabVersion = string(version);
    meta.outputDirectory = outputDirectory;
    meta.bradfordSourceRevision = ...
        "9ec2aa2f54d1232f80d37494ac067f2ebc112688";
    meta.error = struct();

    result = struct();
    result.meta = meta;
    result.problem = publicProblem;
    result.options = options;
    result.data = data;
    result.iterations = repmat(emptyIterationRecord(), 0, 1);
    result.pareto = ctsemo.updatePareto( ...
        data.X, data.Y, data.isFeasible);
end

function data = initializeDataHistory(data)
    observationCount = size(data.X, 1);
    data.constraintValues = double(data.constraintValues);
    data.selectionSource = repmat("initial", observationCount, 1);
    data.addedIteration = zeros(observationCount, 1);
    data.evaluationIndex = (1:observationCount).';
end

function [outputDirectory, runId] = configureOutput(options, startedAt)
    runId = "ctsemo_" + ...
        string(startedAt, "yyyyMMdd_HHmmss_SSS") + ...
        "_seed" + string(options.seed);
    needsDirectory = options.logging.level ~= "none" || ...
        options.logging.checkpoint || ...
        options.logging.saveEveryIteration;
    if ~needsDirectory
        outputDirectory = "";
        return
    end

    rootDirectory = options.logging.directory;
    if strlength(rootDirectory) == 0
        rootDirectory = string(fullfile(pwd, "ctsemo-output"));
    end
    if ~isfolder(rootDirectory)
        [created, message] = mkdir(rootDirectory);
        if ~created
            error("cTSEMO:Logging:DirectoryCreationFailed", ...
                "Could not create logging directory '%s': %s", ...
                rootDirectory, message);
        end
    end

    outputDirectory = fullfile(rootDirectory, runId);
    suffix = 1;
    while isfolder(outputDirectory)
        outputDirectory = fullfile( ...
            rootDirectory, runId + "_" + string(suffix));
        suffix = suffix + 1;
    end
    [created, message] = mkdir(outputDirectory);
    if ~created
        error("cTSEMO:Logging:DirectoryCreationFailed", ...
            "Could not create run directory '%s': %s", ...
            outputDirectory, message);
    end
end

function [model, diagnostics, elapsedSeconds] = ...
        fitFeasibilityField(XUnit, isFeasible, options)
    timer = tic;
    if all(isFeasible)
        model = struct( ...
            "construction", "constant_all_feasible", ...
            "dimension", size(XUnit, 2), ...
            "rawValue", options.pof.rawFeasible, ...
            "clippedValue", 1);
        diagnostics = struct( ...
            "construction", model.construction, ...
            "observationCount", size(XUnit, 1), ...
            "reason", "No infeasible observation is available.");
    else
        [model, diagnostics] = ctsemo.fitClippedBinaryPof( ...
            XUnit, isFeasible, options);
    end
    elapsedSeconds = toc(timer);
end

function [pof, rawPof, diagnostics] = ...
        predictFeasibilityField(model, XUnit)
    if string(model.construction) == "constant_all_feasible"
        pof = ones(size(XUnit, 1), 1);
        rawPof = repmat(model.rawValue, size(XUnit, 1), 1);
        diagnostics = struct( ...
            "queryCount", size(XUnit, 1), ...
            "construction", model.construction);
    else
        [pof, rawPof, diagnostics] = ...
            ctsemo.predictClippedBinaryPof(model, XUnit);
    end
end

function [pools, generatorFailed] = makePoolsWithRecovery( ...
        problem, evaluatedX, options, iteration)
    generatorFailed = false;
    try
        pools = ctsemo.makeCandidatePools( ...
            problem.lowerBound, problem.upperBound, ...
            options, iteration, evaluatedX);
    catch exception
        if ~startsWith(string(exception.identifier), ...
                "cTSEMO:Candidates:")
            rethrow(exception)
        end
        generatorFailed = true;
        pools = emergencyPool( ...
            problem, evaluatedX, options, iteration);
    end
end

function pools = emergencyPool(problem, evaluatedX, options, iteration)
    dimension = problem.dimension;
    requested = min(4096, max(256, ...
        options.candidates.primaryCount + ...
        options.challengers.count));
    seed = ctsemo.componentSeed( ...
        options.seed, "candidate-recovery", iteration);
    cleanup = ctsemo.scopedRng(seed); %#ok<NASGU>
    evaluatedUnit = normalizeInputs(evaluatedX, ...
        problem.lowerBound, problem.upperBound);
    candidateUnit = zeros(0, dimension);

    for attempt = 1:10
        draw = rand(max(2 .* requested, 512), dimension);
        draw = hardDuplicateFilter( ...
            draw, [evaluatedUnit; candidateUnit], ...
            options.candidates.duplicateTolerance);
        candidateUnit = [candidateUnit; draw]; %#ok<AGROW>
        [~, uniqueIndex] = unique(candidateUnit, "rows", "stable");
        candidateUnit = candidateUnit(sort(uniqueIndex), :);
        if size(candidateUnit, 1) >= requested
            break
        end
    end
    if isempty(candidateUnit)
        error("cTSEMO:Candidates:RecoveryFailed", ...
            "No unevaluated recovery candidate could be generated.");
    end
    candidateUnit = candidateUnit( ...
        1:min(requested, size(candidateUnit, 1)), :);
    candidateX = problem.lowerBound + candidateUnit .* ...
        (problem.upperBound - problem.lowerBound);
    source = repmat("primary", size(candidateX, 1), 1);
    origin = repmat("recovery", size(candidateX, 1), 1);

    pools = struct();
    pools.primary = struct( ...
        "X", candidateX, "XUnit", candidateUnit, ...
        "source", source, "origin", origin);
    pools.challenger = struct( ...
        "X", zeros(0, dimension), ...
        "XUnit", zeros(0, dimension), ...
        "source", strings(0, 1), ...
        "origin", strings(0, 1));
    pools.X = candidateX;
    pools.XUnit = candidateUnit;
    pools.source = source;
    pools.origin = origin;
    pools.seed = struct("primary", seed, "challenger", NaN);
end

function filtered = hardDuplicateFilter(candidate, excluded, tolerance)
    if isempty(excluded)
        filtered = candidate;
        return
    end
    keep = true(size(candidate, 1), 1);
    for row = 1:size(excluded, 1)
        keep = keep & ...
            max(abs(candidate - excluded(row, :)), [], 2) > tolerance;
    end
    filtered = candidate(keep, :);
end

function selection = selectNextPoint( ...
        pools, objectiveDraws, pofModel, data, problem, options, ...
        iteration, hasFeasibleObservation, generatorFailed)
    if hasFeasibleObservation
        primaryYDraw = evaluateDraws(objectiveDraws, pools.primary.XUnit);
        challengerYDraw = evaluateDraws( ...
            objectiveDraws, pools.challenger.XUnit);
        if options.challengers.scoreCompletePools
            primaryKeep = (1:size(pools.primary.X, 1)).';
        else
            if isempty(primaryYDraw)
                primaryKeep = zeros(0, 1);
            else
                [~, primaryKeep] = ctsemo.pareto2d(primaryYDraw);
            end
            if isempty(primaryKeep)
                primaryKeep = (1:size(pools.primary.X, 1)).';
            end
        end
    else
        primaryYDraw = nan(size(pools.primary.X, 1), 2);
        primaryKeep = (1:size(pools.primary.X, 1)).';
        challengerYDraw = nan(size(pools.challenger.X, 1), 2);
    end

    candidate = concatenateCandidates( ...
        pools, primaryYDraw, primaryKeep, challengerYDraw);
    [candidate.pof, candidate.rawPof, candidate.pofDiagnostics] = ...
        predictFeasibilityField(pofModel, candidate.XUnit);
    [standardizedTrainingY, objectiveCenter, objectiveScale] = ...
        standardizeObjectives(data.Y);
    candidate.YDrawStandardized = ...
        (candidate.YDraw - objectiveCenter) ./ objectiveScale;

    primaryRows = find(candidate.source == "primary");
    challengerRows = find(candidate.source == "challenger");
    fallbackReason = "";
    fallbackUsed = false;
    selectionState = "acquisition";
    fallbackPoolRegenerated = false;

    if ~hasFeasibleObservation
        candidate = zeroAcquisitionComponents(candidate);
        invalidMask = hardDuplicateMask( ...
            candidate.XUnit, normalizeInputs(data.X, ...
            problem.lowerBound, problem.upperBound), ...
            options.candidates.duplicateTolerance);
        [selectedIndex, candidate.fallbackScore, fallbackInfo] = ...
            ctsemo.selectFallback( ...
            candidate.XUnit, candidate.pof, ...
            normalizeInputs(data.X, ...
            problem.lowerBound, problem.upperBound), ...
            invalidMask, "no_feasible_front", options);
        fallbackReason = "noFeasibleObservation";
        fallbackUsed = true;
        selectionState = "feasibilityDiscovery";
        acquisitionStatus = struct( ...
            "requiresFallback", true, ...
            "reason", fallbackReason);
        acquisitionReferencePoint = zeros(0, 2);
    else
        feasibleY = standardizedTrainingY(data.isFeasible, :);
        acquisitionReferencePoint = ...
            acquisitionReference(feasibleY);
        [candidate.AF, components, acquisitionStatus] = ...
            ctsemo.scoreCandidates( ...
            candidate.XUnit, candidate.YDrawStandardized, candidate.pof, ...
            feasibleY, acquisitionReferencePoint, ...
            normalizeInputs(data.X, ...
            problem.lowerBound, problem.upperBound), ...
            standardizedTrainingY, options);
        candidate.sampledHVI = components.hvi;
        candidate.epsilon = components.epsilon;
        candidate.designMask = components.designMask;
        candidate.codomainMask = components.codomainMask;
        candidate.invalid = components.invalid;
        candidate.hardDuplicate = components.hardDuplicate;
        candidate.fallbackScore = nan(size(candidate.AF));

        [primaryMaxAF, primaryIndex] = verifiedMaximum( ...
            candidate.AF, primaryRows);
        [challengerMaxAF, challengerIndex] = verifiedMaximum( ...
            candidate.AF, challengerRows);
        verifiedMaxAF = max(primaryMaxAF, challengerMaxAF);

        if generatorFailed
            fallbackUsed = true;
            fallbackReason = "candidateGenerationFailure";
        elseif logical(acquisitionStatus.requiresFallback)
            fallbackUsed = options.fallback.enabled;
            fallbackReason = string(acquisitionStatus.reason);
        elseif ~isfinite(verifiedMaxAF)
            fallbackUsed = true;
            fallbackReason = "nonfiniteAcquisition";
        elseif verifiedMaxAF <= options.fallback.triggerTolerance
            fallbackUsed = options.fallback.enabled;
            fallbackReason = "lowAcquisition";
        end

        if fallbackUsed
            selectionState = "recovery";
            invalidMask = candidate.invalid | ...
                candidate.hardDuplicate;
            [selectedIndex, candidate.fallbackScore, fallbackInfo] = ...
                ctsemo.selectFallback( ...
                candidate.XUnit, candidate.pof, ...
                normalizeInputs(data.X, ...
                problem.lowerBound, problem.upperBound), ...
                invalidMask, fallbackReason, options);
        else
            [~, selectedIndex] = verifiedMaximum( ...
                candidate.AF, (1:size(candidate.X, 1)).');
            if selectedIndex == 0
                error("cTSEMO:Selection:NoFiniteCandidate", ...
                    "No finite, nonduplicate acquisition candidate is available.");
            end
            fallbackInfo = struct();
        end
    end

    if isempty(selectedIndex)
        [candidate, selectedIndex, fallbackInfo] = ...
            regenerateFallbackPool( ...
                objectiveDraws, pofModel, data, problem, options, ...
                iteration, hasFeasibleObservation, ...
                fallbackReason, objectiveCenter, objectiveScale, ...
                acquisitionReferencePoint);
        primaryRows = (1:size(candidate.X, 1)).';
        challengerRows = zeros(0, 1);
        fallbackPoolRegenerated = true;
    end

    if ~hasFeasibleObservation
        [primaryMaxAF, primaryIndex] = verifiedMaximum( ...
            candidate.AF, primaryRows);
        [challengerMaxAF, challengerIndex] = verifiedMaximum( ...
            candidate.AF, challengerRows);
    end

    if isempty(selectedIndex) || selectedIndex < 1 || ...
            selectedIndex > size(candidate.X, 1)
        error("cTSEMO:Selection:InvalidSelection", ...
            "Candidate selection did not return a valid row index.");
    end

    if fallbackUsed
        selectionSource = "fallback";
    else
        selectionSource = candidate.source(selectedIndex);
    end

    selected = selectedCandidate(candidate, selectedIndex);
    selection = struct();
    selection.selectionState = selectionState;
    selection.selectionSource = selectionSource;
    selection.fallbackUsed = fallbackUsed;
    selection.fallbackReason = fallbackReason;
    selection.generatorFailed = generatorFailed;
    selection.fallbackPoolRegenerated = fallbackPoolRegenerated;
    selection.acquisitionReferencePoint = acquisitionReferencePoint;
    selection.objectiveScaling = struct( ...
        "center", objectiveCenter, ...
        "scale", objectiveScale);
    selection.acquisitionStatus = acquisitionStatus;
    selection.primary = candidateMaximumSummary( ...
        candidate, primaryRows, primaryIndex, primaryMaxAF);
    selection.challenger = candidateMaximumSummary( ...
        candidate, challengerRows, challengerIndex, challengerMaxAF);
    selection.selected = selected;
    selection.fallbackInfo = fallbackInfo;
    selection.candidates = candidate;
    selection.summary = struct( ...
        "selectionState", selectionState, ...
        "selectionSource", selectionSource, ...
        "fallbackUsed", fallbackUsed, ...
        "fallbackReason", fallbackReason, ...
        "fallbackPoolRegenerated", fallbackPoolRegenerated, ...
        "selectedX", selected.X);
end

function YDraw = evaluateDraws(draws, XUnit)
    if isempty(XUnit)
        YDraw = zeros(0, 2);
        return
    end
    YDraw = zeros(size(XUnit, 1), 2);
    for objectiveIndex = 1:2
        YDraw(:, objectiveIndex) = ...
            ctsemo.evaluateObjectiveTS(draws{objectiveIndex}, XUnit);
    end
end

function candidate = concatenateCandidates( ...
        pools, primaryYDraw, primaryKeep, challengerYDraw)
    candidate = struct();
    candidate.X = [ ...
        pools.primary.X(primaryKeep, :); ...
        pools.challenger.X];
    candidate.XUnit = [ ...
        pools.primary.XUnit(primaryKeep, :); ...
        pools.challenger.XUnit];
    candidate.source = [ ...
        pools.primary.source(primaryKeep); ...
        pools.challenger.source];
    candidate.origin = [ ...
        pools.primary.origin(primaryKeep); ...
        pools.challenger.origin];
    candidate.YDraw = [ ...
        primaryYDraw(primaryKeep, :); challengerYDraw];
end

function [candidate, selectedIndex, fallbackInfo] = ...
        regenerateFallbackPool( ...
        objectiveDraws, pofModel, data, problem, options, iteration, ...
        hasFeasibleObservation, reason, objectiveCenter, ...
        objectiveScale, referencePoint)
    recoveryPools = emergencyPool( ...
        problem, data.X, options, iteration + 100000);
    candidate = concatenateCandidates( ...
        recoveryPools, ...
        evaluateRecoveryDraws(objectiveDraws, ...
            recoveryPools.primary.XUnit, hasFeasibleObservation), ...
        (1:size(recoveryPools.primary.X, 1)).', zeros(0, 2));
    [candidate.pof, candidate.rawPof, candidate.pofDiagnostics] = ...
        predictFeasibilityField(pofModel, candidate.XUnit);
    candidate.YDrawStandardized = ...
        (candidate.YDraw - objectiveCenter) ./ objectiveScale;
    if hasFeasibleObservation
        standardizedTrainingY = ...
            (data.Y - objectiveCenter) ./ objectiveScale;
        feasibleY = standardizedTrainingY(data.isFeasible, :);
        [candidate.AF, components, acquisitionStatus] = ...
            ctsemo.scoreCandidates( ...
                candidate.XUnit, candidate.YDrawStandardized, ...
                candidate.pof, feasibleY, referencePoint, ...
                normalizeInputs(data.X, problem.lowerBound, ...
                    problem.upperBound), ...
                standardizedTrainingY, options);
        candidate.sampledHVI = components.hvi;
        candidate.epsilon = components.epsilon;
        candidate.designMask = components.designMask;
        candidate.codomainMask = components.codomainMask;
        candidate.invalid = components.invalid;
        candidate.hardDuplicate = components.hardDuplicate;
    else
        candidate = zeroAcquisitionComponents(candidate);
        acquisitionStatus = struct( ...
            "requiresFallback", true, ...
            "reason", "no_feasible_front");
    end

    invalidMask = candidate.invalid | candidate.hardDuplicate;
    fallbackReasonForModule = reason;
    if reason == "noFeasibleObservation"
        fallbackReasonForModule = "no_feasible_front";
    end
    [selectedIndex, candidate.fallbackScore, fallbackInfo] = ...
        ctsemo.selectFallback( ...
            candidate.XUnit, candidate.pof, ...
            normalizeInputs(data.X, problem.lowerBound, ...
                problem.upperBound), ...
            invalidMask, fallbackReasonForModule, options);
    fallbackInfo.regeneratedPool = true;
    fallbackInfo.acquisitionStatus = acquisitionStatus;
    if isempty(selectedIndex)
        error("cTSEMO:Selection:CandidateRegenerationFailed", ...
            ["Fallback requested candidate regeneration, but a fresh " ...
             "deterministic pool still contained no valid point."]);
    end
end

function YDraw = evaluateRecoveryDraws( ...
        objectiveDraws, XUnit, hasFeasibleObservation)
    if hasFeasibleObservation
        YDraw = evaluateDraws(objectiveDraws, XUnit);
    else
        YDraw = nan(size(XUnit, 1), 2);
    end
end

function candidate = zeroAcquisitionComponents(candidate)
    pointCount = size(candidate.X, 1);
    candidate.sampledHVI = zeros(pointCount, 1);
    candidate.epsilon = 0;
    candidate.designMask = ones(pointCount, 1);
    candidate.codomainMask = ones(pointCount, 1);
    candidate.AF = zeros(pointCount, 1);
    candidate.fallbackScore = nan(pointCount, 1);
    candidate.invalid = false(pointCount, 1);
    candidate.hardDuplicate = false(pointCount, 1);
end

function referencePoint = acquisitionReference(feasibleY)
    lower = min(feasibleY, [], 1);
    upper = max(feasibleY, [], 1);
    span = upper - lower;
    referencePoint = upper + max( ...
        0.1 .* span, 0.1 .* max(1, abs(upper)));
end

function duplicate = hardDuplicateMask(candidate, evaluated, tolerance)
    duplicate = false(size(candidate, 1), 1);
    for row = 1:size(evaluated, 1)
        duplicate = duplicate | ...
            max(abs(candidate - evaluated(row, :)), [], 2) <= tolerance;
    end
end

function [maximumValue, maximumIndex] = ...
        verifiedMaximum(values, allowedRows)
    maximumValue = -Inf;
    maximumIndex = 0;
    if isempty(allowedRows)
        return
    end
    allowedValues = values(allowedRows);
    finite = isfinite(allowedValues);
    if ~any(finite)
        return
    end
    finiteRows = allowedRows(finite);
    [maximumValue, localIndex] = max(values(finiteRows));
    maximumIndex = finiteRows(localIndex);
end

function summary = candidateMaximumSummary( ...
        candidate, sourceRows, index, value)
    summary = struct( ...
        "candidateCount", numel(sourceRows), ...
        "index", index, ...
        "X", zeros(0, size(candidate.X, 2)), ...
        "YDraw", zeros(0, 2), ...
        "AF", value);
    if index > 0
        summary.X = candidate.X(index, :);
        summary.YDraw = candidate.YDraw(index, :);
    end
end

function selected = selectedCandidate(candidate, index)
    selected = struct();
    selected.index = index;
    selected.X = candidate.X(index, :);
    selected.XUnit = candidate.XUnit(index, :);
    selected.candidateSource = candidate.source(index);
    selected.origin = candidate.origin(index);
    selected.YDraw = candidate.YDraw(index, :);
    selected.YDrawStandardized = ...
        candidate.YDrawStandardized(index, :);
    selected.pof = candidate.pof(index);
    selected.rawPof = candidate.rawPof(index);
    selected.sampledHVI = candidate.sampledHVI(index);
    selected.designMask = candidate.designMask(index);
    selected.codomainMask = candidate.codomainMask(index);
    selected.AF = candidate.AF(index);
    selected.fallbackScore = candidate.fallbackScore(index);
    selected.invalid = candidate.invalid(index);
    selected.hardDuplicate = candidate.hardDuplicate(index);
end

function [Y, constraintValues, isFeasible] = ...
        evaluateExpensivePoint( ...
        problem, X, options, activeContext, result, outputDirectory)
    try
        Y = problem.objective(X);
    catch exception
        checkpointEvaluationFailure( ...
            exception, activeContext, result, outputDirectory, ...
            "objectiveEvaluation", X, []);
        rethrow(exception)
    end
    if ~(isnumeric(Y) && isreal(Y) && numel(Y) == 2 && ...
            all(isfinite(Y), "all"))
        exception = MException( ...
            "cTSEMO:Evaluation:InvalidObjective", ...
            "The objective must return two finite real values.");
        checkpointEvaluationFailure( ...
            exception, activeContext, result, outputDirectory, ...
            "objectiveEvaluation", X, Y);
        throw(exception)
    end
    Y = reshape(double(Y), 1, 2);

    if problem.isUnconstrained
        constraintValues = zeros(1, 0);
        isFeasible = true;
        return
    end

    try
        constraintOutput = problem.constraint(X);
        [constraintValues, isFeasible] = ...
            canonicalConstraintOutput( ...
            constraintOutput, options.feasibility.inputEncoding);
    catch exception
        checkpointEvaluationFailure( ...
            exception, activeContext, result, outputDirectory, ...
            "constraintEvaluation", X, Y);
        rethrow(exception)
    end
end

function [values, isFeasible] = ...
        canonicalConstraintOutput(output, encoding)
    if ~(islogical(output) || isnumeric(output)) || ...
            isempty(output) || ~isvector(output)
        error("cTSEMO:Evaluation:InvalidConstraint", ...
            "The constraint must return a nonempty numeric or logical vector.");
    end
    values = reshape(double(output), 1, []);
    if islogical(output)
        isFeasible = all(output(:));
        return
    end

    switch string(encoding)
        case "auto"
            finiteValues = values(isfinite(values));
            isZeroOne = ~isempty(finiteValues) && ...
                all(finiteValues == 0 | finiteValues == 1) && ...
                numel(finiteValues) == numel(values);
            if isZeroOne
                error("cTSEMO:Inputs:AmbiguousNumericLabels", ...
                    "Numeric constraint output contains only 0 and 1, " + ...
                    "so its meaning is ambiguous. Set " + ...
                    "options.feasibility.inputEncoding to " + ...
                    "'feasibleIsOne', 'feasibleIsZero', or " + ...
                    "'continuousInequality' explicitly.");
            end
            isFeasible = all(isfinite(values)) && all(values <= 0);
        case "continuousInequality"
            isFeasible = all(isfinite(values)) && all(values <= 0);
        case "feasibleIsOne"
            requireBinaryConstraint(values);
            isFeasible = all(values == 1);
        case "feasibleIsZero"
            requireBinaryConstraint(values);
            isFeasible = all(values == 0);
        otherwise
            error("cTSEMO:Evaluation:UnknownEncoding", ...
                "Unsupported feasibility encoding '%s'.", encoding);
    end
end

function requireBinaryConstraint(values)
    if any(~isfinite(values)) || any(values ~= 0 & values ~= 1)
        error("cTSEMO:Evaluation:ExpectedBinaryConstraint", ...
            "The selected constraint encoding requires only 0/1 values.");
    end
end

function checkpointEvaluationFailure( ...
        exception, activeContext, result, outputDirectory, ...
        stage, X, Y)
    if strlength(outputDirectory) == 0
        return
    end
    context = activeContext;
    context.stage = stage;
    context.X = X;
    context.Y = Y;
    errorInformation = exceptionRecord(exception, context);
    try
        ctsemo.saveCheckpoint( ...
            result, outputDirectory, "evaluationFailed", ...
            errorInformation);
    catch
        % The outer handler makes one final checkpoint attempt.
    end
end

function data = appendObservation( ...
        data, X, Y, constraintValues, isFeasible, source, iteration)
    if size(constraintValues, 2) ~= size(data.constraintValues, 2)
        error("cTSEMO:Evaluation:ConstraintCountChanged", ...
            ["The constraint returned %d values, whereas C0 contains %d " ...
             "columns. Keep the aggregate/continuous representation fixed."], ...
            size(constraintValues, 2), ...
            size(data.constraintValues, 2));
    end
    data.X(end + 1, :) = X;
    data.Y(end + 1, :) = Y;
    data.constraintValues(end + 1, :) = constraintValues;
    data.isFeasible(end + 1, 1) = logical(isFeasible);
    data.selectionSource(end + 1, 1) = source;
    data.addedIteration(end + 1, 1) = iteration;
    data.evaluationIndex(end + 1, 1) = size(data.X, 1);
    data.feasibilityState = classifyFeasibility(data.isFeasible);
end

function state = classifyFeasibility(isFeasible)
    if all(isFeasible)
        state = "allFeasible";
    elseif any(isFeasible)
        state = "mixed";
    else
        state = "noneFeasible";
    end
end

function record = makeIterationRecord( ...
        iteration, data, selection, newY, constraintValues, ...
        newIsFeasible, currentPareto, objectiveModels, ...
        objectiveDraws, pofModel, pofDiagnostics, timing, options)
    record = emptyIterationRecord();
    record.iteration = iteration;
    record.evaluationIndex = size(data.X, 1);
    record.status = "completed";
    record.selectionState = selection.selectionState;
    record.selectionSource = selection.selectionSource;
    record.fallbackUsed = selection.fallbackUsed;
    record.fallbackReason = selection.fallbackReason;
    record.generatorFailed = selection.generatorFailed;
    record.fallbackPoolRegenerated = ...
        selection.fallbackPoolRegenerated;
    record.timing = timing;
    record.acquisitionReferencePoint = ...
        selection.acquisitionReferencePoint;
    record.objectiveScaling = selection.objectiveScaling;
    record.acquisitionStatus = selection.acquisitionStatus;
    record.primary = selection.primary;
    record.challenger = selection.challenger;
    record.selected = selection.selected;
    record.observation = struct( ...
        "X", selection.selected.X, ...
        "Y", newY, ...
        "constraintValues", constraintValues, ...
        "isFeasible", logical(newIsFeasible));
    record.pareto = struct( ...
        "referencePoint", currentPareto.referencePoint, ...
        "hypervolume", currentPareto.hypervolume, ...
        "nPoints", currentPareto.nPoints);
    objectiveDiagnostics = cell(1, 2);
    for objectiveIndex = 1:2
        if ~isempty(objectiveModels{objectiveIndex})
            objectiveDiagnostics{objectiveIndex} = ...
                objectiveModels{objectiveIndex}.fitInfo;
        else
            objectiveDiagnostics{objectiveIndex} = struct( ...
                "skipped", true, ...
                "reason", "No feasible observation: Phase-I recovery.");
        end
    end
    record.modelDiagnostics = struct( ...
        "objective", {objectiveDiagnostics}, ...
        "pof", pofDiagnostics);

    if options.logging.level == "full"
        record.objectiveModels = objectiveModels;
        record.objectiveDraws = objectiveDraws;
        record.pofModel = pofModel;
        record.candidates = selection.candidates;
        record.fallbackInfo = selection.fallbackInfo;
    end
end

function record = emptyIterationRecord()
    record = struct( ...
        "iteration", 0, ...
        "evaluationIndex", 0, ...
        "status", "", ...
        "selectionState", "", ...
        "selectionSource", "", ...
        "fallbackUsed", false, ...
        "fallbackReason", "", ...
        "generatorFailed", false, ...
        "fallbackPoolRegenerated", false, ...
        "timing", struct(), ...
        "acquisitionReferencePoint", zeros(0, 2), ...
        "objectiveScaling", struct(), ...
        "acquisitionStatus", struct(), ...
        "primary", struct(), ...
        "challenger", struct(), ...
        "selected", struct(), ...
        "observation", struct(), ...
        "pareto", struct(), ...
        "modelDiagnostics", struct(), ...
        "objectiveModels", {cell(1, 2)}, ...
        "objectiveDraws", {cell(1, 2)}, ...
        "pofModel", struct(), ...
        "candidates", struct(), ...
        "fallbackInfo", struct());
end

function writeIterationRecord( ...
        record, outputDirectory, logging, iteration)
    if strlength(outputDirectory) == 0
        return
    end
    writeFull = logging.level == "full";
    writeSummary = logging.saveEveryIteration && ...
        logging.level ~= "none";
    if ~(writeFull || writeSummary)
        return
    end

    if writeFull
        fileName = sprintf("online_iteration_%04d_full.mat", iteration);
        diagnostic = record;
    else
        fileName = sprintf("online_iteration_%04d_summary.mat", iteration);
        diagnostic = record;
        diagnostic.objectiveModels = cell(1, 2);
        diagnostic.objectiveDraws = cell(1, 2);
        diagnostic.pofModel = struct();
        diagnostic.candidates = struct();
    end
    path = fullfile(outputDirectory, fileName);
    if isfile(path)
        error("cTSEMO:Logging:ImmutableRecordExists", ...
            "Refusing to overwrite immutable online record '%s'.", path);
    end
    save(path, "diagnostic", "-v7");
end

function result = finalizeResult(result, startedAt)
    result.meta.status = "completed";
    finishedAt = datetime("now", "TimeZone", "local");
    result.meta.finishedAt = timestamp(finishedAt);
    result.meta.wallTimeSeconds = seconds(finishedAt - startedAt);

    data = result.data;
    result.pareto = ctsemo.updatePareto( ...
        data.X, data.Y, data.isFeasible);
    result.pareto.history = fixedReferenceHistory( ...
        data, result.pareto.referencePoint);
end

function history = fixedReferenceHistory(data, referencePoint)
    iterationCount = max(data.addedIteration);
    history = struct();
    history.iteration = (0:iterationCount).';
    history.evaluationCount = data.nInitial + history.iteration;
    history.hypervolume = zeros(iterationCount + 1, 1);
    history.feasibleCount = zeros(iterationCount + 1, 1);

    for row = 1:(iterationCount + 1)
        count = history.evaluationCount(row);
        selected = 1:count;
        history.feasibleCount(row) = nnz(data.isFeasible(selected));
        if isempty(referencePoint) || history.feasibleCount(row) == 0
            continue
        end
        pareto = ctsemo.updatePareto( ...
            data.X(selected, :), data.Y(selected, :), ...
            data.isFeasible(selected), referencePoint);
        history.hypervolume(row) = pareto.hypervolume;
    end
end

function saveFinalResult(result, outputDirectory)
    path = fullfile(outputDirectory, "result.mat");
    temporaryPath = string(tempname(outputDirectory)) + ".mat";
    cleanup = onCleanup(@() removeTemporaryFile(temporaryPath));
    save(temporaryPath, "result", "-v7");
    [moved, message] = movefile(temporaryPath, path, "f");
    if ~moved
        error("cTSEMO:Logging:ResultMoveFailed", ...
            "Could not finalize result '%s': %s", path, message);
    end
end

function removeTemporaryFile(path)
    if isfile(path)
        delete(path);
    end
end

function XUnit = normalizeInputs(X, lowerBound, upperBound)
    XUnit = (double(X) - lowerBound) ./ ...
        (upperBound - lowerBound);
    XUnit = min(max(XUnit, 0), 1);
end

function [standardizedY, center, scale] = standardizeObjectives(Y)
    center = mean(Y, 1);
    scale = std(Y, 0, 1);
    minimumScale = sqrt(eps) .* max(1, max(abs(Y), [], 1));
    invalidScale = ~isfinite(scale) | scale <= minimumScale;
    scale(invalidScale) = 1;
    standardizedY = (Y - center) ./ scale;
end

function record = exceptionRecord(exception, context)
    stack = exception.stack;
    stackRecord = repmat(struct( ...
        "name", "", "file", "", "line", 0), numel(stack), 1);
    for index = 1:numel(stack)
        stackRecord(index).name = string(stack(index).name);
        stackRecord(index).file = string(stack(index).file);
        stackRecord(index).line = stack(index).line;
    end
    record = struct( ...
        "identifier", string(exception.identifier), ...
        "message", string(exception.message), ...
        "context", context, ...
        "stack", stackRecord);
end

function value = timestamp(dateTime)
    value = string(dateTime, "yyyy-MM-dd'T'HH:mm:ss.SSSXXX");
end
