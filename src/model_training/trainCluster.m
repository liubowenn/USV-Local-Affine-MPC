function [clusterModels, numClusters] = trainCluster(gam_u, gam_v, gam_r, tag)
    defaults = defaultExperimentConfig();
    if ~exist('gam_u', 'var'), gam_u = defaults.gam_u; end
    if ~exist('gam_v', 'var'), gam_v = defaults.gam_v; end
    if ~exist('gam_r', 'var'), gam_r = defaults.gam_r; end
    if ~exist('tag', 'var') || isempty(tag), tag = ''; end
    tag = char(tag);
    load(dataFile('data.mat'), 'data');
    if isempty(tag)
        load(dataFile('clusters.mat'), 'clusters');
        load(dataFile('cluster_index.mat'), 'cluster_index');
        suffix = '';
    else
        load(dataFile(['clusters_' tag '.mat']), 'clusters');
        load(dataFile(['cluster_index_' tag '.mat']), 'cluster_index');
        suffix = ['_' tag];
    end
    numClusters = length(clusters);
    clusterModels = cell(numClusters, 1);
    ensureModelDir();
    for i = 1:numClusters
        fprintf('Training cluster %d/%d ...\n', i, numClusters);
        sample_idx = cluster_index{i};
        [modelu, modelv, modelr] = trainSingleModel(data, gam_u, gam_v, gam_r, sample_idx);
        save(modelArtifactFile(['modeluCluster', num2str(i), suffix, '.mat']), 'modelu');
        save(modelArtifactFile(['modelvCluster', num2str(i), suffix, '.mat']), 'modelv');
        save(modelArtifactFile(['modelrCluster', num2str(i), suffix, '.mat']), 'modelr');
        clusterModels{i}.modelu = modelu;
        clusterModels{i}.modelv = modelv;
        clusterModels{i}.modelr = modelr;
    end
    fprintf('Cluster-specific models saved to %s\n', modelArtifactFile());
end
function ensureModelDir()
    if exist(modelArtifactFile(), 'dir') ~= 7
        mkdir(modelArtifactFile());
    end
end


