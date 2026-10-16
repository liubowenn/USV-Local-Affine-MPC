function [modelu, modelv, modelr] = trainGlobalLssvm(gam_u, gam_v, gam_r)
    defaults = defaultExperimentConfig();
    if ~exist('gam_u', 'var'), gam_u = defaults.gam_u; end
    if ~exist('gam_v', 'var'), gam_v = defaults.gam_v; end
    if ~exist('gam_r', 'var'), gam_r = defaults.gam_r; end
    load(dataFile('data.mat'), 'data');
    X_train = data(1:end-1, [1, 2, 3, 7, 8]);
    Yu = data(2:end, 1) - data(1:end-1, 1);
    Yv = data(2:end, 2) - data(1:end-1, 2);
    Yr = data(2:end, 3) - data(1:end-1, 3);
    max_samples = 30000;
    if size(X_train, 1) > max_samples
        idx = randperm(size(X_train, 1), max_samples);
        X_train = X_train(idx, :);
        Yu = Yu(idx);
        Yv = Yv(idx);
        Yr = Yr(idx);
        fprintf('  Subsampled to %d points for memory safety.\n', max_samples);
    end
    modelu = trainDeltaLssvm(X_train, Yu, gam_u);
    modelv = trainDeltaLssvm(X_train, Yv, gam_v);
    modelr = trainDeltaLssvm(X_train, Yr, gam_r);
    ensureModelDir();
    save(modelArtifactFile('modeluNoCluster.mat'), 'modelu');
    save(modelArtifactFile('modelvNoCluster.mat'), 'modelv');
    save(modelArtifactFile('modelrNoCluster.mat'), 'modelr');
    fprintf('Non-clustered LSSVM models saved to %s\n', modelArtifactFile());
end
function ensureModelDir()
    if exist(modelArtifactFile(), 'dir') ~= 7
        mkdir(modelArtifactFile());
    end
end


