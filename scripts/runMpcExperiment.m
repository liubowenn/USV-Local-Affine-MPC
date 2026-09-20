function runMpcExperiment(cfg)
    rootDir = setupProject();
    if ~exist('cfg', 'var') || isempty(cfg)
        cfg = defaultExperimentConfig();
    end
    if ~cfg.steps.run_mpc
        fprintf('MPC simulation skipped. Set cfg.steps.run_mpc = true to enable it.\n');
        return;
    end
    fprintf('Running MPC simulation...\n');
    run(fullfile(rootDir, 'src', 'mpc', 'runMpcSimulation.m'));
end
