function results = runRepeatedClusterComparison(nRuns)
    if ~exist('nRuns', 'var') || isempty(nRuns)
        nRuns = 10;
    end
    cfg = defaultExperimentConfig();
    Ts = cfg.training.ts;
    beta = cfg.weighted_fcm.beta;
    data_val = loadValidationData();
    methods = {'WFCM-LSSVM', 'KMeans-LSSVM'};
    metricNames = {'rmse_u', 'rmse_v', 'rmse_r', ...
                   'rmse_u_norm', 'rmse_v_norm', 'rmse_r_norm', ...
                   'rmse_psi', 'rmse_x', 'rmse_y', 'rmse_xy'};
    metricValues = nan(nRuns, numel(methods), numel(metricNames));
    modelTags = cell(nRuns, numel(methods));
    seeds = cfg.fcm_weight_search.seed + (0:nRuns-1);
    wfcmWeights = nan(nRuns, 5);
    wfcmGaScores = nan(nRuns, 1);
    fprintf('\nRepeated clustered-model comparison: %d runs\n', nRuns);
    fprintf('Evaluation data: %s\n', dataFile('data_val.mat'));
    fprintf('WFCM objective: %s, GA population=%d, generations=%d\n', ...
        cfg.weighted_fcm.objective, ...
        cfg.fcm_weight_search.population_size, ...
        cfg.fcm_weight_search.max_generations);
    clusterBackup = backupGenericClusterFiles();
    cleanupObj = onCleanup(@() restoreGenericClusterFiles(clusterBackup));
    for runIdx = 1:nRuns
        seed = seeds(runIdx);
        fprintf('\n=== Repeat %d/%d, seed=%d ===\n', runIdx, nRuns, seed);
        fcmTag = sprintf('FCM_REPEAT_%02d', runIdx);
        modelTags{runIdx, 1} = fcmTag;
        [wfcmWeights(runIdx, :), wfcmGaScores(runIdx)] = runWfcmRepeat( ...
            cfg, fcmTag, seed);
        metricValues(runIdx, 1, :) = metricVector( ...
            evaluateClusterModel(fcmTag, data_val, beta, Ts), metricNames);
        rng(seed, 'twister');
        kmeansTag = sprintf('KMEANS_REPEAT_%02d', runIdx);
        modelTags{runIdx, 2} = kmeansTag;
        deleteTaggedArtifacts(kmeansTag);
        runKMeans(cfg.num_clusters, false, kmeansTag);
        trainCluster(cfg.gam_u, cfg.gam_v, cfg.gam_r, kmeansTag);
        buildStateModels(kmeansTag);
        metricValues(runIdx, 2, :) = metricVector( ...
            evaluateClusterModel(kmeansTag, data_val, 1, Ts), metricNames);
        fprintf('  WFCM   score(uvr_norm)=%.4f\n', ...
            sum(metricValues(runIdx, 1, 4:6)));
        fprintf('  KMeans score(uvr_norm)=%.4f\n', ...
            sum(metricValues(runIdx, 2, 4:6)));
    end
    results = buildResults(methods, metricNames, metricValues, seeds);
    results.modelTags = modelTags;
    results.wfcmWeights = wfcmWeights;
    results.wfcmGaScores = wfcmGaScores;
    results.wfcmWeightTable = buildWfcmWeightTable(seeds, wfcmWeights, wfcmGaScores);
    results.best = selectBestRuns(methods, modelTags, metricValues);
    printSummary(results);
    printWfcmWeights(wfcmWeights, wfcmGaScores);
    printBestRuns(results.best);
    packageRepeatedModels(modelTags);
    promoteBestRuns(results.best);
    cleanupRepeatedRunArtifacts(modelTags);
    saveRepeatedResults(results);
end

function data_val = loadValidationData()
    filePath = dataFile('data_val.mat');
    S = load(filePath);
    if isfield(S, 'data_val')
        data_val = S.data_val;
    elseif isfield(S, 'data')
        data_val = S.data;
    else
        names = fieldnames(S);
        if numel(names) == 1 && isnumeric(S.(names{1}))
            data_val = S.(names{1});
        else
            error('runRepeatedClusterComparison: cannot find data_val or data in %s.', filePath);
        end
    end
