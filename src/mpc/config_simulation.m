function param = config_simulation()
% config_simulation  Build the default closed-loop MPC configuration.
%
% This is the main parameter entry point for closed-loop experiments.
% Curve presets are maintained in curveScenarioPreset.m.

    % Basic MPC settings.
    param.Ts = 0.1;
    param.Np = 30;
    param.N_sim = 300;

    % Tracking weights.
    % mpc_track_u=false: heading-only MPC.
    % mpc_track_u=true : track heading and surge speed.
    param.Qpsi = 500;
    param.mpc_track_u = false;
    param.Qu = 50;

    % Input smoothness and actuator limits for [tau_X; tau_N].
    param.Rdu = [0.5 0; 0 0.05];
    param.Du_lim = [10; 5];
    param.u_min = [80; -30];
    param.u_max = [120; 30];

    % QP solver: 'osqp' or 'quadprog'.
    param.qp_solver = 'osqp';
    param.osqp.eps_abs = 1e-4;
    param.osqp.eps_rel = 1e-4;
    param.osqp.max_iter = 4000;
    param.osqp.polish = true;
    param.osqp.verbose = false;

    % Nomoto-tuned PID and initial state.
    % V0 = [u; v; r; x; y; psi]. Angles are stored in radians.
    param.K_u = [15, 0.10, 0.8];
    param.u_ref = 1.2;
    param.V0 = [0; 0; 0; 0; 0; 0];

    % Current disturbance model.
    % mode='temporal': same time-varying current everywhere.
    % mode='spatial' : current depends on the vessel position [x, y].
    % If wave.enabled=true and mode='spatial', result-file plotting draws it.
    param.wave.enabled = true;
    param.wave.mode = 'spatial';
    param.wave.V_c0 = 0.15;
    param.wave.V_c_amp = 0.08;
    param.wave.V_c_amp2 = 0.03;
    param.wave.beta_c0 = pi / 6;
    param.wave.beta_amp = pi / 12;
    param.wave.freq1 = 0.015;
    param.wave.freq2 = 0.037;
    param.wave.x_lim = [-5 55];
    param.wave.y_lim = [-25 30];
    param.wave.x_wavelength = 45;
    param.wave.y_wavelength = 35;

    param.opts = optimoptions('quadprog', 'Display', 'off');

    % Simulation mode: 'heading' or 'curve'.
    param.mode = 'heading';

    % Curve tracking case. Change only this name to select a curve case.
    % Available: sine_s, circle, rising_peak_sine_s, strong_current_s,
    % heavy_payload_s.
    param.curve.name = 'sine_s';
    param = applyCurveScenario(param, param.curve.name);

    % Heading tracking cases:
    % sine, sine_decay, sine_rise, multi_sine, multi_sine_decay.
    param.heading_ref_type = 'multi_sine';
    param.psi_sine_offset = 0;

    % Single-sine parameters.
    param.psi_sine_amp = deg2rad(30);
    param.psi_sine_period = 20;
    param.psi_sine_decay_time = 20;
    param.psi_sine_rise_time = 20;

    % Multi-sine heading reference.
    % Use heading_ref_type='multi_sine_decay' to apply exp(-lambda*t).
    param.psi_multi_sine_amp = deg2rad([15, 8, 5]);
    param.psi_multi_sine_period = [10, 20, 5];
    param.psi_multi_sine_phase = deg2rad([0, 60, -45]);
    param.psi_multi_sine_decay_lambda = 0.01;

    % Payload variation.
    param.mp_base = 10;
    param.mp_amp = 10;
    param.mp_freq = 0.01;
    param.mp_noise = 1;
    param.mp_min = 10;
    param.mp_max = 25;

    param.V0(6) = normalizeAngleConfig(param.V0(6), 'param.V0(6)');

    fprintf('Simulation config loaded: Ts=%.2f, Np=%d, N_sim=%d\n', ...
            param.Ts, param.Np, param.N_sim);
end

function angle = normalizeAngleConfig(angle, name)
    if abs(angle) > 2*pi
        warning('config_simulation:AngleLooksLikeDegrees', ...
            '%s = %.4g looks like degrees. Converting it to radians.', ...
            name, angle);
        angle = deg2rad(angle);
    end
    angle = atan2(sin(angle), cos(angle));
end

function param = applyCurveScenario(param, name)
    preset = curveScenarioPreset(name);
    param.curve = preset.curve;
    if isfield(preset, 'wave')
        param.wave = mergeStruct(param.wave, preset.wave);
    end
    if isfield(preset, 'mp')
        param = mergeStruct(param, preset.mp);
    end
end

function out = mergeStruct(out, in)
    fields = fieldnames(in);
    for i = 1:numel(fields)
        out.(fields{i}) = in.(fields{i});
    end
end
