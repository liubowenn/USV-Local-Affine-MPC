function fig = plotMPCResultFile(resultFile)
    if ~exist('resultFile', 'var') || isempty(resultFile)
        param = config_simulation();
        resultFile = mpcResultFile('latestMpcResult.mat', [], mpcScenarioName(param));
    end
    result = loadMpcResultStruct(resultFile);
    result.metrics = computeMpcResultMetrics(result);
    printMpcResultMetrics(result.metrics);
    param = getStructField(result, 'param', struct());
    param.result_source = inferMpcPlotSource(result, resultFile);
    fig = plotMPCResults( ...
        result.t, ...
        result.v, ...
        result.psi_ref, ...
        result.path_err, ...
        result.ulog, ...
        result.t_solve, ...
        result.wpt, ...
        result.mode, ...
        getStructField(result, 'mp_mem', []), ...
        param);
end

function result = loadMpcResultStruct(resultFile)
    if exist(resultFile, 'file') ~= 2
        error('plotMPCResultFile:FileNotFound', ...
            'MPC result file not found: %s', resultFile);
    end
    s = load(resultFile);
    if isfield(s, 'mpcResult')
        result = s.mpcResult;
    else
        result = s;
    end
    required = {'t', 'v', 'psi_ref', 'path_err', 'ulog', 't_solve', 'wpt', 'mode'};
    missing = required(~cellfun(@(f) isfield(result, f), required));
    if ~isempty(missing)
        error('plotMPCResultFile:InvalidFile', ...
            'MPC result file is missing fields: %s', strjoin(missing, ', '));
    end
end

