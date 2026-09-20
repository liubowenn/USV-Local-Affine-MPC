function models = loadMpcModels(modelSource)
% loadMpcModels  Load learned models required by closed-loop MPC.
%
% Output groups
%   nc       - global LSSVM state-space model
%   gp       - global GP state-space model
%   clusters - FCM and K-means local models

    if ~exist('modelSource', 'var') || isempty(modelSource)
        modelSource = 'mss';
    end

    ncFile = load(stateModelFile('StateModelNC.mat', modelSource), 'StateModelNoCluster');
    models.nc.A = ncFile.StateModelNoCluster.A;
    models.nc.B = ncFile.StateModelNoCluster.B;
    models.nc.b = getStructField(ncFile.StateModelNoCluster, 'b', zeros(3, 1));

    gpFile = load(stateModelFile('StateModelGP.mat', modelSource), 'StateModelGP');
    models.gp.A = gpFile.StateModelGP.A;
    models.gp.B = gpFile.StateModelGP.B;
    models.gp.b = getStructField(gpFile.StateModelGP, 'b', zeros(3, 1));

    models.clusters = struct();
    for tagCell = {'FCM', 'KMEANS'}
        tag = tagCell{1};
        stateFile = load(stateModelFile(['StateModelCluster' tag '.mat'], modelSource), ...
            'StateModelCluster');
        StateModelCluster = stateFile.StateModelCluster;

        models.clusters.(tag).A = cellfun(@(s) s.A, StateModelCluster, ...
            'UniformOutput', false);
        models.clusters.(tag).B = cellfun(@(s) s.B, StateModelCluster, ...
            'UniformOutput', false);
        models.clusters.(tag).b = cellfun(@(s) getStructField(s, 'b', zeros(3, 1)), ...
            StateModelCluster, 'UniformOutput', false);
        models.clusters.(tag).K = numel(StateModelCluster);
        models.clusters.(tag).cInfo = clusterInfoFromStateModel(StateModelCluster{1}, ...
            tag, modelSource);
    end
end

function cInfo = clusterInfoFromStateModel(stateModel, tag, modelSource)
    cInfo.min = stateModel.min_all;
    cInfo.max = stateModel.max_all;
    cInfo.CENTER = stateModel.CENTER;
    cInfo.cluster_min = stateModel.cluster_min;
    cInfo.cluster_max = stateModel.cluster_max;
    cInfo.cluster_cols = stateModel.cluster_cols;

    tailFile = load(dataFile(['clusterTail_' tag '.mat'], modelSource), 'clusterTail');
    cInfo.method = getStructField(tailFile.clusterTail, 'method', 'fcm');
    cInfo.F_cov = getStructField(tailFile.clusterTail, 'F_cov', []);
    cInfo.fusion_beta = getStructField(tailFile.clusterTail, 'fusion_beta', 1);
    cInfo.feature_weights = getStructField(tailFile.clusterTail, 'feature_weights', []);
end
