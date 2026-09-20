function [du, du_seq, solve_time] = solveDeltaU(xi, psi_ref, u_prev, param)
    % Solve one receding-horizon QP and return the first input increment.
    %
    % xi is the augmented incremental state from runMpcSimulation.
    % The reference vector follows the selected output dimension:
    %   heading only, or [u_ref; psi_ref].
    Phi   = param.Phi;
    Gamma = param.Gamma;
    H     = param.H;
    lb    = param.lb;
    ub    = param.ub;
    Cblk  = param.Cblk;
    Qblk  = param.Qblk;
    opts  = param.opts;
    Np    = param.Np;
    Du_lim = param.Du_lim(:);
    if isscalar(Du_lim)
        Du_lim = repmat(Du_lim, 2, 1);
    end
    u_min = param.u_min(:);
    u_max = param.u_max(:);
    nu     = 2;
    ny = size(Cblk, 1) / Np;
    if ny == 1
        ref = psi_ref * ones(Np, 1);
    elseif ny == 2
        % Output order must match Cbar: [surge speed; heading].
        ref = repmat([param.u_ref; psi_ref], Np, 1);
    else
        error('solveDeltaU:InvalidOutputSize', ...
            'Unsupported MPC output dimension: %d.', ny);
    end
    f   = Gamma' * Cblk' * Qblk * (Cblk * (Phi * xi) - ref);

    % Bound yaw-moment increments separately from the global box limits.
    Aineq_du2 = zeros(2*Np, nu*Np);
    bineq_du2 = Du_lim(2) * ones(2*Np, 1);
    for k = 1:Np
        j = (k-1)*nu + 2;
        Aineq_du2(2*k-1, j) =  1;
        Aineq_du2(2*k,   j) = -1;
    end

    % Convert input increments into absolute input constraints.
    S      = kron(tril(ones(Np)), eye(nu));
    ub_abs = repmat(u_max, Np, 1);
    lb_abs = repmat(u_min, Np, 1);
    ub_vec = ub_abs - repmat(u_prev, Np, 1);
    lb_vec = lb_abs - repmat(u_prev, Np, 1);
    Aineq_abs = [S; -S];
    bineq_abs = [ub_vec; -lb_vec];
    Aineq = [Aineq_du2; Aineq_abs];
    bineq = [bineq_du2; bineq_abs];
    solver = lower(getStructField(param, 'qp_solver', 'quadprog'));
    tic
    switch solver
        case 'osqp'
            du_seq = solveWithOsqp(H, f, Aineq, bineq, lb, ub, param);
        case 'quadprog'
            du_seq = quadprog(H, f, Aineq, bineq, [], [], lb, ub, [], opts);
        otherwise
            error('solveDeltaU:UnknownSolver', ...
                'Unknown QP solver: %s. Use ''osqp'' or ''quadprog''.', solver);
    end
    solve_time = toc;
    if isempty(du_seq)
        error('solveDeltaU: QP infeasible at current step.');
    end
    du = du_seq(1:nu);
end

function x = solveWithOsqp(H, f, Aineq, bineq, lb, ub, param)
    if exist('osqp', 'class') ~= 8 && exist('osqp', 'file') ~= 2
        error('solveDeltaU:OsqpNotFound', ...
            'OSQP is not on the MATLAB path. Add external/osqp-matlab to the path.');
    end

    n = numel(f);
    P = sparse(0.5 * (H + H.'));
    q = full(f(:));

    % OSQP uses two-sided constraints l <= A*x <= u.
    A = sparse([speye(n); Aineq]);
    l = [lb(:); -inf(size(bineq(:)))];
    u = [ub(:); bineq(:)];

    settings = osqpSettings(getStructField(param, 'osqp', struct()));
    solver = osqp;
    solver.setup(P, q, A, l, u, settings);
    result = solver.solve();

    status = lower(char(result.info.status));
    if ~(strcmp(status, 'solved') || strcmp(status, 'solved inaccurate'))
        error('solveDeltaU:OsqpFailed', ...
            'OSQP failed with status: %s.', result.info.status);
    end

    x = result.x;
end

function settings = osqpSettings(userSettings)
    settings = osqp.default_settings();
    settings.verbose = logical(getStructField(userSettings, 'verbose', false));
    settings.eps_abs = getStructField(userSettings, 'eps_abs', 1e-4);
    settings.eps_rel = getStructField(userSettings, 'eps_rel', 1e-4);
    settings.max_iter = getStructField(userSettings, 'max_iter', 4000);
    settings.polish = logical(getStructField(userSettings, 'polish', true));
    settings.warm_start = true;
end

