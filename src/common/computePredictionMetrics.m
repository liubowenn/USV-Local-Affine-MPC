function metrics = computePredictionMetrics(pred, truth, switchMask, Ts)
    if ~exist('switchMask', 'var') || isempty(switchMask)
        switchMask = true(size(truth.r));
    end
    if ~exist('Ts', 'var') || isempty(Ts)
        Ts = 0.1;
    end
    metrics.rmse_u = rmseMetric(pred.u, truth.u);
    metrics.rmse_v = rmseMetric(pred.v, truth.v);
    metrics.rmse_r = rmseMetric(pred.r, truth.r);
    metrics.rmse_u_norm = metrics.rmse_u / signalRange(truth.u);
    metrics.rmse_v_norm = metrics.rmse_v / signalRange(truth.v);
    metrics.rmse_r_norm = metrics.rmse_r / signalRange(truth.r);
    metrics.rmse_r_switch = rmseMetric(pred.r(switchMask), truth.r(switchMask));
    psiErr = atan2(sin(pred.psi - truth.psi), cos(pred.psi - truth.psi));
    metrics.rmse_psi = rmseMetric(psiErr * 180/pi, zeros(size(psiErr)));
    [predX, predY, truthX, truthY] = xySignals(pred, truth, Ts);
    metrics.rmse_x = rmseMetric(predX, truthX);
    metrics.rmse_y = rmseMetric(predY, truthY);
    metrics.rmse_xy = sqrt(mean((predX(:) - truthX(:)).^2 + (predY(:) - truthY(:)).^2));
end
function value = signalRange(x)
    value = max(x(:)) - min(x(:));
    if value < 1e-10
        value = 1;
    end
end
function value = rmseMetric(prediction, truth)
    value = sqrt(mean((prediction(:) - truth(:)).^2));
end
function [predX, predY, truthX, truthY] = xySignals(pred, truth, Ts)
    N = min([numel(pred.u), numel(pred.v), numel(pred.psi)]);
    if isfield(truth, 'x') && isfield(truth, 'y')
        N = min([N, numel(truth.x), numel(truth.y)]);
        truthX = truth.x(1:N);
        truthY = truth.y(1:N);
    else
        truthX = zeros(N, 1);
        truthY = zeros(N, 1);
    end
    if isfield(pred, 'x') && isfield(pred, 'y')
        predX = pred.x(1:N);
        predY = pred.y(1:N);
        return;
    end
    predX = zeros(N, 1);
    predY = zeros(N, 1);
    if N == 0
        return;
    end
    predX(1) = truthX(1);
    predY(1) = truthY(1);
    u = pred.u(1:N);
    v = pred.v(1:N);
    psi = pred.psi(1:N);
    for k = 1:N-1
        xDot = u(k) * cos(psi(k)) - v(k) * sin(psi(k));
        yDot = u(k) * sin(psi(k)) + v(k) * cos(psi(k));
        predX(k+1) = predX(k) + Ts * xDot;
        predY(k+1) = predY(k) + Ts * yDot;
    end
end



