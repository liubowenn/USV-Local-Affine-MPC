function results = validateModels(visualize, useRepeatedModels)
% validateModels  Run open-loop model prediction validation.
%
% visualize=true draws compact overview figures.
% useRepeatedModels=true evaluates repeated FCM/K-means model packages and
% reports mean +/- std while plotting the best normalized u/v/r run.

    if ~exist('visualize', 'var') || isempty(visualize)
        visualize = true;
    end
    if ~exist('useRepeatedModels', 'var') || isempty(useRepeatedModels)
        useRepeatedModels = false;
    end
    testSuite = loadValidationSuite();
    repeatInfo = discoverRepeatedClusterModels(useRepeatedModels);
    fprintf('Validation source: %s\n', artifactSourceName());
    fprintf('  validation data root: %s\n', dataRoot());
    fprintf('  learned models      : %s\n', modelArtifactFile());
    caseResults = repmat(struct('name', '', 'metrics', []), numel(testSuite), 1);
    plotPacks = repmat(emptyValidationPlotPack(), numel(testSuite), 1);
    if repeatInfo.enabled
        fprintf('\nRepeated validation mode detected: FCM=%d runs, KMeans=%d runs\n', ...
            numel(repeatInfo.fcmTags), numel(repeatInfo.kmeansTags));
        fprintf('Clustered methods report mean +/- std; plots use the best uvr_norm run.\n');
    elseif exist(repeatedModelFile('repeatedClusterModels.mat'), 'file') == 2
        fprintf('\nRepeated model package exists but is disabled; using current official FCM/KMEANS models.\n');
        warnIfOfficialModelsDifferFromRepeatedPackage();
    end
    for i = 1:numel(testSuite)
        fprintf('\n--- Validation case: %s ---\n', testSuite(i).name);
        caseResults(i).name = testSuite(i).name;
        [caseResults(i).metrics, plotPacks(i)] = validateSingleDataset( ...
            testSuite(i).data, testSuite(i).name, repeatInfo);
    end
    results = summarizeValidation(caseResults);
    printSummary(results);
    if visualize
        plotValidationOverview(plotPacks);
    end
end

function warnIfOfficialModelsDifferFromRepeatedPackage()
    packageFile = repeatedModelFile('repeatedClusterModels.mat');
    if exist(packageFile, 'file') ~= 2
        return;
    end

    s = load(packageFile, 'repeatedClusterModels');
    package = s.repeatedClusterModels;

    checkOneMethod(package, 'FCM', 'clusterTail_FCM.mat');
    checkOneMethod(package, 'KMEANS', 'clusterTail_KMEANS.mat');
end

function checkOneMethod(package, methodKey, officialTailName)
    if ~isfield(package, methodKey)
        return;
    end

    officialFile = dataFile(officialTailName, artifactSourceName());
    if exist(officialFile, 'file') ~= 2
        return;
    end

    s = load(officialFile, 'clusterTail');
    officialTail = s.clusterTail;
    methodPackage = package.(methodKey);
    matched = false;

    for i = 1:numel(methodPackage.runs)
        if isequaln(officialTail, methodPackage.runs(i).clusterTail)
            matched = true;
            break;
        end
    end

    if ~matched
        warning('validateModels:OfficialModelNotInRepeatedPackage', ...
            ['Current official %s model is not one of repeatedClusterModels.mat. ', ...
             'validateModels(true) may fall outside validateModels(true,true) statistics. ', ...
             'Rerun runRepeatedClusterComparison or restore the promoted best model.'], ...
            methodKey);
    end
end

