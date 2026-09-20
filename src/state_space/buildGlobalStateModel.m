function StateModelNoCluster = buildGlobalStateModel()
    load(modelArtifactFile('modeluNoCluster.mat'), 'modelu');
    load(modelArtifactFile('modelvNoCluster.mat'), 'modelv');
    load(modelArtifactFile('modelrNoCluster.mat'), 'modelr');
    [A, B, b_vec] = computeLineModel(modelu, modelv, modelr);
    StateModelNoCluster.A = A;
    StateModelNoCluster.B = B;
    StateModelNoCluster.b = b_vec;
    ensureStateModelDir();
    save(stateModelFile('StateModelNC.mat'), 'StateModelNoCluster');
    fprintf('Non-clustered state-space model saved.\n');
end
function ensureStateModelDir()
    if exist(stateModelFile(), 'dir') ~= 7
        mkdir(stateModelFile());
    end
end


