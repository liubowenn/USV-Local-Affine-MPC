function [data_25, info] = generateTestData(mode, varargin)
    rng(2);
    if ~exist('mode', 'var') || isempty(mode), mode = 'suite'; end
    p = inputParser;
    p.addParameter('Ts', 0.1);
    p.addParameter('mp', 30);
    p.addParameter('visualize', true);
    p.addParameter('tau_X_nom', 90);
    p.addParameter('N_steps', 200);
    p.parse(varargin{:});
    opts = p.Results;
    ensureDataDir();
    switch lower(mode)
        case 'suite'
            [testSuite, data_25] = generateTestSuite(opts);
            ensureDataDir();
            save(dataFile('testSuite.mat'), 'testSuite');
            save(dataFile('data_25.mat'), 'data_25');
            fprintf('Test suite: %d cases saved to %s\n', numel(testSuite), dataFile('testSuite.mat'));
            info = testSuite;
            return;
        case 'random'
            data_25 = generateRandomTest(opts);
            caseName = 'random';
        case 'zigzag_multi'
            tau_amps = 30 * [15, 20, 25, 30] / 25;
            data_25 = generateZigzagByThrust(tau_amps, [], opts);
            caseName = 'zigzag_multi';
        case 'zigzag_single'
            data_25 = generateStrictZigzag(25, 26, opts.N_steps, opts);
            caseName = 'zigzag25';
        case 'zigzag15'
            data_25 = generateStrictZigzag(15, 18, opts.N_steps, opts);
            caseName = 'zigzag15';
        case 'zigzag25'
            data_25 = generateStrictZigzag(25, 26, opts.N_steps, opts);
            caseName = 'zigzag25';
        case 'zigzag35'
            data_25 = generateStrictZigzag(35, 34, opts.N_steps, opts);
            caseName = 'zigzag35';
        case 'circle'
            data_25 = generateCircleTest(opts);
            caseName = 'circle';
        case 'sine'
            data_25 = generateSineTest(opts);
            caseName = 'sine';
        otherwise
            error('generateTestData: unknown mode "%s".', mode);
    end
    ensureDataDir();
    save(dataFile(['test_' caseName '.mat']), 'data_25');
    save(dataFile('data_25.mat'), 'data_25');
    fprintf('Test data (%s): %d steps saved to %s\n', mode, size(data_25, 1), dataFile('data_25.mat'));
    info = struct('name', caseName, 'data', data_25);
end
function [testSuite, primaryData] = generateTestSuite(opts)
    specs = {
        'zigzag25', @() generateStrictZigzag(25, 26, opts.N_steps, opts)
        'zigzag35', @() generateStrictZigzag(35, 34, opts.N_steps, opts)
        'circle',   @() generateCircleTest(opts)
        'sine',     @() generateSineTest(opts)
    };
    testSuite = repmat(struct('name', '', 'data', []), size(specs, 1), 1);
    for i = 1:size(specs, 1)
        name = specs{i, 1};
        data = specs{i, 2}();
        testSuite(i).name = name;
        testSuite(i).data = data;
        save(dataFile(['test_' name '.mat']), 'data');
        fprintf('  %-8s: %d steps\n', name, size(data, 1));
    end
    primaryData = testSuite(1).data;
end
function ensureDataDir()
    dataDir = dataRoot();
    if exist(dataDir, 'dir') ~= 7
        mkdir(dataDir);
    end
end
function data = generateStrictZigzag(angle_deg, tau_N_amp, N_steps, opts)
    Ts = opts.Ts; mp = opts.mp; tau_X_nom = opts.tau_X_nom;
    if isempty(N_steps), N_steps = 400; end
    V = [1.8, 0, 0, 0, 0, 0]; V1 = zeros(1, 6);
    dt_inner = 0.05;
    inner_steps = round(Ts / dt_inner);
    V_mem = zeros(N_steps, 6);
    tau_mem = zeros(N_steps, 2);
    psi0 = V(6);
    psi_limit = angle_deg * pi / 180;
    command_sign = 1;
    tau_X = tau_X_nom;
    switch_count = 0;
    for i = 1:N_steps
        psi_rel = atan2(sin(V(6) - psi0), cos(V(6) - psi0));
        if command_sign > 0 && psi_rel >= psi_limit
            command_sign = -1;
            switch_count = switch_count + 1;
            tau_X = tau_X_nom + 30 * (rand(1) - 0.5);
        elseif command_sign < 0 && psi_rel <= -psi_limit
            command_sign = 1;
            switch_count = switch_count + 1;
            tau_X = tau_X_nom + 30 * (rand(1) - 0.5);
        end
        tau_N = command_sign * tau_N_amp;
        V_mem(i, :) = V;
        for j = 1:inner_steps
            [V, V1] = otter3DOF(V, V1, dt_inner, [tau_X, tau_N], [0, 0, 0], mp);
        end
        tau_mem(i, :) = [tau_X, tau_N];
    end
    data = [V_mem, tau_mem];
    if opts.visualize
        plotTestData(Ts, N_steps, tau_mem, V_mem, sprintf('Zigzag %d deg', angle_deg));
        fprintf('Strict %d-deg zigzag switches: %d\n', angle_deg, switch_count);
    end
end
function data = generateCircleTest(opts)
    opts.N_steps = max(opts.N_steps, 500);
    data = simulateCommandedThrust(opts, @(t) circleCommand(t, opts));
