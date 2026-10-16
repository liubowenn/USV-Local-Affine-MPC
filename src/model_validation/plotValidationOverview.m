function plotValidationOverview(plotPacks)
% plotValidationOverview  Draw the compact open-loop validation overview figures.
    for i = 1:numel(plotPacks)
        isProposed = ismember(lower(string(plotPacks(i).labels)), {'this work', 'ours'});
        order = [find(~isProposed), find(isProposed)];
        plotPacks(i).labels = plotPacks(i).labels(order);
        plotPacks(i).predictions = plotPacks(i).predictions(order);
    end
    plotCasePairFigure(plotPacks, {'zigzag25', 'zigzag35'}, ...
        'open_loop_validation_zigzag25_35', ...
        {'(a) Zigzag25', '(b) Zigzag25 XY', ...
         '(c) Zigzag35', '(d) Zigzag35 XY'});
    plotCasePairFigure(plotPacks, {'sine', 'circle'}, ...
        'open_loop_validation_sine_circle', ...
        {'(a) Sine', '(b) Sine XY', ...
         '(c) Circle', '(d) Circle XY'});
end
function plotCasePairFigure(plotPacks, caseNames, exportBaseName, panelTitles)
    figW = 7.2;
    figH = 5.8;
    fig = figure('Name', exportBaseName, 'Color', 'w', ...
        'Units', 'inches', 'Position', [1 1 figW figH]);
    left = 0.075;
    right = 0.035;
    bottom = 0.040;
    top = 0.02;
    rowGap = 0.03;
    rowH = (1 - bottom - top - rowGap) / 2;
    timeAxW = 0.53;
    timeAxH = 0.09;
    xyGap = 0.055;
    xyLeft = left + timeAxW + xyGap;
    xyW = 1 - xyLeft - right;
    posTime1 = [left, bottom + rowH + rowGap, timeAxW, rowH];
    posXY1   = [xyLeft, bottom + rowH + rowGap, xyW, rowH];
    posTime2 = [left, bottom, timeAxW, rowH];
    posXY2   = [xyLeft, bottom, xyW, rowH];
    idx1 = findCaseByName(plotPacks, caseNames{1});
    idx2 = findCaseByName(plotPacks, caseNames{2});
    if ~isempty(idx1)
        plotTimeResponsePanel(fig, posTime1, plotPacks(idx1), ...
            panelTitles{1}, true, true, timeAxW, timeAxH);
        plotXYTrajectoryPanel(fig, posXY1, plotPacks(idx1), panelTitles{2}, false);
    else
        drawMissingPanel(fig, posTime1, caseNames{1});
        drawMissingPanel(fig, posXY1, [caseNames{1}, ' XY']);
    end
    if ~isempty(idx2)
        plotTimeResponsePanel(fig, posTime2, plotPacks(idx2), ...
            panelTitles{3}, false, true, timeAxW, timeAxH);
        plotXYTrajectoryPanel(fig, posXY2, plotPacks(idx2), panelTitles{4}, false);
    else
        drawMissingPanel(fig, posTime2, caseNames{2});
        drawMissingPanel(fig, posXY2, [caseNames{2}, ' XY']);
    end
