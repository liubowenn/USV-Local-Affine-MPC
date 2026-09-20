function StateModelCluster = buildStateModels(tag)
    if ~exist('tag', 'var') || isempty(tag), tag = ''; end
    tag = char(tag);
    if isempty(tag)
        load(dataFile('clusters.mat'), 'clusters');
        load(dataFile('clusterTail.mat'), 'clusterTail');
        suffix = '';
    else
        load(dataFile(['clusters_' tag '.mat']), 'clusters');
        load(dataFile(['clusterTail_' tag '.mat']), 'clusterTail');
        suffix = ['_' tag];
    end
    K = size(clusters, 1);
    modeluCl = cell(K,1); modelvCl = cell(K,1); modelrCl = cell(K,1);
    for i = 1:K
        modeluCl{i} = load(modelArtifactFile(['modeluCluster', num2str(i), suffix, '.mat']));
        modelvCl{i} = load(modelArtifactFile(['modelvCluster', num2str(i), suffix, '.mat']));
        modelrCl{i} = load(modelArtifactFile(['modelrCluster', num2str(i), suffix, '.mat']));
    end
    StateModelCluster = cell(K, 1);
    for i = 1:K
        [A, B, b_vec] = computeLineModel( ...
            modeluCl{i}.modelu, modelvCl{i}.modelv, modelrCl{i}.modelr);
        StateModelCluster{i}.A = A;  StateModelCluster{i}.B = B;  StateModelCluster{i}.b = b_vec;
        StateModelCluster{i}.max_all     = clusterTail.max_all;
        StateModelCluster{i}.min_all     = clusterTail.min_all;
        StateModelCluster{i}.cluster_min = clusterTail.cluster_min;
        StateModelCluster{i}.cluster_max = clusterTail.cluster_max;
        StateModelCluster{i}.cluster_cols = clusterTail.cluster_cols;
        StateModelCluster{i}.CENTER      = clusterTail.CENTER;
        StateModelCluster{i}.feature_weights = getStructField(clusterTail, 'feature_weights', []);
        StateModelCluster{i}.method      = getStructField(clusterTail, 'method', 'fcm');
        StateModelCluster{i}.F_cov       = getStructField(clusterTail, 'F_cov', []);
    end
    ensureStateModelDir();
    save(stateModelFile(['StateModelCluster', tag, '.mat']), 'StateModelCluster');
    fprintf('Clustered state-space models built (%d clusters).\n', K);
end
function ensureStateModelDir()
    if exist(stateModelFile(), 'dir') ~= 7
        mkdir(stateModelFile());
    end
end


