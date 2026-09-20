function result = runMpcExperimentCore(doPlot)
% runMpcExperimentCore  Run the shared closed-loop MPC simulation core.
%
% doPlot=true saves latestMpcResult.mat and opens the overview figure.

    if ~exist('doPlot', 'var') || isempty(doPlot)
        doPlot = false;
    end
    cfg = defaultExperimentConfig();
    setenv('MPC_DATA_SOURCE', cfg.data.source);
    modelSource = 'mss';
    models = loadMpcModels(modelSource);
    clusters = models.clusters;
    param = config_simulation();
    param = applyMpcEnvironmentOverride(param);
    Ts = param.Ts;
    Nsim = param.N_sim;
    ctrlNames = mpcControllerNames();
    V0 = param.V0;
    x = struct();
    x2 = struct();
    xi = struct();
    xt = struct();
    u = struct();
    for name = ctrlNames
        n = name{1};
        x.(n) = V0;
        x2.(n) = zeros(6, 1);
        xi.(n) = [zeros(4, 1); V0(1); V0(6)];
        xt.(n) = [V0(1); V0(2); V0(3); V0(6)];
        u.(n) = [100; 0];
    end
    [Phi, Gamma, H, lb, ub, Cblk, Qblk] = ...
        computeIncrementalStateSpaceModel(models.nc.A, models.nc.B, param, models.nc.b);
    param_nc = packMpcParams(param, Phi, Gamma, H, lb, ub, Cblk, Qblk);
    [Phi, Gamma, H, lb, ub, Cblk, Qblk] = ...
        computeIncrementalStateSpaceModel(models.gp.A, models.gp.B, param, models.gp.b);
    param_gp = packMpcParams(param, Phi, Gamma, H, lb, ub, Cblk, Qblk);
    if strcmpi(param.mode, 'curve')
        curve_ref = generateCurveReference(param.curve);
        wpt = struct('pos', struct('x', curve_ref.x, 'y', curve_ref.y));
        fprintf('Curve guidance: %s, los_delta=%.1f\n', ...
            getStructField(param.curve, 'guidance', 'frenet_los'), ...
            getStructField(param.curve, 'los_delta', 18));
    elseif strcmpi(param.mode, 'heading')
        wpt = struct('pos', struct('x', [], 'y', []));
        curve_ref = [];
        psi_seq = generateHeadingReference(param, Nsim, Ts);
    else
        error('runRepeatedMpcStats:UnknownMode', ...
            'Unknown param.mode: %s. Use ''curve'' or ''heading''.', param.mode);
    end
    mss_st = [];
    active = struct();
    finish_step = struct();
    for name = ctrlNames
        n = name{1};
        active.(n) = true;
        finish_step.(n) = Nsim;
    end
    psi_ref = struct();
    path_err = struct();
    t_solve = struct();
    v = struct();
    ulog = struct();
    mp_mem = zeros(1, Nsim);
    for name = ctrlNames
        n = name{1};
        psi_ref.(n) = zeros(1, Nsim);
        path_err.(n) = nan(1, Nsim);
        t_solve.(n) = zeros(1, Nsim);
        v.(n) = zeros(6, Nsim);
        ulog.(n) = zeros(2, Nsim);
    end
    fprintf('Starting MPC: %d steps, %d controllers\n', Nsim, numel(ctrlNames));
    for k = 1:Nsim
        mp = param.mp_base + param.mp_amp * sin(param.mp_freq * k * Ts) ...
            + param.mp_noise * (rand(1) - 0.5);
        mp = min(max(mp, param.mp_min), param.mp_max);
        mp_mem(k) = mp;
        if strcmpi(param.mode, 'curve')
            for name = ctrlNames
                n = name{1};
                if active.(n)
                    [psi_ref.(n)(k), path_err.(n)(k)] = curveGuidance(x.(n), curve_ref, param.curve);
                else
                    psi_ref.(n)(k) = nan;
                    path_err.(n)(k) = nan;
                end
            end
        elseif strcmpi(param.mode, 'heading')
            for name = ctrlNames
                n = name{1};
                if active.(n)
                    psi_ref.(n)(k) = psi_seq(k);
                else
                    psi_ref.(n)(k) = nan;
                end
            end
        end
        u_applied = u;
        u_cmd = u;
        if active.fcm
            ci = clusters.FCM.cInfo;
            nd5 = [x.fcm(1), x.fcm(2), x.fcm(3), u_applied.fcm(1), u_applied.fcm(2)];
            nd = normalizeClusterPoint(nd5, ci);
            fw = getFeatureWeights(ci);
            mem_fcm = computeClusterMembership(2, ci.CENTER, nd, ci.method, ci.F_cov, fw);
            mem_fcm = sharpenMembership(mem_fcm, ci.fusion_beta);
        end
        if active.kmeans
            ci = clusters.KMEANS.cInfo;
            nd5 = [x.kmeans(1), x.kmeans(2), x.kmeans(3), u_applied.kmeans(1), u_applied.kmeans(2)];
            nd = normalizeClusterPoint(nd5, ci);
            kmeans_id = selectHardCluster(nd, ci);
        end
        if active.nc
            [du, ~, t_solve.nc(k)] = solveDeltaU(xi.nc, psi_ref.nc(k), u_applied.nc, param_nc);
            u_cmd.nc = u_applied.nc + du;
        else
            t_solve.nc(k) = nan;
        end
        if active.fcm
            [du, t_solve.fcm(k)] = solveFusedMPC(xi.fcm, psi_ref.fcm(k), u_applied.fcm, ...
                clusters.FCM, mem_fcm, param);
            u_cmd.fcm = u_applied.fcm + du;
        else
            t_solve.fcm(k) = nan;
        end
        if active.kmeans
            [du, t_solve.kmeans(k)] = solveSingleClusterMPC(xi.kmeans, psi_ref.kmeans(k), ...
                u_applied.kmeans, clusters.KMEANS, kmeans_id, param);
            u_cmd.kmeans = u_applied.kmeans + du;
        else
            t_solve.kmeans(k) = nan;
        end
        if active.gp
            [du, ~, t_solve.gp(k)] = solveDeltaU(xi.gp, psi_ref.gp(k), u_applied.gp, param_gp);
            u_cmd.gp = u_applied.gp + du;
        else
            t_solve.gp(k) = nan;
        end
        if active.mss
            [u_cmd.mss, ~, mss_st] = mssOtterController(x.mss(1), x.mss(6), ...
                x.mss(3), param.u_ref, psi_ref.mss(k), Ts, param.K_u, mss_st, param);
        end
        for name = ctrlNames
            n = name{1};
            if ~active.(n)
                v.(n)(:, k) = nan;
                ulog.(n)(:, k) = nan;
                continue;
            end
            for j = 1:(Ts / 0.05)
                current_cmd = currentDisturbanceAt(x.(n), param.wave, k * Ts);
                [x.(n), x2.(n)] = otter3DOF(x.(n), x2.(n), ...
                    0.05, u_applied.(n), current_cmd, mp);
            end
            v.(n)(:, k) = x.(n);
            ulog.(n)(:, k) = u_applied.(n);
            xn = [x.(n)(1); x.(n)(2); x.(n)(3); x.(n)(6)];
            xi.(n) = [xn - xt.(n); xn(1); xn(4)];
            xt.(n) = xn;
            u.(n) = u_cmd.(n);
        end
        if strcmpi(param.mode, 'curve')
            for name = ctrlNames
                n = name{1};
                if active.(n)
                    [psi_ref.(n)(k), path_err.(n)(k)] = curveGuidance(x.(n), curve_ref, param.curve);
                    if isCurveComplete(x.(n), curve_ref, param.curve)
                        active.(n) = false;
                        finish_step.(n) = k;
                    end
                end
            end
            all_finished = true;
            for name = ctrlNames
                all_finished = all_finished && ~active.(name{1});
            end
            if all_finished
                fprintf('All controllers completed the curve at t=%.2f s (%d steps).\n', k * Ts, k);
                break;
            end
        end
    end
    Ndone = k;
    if Ndone < size(mp_mem, 2)
        mp_mem = mp_mem(1:Ndone);
        for name = ctrlNames
            n = name{1};
            psi_ref.(n) = psi_ref.(n)(1:Ndone);
            path_err.(n) = path_err.(n)(1:Ndone);
            t_solve.(n) = t_solve.(n)(1:Ndone);
            v.(n) = v.(n)(:, 1:Ndone);
            ulog.(n) = ulog.(n)(:, 1:Ndone);
        end
    end
    t = (0:Ndone-1) * Ts;
    result = buildMpcResultStruct(t, v, psi_ref, path_err, ulog, t_solve, ...
        wpt, param.mode, mp_mem, param, finish_step, modelSource);
    result.Ndone = Ndone;
    result.modelSource = modelSource;

    if doPlot
        resultFile = saveMPCResult(t, v, psi_ref, path_err, ulog, t_solve, ...
            wpt, param.mode, mp_mem, param, finish_step, modelSource);
        plotMPCResultFile(resultFile);
    end
end

