function [data, info] = generateTrainingData(tau_X_nom, N_steps, Ts, mp, visualize)
    if ~exist('tau_X_nom', 'var') || isempty(tau_X_nom), tau_X_nom = 100; end
    if ~exist('N_steps', 'var') || isempty(N_steps), N_steps = 5000; end
    if ~exist('Ts', 'var') || isempty(Ts), Ts = 0.1; end
    if ~exist('mp', 'var') || isempty(mp), mp = 25; end
    if ~exist('visualize', 'var') || isempty(visualize), visualize = true; end
    rng(1);
    V  = [1.5, 0, 0, 0, 0, 0];
    V1 = [0, 0, 0, 0, 0, 0];
    N_total = round(N_steps * 3/2);
    V_mem = zeros(N_total, 6);
    tau_mem = zeros(N_total, 2);
    nn_mem = zeros(N_total, 2);
    dt_inner = 0.05;
    inner_steps = round(Ts / dt_inner);
    if abs(inner_steps * dt_inner - Ts) > 1e-10
        warning('Ts is not an integer multiple of dt_inner. Actual integration time may differ from Ts.');
    end
    min_hold_time = 1;
    max_hold_time = 10;
    tau_X = tau_X_nom + 30 * (rand(1) - 0.5);
    tau_N = 90 * rand(1) - 25;
    change_interval = round((min_hold_time + ...
        (max_hold_time - min_hold_time) * rand(1)) / Ts);
    next_change_step = 1 + change_interval;
    fprintf('Generating training data: %d steps at Ts=%.2f s...\n', N_total, Ts);
    for i = 1:N_total
        if i == next_change_step
            tau_X = tau_X_nom + 30 * (rand(1) - 0.5);
            tau_N = 120 * rand(1) - 60;
            change_interval = round((min_hold_time + ...
                (max_hold_time - min_hold_time) * rand(1)) / Ts);
            next_change_step = i + change_interval;
        end
        V_mem(i, :) = V;
        for j = 1:inner_steps
            [V, V1] = otter3DOF(V, V1, dt_inner, ...
                                [tau_X, tau_N], [0, 0, 0], mp);
        end
        tau_mem(i, :) = [tau_X, tau_N];
        nn_mem(i, :) = thrustAllocation(tau_X, tau_N);
    end
    data = [V_mem, tau_mem];
    dataDir = dataRoot();
    if ~exist(dataDir, 'dir')
        mkdir(dataDir);
    end
    n_train = round(N_total * 2/3);
    data_val  = data(n_train+1:end, :);
    data      = data(1:n_train, :);
    save(dataFile('data.mat'), 'data');
    save(dataFile('data_val.mat'), 'data_val');
    fprintf('Training data: %d steps saved to %s\n', n_train, dataFile('data.mat'));
    fprintf('Validation data: %d steps saved to %s\n', N_total - n_train, dataFile('data_val.mat'));
    info.tau_mem = tau_mem;
    info.nn_mem  = nn_mem;
    info.V_mem   = V_mem;
    info.Ts      = Ts;
    info.min_hold_time = min_hold_time;
    info.max_hold_time = max_hold_time;
    fprintf('Training data saved to %s\n', dataFile('data.mat'));
    if visualize
        plotTrainingData(Ts, N_total, nn_mem, V_mem, tau_mem);
    end
end
function plotTrainingData(Ts, N, nn_mem, V_mem, tau_mem)
    t = Ts:Ts:Ts*N;
    figure('Name', 'Training Data', 'Color', 'w');
    subplot(4, 1, 1);
    plot(t, tau_mem(:, 1), 'LineWidth', 1); hold on; grid on;
    plot(t, tau_mem(:, 2), 'LineWidth', 1);
    legend('\tau_X', '\tau_N');
    ylabel('Thrust / Moment');
    subplot(4, 1, 2);
    plot(t, nn_mem(:, 1), 'LineWidth', 1); hold on; grid on;
    plot(t, nn_mem(:, 2), 'LineWidth', 1);
    legend('n_1', 'n_2');
    ylabel('Propeller speed (rad/s)');
    subplot(4, 1, 3);
    plot(t, V_mem(:, 1), 'Color', '#FEB40B', 'LineWidth', 1); grid on;
    legend('u');
    ylabel('Surge velocity (m/s)');
    subplot(4, 1, 4);
    plot(t, V_mem(:, 2), 'Color', '#518CD8', 'LineWidth', 1); hold on;
    plot(t, V_mem(:, 3) * 180/pi, 'Color', '#FD6D5A', 'LineWidth', 1); grid on;
    legend('v', 'r');
    xlabel('Time (s)');
    ylabel('v (m/s), r (deg/s)');
end


