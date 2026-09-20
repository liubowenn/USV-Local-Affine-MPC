function repeatedFile = saveRepeatedMpcResults(runs, seeds, runWallTime)
% saveRepeatedMpcResults  Save all repeated MPC runs and aggregate metrics.
%
% Saved variable:
%   mpcRepeatedResult.runs{i}.mpcResult  - full result for run i
%   mpcRepeatedResult.runs{i}.metrics    - metrics for run i
%   mpcRepeatedResult.summary            - mean/std tables across runs
%   mpcRepeatedResult.best_run           - best run selected by Ours score
%   mpcRepeatedResult.best_result_file   - bestMpcResult.mat path

    nRuns = numel(runs);
    if nRuns == 0
        error('saveRepeatedMpcResults:EmptyRuns', 'No MPC runs to save.');
    end

    first = runs{1};
    source = getStructField(first, 'source', artifactSourceName());
    scenario = getStructField(first, 'scenario', mpcScenarioName(first.param));

    mpcRepeatedResult = struct();
    mpcRepeatedResult.version = 1;
    mpcRepeatedResult.source = source;
    mpcRepeatedResult.scenario = scenario;
    mpcRepeatedResult.created_at = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    mpcRepeatedResult.n_runs = nRuns;
    mpcRepeatedResult.seeds = seeds(:);
    mpcRepeatedResult.run_wall_time_s = runWallTime(:);
    mpcRepeatedResult.runs = cell(nRuns, 1);

    scores = nan(nRuns, 1);
    metricTables = cell(nRuns, 1);
    for i = 1:nRuns
        run = runs{i};
        run.metrics = computeMpcResultMetrics(run);
        metricTables{i} = run.metrics.table;
        scores(i) = run.metrics.best.score;
        mpcRepeatedResult.runs{i} = struct( ...
            'run_index', i, ...
            'seed', seeds(i), ...
            'wall_time_s', runWallTime(i), ...
            'mpcResult', run, ...
            'metrics', run.metrics);
    end

    [bestScore, bestIdx] = min(scores);
    mpcRepeatedResult.best_run = struct( ...
        'run_index', bestIdx, ...
        'seed', seeds(bestIdx), ...
        'score', bestScore, ...
        'score_note', runs{bestIdx}.metrics.best.score_note);
    mpcRepeatedResult.summary = summarizeRepeatedMpcMetrics(metricTables);

    outDir = mpcResultFile([], source, scenario);
    if exist(outDir, 'dir') ~= 7
        mkdir(outDir);
    end

    repeatedFile = mpcResultFile('repeatedMpcResults.mat', source, scenario);
    save(repeatedFile, 'mpcRepeatedResult', '-v7.3');

    mpcResult = mpcRepeatedResult.runs{bestIdx}.mpcResult;
    bestFile = mpcResultFile('bestMpcResult.mat', source, scenario);
    save(bestFile, 'mpcResult', '-v7.3');
    mpcRepeatedResult.best_result_file = bestFile;
    save(repeatedFile, 'mpcRepeatedResult', '-v7.3');

    fprintf('\nRepeated MPC result saved to %s\n', repeatedFile);
    fprintf('Best run saved to %s\n', bestFile);
end

function summary = summarizeRepeatedMpcMetrics(metricTables)
    methods = metricTables{1}.method;
    numericVars = metricTables{1}.Properties.VariableNames(2:end);
    summary = struct();
    summary.method = methods;

    for v = 1:numel(numericVars)
        name = numericVars{v};
        values = nan(numel(metricTables), height(metricTables{1}));
        for i = 1:numel(metricTables)
            values(i, :) = metricTables{i}.(name);
        end
        summary.([name '_mean']) = mean(values, 1, 'omitnan')';
        summary.([name '_std']) = std(values, 0, 1, 'omitnan')';
        summary.([name '_all']) = values;
    end
end
