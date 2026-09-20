function fig = plotMPCResults(t, v, psi_ref, path_err, ulog, t_solve, wpt, mode, mp_mem, param)
% plotMPCResults  Draw the closed-loop MPC overview figure.
%
% The function only consumes saved result data, so the same plotting logic can
% be reused for MATLAB simulations and future external-environment logs.
    if ~exist('mp_mem', 'var') || isempty(mp_mem)
        mp_mem = [];
    end

    if ~exist('param', 'var') || isempty(param)
        param = struct();
    end

    names = mpcControllerNames();
    labels = cellfun(@mpcMethodLabel, names, 'UniformOutput', false);
    colors = methodColors();

    lineStyles = {'-', '-', '-', '-', '-'};
    lineWidths = [0.9, 1.0, 1.0, 1.0, 1.5];

    showCrossTrack = shouldShowCrossTrack(path_err, names, mode);
    showSpeedTrack = getStructField(param, 'mpc_track_u', false);

    titles = makePanelTitles(showCrossTrack, showSpeedTrack);

    figW = 7.2;
    figH = 5.8;

    fig = figure('Name', 'MPC Experiment Overview', ...
        'Color', 'w', ...
        'Units', 'inches', ...
        'Position', [1 1 figW figH]);

    pos = mpcOverviewLayout(showCrossTrack, showSpeedTrack, figW, figH);

    axXY = makeAxes(fig, pos.xy);
    axTauX = makeAxes(fig, pos.tauX);
    axTauN = makeAxes(fig, pos.tauN);
    axHeading = makeAxes(fig, pos.heading);
    axHeadingErr = makeAxes(fig, pos.headingErr);

    if showCrossTrack
        axCross = makeAxes(fig, pos.cross);
    else
        axCross = [];
    end

    if showSpeedTrack
        axSpeed = makeAxes(fig, pos.speed);
    else
        axSpeed = [];
    end

    axSolve = makeAxes(fig, pos.solve);

    plotXY(axXY, v, wpt, names, labels, colors, ...
        lineStyles, lineWidths, titles.xy, param);

    plotInput(axTauX, t, ulog, names, colors, lineStyles, lineWidths, ...
        1, '\tau_X (N)', titles.tauX);

    plotInput(axTauN, t, ulog, names, colors, lineStyles, lineWidths, ...
        2, '\tau_N (N\cdot m)', titles.tauN);

    plotHeading(axHeading, t, v, psi_ref, names, labels, colors, ...
        lineStyles, lineWidths, mode, titles.heading, mp_mem);

    plotHeadingError(axHeadingErr, t, v, psi_ref, names, colors, ...
        lineStyles, lineWidths, titles.headingErr);

    if showCrossTrack
        plotCrossTrack(axCross, t, path_err, names, colors, ...
            lineStyles, lineWidths, titles.cross);
    end

    if showSpeedTrack
        plotSurgeSpeed(axSpeed, t, v, names, labels, colors, ...
            lineStyles, lineWidths, getStructField(param, 'u_ref', []), titles.speed);
    end

    plotSolverTime(axSolve, t, t_solve, names, labels, colors, ...
        lineStyles, lineWidths, titles.solve);

    set(axTauX, 'XTickLabel', []);
    xlabel(axTauX, '');

    set(axHeading, 'XTickLabel', []);
    xlabel(axHeading, '');

    set(axHeadingErr, 'XTickLabel', []);
    xlabel(axHeadingErr, '');

    if showCrossTrack
        set(axCross, 'XTickLabel', []);
        xlabel(axCross, '');
    end

    if showSpeedTrack
        set(axSpeed, 'XTickLabel', []);
        xlabel(axSpeed, '');
    end

    lockAxesPosition(axXY, pos.xy);
    lockAxesPosition(axTauX, pos.tauX);
    lockAxesPosition(axTauN, pos.tauN);
    lockAxesPosition(axHeading, pos.heading);
    lockAxesPosition(axHeadingErr, pos.headingErr);

    if showCrossTrack
        lockAxesPosition(axCross, pos.cross);
    end

    if showSpeedTrack
        lockAxesPosition(axSpeed, pos.speed);
    end

    lockAxesPosition(axSolve, pos.solve);

    set(findall(fig, '-property', 'FontName'), 'FontName', 'Times New Roman');
    set(findall(fig, '-property', 'FontSize'), 'FontSize', 8);
