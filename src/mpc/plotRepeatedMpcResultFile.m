function fig = plotRepeatedMpcResultFile(repeatedFile)
% plotRepeatedMpcResultFile  Print repeated metrics and plot the best run.

    if ~exist('repeatedFile', 'var') || isempty(repeatedFile)
        param = config_simulation();
        repeatedFile = mpcResultFile('repeatedMpcResults.mat', [], mpcScenarioName(param));
    end

    if exist(repeatedFile, 'file') ~= 2
        error('plotRepeatedMpcResultFile:FileNotFound', ...
            'Repeated MPC result file not found: %s', repeatedFile);
    end

    s = load(repeatedFile, 'mpcRepeatedResult');
    if ~isfield(s, 'mpcRepeatedResult')
        error('plotRepeatedMpcResultFile:InvalidFile', ...
            'File must contain variable mpcRepeatedResult.');
    end

    repeated = s.mpcRepeatedResult;
    printRepeatedMpcMetrics(repeated);

    if isfield(repeated, 'best_result_file') && exist(repeated.best_result_file, 'file') == 2
        fig = plotMPCResultFile(repeated.best_result_file);
        return;
    end

    bestIdx = repeated.best_run.run_index;
    result = repeated.runs{bestIdx}.mpcResult;
    printMpcResultMetrics(result);
    param = getStructField(result, 'param', struct());
    param.result_source = inferMpcPlotSource(result, repeatedFile, getStructField(repeated, 'source', ''));
    fig = plotMPCResults( ...
        result.t, result.v, result.psi_ref, result.path_err, result.ulog, ...
        result.t_solve, result.wpt, result.mode, ...
        getStructField(result, 'mp_mem', []), ...
        param);
end
