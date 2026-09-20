function nd = normalizeClusterPoint(sample, clusterInfo)
% normalizeClusterPoint  Normalize the features used for cluster selection.

    range = clusterInfo.cluster_max - clusterInfo.cluster_min;
    range(range < 1e-10) = 1;
    nd = (sample(clusterInfo.cluster_cols) - clusterInfo.cluster_min) ./ range;
end
