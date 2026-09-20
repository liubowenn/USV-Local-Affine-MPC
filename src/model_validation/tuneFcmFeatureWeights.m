function weightResults = tuneFcmFeatureWeights(numClusters, delta, gam_u, gam_v, gam_r, searchConfig, objective, beta)
    if ~exist('searchConfig', 'var') || isempty(searchConfig), searchConfig = defaultGaConfig(); end
    if ~exist('objective', 'var') || isempty(objective), objective = 'uvr'; end
    if ~exist('beta', 'var') || isempty(beta), beta = 2; end
    load(dataFile('data.mat'), 'data');
    load(dataFile('data_val.mat'), 'data_val');
    Ts = 0.1;
    searchConfig = normalizeSearchConfig(searchConfig);
    scoreScale = computeUvrScoreScale(data);
    fprintf('\nTuning weighted FCM feature weights using validation set...\n');
    fprintf('Objective = %s\n', objective);
    fprintf('UVR score scale from training data: scale_u=%.6g, scale_v=%.6g, scale_r=%.6g\n', ...
        scoreScale.u, scoreScale.v, scoreScale.r);
    switch lower(char(searchConfig.method))
        case 'ga'
            [bestWeights, bestScore, scores, metrics, weightHistory] = ...
                runGaSearch(searchConfig, data_val, Ts, numClusters, delta, ...
                            gam_u, gam_v, gam_r, objective, beta, scoreScale);
        case 'grid'
            [bestWeights, bestScore, scores, metrics, weightHistory] = ...
                runGridSearch(searchConfig.weight_grid, data_val, Ts, numClusters, delta, ...
                              gam_u, gam_v, gam_r, objective, beta, scoreScale);
        otherwise
            error('tuneFcmFeatureWeights: unknown search method "%s".', searchConfig.method);
    end
    fprintf('\nWeighted FCM best weights = [%s], %s score = %.6f\n', ...
        sprintf('%.3g ', bestWeights), objective, bestScore);
    runFCM(numClusters, delta, false, 'fcm', 'FCM', bestWeights);
    trainCluster(gam_u, gam_v, gam_r, 'FCM');
    buildStateModels('FCM');
    load(dataFile('clusterTail_FCM.mat'), 'clusterTail');
    clusterTail.fusion_beta = beta;
    clusterTail.feature_weight_objective = objective;
    clusterTail.feature_weight_search = searchConfig;
    clusterTail.feature_weight_score_scale = scoreScale;
    clusterTail.feature_weight_score_normalized_uvr = true;
    save(dataFile('clusterTail_FCM.mat'), 'clusterTail');
    weightResults.best_weights = bestWeights;
    weightResults.best_score = bestScore;
    weightResults.objective = objective;
    weightResults.beta = beta;
    weightResults.search_config = searchConfig;
    weightResults.score_scale = scoreScale;
    weightResults.scores = scores;
    weightResults.metrics = metrics;
    weightResults.weight_history = weightHistory;
end
function cfg = defaultGaConfig()
    experiment = defaultExperimentConfig();
    cfg = experiment.fcm_weight_search;
end
function cfg = normalizeSearchConfig(searchConfig)
    if isnumeric(searchConfig)
        cfg = struct('method', 'grid', 'weight_grid', searchConfig);
        return;
    end
    if ischar(searchConfig) || isstring(searchConfig)
        cfg = defaultGaConfig();
        cfg.method = char(searchConfig);
        return;
    end
    cfg = defaultGaConfig();
    fields = fieldnames(searchConfig);
    for i = 1:numel(fields)
        cfg.(fields{i}) = searchConfig.(fields{i});
    end
end
function scoreScale = computeUvrScoreScale(data)
    if size(data, 2) < 3
        error('computeUvrScoreScale: data must contain at least columns [u, v, r].');
    end
    scale_u = max(data(:, 1)) - min(data(:, 1));
    scale_v = max(data(:, 2)) - min(data(:, 2));
    scale_r = max(data(:, 3)) - min(data(:, 3));
    eps_scale = 1e-10;
    scoreScale = struct();
    scoreScale.u = max(scale_u, eps_scale);
    scoreScale.v = max(scale_v, eps_scale);
    scoreScale.r = max(scale_r, eps_scale);
    scoreScale.source = 'training_range';
    scoreScale.description = 'range of [u,v,r] computed from data.mat';
end
function [bestWeights, bestScore, scores, metrics, weightHistory] = runGaSearch( ...
        cfg, data_val, Ts, numClusters, delta, gam_u, gam_v, gam_r, objective, beta, scoreScale)
    if exist('ga', 'file') ~= 2
        error('tuneFcmFeatureWeights: MATLAB ga function is unavailable. Install/enable Global Optimization Toolbox.');
    end
    rng(cfg.seed);
    nvars = 5;
    evalCount = 0;
    cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
    historyWeights = zeros(0, nvars);
    historyScores = zeros(0, 1);
    historyMetrics = repmat(emptyMetrics(), 0, 1);
    options = optimoptions('ga', ...
        'PopulationSize', cfg.population_size, ...
        'MaxGenerations', cfg.max_generations, ...
        'EliteCount', cfg.elite_count, ...
        'UseParallel', cfg.use_parallel, ...
        'Display', cfg.display);
    [xBest, bestScore] = ga(@objectiveFun, nvars, [], [], [], [], ...
                            cfg.lb(:)', cfg.ub(:)', [], options);
    bestWeights = normalizeWeights(xBest);
    weightHistory = historyWeights;
    scores = historyScores;
    metrics = historyMetrics;
    function score = objectiveFun(x)
        weights = normalizeWeights(x);
        key = sprintf('%.3f_', round(weights, 3));
        if isKey(cache, key)
            cached = cache(key);
            score = cached.score;
            return;
        end
        evalCount = evalCount + 1;
        tag = sprintf('WFCM_GA_%03d', evalCount);
        [score, metric] = evaluateWeights(weights, tag, data_val, Ts, numClusters, ...
                                          delta, gam_u, gam_v, gam_r, objective, beta, scoreScale);
        cache(key) = struct('score', score, 'metric', metric);
        historyWeights(end+1, :) = weights;
        historyScores(end+1, 1) = score;
        historyMetrics(end+1, 1) = metric;
        deleteTaggedArtifacts(tag);
    end