end


function ax = makeAxes(fig, pos)
    ax = axes(fig, 'Units', 'normalized', 'Position', pos);
    lockAxesPosition(ax, pos);
end


function lockAxesPosition(ax, pos)
    ax.Units = 'normalized';

    if isprop(ax, 'PositionConstraint')
        ax.PositionConstraint = 'innerposition';
    elseif isprop(ax, 'ActivePositionProperty')
        ax.ActivePositionProperty = 'position';
    end

    ax.LooseInset = [0.10 0.08 0.08 0.06];
    ax.Position = pos;
end


function plotHeading(ax, t, v, psi_ref, names, labels, colors, ...
    lineStyles, lineWidths, mode, titleText, mp_mem)

    hold(ax, 'on');

    isCurve = strcmpi(mode, 'curve');
    allY = [];

    hDesired = gobjects(0);
    hPayload = gobjects(0);

    if ~isCurve
        refName = names{1};

        if ~isfield(psi_ref, refName)
            error('psi_ref.%s does not exist.', refName);
        end

        psiDes = psi_ref.(refName) * 180/pi;
        nRef = min(numel(t), numel(psiDes));

        hDesired = plot(ax, t(1:nRef), psiDes(1:nRef), 'k--', ...
            'LineWidth', 1.1, ...
            'DisplayName', 'Desired heading');

        allY = [allY, psiDes(1:nRef)];
    end

    for i = 1:numel(names)
        name_i = names{i};

        psi = v.(name_i)(6,:) * 180/pi;
        n = min(numel(t), numel(psi));

        if isCurve
            if isfield(psi_ref, name_i)
                psiDes_i = psi_ref.(name_i) * 180/pi;
                nRef = min(numel(t), numel(psiDes_i));

                plot(ax, t(1:nRef), psiDes_i(1:nRef), '--', ...
                    'Color', colors(i,:), ...
                    'LineWidth', 0.75, ...
                    'HandleVisibility', 'off');

                allY = [allY, psiDes_i(1:nRef)];
            else
                warning('psi_ref.%s does not exist. Skip its reference heading.', name_i);
            end
        end

        plot(ax, t(1:n), psi(1:n), ...
            'Color', colors(i,:), ...
            'LineStyle', lineStyles{i}, ...
            'LineWidth', lineWidths(i), ...
            'DisplayName', labels{i}, ...
            'HandleVisibility', 'off');

        allY = [allY, psi(1:n)];
    end

    styleTimeAxis(ax, t);
    setPaddedYLim(ax, allY, 8, [-180 180]);

    title(ax, titleText);
    ylabel(ax, '\psi (deg)');

    if ~isempty(mp_mem)
        yyaxis(ax, 'right');

        mp_mem = mp_mem(:)';
        n = min(numel(t), numel(mp_mem));

        mpColor = [0.60 0.60 0.60];

        hPayload = plot(ax, t(1:n), mp_mem(1:n), '-.', ...
            'Color', mpColor, ...
            'LineWidth', 0.65, ...
            'DisplayName', 'Payload mass');

        ylabel(ax, 'Payload mass (kg)');
        setPaddedYLim(ax, mp_mem(1:n), 1, [-inf inf]);

        ax.YAxis(2).Color = mpColor;

        yyaxis(ax, 'left');
    end

    legendHandles = gobjects(0);
    legendLabels = {};

    if numel(hDesired) == 1 && isgraphics(hDesired)
        legendHandles(end+1) = hDesired;
        legendLabels{end+1} = 'Desired heading';
    end

    if numel(hPayload) == 1 && isgraphics(hPayload)
        legendHandles(end+1) = hPayload;
        legendLabels{end+1} = 'Payload mass';
    end

    if ~isempty(legendHandles)
        lgd = legend(ax, legendHandles, legendLabels, ...
            'Location', 'northeast', ...
            'Box', 'on', ...
            'NumColumns', numel(legendHandles));

        styleLegendBox(lgd);

        lgd.ItemTokenSize = [13 6];
        lgd.FontSize = 7;
        lgd.AutoUpdate = 'off';
    else
        legend(ax, 'off');
    end
