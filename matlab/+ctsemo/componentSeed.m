function seed = componentSeed(baseSeed, component, index)
%COMPONENTSEED Derive a reproducible, component-specific RNG seed.
%   SEED = ctsemo.componentSeed(BASESEED, COMPONENT, INDEX) maps the
%   supplied values to an integer accepted by RNG. The mapping is stable
%   across calls and does not read or change MATLAB's global RNG state.

if nargin < 1 || isempty(baseSeed)
    baseSeed = 1;
end
if nargin < 2 || isempty(component)
    component = "default";
end
if nargin < 3 || isempty(index)
    index = 0;
end

validateattributes(baseSeed, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'nonnegative'}, mfilename, 'baseSeed');
validateattributes(index, {'numeric'}, ...
    {'vector', 'real', 'finite', 'nonnegative'}, mfilename, 'index');

componentText = char(string(component));
modulus = 2147483646;
hashValue = mod(floor(double(baseSeed)), modulus);

payload = [double(componentText), 255, double(index(:).')];
for payloadIndex = 1:numel(payload)
    hashValue = mod(131 * hashValue + payload(payloadIndex) + 1, modulus);
end

seed = floor(hashValue) + 1;
end
