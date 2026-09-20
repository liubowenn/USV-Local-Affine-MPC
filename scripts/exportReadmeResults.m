function exportReadmeResults()
% exportReadmeResults  Refresh README previews and tables from saved MSS runs.
% Run from the repository root after setupProject. Does not rerun experiments.
    root = setupProject();
    previousDirectory = pwd;
    restoreDirectory = onCleanup(@() cd(previousDirectory));
    cd(root);
    assetDirectory = fullfile(root, 'docs', 'assets');
    if ~isfolder(assetDirectory), mkdir(assetDirectory); end
    cases = {'heading_multi_sine', 'curve_sine_s'};
    packages = cell(1, numel(cases));
    for i = 1:numel(cases)
        source = fullfile('results', 'mpc', 'mss', cases{i}, 'repeatedMpcResults.mat');
        loaded = load(source, 'mpcRepeatedResult');
        packages{i} = loaded.mpcRepeatedResult;
        fig = plotRepeatedMpcResultFile(source);
        set(fig, 'Units', 'inches', 'Position', [1 1 12 10]);
        axesHandles = findall(fig, 'Type', 'axes');
        for axisHandle = axesHandles'
            axisHandle.Units = 'normalized';
            position = axisHandle.Position;
            position(1) = position(1) * 0.96;
            position(3) = position(3) * 0.96;
            if position(1) > 0.3 && position(2) > 0.6
                % Reserve space between current-colorbar labels and input axes.
                position(1) = position(1) + 0.075;
                position(3) = position(3) - 0.075;
            end
            axisHandle.Position = position;
        end
        drawnow;
        exportgraphics(fig, fullfile(assetDirectory, [cases{i}, '.png']), ...
            'Resolution', 180, 'BackgroundColor', 'white');
        close(fig);
    end
    heading = packages{1};
    curve = packages{2};
    section = sprintf(['## Results\n\n', ...
        'Representative MSS heading-tracking and S-path-following experiments. ', ...
        'Each preview shows the saved best run selected by the existing ', ...
        'experiment scoring rule; the table reports mean +/- sample standard ', ...
        'deviation across all %d heading runs and %d path-following runs.\n\n', ...
        '### Heading tracking\n\n', ...
        '![MSS heading tracking: trajectory, inputs, heading error and QP time]', ...
        '(docs/assets/heading_multi_sine.png)\n\n', ...
        '### Path following\n\n', ...
        '![MSS S-path following: trajectory, inputs, speed, heading and cross-track error]', ...
        '(docs/assets/curve_sine_s.png)\n\n', ...
        '### Controller comparison\n\n', ...
        'Lower is better. QP time is the per-run mean solver time, aggregated ', ...
        'across the saved runs; it is not total controller latency. ', ...
        'A dash means the PID controller does not solve a QP.\n\n', ...
        '| Controller | Heading MAE (deg) | Path cross-track MAE (m) | ', ...
        'Heading QP time (ms) | Path QP time (ms) |\n', ...
        '| --- | ---: | ---: | ---: | ---: |\n'], ...
        numel(heading.runs), numel(curve.runs));
    hs = heading.summary;
    cs = curve.summary;
    assert(isequal(string(hs.method), string(cs.method)), 'Controller order differs.');
    for i = 1:numel(hs.method)
        section = [section, sprintf('| %s | %s | %s | %s | %s |\n', ...
            char(hs.method(i)), pair(hs, 'heading_mae_deg', i), ...
            pair(cs, 'cross_track_mae_m', i), pair(hs, 'qp_mean_ms', i), ...
            pair(cs, 'qp_mean_ms', i))]; %#ok<AGROW>
    end
    section = [section, sprintf(['\nSources: ', ...
        '[heading runs](results/mpc/mss/heading_multi_sine/repeatedMpcResults.mat), ', ...
        '[path-following runs](results/mpc/mss/curve_sine_s/repeatedMpcResults.mat). ', ...
        'These previews use included MSS results; USV-Simulator result files ', ...
        'are also available under `results/mpc/usv_simulator/`.\n\n', ...
        'Refresh these PNG previews and the table from the saved files:\n\n', ...
        '```matlab\nsetupProject; exportReadmeResults;\n```\n'])];
    startMarker = '<!-- RESULTS:START -->';
    endMarker = '<!-- RESULTS:END -->';
    block = sprintf('%s\n%s%s', startMarker, section, endMarker);
    readmeFile = fullfile(root, 'README.md');
    content = fileread(readmeFile);
    first = strfind(content, startMarker);
    last = strfind(content, endMarker);
    if isempty(first) && isempty(last)
        anchor = strfind(content, '## Repository Layout');
        assert(isscalar(anchor), 'README layout heading must occur once.');
        content = [content(1:anchor-1), block, newline, newline, content(anchor:end)];
    else
        assert(isscalar(first) && isscalar(last) && last > first, 'Invalid results markers.');
        content = [content(1:first-1), block, content(last+length(endMarker):end)];
    end
    fid = fopen(readmeFile, 'w', 'n', 'UTF-8');
    assert(fid ~= -1, 'Cannot write README.');
    closeFile = onCleanup(@() fclose(fid));
    fprintf(fid, '%s', content);
end

function value = pair(summary, field, index)
    average = summary.([field, '_mean'])(index);
    spread = summary.([field, '_std'])(index);
    if ~isfinite(average), value = '-'; return; end
    value = sprintf('%.4f +/- %.4f', average, spread);
end
