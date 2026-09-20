function gpModels = trainGPModel(max_samples, active_set_size)
    if ~exist('max_samples', 'var') || isempty(max_samples), max_samples = 10000; end
    if ~exist('active_set_size', 'var') || isempty(active_set_size), active_set_size = min(1000, max_samples); end
    load(dataFile('data.mat'), 'data');
    X = data(1:end-1, [1, 2, 3, 7, 8]);
    Yu = data(2:end, 1) - data(1:end-1, 1);
    Yv = data(2:end, 2) - data(1:end-1, 2);
    Yr = data(2:end, 3) - data(1:end-1, 3);
    if size(X, 1) > max_samples
        rng(1);
        idx = randperm(size(X, 1), max_samples);
        X = X(idx, :);
        Yu = Yu(idx); Yv = Yv(idx); Yr = Yr(idx);
        fprintf('  GP subsampled to %d points.\n', max_samples);
    end
    commonArgs = {'KernelFunction', @gpLinearKernel, ...
                  'KernelParameters', [0; 0], ...
                  'BasisFunction', 'constant', ...
                  'Standardize', true, ...
                  'FitMethod', 'sr', ...
                  'PredictMethod', 'sr', ...
                  'ActiveSetSize', active_set_size};
    fprintf('Training GP-u...\n');
    modelu = fitrgp(X, Yu, commonArgs{:});
    fprintf('Training GP-v...\n');
    modelv = fitrgp(X, Yv, commonArgs{:});
    fprintf('Training GP-r...\n');
    modelr = fitrgp(X, Yr, commonArgs{:});
    gpModels.modelu = modelu;
    gpModels.modelv = modelv;
    gpModels.modelr = modelr;
    gpModels.prediction_target = 'delta';
    gpModels.model_type = 'gp';
    gpModels.feature_cols = [1, 2, 3, 7, 8];
    gpModels.max_samples = max_samples;
    gpModels.active_set_size = active_set_size;
    if exist(modelArtifactFile(), 'dir') ~= 7
        mkdir(modelArtifactFile());
    end
    save(modelArtifactFile('modelGP.mat'), 'gpModels');
    fprintf('GP models saved to %s\n', modelArtifactFile('modelGP.mat'));
end


