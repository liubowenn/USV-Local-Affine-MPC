function [pred, truth] = predictGpModel(data, gpModels, Ts)
    if ~exist('Ts', 'var') || isempty(Ts), Ts = 0.1; end
    XX = data(1:end-1, :);
    XXX = XX(:, [1, 2, 3, 7, 8]);
    N = size(XX, 1);
    pred.u = zeros(N, 1);
    pred.v = zeros(N, 1);
    pred.r = zeros(N, 1);
    pred.psi = zeros(N, 1);
    truth = truthFromData(XX);
    psi = XX(1, 6);
    for i = 1:N
        xi = XXX(i, :);
        pred.u(i) = xi(1) + predict(gpModels.modelu, xi);
        pred.v(i) = xi(2) + predict(gpModels.modelv, xi);
        pred.r(i) = xi(3) + predict(gpModels.modelr, xi);
        if i < N
            XXX(i+1, 1:3) = [pred.u(i), pred.v(i), pred.r(i)];
        end
        psi = psi + Ts * pred.r(i);
        pred.psi(i) = psi;
    end
end


