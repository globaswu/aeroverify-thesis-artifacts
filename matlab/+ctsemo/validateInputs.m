function [problem, data, options] = validateInputs( ...
        f, g, X0, Y0, C0, lb, ub, options)
%VALIDATEINPUTS Validate and canonicalize the public cTSEMO inputs.
%   [PROBLEM, DATA, OPTIONS] = ctsemo.validateInputs(F,G,X0,Y0,C0,LB,UB,OPT)
%   performs no objective or constraint evaluations. DATA.isFeasible is the
%   canonical logical feasibility label used by the solver.
%
%   Logical C0 values are interpreted as feasibility labels (true means
%   feasible). Numeric C0 values are continuous inequality observations by
%   default, with a row feasible only when every entry is finite and <= 0.
%   Numeric arrays containing only zero and one are intentionally ambiguous
%   and require an explicit options.feasibility.inputEncoding setting.

    if nargin < 8 || isempty(options)
        options = cTSEMOOptions();
    else
        options = cTSEMOOptions(options);
    end

    if ~isa(f, "function_handle")
        error("cTSEMO:Inputs:InvalidObjective", ...
            "f must be a function handle.");
    end
    if ~(isempty(g) || isa(g, "function_handle"))
        error("cTSEMO:Inputs:InvalidConstraint", ...
            "g must be empty for an unconstrained problem or a function handle.");
    end

    [lb, ub] = validateBounds(lb, ub);
    dimension = numel(lb);

    validateattributes(X0, {'numeric'}, ...
        {'2d', 'real', 'finite', 'nonempty'}, mfilename, "X0");
    X0 = double(X0);
    if size(X0, 2) ~= dimension
        error("cTSEMO:Inputs:InputDimensionMismatch", ...
            "X0 has %d columns, but lb and ub define %d variables.", ...
            size(X0, 2), dimension);
    end
    validateWithinBounds(X0, lb, ub);

    validateattributes(Y0, {'numeric'}, ...
        {'2d', 'real', 'finite', 'nonempty'}, mfilename, "Y0");
    Y0 = double(Y0);
    if size(Y0, 1) ~= size(X0, 1)
        error("cTSEMO:Inputs:ObjectiveRowMismatch", ...
            "Y0 must contain one row for every row of X0.");
    end
    if size(Y0, 2) ~= 2
        error("cTSEMO:Inputs:ObjectiveCount", ...
            "The lightweight release supports exactly two objectives.");
    end

    [isFeasible, constraintValues, isUnconstrained] = ...
        canonicalizeFeasibility(C0, g, size(X0, 1), options);

    duplicateGroup = identifyDuplicateGroups( ...
        X0, lb, ub, options.candidates.duplicateTolerance);
    verifyDuplicateLabels(duplicateGroup, isFeasible);

    problem = struct();
    problem.objective = f;
    problem.constraint = g;
    problem.lowerBound = lb;
    problem.upperBound = ub;
    problem.dimension = dimension;
    problem.nObjectives = size(Y0, 2);
    problem.isUnconstrained = isUnconstrained;
    problem.constraintEncoding = options.feasibility.inputEncoding;

    data = struct();
    data.X = X0;
    data.Y = Y0;
    data.constraintValues = constraintValues;
    data.isFeasible = isFeasible;
    data.nInitial = size(X0, 1);
    data.duplicateGroup = duplicateGroup;
    data.hasDuplicateLocations = numel(unique(duplicateGroup)) < size(X0, 1);
    data.feasibilityState = classifyFeasibilityState(isFeasible);
end

function [lb, ub] = validateBounds(lb, ub)
    validateattributes(lb, {'numeric'}, ...
        {'vector', 'real', 'finite', 'nonempty'}, mfilename, "lb");
    validateattributes(ub, {'numeric'}, ...
        {'vector', 'real', 'finite', 'nonempty'}, mfilename, "ub");

    lb = reshape(double(lb), 1, []);
    ub = reshape(double(ub), 1, []);
    if numel(lb) ~= numel(ub)
        error("cTSEMO:Inputs:BoundDimensionMismatch", ...
            "lb and ub must contain the same number of elements.");
    end
    if any(lb >= ub)
        error("cTSEMO:Inputs:InvalidBounds", ...
            "Every lower bound must be strictly smaller than its upper bound.");
    end
end

function validateWithinBounds(X, lb, ub)
    scale = max(1.0, ub - lb);
    tolerance = 32 * eps(scale);
    below = X < lb - tolerance;
    above = X > ub + tolerance;
    if any(below | above, "all")
        row = find(any(below | above, 2), 1);
        error("cTSEMO:Inputs:InitialPointOutOfBounds", ...
            "X0 row %d lies outside the supplied bounds.", row);
    end
