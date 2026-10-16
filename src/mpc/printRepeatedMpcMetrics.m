function printRepeatedMpcMetrics(mpcRepeatedResult)
% printRepeatedMpcMetrics  Print mean +/- std metrics for repeated MPC runs.

    fprintf('\n\n========== Repeated MPC Metrics: Mean +/- Std ==========\n');
    summary = mpcRepeatedResult.summary;
    methods = string(cellfun(@mpcMethodLabel, cellstr(summary.method), ...
        'UniformOutput', false));
    if strcmp(inferMpcPlotSource(mpcRepeatedResult), 'usvsimu')
        methods(methods == "Nomoto-tuned PID") = "Native PID";
    end

    printSummaryPair(methods, summary, ...
        'heading_mae_deg', 'heading_iae_deg_s', ...
        'Heading', 'deg', 'deg*s');

    if isfield(summary, 'surge_mae_mps_mean')
        printSummaryPair(methods, summary, ...
            'surge_mae_mps', 'surge_iae_m', ...
            'Surge speed', 'm/s', 'm');
    end

    if isfield(summary, 'cross_track_mae_m_mean')
        printSummaryPair(methods, summary, ...
            'cross_track_mae_m', 'cross_track_iae_m_s', ...
            'Cross-track', 'm', 'm*s');
    end

    if isfield(summary, 'qp_mean_ms_mean')
        fprintf('\nQP solving time\n');
        for i = 1:numel(methods)
            fprintf('  %-20s mean=%.4f +/- %.4f ms, max=%.4f +/- %.4f ms\n', ...
                char(methods(i)), ...
                summary.qp_mean_ms_mean(i), summary.qp_mean_ms_std(i), ...
                summary.qp_max_ms_mean(i), summary.qp_max_ms_std(i));
        end
    end

    best = mpcRepeatedResult.best_run;
    fprintf('\nSelected run for plot: run %02d, seed=%d\n', ...
        best.run_index, best.seed);
end

function printSummaryPair(methods, summary, maeName, iaeName, titleText, maeUnit, iaeUnit)
    fprintf('\n%s\n', titleText);
    for i = 1:numel(methods)
        fprintf('  %-20s MAE=%.4f +/- %.4f %s   IAE=%.4f +/- %.4f %s\n', ...
            char(methods(i)), ...
            summary.([maeName '_mean'])(i), summary.([maeName '_std'])(i), maeUnit, ...
            summary.([iaeName '_mean'])(i), summary.([iaeName '_std'])(i), iaeUnit);
    end
end
