function [modelu, modelv, modelr] = trainSingleModel(clusterData, gam_u, gam_v, gam_r, sample_idx)
    defaults = defaultExperimentConfig();
    if ~exist('gam_u', 'var'), gam_u = defaults.gam_u; end
    if ~exist('gam_v', 'var'), gam_v = defaults.gam_v; end
    if ~exist('gam_r', 'var'), gam_r = defaults.gam_r; end
    if ~exist('sample_idx', 'var') || isempty(sample_idx)
        sample_idx = [];
    end
    if isempty(sample_idx)
        X = clusterData(1:end-1, :);
        Y_next = clusterData(2:end, :);
    else
        sample_idx = sample_idx(:);
        sample_idx = sample_idx(sample_idx >= 1 & sample_idx < size(clusterData, 1));
        if isempty(sample_idx)
            error('trainSingleModel: no valid one-step samples in this cluster.');
        end
        X = clusterData(sample_idx, :);
        Y_next = clusterData(sample_idx + 1, :);
    end
    Yu = Y_next(:, 1) - X(:, 1);
    Yv = Y_next(:, 2) - X(:, 2);
    Yr = Y_next(:, 3) - X(:, 3);
    X = X(:, [1, 2, 3, 7, 8]);
    max_samples = 10000;
    if size(X, 1) > max_samples
        idx = randperm(size(X, 1), max_samples);
        X = X(idx, :);  Yu = Yu(idx);  Yv = Yv(idx);  Yr = Yr(idx);
    end
    modelu = trainDeltaLssvm(X, Yu, gam_u);
    modelv = trainDeltaLssvm(X, Yv, gam_v);
    modelr = trainDeltaLssvm(X, Yr, gam_r);
end