end
function [bestWeights, bestScore, scores, metrics, weightHistory] = runGridSearch( ...
        weightGrid, data_val, Ts, numClusters, delta, gam_u, gam_v, gam_r, objective, beta, scoreScale)
    nCandidates = size(weightGrid, 1);
    scores = zeros(nCandidates, 1);
    metrics = repmat(emptyMetrics(), nCandidates, 1);
    weightHistory = zeros(nCandidates, size(weightGrid, 2));
    for i = 1:nCandidates
        weights = normalizeWeights(weightGrid(i, :));
        tag = sprintf('WFCM_%02d', i);
        [scores(i), metrics(i)] = evaluateWeights(weights, tag, data_val, Ts, ...
            numClusters, delta, gam_u, gam_v, gam_r, objective, beta, scoreScale);
        weightHistory(i, :) = weights;
        deleteTaggedArtifacts(tag);
    end
    [bestScore, bestIdx] = min(scores);
    bestWeights = weightHistory(bestIdx, :);
end
function [score, metric] = evaluateWeights(weights, tag, data_val, Ts, numClusters, ...
        delta, gam_u, gam_v, gam_r, objective, beta, scoreScale)
    fprintf('\nEvaluating %s weights = [%s]\n', tag, sprintf('%.3g ', weights));
    runFCM(numClusters, delta, false, 'fcm', tag, weights);
    trainCluster(gam_u, gam_v, gam_r, tag);
    buildStateModels(tag);
    load(dataFile(['clusterTail_' tag '.mat']), 'clusterTail');
    clusterTail.fusion_beta = beta;
    clusterTail.feature_weight_score_scale = scoreScale;
    save(dataFile(['clusterTail_' tag '.mat']), 'clusterTail');
    models = loadClusterLssvmModels(tag, size(clusterTail.CENTER, 1));
    [pred, truth, switchMask] = predictClusteredLssvm(data_val, clusterTail, models, beta, Ts);
    metric = computePredictionMetrics(pred, truth, switchMask);
    score = scorePredictionMetrics(metric, objective, scoreScale);
    nrmse_u = metric.rmse_u / scoreScale.u;
    nrmse_v = metric.rmse_v / scoreScale.v;
    nrmse_r = metric.rmse_r / scoreScale.r;
    fprintf('  RMSE:  u=%.6f v=%.6f r=%.6f r_switch=%.6f psi=%.6f\n', ...
        metric.rmse_u, metric.rmse_v, metric.rmse_r, ...
        metric.rmse_r_switch, metric.rmse_psi);
    fprintf('  NRMSE: u=%.6f v=%.6f r=%.6f  score=%.6f\n', ...
        nrmse_u, nrmse_v, nrmse_r, score);
end
function score = scorePredictionMetrics(metric, objective, scoreScale)
    objective = lower(char(objective));
    switch objective
        case {'uvr', 'uvr_mean', 'nrmse_uvr'}
            score = mean([
                metric.rmse_u / scoreScale.u, ...
                metric.rmse_v / scoreScale.v, ...
                metric.rmse_r / scoreScale.r
            ]);
        case {'uvr_sum', 'nrmse_uvr_sum'}
            score = ...
                metric.rmse_u / scoreScale.u + ...
                metric.rmse_v / scoreScale.v + ...
                metric.rmse_r / scoreScale.r;
        case {'uvr_raw', 'raw_uvr'}
            score = metric.rmse_u + metric.rmse_v + metric.rmse_r;
        case 'u'
            score = metric.rmse_u;
        case 'v'
            score = metric.rmse_v;
        case 'r'
            score = metric.rmse_r;
        case 'r_switch'
            score = metric.rmse_r_switch;
        case 'psi'
            score = metric.rmse_psi;
        otherwise
            error('scorePredictionMetrics: unknown objective "%s".', objective);
    end
end
function weights = normalizeWeights(weights)
    weights = max(weights(:)', 1e-6);
    weights = weights / mean(weights);
end
function deleteTaggedArtifacts(tag)
    stems = {'cluster_index', 'clusters', 'clusterTail'};
    for i = 1:numel(stems)
        deleteIfExists(dataFile([stems{i} '_' tag '.mat']));
    end
    for k = 1:100
        modelU = modelArtifactFile(sprintf('modeluCluster%d_%s.mat', k, tag));
        modelV = modelArtifactFile(sprintf('modelvCluster%d_%s.mat', k, tag));
        modelR = modelArtifactFile(sprintf('modelrCluster%d_%s.mat', k, tag));
        if exist(modelU, 'file') ~= 2 && ...
           exist(modelV, 'file') ~= 2 && ...
           exist(modelR, 'file') ~= 2
            break;
        end
        deleteIfExists(modelU);
        deleteIfExists(modelV);
        deleteIfExists(modelR);
    end
    deleteIfExists(stateModelFile(['StateModelCluster' tag '.mat']));
end
function deleteIfExists(filePath)
    if exist(filePath, 'file') == 2
        delete(filePath);
    end
end


