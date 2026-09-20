function cluster_id = selectHardCluster(normalizedSample, clusterInfo)
% selectHardCluster  Pick the nearest K-means cluster under feature weights.

    featureWeights = getFeatureWeights(clusterInfo);
    diff = (clusterInfo.CENTER - normalizedSample) .* sqrt(featureWeights(:)');
    [~, cluster_id] = min(sum(diff.^2, 2));
end