end


function plotHeadingError(ax, t, v, psi_ref, names, colors, ...
    lineStyles, lineWidths, titleText)

    hold(ax, 'on');

    allY = [];

    for i = 1:numel(names)
        name_i = names{i};

        if ~isfield(psi_ref, name_i)
            continue;
        end

        psi = v.(name_i)(6,:);
        psiD = psi_ref.(name_i);

        n = min([numel(t), numel(psi), numel(psiD)]);

        err = abs(atan2( ...
            sin(psi(1:n) - psiD(1:n)), ...
            cos(psi(1:n) - psiD(1:n))) * 180/pi);

        plot(ax, t(1:n), err, ...
            'Color', colors(i,:), ...
            'LineStyle', lineStyles{i}, ...
            'LineWidth', lineWidths(i));

        allY = [allY, err];
    end

    styleTimeAxis(ax, t);
    setPaddedYLim(ax, allY, 1, [0 inf]);

    title(ax, titleText);
    ylabel(ax, '|\psi_{error}| (deg)');
end


function plotSolverTime(ax, t, t_solve, names, labels, colors, ...
    lineStyles, lineWidths, titleText)

    hold(ax, 'on');

    mpcIdx = find(~ismember(names, {'mss'}));
    allY = [];

    for i = mpcIdx
        name_i = names{i};

        if ~isfield(t_solve, name_i)
            continue;
        end

        y = t_solve.(name_i) * 1000;
        n = min(numel(t), numel(y));

        plot(ax, t(1:n), y(1:n), ...
            'Color', colors(i,:), ...
            'LineStyle', lineStyles{i}, ...
            'LineWidth', lineWidths(i), ...
            'DisplayName', labels{i});

        allY = [allY, y(1:n)];
    end

    styleTimeAxis(ax, t);
    setPaddedYLim(ax, allY, 0.5, [0 inf]);

    title(ax, titleText);
    ylabel(ax, 'QP time (ms)');
    xlabel(ax, 'Time (s)');

    ax.YAxis(1).Color = [0.15 0.15 0.15];

    lgd = legend(ax, 'Location', 'northeast', ...
        'Box', 'on', ...
        'NumColumns', 2);

    styleLegendBox(lgd);

    lgd.ItemTokenSize = [15 7];
    lgd.FontSize = 7;
    lgd.AutoUpdate = 'off';
end


function plotXY(ax, v, wpt, names, labels, colors, ...
    lineStyles, lineWidths, titleText, param)

    hold(ax, 'on');

    allX = [];
    allY = [];

    legendHandles = gobjects(0);
    legendLabels = {};

    if isfield(wpt, 'pos') && ~isempty(wpt.pos.x)
        hRef = plot(ax, wpt.pos.y, wpt.pos.x, 'k-', ...
            'LineWidth', 1.1, ...
            'DisplayName', 'Reference');

        legendHandles(end+1) = hRef;
        legendLabels{end+1} = 'Reference';

        allX = [allX, wpt.pos.y];
        allY = [allY, wpt.pos.x];
    end

    for i = 1:numel(names)
        name_i = names{i};

        [xData, yData] = xyPlotData(v.(name_i), param);

        h = plot(ax, xData, yData, ...
            'Color', colors(i,:), ...
            'LineStyle', lineStyles{i}, ...
            'LineWidth', lineWidths(i), ...
            'DisplayName', labels{i});

        legendHandles(end+1) = h;
        legendLabels{end+1} = labels{i};

        allX = [allX, xData];
        allY = [allY, yData];
    end

    grid(ax, 'on');
    box(ax, 'on');

    xlabel(ax, 'Y (m)');
    ylabel(ax, 'X (m)');
    title(ax, titleText);

    allX = allX(isfinite(allX));
    allY = allY(isfinite(allY));

    if ~isempty(allX) && ~isempty(allY)
        xMin = min(allX);
        xMax = max(allX);

        yMin = min(allY);
        yMax = max(allY);

        padRatio = 0.04;

        xPad = max((xMax - xMin) * padRatio, 1e-6);
        yPad = max((yMax - yMin) * padRatio, 1e-6);

        xlim(ax, [xMin - xPad, xMax + xPad]);
        ylim(ax, [yMin - yPad, yMax + yPad]);
    end

    axis(ax, 'normal');
    daspect(ax, 'auto');
    pbaspect(ax, [1 1 1]);

    if exist('param', 'var') && isfield(param, 'wave')
        plotCurrentField(ax, param.wave);
    end

    if ~isempty(legendHandles)
        lgd = legend(ax, legendHandles, legendLabels, ...
            'Location', 'northeast', ...
            'Box', 'on', ...
            'NumColumns', 1);

        styleLegendBox(lgd);

        lgd.ItemTokenSize = [13 6];
        lgd.FontSize = 7;
        lgd.AutoUpdate = 'off';
    end
