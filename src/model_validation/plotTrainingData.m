function fig = plotTrainingData(source, Ts)
% plotTrainingData  Plot the saved training and validation datasets.
% Run from the repository root after setupProject; source is 'mss' or
% 'usv_simulator'. Uses the same data.mat/data_val.mat split as model training.
    if nargin < 1 || isempty(source)
        cfg = defaultExperimentConfig();
        source = cfg.data.source;
    end
    if nargin < 2 || isempty(Ts), Ts = 0.1; end
    trainSet = load(dataFile('data.mat', source), 'data');
    validationSet = load(dataFile('data_val.mat', source), 'data_val');
    data_train = trainSet.data;
    data_val = validationSet.data_val;

N_train = size(data_train, 1);
N_val   = size(data_val, 1);

t_train = (0:N_train-1) * Ts;
t_val   = (0:N_val-1) * Ts;

% Plot colors.
c_taux = [0.0000, 0.4470, 0.7410];
c_taun = [1.0000, 0.3000, 0.2000];
c_u    = [0.4660, 0.6740, 0.1880];
c_v    = [0.9290, 0.6940, 0.1250];
c_r    = [1.0000, 0.0000, 1.0000];

% Create the figure.
fig = figure( ...
    'Color', 'w', ...
    'Position', [100, 100, 1250, 650]);

% =========================================================
% Figure layout.
% =========================================================

left_margin   = 0.07;
right_margin  = 0.04;
middle_gap    = 0.06;

bottom_margin = 0.10;
top_margin    = 0.055;
row_gap       = 0.07;

total_width = 1 - left_margin - right_margin - middle_gap;

% Training data occupies two thirds of the panel width.
% Validation data occupies one third of the panel width.
w1 = total_width * 2 / 3;
w2 = total_width * 1 / 3;

x1 = left_margin;
x2 = left_margin + w1 + middle_gap;

total_height = 1 - bottom_margin - top_margin - 2 * row_gap;
h = total_height / 3;

y3 = bottom_margin;
y2 = bottom_margin + h + row_gap;
y1 = bottom_margin + 2 * (h + row_gap);

% Training panel positions.
pos11 = [x1, y1, w1, h];
pos21 = [x1, y2, w1, h];
pos31 = [x1, y3, w1, h];

% Validation panel positions.
pos12 = [x2, y1, w2, h];
pos22 = [x2, y2, w2, h];
pos32 = [x2, y3, w2, h];

% =========================================================
% Column titles.
% =========================================================

annotation( ...
    'textbox', ...
    [x1, 0.950, w1, 0.025], ...
    'String', '(a) Training data', ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle');

annotation( ...
    'textbox', ...
    [x2, 0.950, w2, 0.025], ...
    'String', '(b) Weight validation data', ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle');

% =========================================================
% Training data.
% =========================================================

% ---------------------------------------------------------
% Panel 1: thrust inputs.
% ---------------------------------------------------------

ax1 = axes('Position', pos11);

p1 = plot( ...
    t_train, ...
    data_train(:, 7), ...
    'LineWidth', 1.2, ...
    'Color', c_taux);

hold on;

p2 = plot( ...
    t_train, ...
    data_train(:, 8), ...
    'LineWidth', 1.2, ...
    'Color', c_taun);

grid on;
box on;

xlim([t_train(1), t_train(end)]);

set(ax1, 'XTickLabel', []);

ylabel('\tau_X & \tau_N');

legend( ...
    [p1, p2], ...
    {'\tau_X', '\tau_N'}, ...
    'Location', 'northeast');

% ---------------------------------------------------------
% Panel 2: surge and sway velocities.
% ---------------------------------------------------------

ax2 = axes('Position', pos21);

p3 = plot( ...
    t_train, ...
    data_train(:, 1), ...
    'LineWidth', 1.2, ...
    'Color', c_u);

hold on;

p4 = plot( ...
    t_train, ...
    data_train(:, 2), ...
    'LineWidth', 1.2, ...
    'Color', c_v);

grid on;
box on;

xlim([t_train(1), t_train(end)]);

set(ax2, 'XTickLabel', []);

ylabel('u & v (m/s)');

legend( ...
    [p3, p4], ...
    {'u', 'v'}, ...
    'Location', 'northeast');

% ---------------------------------------------------------
% Panel 3: yaw rate.
% ---------------------------------------------------------

ax3 = axes('Position', pos31);

p5 = plot( ...
    t_train, ...
    data_train(:, 3), ...
    'LineWidth', 1.2, ...
    'Color', c_r);

grid on;
box on;

xlim([t_train(1), t_train(end)]);

xlabel('Time (s)');
ylabel('r (rad/s)');

legend( ...
    p5, ...
    {'r'}, ...
    'Location', 'northeast');

% =========================================================
% Feature-weight validation data.
% =========================================================

% ---------------------------------------------------------
% Panel 4: thrust inputs.
% ---------------------------------------------------------

ax4 = axes('Position', pos12);

p6 = plot( ...
    t_val, ...
    data_val(:, 7), ...
    'LineWidth', 1.2, ...
    'Color', c_taux);

hold on;

p7 = plot( ...
    t_val, ...
    data_val(:, 8), ...
    'LineWidth', 1.2, ...
    'Color', c_taun);

grid on;
box on;

xlim([t_val(1), t_val(end)]);

set(ax4, ...
    'XTickLabel', [], ...
    'YTickLabel', []);

ylabel('');

legend( ...
    [p6, p7], ...
    {'\tau_X', '\tau_N'}, ...
    'Location', 'northeast');

% ---------------------------------------------------------
% Panel 5: surge and sway velocities.
% ---------------------------------------------------------

ax5 = axes('Position', pos22);

p8 = plot( ...
    t_val, ...
    data_val(:, 1), ...
    'LineWidth', 1.2, ...
    'Color', c_u);

hold on;

p9 = plot( ...
    t_val, ...
    data_val(:, 2), ...
    'LineWidth', 1.2, ...
    'Color', c_v);

grid on;
box on;

xlim([t_val(1), t_val(end)]);

set(ax5, ...
    'XTickLabel', [], ...
    'YTickLabel', []);

ylabel('');

legend( ...
    [p8, p9], ...
    {'u', 'v'}, ...
    'Location', 'northeast');

% ---------------------------------------------------------
% Panel 6: yaw rate.
% ---------------------------------------------------------

ax6 = axes('Position', pos32);

p10 = plot( ...
    t_val, ...
    data_val(:, 3), ...
    'LineWidth', 1.2, ...
    'Color', c_r);

grid on;
box on;

xlim([t_val(1), t_val(end)]);

xlabel('Time (s)');
ylabel('');

set(ax6, 'YTickLabel', []);

legend( ...
    p10, ...
    {'r'}, ...
    'Location', 'northeast');

% =========================================================
% Apply common axis styling.
% =========================================================

all_axes = findall(gcf, 'Type', 'axes');

for i = 1:length(all_axes)
    set(all_axes(i), ...
        'XColor', 'k', ...
        'YColor', 'k', ...
        'GridAlpha', 0.18, ...
        'MinorGridAlpha', 0.10, ...
        'TickDir', 'in');
end

set(ax4, 'YTickLabel', []);
set(ax5, 'YTickLabel', []);
set(ax6, 'YTickLabel', []);


end
