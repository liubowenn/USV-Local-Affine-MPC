function mpcResult = buildMpcResultStruct(t, v, psi_ref, path_err, ulog, ...
    t_solve, wpt, mode, mp_mem, param, finish_step, source)
% buildMpcResultStruct  Build the standard saved MPC result structure.
% This same structure is used by single runs, repeated runs, and external logs.

    if nargin < 11 || isempty(finish_step)
        finish_step = struct();
    end
    if ~exist('source', 'var') || isempty(source)
        source = artifactSourceName();
    end

    mpcResult = struct();
    mpcResult.version = 1;
    mpcResult.source = artifactSourceName(source);
    mpcResult.created_at = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    mpcResult.Ts = getStructField(param, 'Ts', inferSampleTime(t));
    mpcResult.t = t;
    mpcResult.v = v;
    mpcResult.psi_ref = psi_ref;
    mpcResult.path_err = path_err;
    mpcResult.ulog = ulog;
    mpcResult.t_solve = t_solve;
    mpcResult.wpt = wpt;
    mpcResult.mode = mode;
    mpcResult.scenario = mpcScenarioName(param);
    mpcResult.mp_mem = mp_mem;
    mpcResult.param = param;
    mpcResult.finish_step = finish_step;
    mpcResult.metrics = computeMpcResultMetrics(mpcResult);
end

function Ts = inferSampleTime(t)
    if numel(t) >= 2
        Ts = median(diff(t));
    else
        Ts = nan;
    end
end
