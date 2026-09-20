function [clusters, cluster_index, clusterTail] = runFCM(numClusters, delta, visualize, method, tag, feature_weights)
    if ~exist('numClusters', 'var') || isempty(numClusters), numClusters = 3; end
    if ~exist('delta', 'var') || isempty(delta), delta = []; end
    if ~exist('visualize', 'var') || isempty(visualize), visualize = true; end
    if ~exist('method', 'var') || isempty(method), method = 'fcm'; end
    if ~exist('tag', 'var') || isempty(tag), tag = ''; end
    if ~exist('feature_weights', 'var') || isempty(feature_weights), feature_weights = []; end
    load(dataFile('data.mat'), 'data');
    method = lower(method);
    tag = char(tag);
    model_cols    = [1, 2, 3, 7, 8];
    cluster_cols  = 1:length(model_cols);
    feature_names = {'u', 'v', 'r', 'tau_X', 'tau_N'};
    dataCluster   = data(:, model_cols);
    [N, ~] = size(dataCluster);
    if isempty(feature_weights)
        feature_weights = ones(1, length(model_cols));
    end
    feature_weights = feature_weights(:)';
    if length(feature_weights) ~= length(model_cols)
        error('runFCM: feature_weights must have %d elements.', length(model_cols));
    end
    if any(feature_weights <= 0)
        error('runFCM: feature_weights must be positive.');
    end
    cluster_min = min(dataCluster);
    cluster_max = max(dataCluster);
    cluster_range = cluster_max - cluster_min;
    cluster_range(cluster_range < 1e-10) = 1;
    Data = (dataCluster - cluster_min) ./ cluster_range;
    DataWeighted = Data .* sqrt(feature_weights);
    assignment_mode = 'threshold';
    if ~exist('delta', 'var') || isempty(delta)
        delta = repmat(0.8 / numClusters, 1, numClusters);
    elseif ischar(delta) || isstring(delta)
        if any(strcmpi(char(delta), {'max', 'hard'}))
            assignment_mode = 'max';
        else
            error('runFCM: unknown delta mode "%s". Use "max" or a numeric threshold.', char(delta));
        end
    else
        if isscalar(delta)
            delta = repmat(delta, 1, numClusters);
        end
        if numel(delta) ~= numClusters
            error('runFCM: numeric delta must be scalar or have %d elements.', numClusters);
        end
    end
    switch method
        case 'fcm'
            fprintf('Running FCM (Euclidean) with K=%d...\n', numClusters);
            [CENTER_w, U_full] = fcm(DataWeighted, numClusters);
            CENTER = CENTER_w ./ sqrt(feature_weights);
        otherwise
            error('runFCM: unknown method "%s". Use: fcm', method);
    end
    cluster_index = cell(numClusters, 1);
    clusters      = cell(numClusters, 1);
    [~, hard_labels] = max(U_full, [], 1);
    if strcmp(assignment_mode, 'max')
        plot_delta = repmat(0.8 / numClusters, 1, numClusters);
        for i = 1:numClusters
            cluster_index{i} = find(hard_labels == i);
            clusters{i}      = data(cluster_index{i}, :);
        end
    else
        plot_delta = delta;
        for i = 1:numClusters
            cluster_index{i} = find(U_full(i, :) > delta(i));
            if isempty(cluster_index{i})
                cluster_index{i} = find(hard_labels == i);
            end
            clusters{i} = data(cluster_index{i}, :);
        end
    end
    clusterTail.min_all       = cluster_min;
    clusterTail.max_all       = cluster_max;
    clusterTail.range_all     = cluster_range;
    clusterTail.range         = cluster_range;
    clusterTail.cluster_min   = cluster_min;
    clusterTail.cluster_max   = cluster_max;
    clusterTail.cluster_range = cluster_range;
    clusterTail.cluster_cols  = cluster_cols;
    clusterTail.model_cols    = model_cols;
    clusterTail.feature_names = feature_names;
    clusterTail.feature_weights = feature_weights;
    clusterTail.CENTER        = CENTER;
    clusterTail.F_cov         = [];
    clusterTail.U_full        = U_full;
    clusterTail.hard_labels   = hard_labels;
    clusterTail.assignment_mode = assignment_mode;
    clusterTail.delta         = delta;
    clusterTail.method        = method;
    clusterTail.gate_method   = method;
    clusterTail.numClusters   = numClusters;
    clusterTail.tag           = tag;
    if isempty(tag)
        save(dataFile('cluster_index.mat'), 'cluster_index');
        save(dataFile('clusters.mat'), 'clusters');
        save(dataFile('clusterTail.mat'), 'clusterTail');
    else
        save(dataFile(['cluster_index_' tag '.mat']), 'cluster_index');
        save(dataFile(['clusters_' tag '.mat']), 'clusters');
        save(dataFile(['clusterTail_' tag '.mat']), 'clusterTail');
    end
    fprintf('\n%s clustering complete: K=%d, assignment=%s\n', ...
        upper(method), numClusters, assignment_mode);
    for i = 1:numClusters
        fprintf('  Cluster %d: %d samples (%.1f%%)\n', ...
                i, length(cluster_index{i}), 100*length(cluster_index{i})/N);
    end
    if visualize
        plotClusteringResults(0.1, numClusters, plot_delta, U_full, dataCluster);
    end
end
function plotClusteringResults(Ts, K, delta, U_full, dataCluster)
    N = size(U_full, 2);
    t = Ts:Ts:N*Ts;
    [~, labels] = max(U_full, [], 1);
    colors = lines(K);
    figure('Name', 'Cluster Membership', 'Color', 'w');
    for k = 1:K
        subplot(1, K, k);
        plot(t, U_full(k, :) * 100, 'o', 'MarkerEdgeColor', '#518CD8', ...
             'MarkerSize', 3); hold on;
        yline(delta(k) * 100, '-.', 'Color', 'r');
        title(sprintf('Cluster %d', k));
        xlabel('Time (s)'); ylabel('Membership (%)'); grid on;
    end
    figure('Name', 'Clustered States', 'Color', 'w');
    subplot(2, 1, 1);
    for k = 1:K
        idx = labels == k;
        plot(t(idx), dataCluster(idx, 1), '.', ...
             'Color', colors(k, :), 'MarkerSize', 4); hold on;
    end
    ylabel('u (m/s)'); grid on;
    subplot(2, 1, 2);
    for k = 1:K
        idx = labels == k;
        plot(t(idx), dataCluster(idx, 3) * 180/pi, '.', ...
             'Color', colors(k, :), 'MarkerSize', 4); hold on;
    end
    ylabel('r (deg/s)'); xlabel('Time (s)'); grid on;
    figure('Name', 'Cluster Feature Space', 'Color', 'w');
    for k = 1:K
        idx = labels == k;
        scatter3(dataCluster(idx, 1), dataCluster(idx, 2), ...
                 dataCluster(idx, 3) * 180/pi, 12, colors(k, :), 'filled'); hold on;
    end
    xlabel('u (m/s)'); ylabel('v (m/s)'); zlabel('r (deg/s)');
    legend(arrayfun(@(i) sprintf('C%d', i), 1:K, 'UniformOutput', false));
    grid on;
end