end

function [bestWeights, bestScore] = runWfcmRepeat(cfg, finalTag, seed)
    searchCfg = cfg.fcm_weight_search;
    searchCfg.seed = seed;
    weightResults = tuneFcmFeatureWeights( ...
        cfg.num_clusters, ...
        cfg.delta, ...
        cfg.gam_u, ...
        cfg.gam_v, ...
        cfg.gam_r, ...
        searchCfg, ...
        cfg.weighted_fcm.objective, ...
        cfg.weighted_fcm.beta);
    bestWeights = weightResults.best_weights;
    bestScore = weightResults.best_score;
    deleteTaggedArtifacts(finalTag);
    copyTaggedDataFiles('FCM', finalTag);
    copyTaggedModelFiles('FCM', finalTag);
    sourceStatePath = stateModelFile('StateModelClusterFCM.mat');
    targetStatePath = stateModelFile(['StateModelCluster' finalTag '.mat']);
    if exist(sourceStatePath, 'file') == 2
        copyfile(sourceStatePath, targetStatePath, 'f');
    else
        buildStateModels('FCM');
        copyfile(sourceStatePath, targetStatePath, 'f');
    end
    fprintf('  Copied FCM to repeated tag: %s\n', finalTag);
end

function metric = evaluateClusterModel(tag, data, beta, Ts)
    tailFile = load(dataFile(['clusterTail_' tag '.mat']), 'clusterTail');
    clusterTail = tailFile.clusterTail;
    models = loadClusterLssvmModels(tag, size(clusterTail.CENTER, 1));
    [pred, truth, switchMask] = predictClusteredLssvm(data, clusterTail, models, beta, Ts);
    metric = computePredictionMetrics(pred, truth, switchMask, Ts);
end

function values = metricVector(metric, metricNames)
    values = zeros(1, 1, numel(metricNames));
    for i = 1:numel(metricNames)
        values(1, 1, i) = metric.(metricNames{i});
    end
end

function best = selectBestRuns(methods, modelTags, metricValues)
    best = repmat(struct('method', '', 'run', [], 'tag', '', 'score', []), ...
                  1, numel(methods));
    for j = 1:numel(methods)
        scores = squeeze(sum(metricValues(:, j, 4:6), 3));
        [bestScore, bestRun] = min(scores);
        best(j).method = methods{j};
        best(j).run = bestRun;
        best(j).tag = modelTags{bestRun, j};
        best(j).score = bestScore;
    end
end

function results = buildResults(methods, metricNames, metricValues, seeds)
    nRuns = size(metricValues, 1);
    nMethods = numel(methods);
    nMetrics = numel(metricNames);
    runRows = cell(nRuns * nMethods, 2 + nMetrics);
    row = 0;
    for i = 1:nRuns
        for j = 1:nMethods
            row = row + 1;
            runRows{row, 1} = i;
            runRows{row, 2} = methods{j};
            for k = 1:nMetrics
                runRows{row, 2+k} = metricValues(i, j, k);
            end
        end
    end
    results.runTable = cell2table(runRows, ...
        'VariableNames', [{'run', 'method'}, metricNames]);
    summaryRows = cell(nMethods, 1 + 2*nMetrics);
    summaryNames = cell(1, 1 + 2*nMetrics);
    summaryNames{1} = 'method';
    for k = 1:nMetrics
        summaryNames{2*k} = [metricNames{k} '_mean'];
        summaryNames{2*k+1} = [metricNames{k} '_std'];
    end
    for j = 1:nMethods
        summaryRows{j, 1} = methods{j};
        for k = 1:nMetrics
            values = metricValues(:, j, k);
            summaryRows{j, 2*k} = mean(values, 'omitnan');
            summaryRows{j, 2*k+1} = std(values, 0, 'omitnan');
        end
    end
    results.summaryTable = cell2table(summaryRows, 'VariableNames', summaryNames);
    results.methods = methods;
    results.metricNames = metricNames;
    results.metricValues = metricValues;
    results.seeds = seeds;