end
function data = generateSineTest(opts)
    opts.N_steps = max(opts.N_steps, 500);
    data = simulateCommandedThrust(opts, @(t) sineCommand(t, opts));
end
function [tau_X, tau_N] = circleCommand(t, opts)
    tau_X = opts.tau_X_nom + 5 * sin(0.04 * t);
    tau_N = 18;
end
function [tau_X, tau_N] = sineCommand(t, opts)
    tau_X = opts.tau_X_nom + 10 * sin(0.06 * t);
    tau_N = 25 * sin(0.35 * t) + 3 * sin(0.06 * t) ;
end
function data = simulateCommandedThrust(opts, commandFcn)
    Ts = opts.Ts; mp = opts.mp; N_steps = opts.N_steps;
    V = [1.8, 0, 0, 0, 0, 0]; V1 = zeros(1, 6);
    dt_inner = 0.05;
    inner_steps = round(Ts / dt_inner);
    V_mem = zeros(N_steps, 6);
    tau_mem = zeros(N_steps, 2);
    for i = 1:N_steps
        t = (i - 1) * Ts;
        [tau_X, tau_N] = commandFcn(t);
        V_mem(i, :) = V;
        for j = 1:inner_steps
            [V, V1] = otter3DOF(V, V1, dt_inner, [tau_X, tau_N], [0, 0, 0], mp);
        end
        tau_mem(i, :) = [tau_X, tau_N];
    end
    data = [V_mem, tau_mem];
    if opts.visualize
        plotTestData(Ts, N_steps, tau_mem, V_mem, 'Commanded thrust test');
    end
end
function data = generateRandomTest(opts)
    rng(42);
    Ts = opts.Ts; mp = opts.mp;
    V = [1.8, 0, 0, 0, 0, 0]; V1 = zeros(1, 6);
    N_steps = 500;
    dt_inner = 0.05;
    inner_steps = round(Ts / dt_inner);
    V_mem = zeros(N_steps, 6);
    tau_mem = zeros(N_steps, 2);
    tau_X = 100; tau_N = 0;
    for i = 1:N_steps
        if mod(i, round(5/Ts)) == 0 || i == 1
            tau_X = 100 + 30 * (rand(1) - 0.5);
            tau_N = 100 * rand(1) - 30;
        end
        V_mem(i, :) = V;
        for j = 1:inner_steps
            [V, V1] = otter3DOF(V, V1, dt_inner, [tau_X, tau_N], [0, 0, 0], mp);
        end
        tau_mem(i, :) = [tau_X, tau_N];
    end
    data = [V_mem, tau_mem];
end
function data = generateZigzagByThrust(tau_N_amp, N_steps, opts)
    Ts = opts.Ts; mp = opts.mp; tau_X_nom = opts.tau_X_nom;
    use_multi = ~isscalar(tau_N_amp);
    if use_multi
        hold_time = 10;
        steps_per_seg = round(hold_time / Ts);
        N_steps = length(tau_N_amp) * steps_per_seg;
    elseif isempty(N_steps)
        N_steps = 400;
    end
    V = [1.8, 0, 0, 0, 0, 0]; V1 = zeros(1, 6);
    dt_inner = 0.05;
    inner_steps = round(Ts / dt_inner);
    switch_interval = round(5 / Ts);
    V_mem = zeros(N_steps, 6);
    tau_mem = zeros(N_steps, 2);
    tau_X = tau_X_nom;
    tau_N = tau_N_amp(1);
    for i = 1:N_steps
        if use_multi
            seg_idx = min(floor((i-1)/steps_per_seg) + 1, length(tau_N_amp));
            amp = tau_N_amp(seg_idx);
            t_in_seg = mod((i-1) * Ts, hold_time);
            tau_N = amp * (1 - 2 * (mod(floor(t_in_seg/5), 2) > 0));
        elseif mod(i, switch_interval) == 0
            tau_N = -tau_N;
        end
        if mod(i, switch_interval) == 0
            tau_X = tau_X_nom + 20 * (rand(1) - 0.5);
        end
        V_mem(i, :) = V;
        for j = 1:inner_steps
            [V, V1] = otter3DOF(V, V1, dt_inner, [tau_X, tau_N], [0, 0, 0], mp);
        end
        tau_mem(i, :) = [tau_X, tau_N];
    end
    trim_start = 100;
    data = [V_mem(trim_start:end, :), tau_mem(trim_start:end, :)];
    if opts.visualize
        plotTestData(Ts, N_steps, tau_mem, V_mem, 'Zigzag thrust');
    end
end
function plotTestData(Ts, N, tau_mem, V_mem, name)
    t = Ts:Ts:Ts*N;
    figure('Name', ['Test Data - ' name], 'Color', 'w');
    subplot(3,1,1);
    plot(t, tau_mem(:,1), t, tau_mem(:,2)); legend('\tau_X','\tau_N'); ylabel('Thrust'); grid on;
    subplot(3,1,2);
    plot(t, V_mem(:,1)); legend('u'); ylabel('Surge (m/s)'); grid on;
    subplot(3,1,3);
    plot(t, V_mem(:,2), t, V_mem(:,3)); legend('v','r'); ylabel('v,r'); grid on;
    figure('Name', ['Heading - ' name], 'Color', 'w');
    plot(t, V_mem(:,6)*180/pi); xlabel('Time (s)'); ylabel('\psi (deg)'); grid on;
end


