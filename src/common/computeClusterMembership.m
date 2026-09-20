function membership = computeClusterMembership(exponent, centers, sample, method, ~, featureWeights)
% computeClusterMembership  Compute FCM/K-means style membership weights.
%
% Inputs:
%   exponent       - FCM exponent, normally 2.
%   centers        - K-by-D cluster centers.
%   sample         - 1-by-D sample used for online membership evaluation.
%   method         - 'fcm' or 'kmeans'. The current formula is distance based.
%   featureWeights - Optional 1-by-D feature weights.
%
% Output:
%   membership     - K-by-1 normalized membership vector.

    if ~exist('method', 'var') || isempty(method)
        method = 'fcm';
    end
    if ~exist('featureWeights', 'var') || isempty(featureWeights)
        featureWeights = ones(1, size(centers, 2));
    end
    if ~any(strcmpi(method, {'fcm', 'kmeans'}))
        error('computeClusterMembership:UnknownMethod', ...
            'Unknown method "%s". Use fcm or kmeans.', method);
    end

    K = size(centers, 1);
    featureWeights = featureWeights(:)';
    if length(featureWeights) ~= size(centers, 2)
        error('computeClusterMembership:InvalidFeatureWeights', ...
            'featureWeights must have %d elements.', size(centers, 2));
    end

    sqrtWeights = sqrt(featureWeights);
    centersWeighted = centers .* sqrtWeights;
    sampleWeighted = sample .* sqrtWeights;
    distances = sqrt(sum((centersWeighted - repmat(sampleWeighted, K, 1)).^2, 2));
    distances = max(distances, 1e-10);

    membership = (1 ./ distances).^(2 / (exponent - 1));
    membership = membership / sum(membership);
end
