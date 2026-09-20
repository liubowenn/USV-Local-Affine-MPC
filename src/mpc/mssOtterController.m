function [tau_cmd, tau_N, state] = mssOtterController(u, psi, r, u_ref, psi_ref, Ts, K_u, state, limits)
    if ~exist('state', 'var') || isempty(state)
        state = struct('integral_psi', 0, 'last_tau_X', 100, ...
                       'last_tau_N', 0, 'integral_u', 0, 'prev_e_u', 0);
    end
    if ~exist('limits', 'var') || isempty(limits)
        limits.u_min = [80; -30];
        limits.u_max = [120; 30];
        limits.Du_lim = 20;
    end
    if ~isfield(state, 'integral_psi'), state.integral_psi = 0; end
    if ~isfield(state, 'last_tau_X'), state.last_tau_X = 100; end
    if ~isfield(state, 'last_tau_N'), state.last_tau_N = 0; end
    if ~isfield(state, 'integral_u'), state.integral_u = 0; end
    if ~isfield(state, 'prev_e_u'), state.prev_e_u = 0; end

    T = 1;
    m = 41.4;
    wn = 1.5;
    zeta = 1;
    Kp = m * wn^2;
    Kd = m * (2 * zeta * wn - 1 / T);
    Ti = 10 / wn;
    Ki = Kp / Ti;

    e_psi = wrapPiLocal(psi_ref - psi);
    state.integral_psi = state.integral_psi + e_psi * Ts;
    state.integral_psi = max(min(state.integral_psi, 2), -2);

    e_u = u_ref - u;
    state.integral_u = state.integral_u + e_u * Ts;
    derivative_u = (e_u - state.prev_e_u) / Ts;

    tau_X_raw = 100 + K_u(1) * e_u + K_u(2) * state.integral_u + K_u(3) * derivative_u;
    tau_N_raw = Kp * e_psi - Kd * r + Ki * state.integral_psi;

    tau_prev = [state.last_tau_X; state.last_tau_N];
    tau_raw = [tau_X_raw; tau_N_raw];
    delta_tau = tau_raw - tau_prev;
    delta_tau = max(min(delta_tau, limits.Du_lim), -limits.Du_lim);
    tau_cmd = tau_prev + delta_tau;
    tau_cmd = max(min(tau_cmd, limits.u_max(:)), limits.u_min(:));

    tau_N = tau_cmd(2);
    state.last_tau_X = tau_cmd(1);
    state.last_tau_N = tau_cmd(2);
    state.prev_e_u = e_u;
end

function angle = wrapPiLocal(angle)
    angle = atan2(sin(angle), cos(angle));
end



