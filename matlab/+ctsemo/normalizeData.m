function [normalized, scaling] = normalizeData( ...
        X, Y, isFeasible, lb, ub, options)
%NORMALIZEDATA Normalize inputs and objectives without changing labels.
%   [NORMALIZED, SCALING] = ctsemo.normalizeData(X,Y,LABELS,LB,UB,OPTIONS)
%   maps the design variables to [0,1]^d. Objectives are standardized when
%   options.objectiveGP.standardizeY is true. Constant objective columns use
%   a scale of one. NORMALIZED.pofTarget contains the un-clipped regression
%   targets selected by the binary feasibility labels.

    if nargin < 6 || isempty(options)
        options = cTSEMOOptions();
    else
        options = cTSEMOOptions(options);
    end

    lb = reshape(double(lb), 1, []);
    ub = reshape(double(ub), 1, []);
    X = double(X);
    Y = double(Y);

    validateattributes(X, {'numeric'}, {'2d', 'real', 'finite'}, ...
        mfilename, "X");
    validateattributes(Y, {'numeric'}, {'2d', 'real', 'finite'}, ...
        mfilename, "Y");
    if size(X, 1) ~= size(Y, 1)
        error("cTSEMO:Normalize:RowMismatch", ...
            "X and Y must have the same number of rows.");
    end
    if size(X, 2) ~= numel(lb) || numel(lb) ~= numel(ub)
        error("cTSEMO:Normalize:DimensionMismatch", ...
            "The columns of X must match the number of lower and upper bounds.");
    end
    if any(lb >= ub)
        error("cTSEMO:Normalize:InvalidBounds", ...
            "Every lower bound must be strictly smaller than its upper bound.");
    end
    if ~(islogical(isFeasible) && isvector(isFeasible) && ...
            numel(isFeasible) == size(X, 1))
        error("cTSEMO:Normalize:InvalidLabels", ...
            "isFeasible must be one logical value per row of X.");
    end
    isFeasible = isFeasible(:);

    inputScale = ub - lb;
    XUnit = (X - lb) ./ inputScale;

    objectiveMean = mean(Y, 1);
    objectiveScale = std(Y, 0, 1);
    minimumScale = sqrt(eps) .* max(1.0, max(abs(Y), [], 1));
    objectiveWasConstant = ~isfinite(objectiveScale) | ...
        objectiveScale <= minimumScale;
    objectiveScale(objectiveWasConstant) = 1.0;

    if options.objectiveGP.standardizeY
        YModel = (Y - objectiveMean) ./ objectiveScale;
    else
        YModel = Y;
        objectiveMean = zeros(1, size(Y, 2));
        objectiveScale = ones(1, size(Y, 2));
    end

    pofTarget = repmat(options.pof.rawInfeasible, size(X, 1), 1);
    pofTarget(isFeasible) = options.pof.rawFeasible;

    normalized = struct();
    normalized.X = XUnit;
    normalized.Y = YModel;
    normalized.isFeasible = isFeasible;
    normalized.pofTarget = pofTarget;

    scaling = struct();
    scaling.inputLower = lb;
    scaling.inputUpper = ub;
    scaling.inputScale = inputScale;
    scaling.objectiveMean = objectiveMean;
    scaling.objectiveScale = objectiveScale;
    scaling.objectiveWasConstant = objectiveWasConstant;
end