function [results, plotPack] = validateSingleDataset(data, caseName, repeatInfo)
    Ts = 0.1;
    [predictions, labels, methodStats] = collectPredictions(data, Ts, repeatInfo);
    results = metricsFromMethodStats(methodStats, labels);
    if any(results.report_std)
        fprintf('\n=== Model Validation (RMSE, repeated methods mean +/- std) ===\n');
        printRmseMeanStdLine('u', results.rmse_u, results.std_u, labels, results.report_std);
        printRmseMeanStdLine('v', results.rmse_v, results.std_v, labels, results.report_std);
        printRmseMeanStdLine('r', results.rmse_r, results.std_r, labels, results.report_std);
        printRmseMeanStdLine('psi', results.rmse_psi, results.std_psi, labels, results.report_std);
        printRmseMeanStdLine('x', results.rmse_x, results.std_x, labels, results.report_std);
        printRmseMeanStdLine('y', results.rmse_y, results.std_y, labels, results.report_std);
        printRmseMeanStdLine('xy', results.rmse_xy, results.std_xy, labels, results.report_std);
        printBestRunLine(methodStats);
    else
        fprintf('\n=== Model Validation (RMSE) ===\n');
        printRmseLine('u', results.rmse_u, labels);
        printRmseLine('v', results.rmse_v, labels);
        printRmseLine('r', results.rmse_r, labels);
        printRmseLine('psi', results.rmse_psi, labels);
        printRmseLine('x', results.rmse_x, labels);
        printRmseLine('y', results.rmse_y, labels);
        printRmseLine('xy', results.rmse_xy, labels);
    end
    plotPack = buildValidationPlotPack(data, predictions, labels, caseName, Ts);
end
function [predictions, labels, methodStats] = collectPredictions(data, Ts, repeatInfo)
    predictions = {};
    labels = {};
    methodStats = repmat(emptyMethodStats(), 0, 1);
    nc = load(modelArtifactFile('modeluNoCluster.mat'), 'modelu');
    nv = load(modelArtifactFile('modelvNoCluster.mat'), 'modelv');
    nr = load(modelArtifactFile('modelrNoCluster.mat'), 'modelr');
    ncModels = struct( ...
        'modelu', nc.modelu, ...
        'modelv', nv.modelv, ...
        'modelr', nr.modelr);
    [pred, ~] = predictLinearLssvm(data, ncModels, Ts);
    predictions{end+1, 1} = pred;
    labels{end+1} = 'Global LSSVM';
    methodStats(end+1, 1) = buildSingleMethodStats( ...
        'Global LSSVM', ...
        pred, ...
        computePredictionMetrics(pred, truthFromData(data(1:end-1, :)), [], Ts));
    [clusterPreds, clusterLabels, clusterStats] = collectClusterPredictions(data, Ts, repeatInfo);
    predictions = [predictions; clusterPreds];
    labels = [labels, clusterLabels];
    methodStats = [methodStats; clusterStats];
    if exist(modelArtifactFile('modelGP.mat'), 'file') == 2
        gpFile = load(modelArtifactFile('modelGP.mat'), 'gpModels');
        [pred, ~] = predictGpModel(data, gpFile.gpModels, Ts);
        predictions{end+1, 1} = pred;
        labels{end+1} = 'Global GP';
        methodStats(end+1, 1) = buildSingleMethodStats( ...
            'Global GP', ...
            pred, ...
            computePredictionMetrics(pred, truthFromData(data(1:end-1, :)), [], Ts));
    else
        warning('validateModels: modelGP.mat not found. GP comparison is skipped.');
    end
end
function [predictions, labels, methodStats] = collectClusterPredictions(data, Ts, repeatInfo)
    labels = {'Ours', 'K-means-LSSVM'};
    predictions = cell(numel(labels), 1);
    methodStats = repmat(emptyMethodStats(), numel(labels), 1);
    if repeatInfo.enabled
        fcmBeta = repeatInfo.fcmBeta;
        [predictions{1}, methodStats(1)] = evaluateRepeatedClusterTags( ...
            data, Ts, repeatInfo.fcmTags, fcmBeta, labels{1}, true, repeatInfo, 'FCM');
        [predictions{2}, methodStats(2)] = evaluateRepeatedClusterTags( ...
            data, Ts, repeatInfo.kmeansTags, 1, labels{2}, true, repeatInfo, 'KMEANS');
        return;
    end
    tags = {'FCM', 'KMEANS'};
    for i = 1:numel(tags)
        tag = tags{i};
        [pred, metric] = evaluateClusterTag(data, Ts, tag, []);
        predictions{i} = pred;
        methodStats(i) = buildSingleMethodStats(labels{i}, pred, metric);
    end
