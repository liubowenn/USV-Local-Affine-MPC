function [pred, truth, switchMask] = predictClusteredLssvm(data, clusterTail, models, beta, Ts)
    if ~exist('Ts', 'var') || isempty(Ts), Ts = 0.1; end
    XX = data(1:end-1, :);
    XXX = XX(:, [1, 2, 3, 7, 8]);
    N = size(XX, 1);
    pred = emptyPrediction(N);
    truth = truthFromData(XX);
    cm = clusterTail.cluster_min;
    cr = clusterTail.cluster_max - cm;
    cr(cr < 1e-10) = 1;
    cc = clusterTail.cluster_cols;
    method = getStructField(clusterTail, 'method', 'fcm');
    Fcov = getStructField(clusterTail, 'F_cov', []);
    featureWeights = getStructField(clusterTail, 'feature_weights', ones(1, length(cc)));
    psi = XX(1, 6);
    for i = 1:N
        xi = XXX(i, :);
        nd = (xi(cc) - cm) ./ cr;
        mem = computeClusterMembership(2, clusterTail.CENTER, nd, method, Fcov, featureWeights);
        mem = sharpenMembership(mem, beta);
        for k = 1:numel(models.a_u)
            pred.u(i) = pred.u(i) + mem(k) * (xi * models.a_u{k} + models.b_u(k));
            pred.v(i) = pred.v(i) + mem(k) * (xi * models.a_v{k} + models.b_v(k));
            pred.r(i) = pred.r(i) + mem(k) * (xi * models.a_r{k} + models.b_r(k));
        end
        if i < N
            XXX(i+1, 1:3) = [pred.u(i), pred.v(i), pred.r(i)];
        end
        psi = psi + Ts * pred.r(i);
        pred.psi(i) = psi;
    end
    switchMask = buildSwitchMask(XX(:, 8), 10);
end
function pred = emptyPrediction(N)
    pred.u = zeros(N, 1);
    pred.v = zeros(N, 1);
    pred.r = zeros(N, 1);
    pred.psi = zeros(N, 1);
end


