function cleanup = scopedRng(seed)
%SCOPEDRNG Set a deterministic RNG stream and restore the caller's state.
%   CLEANUP = ctsemo.scopedRng(SEED) returns an onCleanup object. Keep the
%   object in the calling workspace for as long as the scoped stream is
%   required. Destroying it restores the RNG state captured on entry.

validateattributes(seed, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'integer', 'positive'}, mfilename, 'seed');

previousState = rng;
cleanup = onCleanup(@() rng(previousState));
rng(double(seed), 'twister');
end
