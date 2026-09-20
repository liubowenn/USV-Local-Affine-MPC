function source = inferMpcPlotSource(result, resultFile, fallbackSource)
% inferMpcPlotSource  Infer coordinate convention for plotting saved MPC logs.
%
% File paths are trusted first because external logs may store their runtime
% source as "ros" while still being placed under results/mpc/usv_simulator.
    if ~exist('resultFile', 'var')
        resultFile = '';
    end
    if ~exist('fallbackSource', 'var')
        fallbackSource = '';
    end

    pathSource = sourceFromPath(resultFile);
    if ~isempty(pathSource)
        source = pathSource;
        return;
    end

    source = getStructField(result, 'source', '');
    if isempty(source) && isfield(result, 'param')
        source = getStructField(result.param, 'data_source', '');
    end
    if isempty(source)
        source = fallbackSource;
    end

    source = normalizePlotSource(source);
end


function source = sourceFromPath(filePath)
    source = '';
    p = lower(strrep(char(filePath), '\', '/'));

    if contains(p, '/usv_simulator/') || contains(p, '/usvsimu/')
        source = 'usvsimu';
    elseif contains(p, '/mss/')
        source = 'mss';
    end
end


function source = normalizePlotSource(source)
    source = lower(char(source));

    if any(strcmp(source, {'usv', 'usvsimu', 'usv_simulator', 'usv_simulatordata', 'ros'}))
        source = 'usvsimu';
    elseif strcmp(source, 'mss')
        source = 'mss';
    end
end
