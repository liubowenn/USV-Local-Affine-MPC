function featureWeights = getFeatureWeights(clusterInfo)
% getFeatureWeights  Return cluster feature weights, defaulting to all ones.

    featureWeights = getStructField(clusterInfo, 'feature_weights', []);
    if isempty(featureWeights)
        featureWeights = ones(1, length(clusterInfo.cluster_cols));
    end
    featureWeights = featureWeights(:)';
end
