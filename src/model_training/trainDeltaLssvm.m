function model = trainDeltaLssvm(X, Y, gam)
    model = initlssvm(X, Y, 'f', gam, [], 'lin_kernel', 'original');
    model = trainlssvm(model);
    model.prediction_target = 'delta';
end