end
function [bestPred, stats] = evaluateRepeatedClusterTags(data, Ts, tags, beta, label, reportStd, repeatInfo, methodKey)
    if ~exist('repeatInfo', 'var') || isempty(repeatInfo)
        repeatInfo = [];
    end
    if ~exist('methodKey', 'var') || isempty(methodKey)
        methodKey = '';
    end
    n = numel(tags);
    metrics = repmat(emptyMetrics(), n, 1);
    scores = zeros(n, 1);
    bestScore = inf;
    bestPred = [];
    bestIdx = 1;
    for i = 1:n
        [pred, metric] = evaluateRepeatedClusterRun( ...
            data, Ts, tags{i}, beta, repeatInfo, methodKey);
        metrics(i) = metric;
        scores(i) = metric.rmse_u_norm + metric.rmse_v_norm + metric.rmse_r_norm;
        if scores(i) < bestScore
            bestScore = scores(i);
            bestPred = pred;
            bestIdx = i;
        end
    end
    if reportStd
        stats = buildRepeatedMethodStats(label, metrics, scores, tags, bestIdx);
    else
        stats = buildBestOnlyMethodStats(label, metrics(bestIdx), scores, tags, bestIdx);
    end
end
function [pred, metric] = evaluateRepeatedClusterRun(data, Ts, tag, beta, repeatInfo, methodKey)
    run = getPackagedRepeatedRun(repeatInfo, methodKey, tag);
    if isempty(run)
        [pred, metric] = evaluateClusterTag(data, Ts, tag, beta);
        return;
    end
    clusterTail = run.clusterTail;
    if ~exist('beta', 'var') || isempty(beta)
        beta = getStructField(clusterTail, 'fusion_beta', 1);
    end
    [pred, truth, switchMask] = predictClusteredLssvm(data, clusterTail, run.models, beta, Ts);
    metric = computePredictionMetrics(pred, truth, switchMask, Ts);
end
function run = getPackagedRepeatedRun(repeatInfo, methodKey, tag)
    run = [];
    if isempty(repeatInfo) || ~isfield(repeatInfo, 'usePackage') || ~repeatInfo.usePackage
        return;
    end
    if ~isfield(repeatInfo.package, methodKey)
        return;
    end
    methodPackage = repeatInfo.package.(methodKey);
    idx = find(strcmp(methodPackage.tags, tag), 1);
    if isempty(idx)
        return;
    end
    run = methodPackage.runs(idx);
end
function [pred, metric] = evaluateClusterTag(data, Ts, tag, beta)
    tailFile = load(dataFile(['clusterTail_' tag '.mat'], artifactSourceName()), 'clusterTail');
    clusterTail = tailFile.clusterTail;
    if ~exist('beta', 'var') || isempty(beta)
        beta = getStructField(clusterTail, 'fusion_beta', 1);
    end
    models = loadClusterLssvmModels(tag, size(clusterTail.CENTER, 1));
    [pred, truth, switchMask] = predictClusteredLssvm(data, clusterTail, models, beta, Ts);
    metric = computePredictionMetrics(pred, truth, switchMask, Ts);
end
function stats = buildSingleMethodStats(label, pred, metric)
    stats = emptyMethodStats();
    stats.label = label;
    stats.best_prediction = pred;
    stats.metrics = metric;
    stats.mean = metric;
    stats.std = zeroMetric(metric);
    stats.tags = {label};
    stats.best_index = 1;
    stats.best_tag = label;
    stats.best_score = metric.rmse_u_norm + metric.rmse_v_norm + metric.rmse_r_norm;
end
function stats = buildRepeatedMethodStats(label, metrics, scores, tags, bestIdx)
    stats = emptyMethodStats();
    stats.label = label;
    stats.metrics = metrics;
    stats.mean = aggregateMetrics(metrics, @mean);
    stats.std = aggregateMetrics(metrics, @std);
    stats.tags = tags;
    stats.best_index = bestIdx;
    stats.best_tag = tags{bestIdx};
    stats.best_score = scores(bestIdx);
    stats.scores = scores;
    stats.report_std = true;
end
function stats = buildBestOnlyMethodStats(label, metric, scores, tags, bestIdx)
    stats = emptyMethodStats();
    stats.label = label;
    stats.metrics = metric;
    stats.mean = metric;
    stats.std = zeroMetric(metric);
    stats.tags = tags;
    stats.best_index = bestIdx;
    stats.best_tag = tags{bestIdx};
    stats.best_score = scores(bestIdx);
    stats.scores = scores;
    stats.report_std = false;