end

function saveRepeatedResults(results)
    outDir = repeatedModelFile();
    if exist(outDir, 'dir') ~= 7
        mkdir(outDir);
    end
    outFile = repeatedModelFile('repeatedClusterComparison.mat');
    save(outFile, 'results');
    fprintf('\nSaved:\n');
    fprintf('  %s\n', outFile);
end

function weightTable = buildWfcmWeightTable(seeds, weights, scores)
    weightTable = array2table([seeds(:), weights, scores(:)], ...
        'VariableNames', {'seed', 'w_u', 'w_v', 'w_r', ...
                          'w_tau_X', 'w_tau_N', 'ga_score'});
end

function printSummary(results)
    fprintf('\n=== Mean +/- std across repeated runs ===\n');
    for i = 1:height(results.summaryTable)
        method = results.summaryTable.method{i};
        fprintf('\n%s\n', method);
        for j = 1:numel(results.metricNames)
            metricName = results.metricNames{j};
            mu = results.summaryTable{i, [metricName '_mean']};
            sigma = results.summaryTable{i, [metricName '_std']};
            fprintf('  %-12s %.6f +/- %.6f\n', metricName, mu, sigma);
        end
    end
end

function printWfcmWeights(weights, scores)
    fprintf('\n=== WFCM GA best weights by run ===\n');
    for i = 1:size(weights, 1)
        fprintf('  run %02d: [%s], score=%.6f\n', ...
            i, sprintf('%.4g ', weights(i, :)), scores(i));
    end
    fprintf('  mean : [%s]\n', sprintf('%.4g ', mean(weights, 1, 'omitnan')));
    fprintf('  std  : [%s]\n', sprintf('%.4g ', std(weights, 0, 1, 'omitnan')));
end

function printBestRuns(best)
    fprintf('\n=== Best run used for validation plot ===\n');
    for i = 1:numel(best)
        fprintf('  %s: run %02d, tag=%s, score(uvr_norm)=%.6f\n', ...
            best(i).method, ...
            best(i).run, ...
            best(i).tag, ...
            best(i).score);
    end
end

function promoteBestRuns(best)
    fprintf('\n=== Best repeated models promoted for MPC ===\n');
    for i = 1:numel(best)
        promoteClusterTag(best(i).tag, officialTagForMethod(best(i).method));
    end
end

function targetTag = officialTagForMethod(method)
    if contains(lower(method), 'kmeans')
        targetTag = 'KMEANS';
    else
        targetTag = 'FCM';
    end
end

function promoteClusterTag(sourceTag, targetTag)
    copyTaggedDataFiles(sourceTag, targetTag);
    copyTaggedModelFiles(sourceTag, targetTag);
    buildStateModels(sourceTag);
    sourceStatePath = stateModelFile(['StateModelCluster' sourceTag '.mat']);
    targetStatePath = stateModelFile(['StateModelCluster' targetTag '.mat']);
    copyfile(sourceStatePath, targetStatePath, 'f');
    fprintf('  Promoted %s to %s for MPC: %s\n', ...
        sourceTag, targetTag, targetStatePath);
end

function copyTaggedDataFiles(sourceTag, targetTag)
    stems = {'cluster_index', 'clusters', 'clusterTail'};
    for i = 1:numel(stems)
        sourcePath = dataFile([stems{i} '_' sourceTag '.mat']);
        targetPath = dataFile([stems{i} '_' targetTag '.mat']);
        copyfile(sourcePath, targetPath, 'f');
    end
end

