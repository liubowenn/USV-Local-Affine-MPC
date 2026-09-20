function models = loadClusterLssvmModels(tag, K)
    models.a_u = cell(K, 1);
    models.a_v = cell(K, 1);
    models.a_r = cell(K, 1);
    models.b_u = zeros(K, 1);
    models.b_v = zeros(K, 1);
    models.b_r = zeros(K, 1);
    for k = 1:K
        mu = load(modelArtifactFile(sprintf('modeluCluster%d_%s.mat', k, tag)));
        mv = load(modelArtifactFile(sprintf('modelvCluster%d_%s.mat', k, tag)));
        mr = load(modelArtifactFile(sprintf('modelrCluster%d_%s.mat', k, tag)));
        [models.a_u{k}, models.b_u(k)] = nextStateCoefficients(mu.modelu, 1);
        [models.a_v{k}, models.b_v(k)] = nextStateCoefficients(mv.modelv, 2);
        [models.a_r{k}, models.b_r(k)] = nextStateCoefficients(mr.modelr, 3);
    end
end