end
function stats = emptyMethodStats()
    stats = struct( ...
        'label', '', ...
        'metrics', [], ...
        'mean', [], ...
        'std', [], ...
        'best_prediction', [], ...
        'tags', {{}}, ...
        'best_index', [], ...
        'best_tag', '', ...
        'best_score', [], ...
        'scores', [], ...
        'report_std', false);
end
function metric = aggregateMetrics(metrics, aggFcn)
    fields = fieldnames(metrics);
    metric = emptyMetrics();
    for i = 1:numel(fields)
        values = arrayfun(@(m) m.(fields{i}), metrics);
        metric.(fields{i}) = aggFcn(values);
    end
end
function metric = zeroMetric(metric)
    fields = fieldnames(metric);
    for i = 1:numel(fields)
        metric.(fields{i}) = 0;
    end
end
function results = metricsFromMethodStats(methodStats, labels)
    n = numel(methodStats);
    results.labels = labels;
    results.rmse_u = zeros(1, n);
    results.rmse_v = zeros(1, n);
    results.rmse_r = zeros(1, n);
    results.rmse_psi = zeros(1, n);
    results.rmse_x = zeros(1, n);
    results.rmse_y = zeros(1, n);
    results.rmse_xy = zeros(1, n);
    results.std_u = zeros(1, n);
    results.std_v = zeros(1, n);
    results.std_r = zeros(1, n);
    results.std_psi = zeros(1, n);
    results.std_x = zeros(1, n);
    results.std_y = zeros(1, n);
    results.std_xy = zeros(1, n);
    results.report_std = false(1, n);
    for i = 1:n
        results.rmse_u(i) = methodStats(i).mean.rmse_u;
        results.rmse_v(i) = methodStats(i).mean.rmse_v;
        results.rmse_r(i) = methodStats(i).mean.rmse_r;
        results.rmse_psi(i) = methodStats(i).mean.rmse_psi;
        results.rmse_x(i) = methodStats(i).mean.rmse_x;
        results.rmse_y(i) = methodStats(i).mean.rmse_y;
        results.rmse_xy(i) = methodStats(i).mean.rmse_xy;
        results.std_u(i) = methodStats(i).std.rmse_u;
        results.std_v(i) = methodStats(i).std.rmse_v;
        results.std_r(i) = methodStats(i).std.rmse_r;
        results.std_psi(i) = methodStats(i).std.rmse_psi;
        results.std_x(i) = methodStats(i).std.rmse_x;
        results.std_y(i) = methodStats(i).std.rmse_y;
        results.std_xy(i) = methodStats(i).std.rmse_xy;
        results.report_std(i) = methodStats(i).report_std;
    end
    results.method_stats = methodStats;
end
function summary = summarizeValidation(caseResults)
    summary.case_results = caseResults;
    summary.labels = caseResults(1).metrics.labels;
    numCases = numel(caseResults);
    numMethods = numel(summary.labels);
    rmse_u = zeros(numCases, numMethods);
    rmse_v = zeros(numCases, numMethods);
    rmse_r = zeros(numCases, numMethods);
    rmse_psi = zeros(numCases, numMethods);
    rmse_x = zeros(numCases, numMethods);
    rmse_y = zeros(numCases, numMethods);
    rmse_xy = zeros(numCases, numMethods);
    for i = 1:numCases
        rmse_u(i, :) = caseResults(i).metrics.rmse_u;
        rmse_v(i, :) = caseResults(i).metrics.rmse_v;
        rmse_r(i, :) = caseResults(i).metrics.rmse_r;
        rmse_psi(i, :) = caseResults(i).metrics.rmse_psi;
        rmse_x(i, :) = caseResults(i).metrics.rmse_x;
        rmse_y(i, :) = caseResults(i).metrics.rmse_y;
        rmse_xy(i, :) = caseResults(i).metrics.rmse_xy;
    end
    summary.rmse_u = mean(rmse_u, 1);
    summary.rmse_v = mean(rmse_v, 1);
    summary.rmse_r = mean(rmse_r, 1);
    summary.rmse_psi = mean(rmse_psi, 1);
    summary.rmse_x = mean(rmse_x, 1);
    summary.rmse_y = mean(rmse_y, 1);
    summary.rmse_xy = mean(rmse_xy, 1);
    summary.report_std = caseResults(1).metrics.report_std;
    summary.std_u = summaryStdAcrossRepeatedRuns(caseResults, 'rmse_u', summary.report_std);
    summary.std_v = summaryStdAcrossRepeatedRuns(caseResults, 'rmse_v', summary.report_std);
    summary.std_r = summaryStdAcrossRepeatedRuns(caseResults, 'rmse_r', summary.report_std);
    summary.std_psi = summaryStdAcrossRepeatedRuns(caseResults, 'rmse_psi', summary.report_std);
    summary.std_x = summaryStdAcrossRepeatedRuns(caseResults, 'rmse_x', summary.report_std);
    summary.std_y = summaryStdAcrossRepeatedRuns(caseResults, 'rmse_y', summary.report_std);
    summary.std_xy = summaryStdAcrossRepeatedRuns(caseResults, 'rmse_xy', summary.report_std);
