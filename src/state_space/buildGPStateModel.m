function StateModelGP = buildGPStateModel()
    load(modelArtifactFile('modelGP.mat'), 'gpModels');
    nFeatures = 5;
    y0 = gpNextState(gpModels, zeros(1, nFeatures));
    coeff = zeros(3, nFeatures);
    for i = 1:nFeatures
        xi = zeros(1, nFeatures);
        xi(i) = 1;
        coeff(:, i) = gpNextState(gpModels, xi) - y0;
    end
    StateModelGP.A = coeff(:, 1:3);
    StateModelGP.B = coeff(:, 4:5);
    StateModelGP.b = y0;
    StateModelGP.model_type = 'gp-linear';
    StateModelGP.feature_cols = [1, 2, 3, 7, 8];
    ensureStateModelDir();
    save(stateModelFile('StateModelGP.mat'), 'StateModelGP');
    fprintf('GP state-space model saved to %s\n', stateModelFile('StateModelGP.mat'));
end
function y = gpNextState(gpModels, xi)
    du = predict(gpModels.modelu, xi);
    dv = predict(gpModels.modelv, xi);
    dr = predict(gpModels.modelr, xi);
    y = [xi(1) + du; xi(2) + dv; xi(3) + dr];
end
function ensureStateModelDir()
    if exist(stateModelFile(), 'dir') ~= 7
        mkdir(stateModelFile());
    end
end


