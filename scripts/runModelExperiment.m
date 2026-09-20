function results = runModelExperiment(cfg)
% runModelExperiment  Execute the selected model-learning pipeline steps.
%
% The active data source is taken from cfg.data.source and propagated through
% MPC_DATA_SOURCE, so all data/model paths remain source-specific.

    if ~exist('cfg', 'var') || isempty(cfg)
        cfg = defaultExperimentConfig();
    end
    if isfield(cfg, 'data') && isfield(cfg.data, 'source')
        setenv('MPC_DATA_SOURCE', cfg.data.source);
    end
    fprintf('Experiment source: %s\n', artifactSourceName());
    fprintf('  data root        : %s\n', dataRoot());
    fprintf('  learned models   : %s\n', modelArtifactFile());
    fprintf('  state-space models: %s\n', stateModelFile());
    results = struct();
    if cfg.steps.generate_test_data
        fprintf('[1/7] Generating test data (%s)...\n', cfg.test_mode);
        generateTestData(cfg.test_mode, 'visualize', cfg.test.visualize);
    end
    if cfg.steps.generate_training_data
        fprintf('[2/7] Generating training data...\n');
        generateTrainingData(cfg.training.tau_x_nom, cfg.training.n_steps, ...
            cfg.training.ts, cfg.training.mp, cfg.training.visualize);
    end
    if cfg.steps.train_nonclustered_lssvm
        fprintf('[3/7] Non-clustered LSSVM: training + state-space...\n');
        trainGlobalLssvm(cfg.gam_u, cfg.gam_v, cfg.gam_r);
        buildGlobalStateModel();
    end
    if cfg.steps.train_weighted_fcm_lssvm
        fprintf('[4/7] WFCM-LSSVM: tuning feature weights + training + state-space...\n');
        tuneFcmFeatureWeights(cfg.num_clusters, cfg.delta, ...
            cfg.gam_u, cfg.gam_v, cfg.gam_r, cfg.fcm_weight_search, ...
            cfg.weighted_fcm.objective, cfg.weighted_fcm.beta);
    end
    if cfg.steps.train_weighted_fcm_lssvm_repeat
        fprintf('[4/8] WFCM-LSSVM-Repeat: tuning feature weights + training + state-space...\n');
        runRepeatedClusterComparison();
    end
    if cfg.steps.train_kmeans_lssvm && cfg.steps.train_weighted_fcm_lssvm_repeat
        warning('runModelExperiment:SkipKmeansAfterRepeatedTraining', ...
            ['train_weighted_fcm_lssvm_repeat already promotes the best ', ...
             'K-means model. Standalone K-means training is skipped to avoid ', ...
             'overwriting the promoted official model.']);
    elseif cfg.steps.train_kmeans_lssvm
        fprintf('[5/7] KMeans-LSSVM: clustering + training + state-space...\n');
        runKMeans(cfg.num_clusters, false, 'KMEANS');
        trainCluster(cfg.gam_u, cfg.gam_v, cfg.gam_r, 'KMEANS');
        buildStateModels('KMEANS');
    end
    if cfg.steps.train_gp
        fprintf('[6/7] GP: training global Gaussian Process models...\n');
        if isempty(cfg.gp.active_set_size)
            trainGPModel(cfg.gp.max_samples);
        else
            trainGPModel(cfg.gp.max_samples, cfg.gp.active_set_size);
        end
        buildGPStateModel();
    end
    if cfg.steps.validate_models
        fprintf('[7/7] Validating models...\n');
        useRepeatedValidation = getStructField(cfg.steps, 'validate_repeated_models', ...
            cfg.steps.train_weighted_fcm_lssvm_repeat);
        results.validation = validateModels(true, useRepeatedValidation);
    end
end
