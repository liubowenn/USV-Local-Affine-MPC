function [clusters, cluster_index, clusterTail] = runKMeans(numClusters, visualize, tag, feature_weights)
    if ~exist('numClusters', 'var') || isempty(numClusters), numClusters = 3; end
    if ~exist('visualize', 'var') || isempty(visualize), visualize = true; end
    if ~exist('tag', 'var') || isempty(tag), tag = 'KMEANS'; end
    if ~exist('feature_weights', 'var') || isempty(feature_weights), feature_weights = []; end
    load(dataFile('data.mat'), 'data');
    tag = char(tag);
    model_cols = [1, 2, 3, 7, 8];
    cluster_cols = 1:length(model_cols);
    feature_names = {'u', 'v', 'r', 'tau_X', 'tau_N'};
    dataCluster = data(:, model_cols);
    [N, ~] = size(dataCluster);
    if isempty(feature_weights)
        feature_weights = ones(1, length(model_cols));
    end
    feature_weights = feature_weights(:)';
    if length(feature_weights) ~= length(model_cols)
        error('runKMeans: feature_weights must have %d elements.', length(model_cols));
    end
    cluster_min = min(dataCluster);
    cluster_max = max(dataCluster);
    cluster_range = cluster_max - cluster_min;
    cluster_range(cluster_range < 1e-10) = 1;
    Data = (dataCluster - cluster_min) ./ cluster_range;
    DataWeighted = Data .* sqrt(feature_weights);
    fprintf('Running K-means with K=%d...\n', numClusters);
    opts = statset('MaxIter', 300, 'Display', 'off');
    [labels, CENTER_w] = kmeans(DataWeighted, numClusters, ...
        'Replicates', 5, 'Options', opts, 'EmptyAction', 'singleton');
    CENTER = CENTER_w ./ sqrt(feature_weights);
    cluster_index = cell(numClusters, 1);
    clusters = cell(numClusters, 1);
    U_full = zeros(numClusters, N);
    for i = 1:numClusters
        cluster_index{i} = find(labels == i);
        clusters{i} = data(cluster_index{i}, :);
        U_full(i, cluster_index{i}) = 1;
    end
    clusterTail.min_all = cluster_min;
    clusterTail.max_all = cluster_max;
    clusterTail.range_all = cluster_range;
    clusterTail.range = cluster_range;
    clusterTail.cluster_min = cluster_min;
    clusterTail.cluster_max = cluster_max;
    clusterTail.cluster_range = cluster_range;
    clusterTail.cluster_cols = cluster_cols;
    clusterTail.model_cols = model_cols;
    clusterTail.feature_names = feature_names;
    clusterTail.feature_weights = feature_weights;
    clusterTail.CENTER = CENTER;
    clusterTail.F_cov = [];
    clusterTail.U_full = U_full;
    clusterTail.hard_labels = labels';
    clusterTail.method = 'kmeans';
    clusterTail.gate_method = 'kmeans';
    clusterTail.numClusters = numClusters;
    clusterTail.tag = tag;
    if isempty(tag)
        save(dataFile('cluster_index.mat'), 'cluster_index');
        save(dataFile('clusters.mat'), 'clusters');
        save(dataFile('clusterTail.mat'), 'clusterTail');
    else
        save(dataFile(['cluster_index_' tag '.mat']), 'cluster_index');
        save(dataFile(['clusters_' tag '.mat']), 'clusters');
        save(dataFile(['clusterTail_' tag '.mat']), 'clusterTail');
    end
    fprintf('\nK-means clustering complete: K=%d\n', numClusters);
    for i = 1:numClusters
        fprintf('  Cluster %d: %d samples (%.1f%%)\n', ...
                i, length(cluster_index{i}), 100*length(cluster_index{i})/N);
    end
    if visualize
        plotKMeansResults(0.1, numClusters, labels, dataCluster);
    end
end
function plotKMeansResults(Ts, K, labels, dataCluster)
    N = length(labels);
    t = Ts:Ts:N*Ts;
    colors = lines(K);
    figure('Name', 'K-means Clustered States', 'Color', 'w');
    subplot(2, 1, 1);
    for k = 1:K
        idx = labels == k;
        plot(t(idx), dataCluster(idx, 1), '.', 'Color', colors(k, :), 'MarkerSize', 4); hold on;
    end
    ylabel('u (m/s)'); grid on;
    subplot(2, 1, 2);
    for k = 1:K
        idx = labels == k;
        plot(t(idx), dataCluster(idx, 3) * 180/pi, '.', 'Color', colors(k, :), 'MarkerSize', 4); hold on;
    end
    ylabel('r (deg/s)'); xlabel('Time (s)'); grid on;
end