end

function values = summaryStdAcrossRepeatedRuns(caseResults, metricName, reportStd)
    numCases = numel(caseResults);
    numMethods = numel(caseResults(1).metrics.method_stats);
    values = zeros(1, numMethods);

    for methodIdx = 1:numMethods
        if ~reportStd(methodIdx)
            continue;
        end

        firstMetrics = caseResults(1).metrics.method_stats(methodIdx).metrics;
        numRuns = numel(firstMetrics);
        if numRuns <= 1
            continue;
        end

        runCaseValues = nan(numRuns, numCases);
        for caseIdx = 1:numCases
            metrics = caseResults(caseIdx).metrics.method_stats(methodIdx).metrics;
            if numel(metrics) ~= numRuns
                warning('validateModels:RepeatedRunCountMismatch', ...
                    ['Cannot compute summary std for %s/%s because the ', ...
                     'number of repeated runs differs across cases.'], ...
                    caseResults(caseIdx).metrics.method_stats(methodIdx).label, metricName);
                runCaseValues = [];
                break;
            end

            runCaseValues(:, caseIdx) = arrayfun(@(m) m.(metricName), metrics(:));
        end

        if isempty(runCaseValues)
            values(methodIdx) = nan;
            continue;
        end

        % Compute each repeat's cross-case mean first, then take std across
        % repeats. This is the std of the reported mean RMSE, not the mean of
        % per-case std values.
        runMeanAcrossCases = mean(runCaseValues, 2, 'omitnan');
        values(methodIdx) = std(runMeanAcrossCases, 0, 'omitnan');
    end
end
function printSummary(results)
    fprintf('\n=== Validation Summary: mean RMSE across cases ===\n');
    printRmseMeanStdLine('u', results.rmse_u, results.std_u, results.labels, results.report_std);
    printRmseMeanStdLine('v', results.rmse_v, results.std_v, results.labels, results.report_std);
    printRmseMeanStdLine('r', results.rmse_r, results.std_r, results.labels, results.report_std);
    printRmseMeanStdLine('psi', results.rmse_psi, results.std_psi, results.labels, results.report_std);
    printRmseMeanStdLine('x', results.rmse_x, results.std_x, results.labels, results.report_std);
    printRmseMeanStdLine('y', results.rmse_y, results.std_y, results.labels, results.report_std);
    printRmseMeanStdLine('xy', results.rmse_xy, results.std_xy, results.labels, results.report_std);
end
function printRmseMeanStdLine(name, means, stds, labels, reportStd)
    if ~exist('reportStd', 'var') || isempty(reportStd)
        reportStd = true(size(means));
    end
    fprintf('%8s:', name);
    for i = 1:numel(means)
        if reportStd(i)
            fprintf('   %s=%.4f +/- %.4f', labels{i}, means(i), stds(i));
        else
            fprintf('   %s=%.4f', labels{i}, means(i));
        end
    end
    fprintf('\n');
end
function printRmseLine(name, values, labels)
    fprintf('%8s:', name);
    for i = 1:numel(values)
        fprintf('   %s=%.4f', labels{i}, values(i));
    end
    fprintf('\n');
end
function printBestRunLine(methodStats)
    for i = 1:numel(methodStats)
        if numel(methodStats(i).tags) > 1
            fprintf('  plot best %-12s: %s, score(uvr_norm)=%.4f\n', ...
                methodStats(i).label, methodStats(i).best_tag, methodStats(i).best_score);
        end
    end
end