end
function plotTimeResponsePanel(fig, panelPos, pack, titleText, showLegend, showYLabel, timeAxW, timeAxH)
    if ~exist('timeAxW', 'var') || isempty(timeAxW)
        timeAxW = 0.53;
    end
    if ~exist('timeAxH', 'var') || isempty(timeAxH)
        timeAxH = 0.09;
    end
    t = pack.t;
    truth = pack.truth;
    predictions = pack.predictions;
    labels = pack.labels;
    colors = validationColors(labels);
    legendText = [{'True'}, labels];
    nRows = 4;
    gap = 0.006;
    titleSpace = 0.012;
    totalH = nRows * timeAxH + (nRows - 1) * gap + titleSpace;
    blockBottom = panelPos(2) + (panelPos(4) - totalH) / 2;
    blockTop = blockBottom + totalH;
    axX = panelPos(1);
    axW = timeAxW;
    axH = timeAxH;
    degree = char(176);
    yLabels = {'u (m/s)', 'v (m/s)', ['r (' degree '/s)'], ['\psi (' degree ')']};
    for sp = 1:nRows
        axY = blockTop - titleSpace - sp * axH - (sp - 1) * gap;
        ax = axes(fig, 'Position', [axX axY axW axH]);
        hold(ax, 'on');
        switch sp
            case 1
                plot(ax, t, truth.u, 'k-', 'LineWidth', 1.0);
                for i = 1:numel(predictions)
                    plot(ax, t, predictions{i}.u, ...
                        'Color', colors(i, :), 'LineWidth', 0.9);
                end
            case 2
                plot(ax, t, truth.v, 'k-', 'LineWidth', 1.0);
                for i = 1:numel(predictions)
                    plot(ax, t, predictions{i}.v, ...
                        'Color', colors(i, :), 'LineWidth', 0.9);
                end
            case 3
                plot(ax, t, truth.r * 180/pi, 'k-', 'LineWidth', 1.0);
                for i = 1:numel(predictions)
                    plot(ax, t, predictions{i}.r * 180/pi, ...
                        'Color', colors(i, :), 'LineWidth', 0.9);
                end
            case 4
                plot(ax, t, wrapAngle(truth.psi) * 180/pi, 'k-', 'LineWidth', 1.0);
                for i = 1:numel(predictions)
                    plot(ax, t, wrapAngle(predictions{i}.psi) * 180/pi, ...
                        'Color', colors(i, :), 'LineWidth', 0.9);
                end
        end
        grid(ax, 'on');
        box(ax, 'on');
        if showYLabel
            ylabel(ax, yLabels{sp});
        else
            ylabel(ax, '');
            set(ax, 'YTickLabel', []);
        end
        if sp < nRows
            set(ax, 'XTickLabel', []);
        else
            xlabel(ax, 'Time (s)');
        end
        if ~isempty(t)
            xlim(ax, [t(1), t(end)]);
        end
        if sp == 1
            title(ax, titleText, 'FontWeight', 'bold');
            if showLegend
                legend(ax, legendText, ...
                    'Location', 'northeast', ...
                    'Box', 'off', ...
                    'NumColumns', 3);
            end
        end
    end
