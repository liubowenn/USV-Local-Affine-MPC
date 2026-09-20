function metrics = computeMpcResultMetrics(result)
% computeMpcResultMetrics  Compute all closed-loop MPC metrics from a result.
% The output is scalar/table-friendly so it can be printed, saved, and averaged.

    names = mpcControllerNames();
    labels = cellfun(@mpcMethodLabel, names, 'UniformOutput', false);
    param = getStructField(result, 'param', struct());
    Ts = getStructField(result, 'Ts', getStructField(param, 'Ts', nan));

    metrics = struct();
    metrics.controller_names = names;
    metrics.method_labels = labels;
    metrics.mode = getStructField(result, 'mode', getStructField(param, 'mode', 'heading'));
    metrics.track_u = getStructField(param, 'mpc_track_u', false);
    metrics.table = table();
    metrics.by_controller = struct();

    rows = cell(numel(names), 1);
    for i = 1:numel(names)
        key = names{i};
        row = controllerMetrics(result, key, Ts);
        metrics.by_controller.(key) = row;
        rows{i} = metricRow(labels{i}, row);
    end

    metrics.table = vertcat(rows{:});
    metrics.best = selectBestMpcRunController(metrics, 'fcm');
end

function row = controllerMetrics(result, key, Ts)
    row = struct();
    row.heading_mae_deg = nan;
    row.heading_iae_deg_s = nan;
    row.surge_mae_mps = nan;
    row.surge_iae_m = nan;
    row.cross_track_mae_m = nan;
    row.cross_track_iae_m_s = nan;
    row.finish_time_s = nan;
    row.qp_mean_ms = nan;
    row.qp_std_ms = nan;
    row.qp_max_ms = nan;

    if isfield(result.v, key) && isfield(result.psi_ref, key)
        psi = result.v.(key)(6, :);
        psiRef = result.psi_ref.(key);
        n = min(numel(psi), numel(psiRef));
        idx = isfinite(psi(1:n)) & isfinite(psiRef(1:n));
        if any(idx)
            err = atan2( ...
                sin(psi(idx) - psiRef(idx)), ...
                cos(psi(idx) - psiRef(idx))) * 180/pi;
            [row.heading_mae_deg, row.heading_iae_deg_s] = maeIae(err, Ts);
        end
    end

    param = getStructField(result, 'param', struct());
    if getStructField(param, 'mpc_track_u', false) && isfield(result.v, key)
        surge = result.v.(key)(1, :);
        idx = isfinite(surge);
        uRef = getStructField(param, 'u_ref', nan);
        if any(idx) && isfinite(uRef)
            err = surge(idx) - uRef;
            [row.surge_mae_mps, row.surge_iae_m] = maeIae(err, Ts);
        end
    end

    if strcmpi(getStructField(result, 'mode', ''), 'curve')
        if isfield(result.finish_step, key)
            row.finish_time_s = result.finish_step.(key) * Ts;
        end
        if isfield(result.path_err, key)
            e = result.path_err.(key);
            e = e(isfinite(e));
            [row.cross_track_mae_m, row.cross_track_iae_m_s] = maeIae(e, Ts);
        end
    end

    if isfield(result.t_solve, key) && ~strcmpi(key, 'mss')
        tq = result.t_solve.(key) * 1000;
        tq = tq(isfinite(tq));
        if ~isempty(tq)
            row.qp_mean_ms = mean(tq);
            row.qp_std_ms = std(tq);
            row.qp_max_ms = max(tq);
        end
    end
end

function T = metricRow(methodLabel, row)
    T = struct2table(row, 'AsArray', true);
    T = addvars(T, string(methodLabel), 'Before', 1, 'NewVariableNames', 'method');
end

function best = selectBestMpcRunController(metrics, key)
    row = metrics.by_controller.(key);
    score = row.heading_mae_deg;
    if strcmpi(metrics.mode, 'curve') && isfinite(row.cross_track_mae_m)
        score = score + row.cross_track_mae_m;
    end
    if metrics.track_u && isfinite(row.surge_mae_mps)
        score = score + row.surge_mae_mps;
    end
    best = struct( ...
        'controller', key, ...
        'method', mpcMethodLabel(key), ...
        'score', score, ...
        'score_note', 'heading MAE + optional cross-track MAE + optional surge-speed MAE');
end

function [mae, iae] = maeIae(err, Ts)
    if isempty(err) || all(~isfinite(err))
        mae = nan;
        iae = nan;
        return;
    end
    err = err(isfinite(err));
    mae = mean(abs(err));
    iae = sum(abs(err)) * Ts;
end
