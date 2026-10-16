function cfg = defaultExperimentConfig()
% defaultExperimentConfig  Configure model learning and validation workflow.
%
% Edit this file before running runFullPipeline or runModelExperiment.

    % Model-learning hyperparameters
    cfg.num_clusters = 4;
    cfg.gam_u = 10;
    cfg.gam_v = 20;
    cfg.gam_r = 50;
    cfg.test_mode = 'suite';

    % Cluster assignment rule
    %   'max'  : select only the largest membership cluster.
    %   number : select clusters whose membership is larger than this value.
    cfg.delta = 1 / cfg.num_clusters;
    cfg.test.visualize = false;

    % Data source
    %   'mss'           : data/mss -> results/model_learned/mss
    %   'usv_simulator' : data/usv_simulator -> results/model_learned/usvsimu
    cfg.data.source = 'mss';

    % Training-data generation
    cfg.training.tau_x_nom = 100;
    cfg.training.n_steps = 5000;
    cfg.training.ts = 0.1;
    cfg.training.mp = 20;
    cfg.training.visualize = true;

    % GA feature-weight search for weighted FCM
    cfg.fcm_weight_search = struct( ...
        'method', 'ga', ...
        'lb', [0.25 0.25 0.25 0.25 0.25], ...
        'ub', [5 5 5 5 5], ...
        'population_size', 10, ...
        'max_generations', 30, ...
        'elite_count', 3, ...
        'seed', 2, ...
        'use_parallel', false, ...
        'display', 'iter');

    % GP and model-fusion settings
    cfg.gp.max_samples = 10000;
    cfg.gp.active_set_size = [];
    cfg.weighted_fcm.objective = 'uvr';
    cfg.weighted_fcm.beta = 2;

    % Pipeline switches
    cfg.steps.generate_test_data = false;
    cfg.steps.generate_training_data = false;
    cfg.steps.train_nonclustered_lssvm = false;
    cfg.steps.train_weighted_fcm_lssvm = false;
    % Repeated WFCM/K-means training. Turn this on only when you want to
    % rerun GA/repeated clustering and overwrite the repeated model package.
    cfg.steps.train_weighted_fcm_lssvm_repeat = false;

    % Repeated validation. This only reads existing repeated model packages
    % and reports mean +/- std; it does not retrain anything.
    cfg.steps.validate_repeated_models = true;
    cfg.steps.train_kmeans_lssvm = false;
    cfg.steps.train_gp = false;
    cfg.steps.validate_models = true;
end