end

function [isFeasible, values, isUnconstrained] = ...
        canonicalizeFeasibility(C0, g, nRows, options)
    encoding = options.feasibility.inputEncoding;
    isUnconstrained = isempty(g);

    if isempty(C0)
        if isUnconstrained
            isFeasible = true(nRows, 1);
            values = zeros(nRows, 0);
            return
        end
        error("cTSEMO:Inputs:MissingInitialFeasibility", ...
            "C0 is required when g is supplied. cTSEMO does not make " + ...
            "hidden evaluations of g at the initial points.");
    end

    if ~(islogical(C0) || isnumeric(C0)) || ~ismatrix(C0)
        error("cTSEMO:Inputs:InvalidFeasibilityData", ...
            "C0 must be a numeric or logical two-dimensional array.");
    end
    if size(C0, 1) ~= nRows
        error("cTSEMO:Inputs:FeasibilityRowMismatch", ...
            "C0 must contain one row for every row of X0.");
    end

    values = C0;
    if islogical(C0)
        isFeasible = all(C0, 2);
    else
        isFeasible = numericFeasibility(double(C0), encoding);
    end
    isFeasible = logical(isFeasible(:));

    if isUnconstrained && any(~isFeasible)
        error("cTSEMO:Inputs:ConstraintHandleRequired", ...
            "C0 contains infeasible initial points, but g is empty. A " + ...
            "constraint handle is required to label new evaluations.");
    end
end

function isFeasible = numericFeasibility(values, encoding)
    switch encoding
        case "auto"
            finiteValues = values(isfinite(values));
            isZeroOne = ~isempty(finiteValues) && ...
                all(finiteValues == 0 | finiteValues == 1) && ...
                numel(finiteValues) == numel(values);
            if isZeroOne
                error("cTSEMO:Inputs:AmbiguousNumericLabels", ...
                    "Numeric C0 contains only 0 and 1, so its meaning is " + ...
                    "ambiguous. Set options.feasibility.inputEncoding to " + ...
                    "'feasibleIsOne', 'feasibleIsZero', or " + ...
                    "'continuousInequality' explicitly.");
            end
            isFeasible = all(isfinite(values), 2) & all(values <= 0, 2);

        case "continuousInequality"
            isFeasible = all(isfinite(values), 2) & all(values <= 0, 2);

        case "feasibleIsOne"
            requireZeroOne(values);
            isFeasible = all(values == 1, 2);

        case "feasibleIsZero"
            requireZeroOne(values);
            isFeasible = all(values == 0, 2);

        otherwise
            error("cTSEMO:Inputs:UnknownEncoding", ...
                "Unsupported feasibility encoding '%s'.", encoding);
    end
end

function requireZeroOne(values)
    if any(~isfinite(values), "all") || ...
            any(values ~= 0 & values ~= 1, "all")
        error("cTSEMO:Inputs:ExpectedZeroOneLabels", ...
            "The selected label encoding requires every C0 entry to be 0 or 1.");
    end
end

function groups = identifyDuplicateGroups(X, lb, ub, tolerance)
    XUnit = (X - lb) ./ (ub - lb);
    nRows = size(XUnit, 1);
    groups = zeros(nRows, 1);
    nGroups = 0;

    for row = 1:nRows
        previousGroup = 0;
        for previous = 1:(row - 1)
            if max(abs(XUnit(row, :) - XUnit(previous, :))) <= tolerance
                previousGroup = groups(previous);
                break
            end
        end
        if previousGroup == 0
            nGroups = nGroups + 1;
            groups(row) = nGroups;
        else
            groups(row) = previousGroup;
        end
    end
end

function verifyDuplicateLabels(groups, isFeasible)
    uniqueGroups = unique(groups);
    for index = 1:numel(uniqueGroups)
        selected = groups == uniqueGroups(index);
        if any(isFeasible(selected) ~= isFeasible(find(selected, 1)))
            rows = find(selected);
            error("cTSEMO:Inputs:ConflictingDuplicateLabels", ...
                "Duplicate initial locations have conflicting feasibility " + ...
                "labels (rows %s).", mat2str(rows(:).'));
        end
    end
end

function state = classifyFeasibilityState(isFeasible)
    if all(isFeasible)
        state = "allFeasible";
    elseif any(isFeasible)
        state = "mixed";
    else
        state = "noneFeasible";
    end
end