end


function [xData, yData] = xyPlotData(stateLog, param)
% xyPlotData  Return horizontal Y and vertical X data for the XY panel.
%
% The legacy MSS simulation stores X/Y in rows 4/5 as used by the original
% plotting code. The USV simulator logs use row 4 = Y and row 5 = X, so they
% need to be converted before plotting against wpt.pos.y / wpt.pos.x.
    if usesUsvSimulatorCoordinates(param)
        xData = stateLog(4, :);
        yData = stateLog(5, :);
    else
        xData = stateLog(5, :);
        yData = stateLog(4, :);
    end
end


function tf = usesUsvSimulatorCoordinates(param)
    source = '';

    if exist('param', 'var') && isstruct(param)
        source = getStructField(param, 'result_source', source);
        source = getStructField(param, 'data_source', source);
    end

    source = lower(char(source));
    tf = any(strcmp(source, {'usv', 'usvsimu', 'usv_simulator', 'usv_simulatordata', 'ros'}));
end


function plotCrossTrack(ax, t, path_err, names, colors, ...
    lineStyles, lineWidths, titleText)

    hold(ax, 'on');

    allY = [];

    for i = 1:numel(names)
        name_i = names{i};

        if ~isfield(path_err, name_i)
            continue;
        end

        y = abs(path_err.(name_i));
        n = min(numel(t), numel(y));

        plot(ax, t(1:n), y(1:n), ...
            'Color', colors(i,:), ...
            'LineStyle', lineStyles{i}, ...
            'LineWidth', lineWidths(i));

        allY = [allY, y(1:n)];
    end

    styleTimeAxis(ax, t);
    setPaddedYLim(ax, allY, 0.2, [0 inf]);

    ylabel(ax, '|e_y| (m)');
    xlabel(ax, '');
    title(ax, titleText);
end


function plotSurgeSpeed(ax, t, v, names, labels, colors, ...
    lineStyles, lineWidths, uRef, titleText)

    hold(ax, 'on');

    allY = [];

    if ~isempty(uRef) && isfinite(uRef)
        plot(ax, t, uRef * ones(size(t)), 'k--', ...
            'LineWidth', 1.0, ...
            'DisplayName', 'Desired u');

        allY = [allY, uRef];
    end

    for i = 1:numel(names)
        name_i = names{i};

        if ~isfield(v, name_i)
            continue;
        end

        y = v.(name_i)(1,:);
        n = min(numel(t), numel(y));

        plot(ax, t(1:n), y(1:n), ...
            'Color', colors(i,:), ...
            'LineStyle', lineStyles{i}, ...
            'LineWidth', lineWidths(i), ...
            'DisplayName', labels{i});

        allY = [allY, y(1:n)];
    end

    styleTimeAxis(ax, t);
    setPaddedYLim(ax, allY, 0.1, [0 inf]);

    ylabel(ax, 'u (m/s)');
    xlabel(ax, '');
    title(ax, titleText);