function copyTaggedModelFiles(sourceTag, targetTag)
    for k = 1:100
        sourceU = modelArtifactFile(sprintf('modeluCluster%d_%s.mat', k, sourceTag));
        if exist(sourceU, 'file') ~= 2
            break;
        end
        copyfile(sourceU, ...
            modelArtifactFile(sprintf('modeluCluster%d_%s.mat', k, targetTag)), 'f');
        copyfile(modelArtifactFile(sprintf('modelvCluster%d_%s.mat', k, sourceTag)), ...
                 modelArtifactFile(sprintf('modelvCluster%d_%s.mat', k, targetTag)), 'f');
        copyfile(modelArtifactFile(sprintf('modelrCluster%d_%s.mat', k, sourceTag)), ...
                 modelArtifactFile(sprintf('modelrCluster%d_%s.mat', k, targetTag)), 'f');
    end
end

function packageRepeatedModels(modelTags)
    repeatedClusterModels = struct();
    repeatedClusterModels.source = artifactSourceName();
    repeatedClusterModels.created_at = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    repeatedClusterModels.note = ...
        'Each run stores clusterTail and linear LSSVM coefficients for repeated validation.';
    repeatedClusterModels.FCM = packageMethodRuns(modelTags(:, 1));
    repeatedClusterModels.KMEANS = packageMethodRuns(modelTags(:, 2));
    outDir = repeatedModelFile();
    if exist(outDir, 'dir') ~= 7
        mkdir(outDir);
    end
    outFile = repeatedModelFile('repeatedClusterModels.mat');
    save(outFile, 'repeatedClusterModels');
    fprintf('\nAggregated repeated models:\n');
    fprintf('  %s\n', outFile);
end

function methodPackage = packageMethodRuns(tags)
    tags = tags(:)';
    methodPackage = struct();
    methodPackage.tags = tags;
    methodPackage.runs = repmat(emptyRepeatedRun(), 1, numel(tags));
    for i = 1:numel(tags)
        tag = tags{i};
        tailFile = load(dataFile(['clusterTail_' tag '.mat']), 'clusterTail');
        clusterTail = tailFile.clusterTail;
        methodPackage.runs(i).tag = tag;
        methodPackage.runs(i).clusterTail = clusterTail;
        methodPackage.runs(i).models = loadClusterLssvmModels(tag, size(clusterTail.CENTER, 1));
    end
end

function run = emptyRepeatedRun()
    run = struct( ...
        'tag', '', ...
        'clusterTail', [], ...
        'models', []);
end

function cleanupRepeatedRunArtifacts(modelTags)
    fprintf('\nCleaning scattered repeated-run files after aggregation...\n');
    tags = unique(modelTags(:));
    tags = tags(~cellfun('isempty', tags));
    for i = 1:numel(tags)
        deleteTaggedArtifacts(tags{i});
    end
    fprintf('  kept official FCM/KMEANS models and aggregated repeat package only.\n');
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

function backup = backupGenericClusterFiles()
    files = {
        dataFile('cluster_index.mat'), ...
        dataFile('clusters.mat'), ...
        dataFile('clusterTail.mat')
    };
    backup = repmat(struct('path', '', 'existed', false, 'bytes', []), numel(files), 1);
    for i = 1:numel(files)
        backup(i).path = files{i};
        backup(i).existed = exist(files{i}, 'file') == 2;
        if backup(i).existed
            backup(i).bytes = filereadBinary(files{i});
        end
    end
end

function restoreGenericClusterFiles(backup)
    for i = 1:numel(backup)
        if backup(i).existed
            writeBinary(backup(i).path, backup(i).bytes);
        elseif exist(backup(i).path, 'file') == 2
            delete(backup(i).path);
        end
    end
end

function bytes = filereadBinary(path)
    fid = fopen(path, 'rb');
    if fid < 0
        error('Cannot open file for reading: %s', path);
    end
    cleaner = onCleanup(@() fclose(fid));
    bytes = fread(fid, inf, '*uint8');
    clear cleaner
end

function writeBinary(path, bytes)
    fid = fopen(path, 'wb');
    if fid < 0
        error('Cannot open file for writing: %s', path);
    end
    cleaner = onCleanup(@() fclose(fid));
    fwrite(fid, bytes, 'uint8');
    clear cleaner
end