end
function plotXYTrajectoryPanel(fig, panelPos, pack, titleText, showLegend)
    ax = axes(fig, 'Position', panelPos);
    hold(ax, 'on');
    [xTrue, yTrue] = getXYFromPack(pack);
    allPlotX = [];
    allPlotY = [];
    if ~isempty(xTrue) && ~isempty(yTrue)
        plot(ax, yTrue, xTrue, 'k-', ...
            'LineWidth', 1.2, ...
            'DisplayName', 'True');
        allPlotX = [allPlotX, yTrue(:)'];
        allPlotY = [allPlotY, xTrue(:)'];
    end
    colors = validationColors(pack.labels);
    for i = 1:numel(pack.predictions)
        pred = pack.predictions{i};
        [xPred, yPred] = getPredictedXY(pred, pack);
        if ~isempty(xPred) && ~isempty(yPred)
            plot(ax, yPred, xPred, ...
                'Color', colors(i, :), ...
                'LineWidth', 0.9, ...
                'DisplayName', pack.labels{i});
            allPlotX = [allPlotX, yPred(:)']; %#ok<AGROW>
            allPlotY = [allPlotY, xPred(:)']; %#ok<AGROW>
        end
    end
    grid(ax, 'on');
    box(ax, 'on');
    xlabel(ax, 'Y (m)');
    ylabel(ax, 'X (m)');
    title(ax, titleText, 'FontWeight', 'bold');
    compactAxis2D(ax, allPlotX, allPlotY);
    axis(ax, 'normal');
    daspect(ax, 'auto');
    pbaspect(ax, [1 1 1]);
    if showLegend
        legend(ax, 'Location', 'best', 'Box', 'off');
    end
end
function [xPred, yPred] = getPredictedXY(pred, pack)
    xPred = [];
    yPred = [];
    if isfield(pred, 'x') && isfield(pred, 'y')
        xPred = pred.x;
        yPred = pred.y;
        return;
    end
    if ~isfield(pred, 'u') || ~isfield(pred, 'v') || ~isfield(pred, 'psi')
        return;
    end
    t = pack.t;
    if numel(t) < 2
        return;
    end
    Ts = mean(diff(t));
    u = pred.u(:)';
    v = pred.v(:)';
    psi = pred.psi(:)';
    n = min([numel(u), numel(v), numel(psi), numel(t)]);
    if n <= 1
        return;
    end
    u = u(1:n);
    v = v(1:n);
    psi = psi(1:n);
    [xTrue, yTrue] = getXYFromPack(pack);
    if isempty(xTrue) || isempty(yTrue)
        x0 = 0;
        y0 = 0;
    else
        x0 = xTrue(1);
        y0 = yTrue(1);
    end
    xPred = zeros(1, n);
    yPred = zeros(1, n);
    xPred(1) = x0;
    yPred(1) = y0;
    for k = 1:n-1
        xDot = u(k) * cos(psi(k)) - v(k) * sin(psi(k));
        yDot = u(k) * sin(psi(k)) + v(k) * cos(psi(k));
        xPred(k+1) = xPred(k) + Ts * xDot;
        yPred(k+1) = yPred(k) + Ts * yDot;
    end
end
function [x, y] = getXYFromPack(pack)
    truth = pack.truth;
    if isfield(truth, 'x') && isfield(truth, 'y')
        x = truth.x;
        y = truth.y;
        return;
    end
    data = pack.data;
    if size(data, 2) >= 5
        x = data(1:end-1, 4);
        y = data(1:end-1, 5);
    else
        x = [];
        y = [];
    end
end
function idx = findCaseByName(plotPacks, caseName)
    idx = [];
    target = lower(caseName);
    for i = 1:numel(plotPacks)
        if contains(lower(plotPacks(i).name), target)
            idx = i;
            return;
        end
    end
end
function drawMissingPanel(fig, panelPos, caseName)
    ax = axes(fig, 'Position', panelPos);
    axis(ax, 'off');
    text(ax, 0.5, 0.5, ['Case not found: ', caseName], ...
        'HorizontalAlignment', 'center');
end
function compactAxis2D(ax, xData, yData)
    xData = xData(isfinite(xData));
    yData = yData(isfinite(yData));
    if isempty(xData) || isempty(yData)
        return;
    end
    xMin = min(xData);
    xMax = max(xData);
    yMin = min(yData);
    yMax = max(yData);
    padRatio = 0.06;
    xPad = max((xMax - xMin) * padRatio, 1e-6);
    yPad = max((yMax - yMin) * padRatio, 1e-6);
    xlim(ax, [xMin - xPad, xMax + xPad]);
    ylim(ax, [yMin - yPad, yMax + yPad]);
end
function colors = validationColors(labels)
    colors = zeros(numel(labels), 3);
    for i = 1:numel(labels)
        name = lower(labels{i});
        if contains(name, 'global ls-svm') || contains(name, 'global lssvm')
            colors(i, :) = [0.00 0.45 0.74];
        elseif contains(name, 'this work') || contains(name, 'ours')
            colors(i, :) = [0.85 0.33 0.10];
        elseif contains(name, 'k-means')
            colors(i, :) = [0.00 0.60 0.50];
        elseif contains(name, 'global gp')
            colors(i, :) = [0.49 0.18 0.56];
        else
            colors(i, :) = [0.45 0.45 0.45];
        end
    end
end
function angle = wrapAngle(angle)
    angle = atan2(sin(angle), cos(angle));
end