end


function plotInput(ax, t, ulog, names, colors, ...
    lineStyles, lineWidths, idx, yLabel, titleText)

    hold(ax, 'on');

    allY = [];

    for i = 1:numel(names)
        name_i = names{i};

        if ~isfield(ulog, name_i)
            continue;
        end

        y = ulog.(name_i)(idx,:);
        n = min(numel(t), numel(y));

        plot(ax, t(1:n), y(1:n), ...
            'Color', colors(i,:), ...
            'LineStyle', lineStyles{i}, ...
            'LineWidth', lineWidths(i));

        allY = [allY, y(1:n)];
    end

    styleTimeAxis(ax, t);
    setPaddedYLim(ax, allY, 2, [-inf inf]);

    ylabel(ax, yLabel);
    xlabel(ax, 'Time (s)');
    title(ax, titleText);
end


function tf = shouldShowCrossTrack(path_err, names, mode)
    tf = strcmpi(mode, 'curve');

    if ~tf
        return;
    end

    tf = false;

    for i = 1:numel(names)
        if isfield(path_err, names{i}) && any(isfinite(path_err.(names{i})))
            tf = true;
            return;
        end
    end
end


function titles = makePanelTitles(showCrossTrack, showSpeedTrack)
    titles.xy = '(a) XY Trajectory';
    titles.tauX = '(b) Surge Force';
    titles.tauN = '(c) Yaw Moment';

    if showCrossTrack
        if showSpeedTrack
            titles.speed = '(d) Surge Speed';
            titles.heading = '(e) Heading Tracking';
            titles.headingErr = '(f) Heading Error';
            titles.cross = '(g) Cross-Track Error';
            titles.solve = '(h) QP Time';
        else
            titles.heading = '(d) Heading Tracking';
            titles.headingErr = '(e) Heading Error';
            titles.cross = '(f) Cross-Track Error';
            titles.solve = '(g) QP Time';
        end
    else
        if showSpeedTrack
            titles.speed = '(d) Surge Speed';
            titles.heading = '(e) Heading Tracking';
            titles.headingErr = '(f) Heading Error';
            titles.solve = '(g) QP Time';
        else
            titles.heading = '(d) Heading Tracking';
            titles.headingErr = '(e) Heading Error';
            titles.solve = '(f) QP Time';
        end
    end
end


function styleTimeAxis(ax, t)
    grid(ax, 'on');
    box(ax, 'on');

    if ~isempty(t)
        xlim(ax, [t(1), t(end)]);
    end
end


function setPaddedYLim(ax, data, minPad, bounds)
    setPaddedLim(ax, 'y', data, minPad, bounds);
end


function setPaddedLim(ax, dim, data, minPad, bounds)
    data = data(isfinite(data));

    if isempty(data)
        if strcmp(dim, 'x')
            xlim(ax, [0 1]);
        else
            ylim(ax, [0 1]);
        end
        return;
    end

    lo = min(data);
    hi = max(data);

    if abs(hi - lo) < eps
        pad = max(minPad, max(abs(hi), 1) * 0.05);
    else
        pad = max(minPad, 0.08 * (hi - lo));
    end

    lo = lo - pad;
    hi = hi + pad;

    lo = max(lo, bounds(1));
    hi = min(hi, bounds(2));

    if lo >= hi
        hi = lo + max(minPad, 1);
    end

    if strcmp(dim, 'x')
        xlim(ax, [lo hi]);
    else
        ylim(ax, [lo hi]);
    end
end


function colors = methodColors()
    colors = [
        0.35 0.70 0.90;
        0.00 0.45 0.74;
        0.00 0.60 0.50;
        0.49 0.18 0.56;
        0.85 0.33 0.10;
    ];
end


function styleLegendBox(lgd)
    if isempty(lgd) || ~isgraphics(lgd)
        return;
    end

    lgd.Box = 'on';
    lgd.Color = 'w';
    lgd.EdgeColor = 'k';
end
