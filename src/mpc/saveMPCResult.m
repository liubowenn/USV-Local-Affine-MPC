function resultFile = saveMPCResult(t, v, psi_ref, path_err, ulog, t_solve, wpt, mode, mp_mem, param, finish_step, source)
    if nargin < 11
        finish_step = struct();
    end
    if ~exist('source', 'var') || isempty(source)
        source = artifactSourceName();
    end
    mpcResult = buildMpcResultStruct(t, v, psi_ref, path_err, ulog, ...
        t_solve, wpt, mode, mp_mem, param, finish_step, source);
    outDir = mpcResultFile([], source, mpcResult.scenario);
    if exist(outDir, 'dir') ~= 7
        mkdir(outDir);
    end
    resultFile = mpcResultFile('latestMpcResult.mat', source, mpcResult.scenario);
    save(resultFile, 'mpcResult');
    fprintf('MPC result saved to %s\n', resultFile);
end

