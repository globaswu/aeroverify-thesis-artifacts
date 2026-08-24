function result = cTSEMO(f, g, X0, Y0, C0, lb, ub, options)
%CTSEMO Lightweight constrained Thompson-sampling multiobjective optimizer.
%   RESULT = cTSEMO(F,G,X0,Y0,C0,LB,UB,OPTIONS) performs sequential
%   minimization of exactly two expensive objectives. F evaluates one
%   design and returns a two-element row or column vector. G returns either
%   continuous inequality values (feasible when every value is <= 0) or
%   labels using the encoding selected in OPTIONS.
%
%   X0, Y0, and C0 contain the already evaluated initial design. Logical
%   labels use true for feasible. For numeric 0/1 labels, set
%   OPTIONS.feasibility.inputEncoding explicitly.
%
%   The feasibility field is an exact Gaussian-process mean fitted to raw
%   binary targets, then clipped to [0,1]. It is an operational feasibility
%   score, not a calibrated Bernoulli probability.
%
%   See also cTSEMOOptions.

    arguments
        f (1,1) function_handle
        g
        X0 double
        Y0 double
        C0
        lb double
        ub double
        options (1,1) struct = cTSEMOOptions()
    end

    [problem, data, options] = ctsemo.validateInputs( ...
        f, g, X0, Y0, C0, lb, ub, options);
    result = ctsemo.run(problem, data, options);
end
