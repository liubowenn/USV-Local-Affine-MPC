function printMpcResultMetrics(resultOrMetrics)
% printMpcResultMetrics  Print metrics computed from an MPC result.

    if isfield(resultOrMetrics, 'table') && isfield(resultOrMetrics, 'by_controller')
        metrics = resultOrMetrics;
    else
        metrics = computeMpcResultMetrics(resultOrMetrics);
    end

    T = metrics.table;
    T.method = string(cellfun(@mpcMethodLabel, cellstr(T.method), ...
        'UniformOutput', false));

    fprintf('\n=== Heading tracking error ===\n');
    printMetricPair(T, 'heading_mae_deg', 'heading_iae_deg_s', 'deg', 'deg*s');

    if metrics.track_u
        fprintf('\n=== Surge speed tracking error ===\n');
        printMetricPair(T, 'surge_mae_mps', 'surge_iae_m', 'm/s', 'm');
    end

    if strcmpi(metrics.mode, 'curve')
        fprintf('\n=== Curve completion time ===\n');
        for i = 1:height(T)
            fprintf('  %-20s t_finish=%.2f s\n', char(T.method(i)), T.finish_time_s(i));
        end

        fprintf('\n=== Curve cross-track error ===\n');
        printMetricPair(T, 'cross_track_mae_m', 'cross_track_iae_m_s', 'm', 'm*s');
    end

    fprintf('\n=== QP solving time ===\n');
    for i = 1:height(T)
        if isfinite(T.qp_mean_ms(i))
            fprintf('  %-20s mean=%.4f ms   std=%.4f ms   max=%.4f ms\n', ...
                char(T.method(i)), T.qp_mean_ms(i), T.qp_std_ms(i), T.qp_max_ms(i));
        end
    end
end

function printMetricPair(T, maeField, iaeField, maeUnit, iaeUnit)
    for i = 1:height(T)
        fprintf('  %-20s MAE=%.4f %s   IAE=%.4f %s\n', ...
            char(T.method(i)), T.(maeField)(i), maeUnit, T.(iaeField)(i), iaeUnit);
    end
end
