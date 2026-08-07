function covariance = localMatern32(X1, length1, X2, length2)
%LOCALMATERN32 Paciorek-Schervish local-length Matern-3/2 covariance.
%   K = ctsemo.localMatern32(X1,L1,X2,L2) evaluates an isotropic,
%   nonstationary Matern-3/2 covariance. L1 and L2 are positive scalar
%   characteristic lengths, with one value per corresponding point. A
%   scalar length is expanded across all rows.
%
%   For input dimension D, the covariance is
%
%     a_ij (1 + sqrt(3 q_ij)) exp(-sqrt(3 q_ij)),
%
%   where a_ij = (2 l_i l_j/(l_i^2+l_j^2))^(D/2) and
%   q_ij = 2 ||x_i-x_j||^2/(l_i^2+l_j^2).

arguments
    X1 (:,:) double {mustBeReal, mustBeFinite}
    length1 double {mustBeReal, mustBeFinite, mustBePositive}
    X2 (:,:) double {mustBeReal, mustBeFinite}
    length2 double {mustBeReal, mustBeFinite, mustBePositive}
end

if size(X1, 2) ~= size(X2, 2)
    error("ctsemo:localMatern32:DimensionMismatch", ...
        "X1 and X2 must have the same number of columns.");
end

length1 = expandLengths(length1, size(X1, 1), "length1");
length2 = expandLengths(length2, size(X2, 1), "length2");

distanceSquared = pairwiseSquaredDistance(X1, X2);
lengthSquaredSum = length1.^2 + (length2').^2;
dimension = size(X1, 2);

determinantFactor = ...
    (2 .* length1 .* length2' ./ lengthSquaredSum).^(dimension ./ 2);
quadraticDistance = 2 .* distanceSquared ./ lengthSquaredSum;
scaledDistance = sqrt(3 .* max(0, quadraticDistance));
covariance = determinantFactor .* ...
    (1 + scaledDistance) .* exp(-scaledDistance);
end

function lengths = expandLengths(lengths, pointCount, argumentName)
if pointCount == 0 && isempty(lengths)
    lengths = zeros(0, 1);
elseif isscalar(lengths)
    lengths = repmat(double(lengths), pointCount, 1);
elseif isvector(lengths) && numel(lengths) == pointCount
    lengths = reshape(double(lengths), [], 1);
else
    error("ctsemo:localMatern32:InvalidLengthCount", ...
        "%s must be scalar or contain one value per point.", argumentName);
end
end

function distanceSquared = pairwiseSquaredDistance(X1, X2)
distanceSquared = sum(X1.^2, 2) + sum(X2.^2, 2)' - 2 .* (X1 * X2');
distanceSquared = max(0, distanceSquared);
end
