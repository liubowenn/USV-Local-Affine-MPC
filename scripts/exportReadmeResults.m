function exportReadmeResults(figureDirectory)
% exportReadmeResults  Export the edited MSS figures for the README.
% Source FIG files remain local; only the three PNG previews are versioned.
% This function does not rerun experiments or replace README text and tables.
    narginchk(1, 1);
    root = fileparts(fileparts(mfilename('fullpath')));
    sourceNames = {'mss_open_loop_all_maneuvers', ...
        'heading_tracking_both_environments', 'trajectory_tracking_both_environments'};
    outputNames = {'mss_open_loop_predictions', 'heading_multi_sine', 'curve_sine_s'};
    for k = 1:numel(sourceNames)
        assert(isfile(fullfile(figureDirectory, [sourceNames{k}, '.fig'])), ...
            'Source figure not found: %s', sourceNames{k});
    end
    assetDirectory = fullfile(root, 'docs', 'assets');
    if ~isfolder(assetDirectory), mkdir(assetDirectory); end
    for k = 1:numel(sourceNames)
        fig = openfig(fullfile(figureDirectory, [sourceNames{k}, '.fig']), 'invisible');
        cleanup = onCleanup(@() close(fig));
        drawnow;
        if k > 1
            retainMssColumn(fig);
        else
            legends = findall(fig, 'Type', 'legend');
            for j = 1:numel(legends)
                legends(j).String = paperLabels(legends(j).String);
            end
        end
        drawnow;
        exportgraphics(fig, fullfile(assetDirectory, [outputNames{k}, '.png']), ...
            'Resolution', 200, 'BackgroundColor', 'white');
        clear cleanup;
    end
end

function retainMssColumn(fig)
    axesHandles = findall(fig, 'Type', 'axes');
    keep = arrayfun(@(ax) ax.Position(1) < 0.5, axesHandles);
    mssAxes = axesHandles(keep);
    legends = findall(fig, 'Type', 'legend');
    for j = 1:numel(legends)
        if ~any(legends(j).Axes == mssAxes), delete(legends(j)); end
    end
    bars = findall(fig, 'Type', 'colorbar');
    for j = 1:numel(bars)
        if bars(j).Position(1) > 0.5, delete(bars(j)); end
    end
    delete(axesHandles(~keep));
    delete(findall(fig, 'Type', 'textboxshape'));

    % Preserve panel dimensions and reserve space above them for the legend.
    fig.Units = 'centimeters';
    sizeBefore = fig.Position;
    widthRatio = 0.54;
    heightRatio = sizeBefore(4) / (sizeBefore(4) + 2.2);
    objects = [mssAxes; findall(fig, 'Type', 'colorbar'); findall(fig, 'Type', 'legend')];
    positions = cell(numel(objects), 1);
    for j = 1:numel(objects)
        objects(j).Units = 'normalized';
        positions{j} = objects(j).Position;
    end
    fig.Position(3:4) = [sizeBefore(3) * widthRatio, sizeBefore(4) + 2.2];
    for j = 1:numel(objects)
        position = positions{j};
        position([1, 3]) = position([1, 3]) / widthRatio;
        position([2, 4]) = position([2, 4]) * heightRatio;
        objects(j).Position = position;
    end
    mainAxes = mssAxes(~strcmp({mssAxes.Tag}, 'PayloadBackgroundAxes'));
    xy = mainAxes(arrayfun(@(ax) contains(string(ax.Title.String), 'XY trajectory'), mainAxes));
    assert(isscalar(xy), 'Expected one MSS trajectory panel.');
    lines = findall(xy, 'Type', 'line');
    lines = lines(arrayfun(@(line) isprop(line, 'DisplayName'), lines));
    lineLabels = arrayfun(@(line) string(line.DisplayName), lines);
    labels = {'Reference', 'Nomoto-tuned PID', 'MPC-Global LS-SVM', ...
        'MPC-K-means LS-SVM', 'MPC-Global GP', 'This work'};
    handles = gobjects(0);
    selectedLabels = {};
    for j = 1:numel(labels)
        index = find(strcmp(paperLabels(lineLabels), labels{j}));
        if isempty(index), continue; end
        assert(isscalar(index), 'Ambiguous controller line: %s', labels{j});
        handles(end+1) = lines(index); %#ok<AGROW>
        selectedLabels{end+1} = labels{j}; %#ok<AGROW>
    end
    assert(numel(handles) >= 5, 'MSS controller legend is incomplete.');
    mainLegend = legend(xy, handles, selectedLabels, 'AutoUpdate', 'off', ...
        'NumColumns', 2, 'FontName', 'Times New Roman', 'FontSize', 8, ...
        'FontWeight', 'bold', 'Interpreter', 'none', 'Box', 'off');
    mainLegend.Units = 'normalized';
    mainLegend.Position = [0.09, 0.915, 0.83, 0.061];

    heading = mainAxes(arrayfun(@(ax) numel(ax.YAxis) == 2, mainAxes));
    assert(isscalar(heading), 'Expected one MSS payload-mass axis.');
    heading.YAxis(2).Label.Units = 'normalized';
    heading.YAxis(2).Label.Position = [1.12, 0.5, 0];
    heading.YAxis(2).Color = [0, 0, 0];
    heading.YAxis(2).Label.Color = [0, 0, 0];
    existing = findall(fig, 'Type', 'legend');
    if ~any(arrayfun(@(lg) isequal(lg.Axes, heading), existing))
        desired = findall(heading, 'Type', 'line', 'DisplayName', 'Desired heading');
        background = findall(fig, 'Tag', 'PayloadBackgroundAxes');
        payload = findall(background, 'Type', 'line', 'DisplayName', 'Payload mass');
        assert(isscalar(desired) && isscalar(payload));
        detailLegend = legend(heading, desired, {'Desired heading'}, ...
            'Location', 'southwest', 'FontName', 'Times New Roman', ...
            'FontSize', 7, 'FontWeight', 'bold', 'AutoUpdate', 'off');
        detailLegend.PlotChildren = [desired; payload];
        detailLegend.String = {'Desired heading', 'Payload mass'};
    end
    % Legend creation can restore an axis's old layout; retain the MSS geometry.
    drawnow;
    for j = 1:numel(objects)
        position = positions{j};
        position([1, 3]) = position([1, 3]) / widthRatio;
        position([2, 4]) = position([2, 4]) * heightRatio;
        if isgraphics(objects(j), 'axes')
            objects(j).PositionConstraint = 'innerposition';
        end
        objects(j).Position = position;
    end
    bars = findall(fig, 'Type', 'colorbar');
    for j = 1:numel(bars)
        bars(j).Label.String = 'Current speed (m/s)';
        bars(j).Label.FontAngle = 'normal';
    end
end

function labels = paperLabels(labels)
    labels = cellstr(string(labels));
    labels = strrep(labels, 'Global LSSVM', 'Global LS-SVM');
    labels = strrep(labels, 'K-means-LSSVM', 'K-means LS-SVM');
    labels = strrep(labels, 'MPC-global LSSVM', 'MPC-Global LS-SVM');
    labels = strrep(labels, 'MPC-k-means-LSSVM', 'MPC-K-means LS-SVM');
    labels = strrep(labels, 'MPC-global GP', 'MPC-Global GP');
    labels = strrep(labels, 'Ours', 'This work');
end
