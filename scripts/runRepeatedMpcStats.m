function mpcRepeatedResult = runRepeatedMpcStats(nRuns)
% runRepeatedMpcStats  Run repeated closed-loop MPC experiments.
%
% All runs are saved to results/mpc/<source>/<scenario>/repeatedMpcResults.mat.
% The selected run is saved as bestMpcResult.mat and plotted.

    if ~exist('nRuns', 'var') || isempty(nRuns)
        nRuns = 10;
    end

    clc; close all;
    setupProject();

    runs = cell(nRuns, 1);
    seeds = 1000 + (1:nRuns);
    runWallTime = nan(nRuns, 1);

    fprintf('\n========== Repeated MPC Test: %d runs ==========\n', nRuns);
    for runIdx = 1:nRuns
        rng(seeds(runIdx), 'twister');
        fprintf('\n---------- Run %02d / %02d, seed = %d ----------\n', ...
            runIdx, nRuns, seeds(runIdx));

        ticRun = tic;
        runs{runIdx} = runMpcExperimentCore(false);
        runs{runIdx}.run_index = runIdx;
        runs{runIdx}.seed = seeds(runIdx);
        runs{runIdx}.metrics = computeMpcResultMetrics(runs{runIdx});
        runWallTime(runIdx) = toc(ticRun);

        fprintf('Run %02d finished. Wall-clock time = %.3f s\n', ...
            runIdx, runWallTime(runIdx));
    end

    repeatedFile = saveRepeatedMpcResults(runs, seeds, runWallTime);
    S = load(repeatedFile, 'mpcRepeatedResult');
    mpcRepeatedResult = S.mpcRepeatedResult;

    printRepeatedMpcMetrics(mpcRepeatedResult);
    plotMPCResultFile(mpcRepeatedResult.best_result_file);
end

