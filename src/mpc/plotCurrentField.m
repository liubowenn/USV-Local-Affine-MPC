function plotCurrentField(ax, wave)
% plotCurrentField  Draw spatial current speed and direction on an XY panel.
%
% The XY panel uses Y as the horizontal axis and X as the vertical axis.
% The current map therefore samples the visible axis limits directly, so it
% always covers the same plotted area as the trajectory.
    if ~getStructField(wave, 'enabled', true) || ...
       ~strcmpi(getStructField(wave, 'mode', 'temporal'), 'spatial')
        return;
    end

    visibleYLim = xlim(ax);
    visibleXLim = ylim(ax);

    x = linspace(visibleXLim(1), visibleXLim(2), 36);
    y = linspace(visibleYLim(1), visibleYLim(2), 36);
    [Yg, Xg] = meshgrid(y, x);
    [speed, beta] = spatialCurrentField(Xg, Yg, wave);

    hImg = imagesc(ax, y, x, speed);
    hImg.AlphaData = 0.18 * isfinite(speed);
    hImg.HandleVisibility = 'off';
    uistack(hImg, 'bottom');
    colormap(ax, parula);

    xlim(ax, visibleYLim);
    ylim(ax, visibleXLim);

    cb = colorbar(ax);
    cb.Label.String = 'Current speed (m/s)';
    cb.FontSize = 7;

    qStep = 7;
    qY = Yg(1:qStep:end, 1:qStep:end);
    qX = Xg(1:qStep:end, 1:qStep:end);
    qBeta = beta(1:qStep:end, 1:qStep:end);

    drawCurrentDirectionArrows(ax, qY, qX, qBeta);
end


function drawCurrentDirectionArrows(ax, qY, qX, qBeta)
% Draw fixed visual-size arrows, then convert them back to data units.
    yLim = xlim(ax);
    xLim = ylim(ax);
    yRange = max(diff(yLim), eps);
    xRange = max(diff(xLim), eps);

    qYNorm = (qY - yLim(1)) / yRange;
    qXNorm = (qX - xLim(1)) / xRange;
    valid = isfinite(qYNorm) & isfinite(qXNorm) & isfinite(qBeta) ...
        & qYNorm >= 0 & qYNorm <= 1 & qXNorm >= 0 & qXNorm <= 1;

    if ~any(valid(:))
        return;
    end

    arrowLen = 0.08;
    headLen = 0.032;
    headWidth = 0.024;
    arrowColor = [0.25 0.25 0.25];

    holdState = ishold(ax);
    hold(ax, 'on');

    qYNorm = qYNorm(valid);
    qXNorm = qXNorm(valid);
    qBeta = qBeta(valid);

    for i = 1:numel(qBeta)
        dir = [sin(qBeta(i)); cos(qBeta(i))];
        tip = [qYNorm(i); qXNorm(i)] + arrowLen * dir;

        if any(tip < 0) || any(tip > 1)
            continue;
        end

        base = tip - headLen * dir;
        normal = [-dir(2); dir(1)];
        left = base + 0.5 * headWidth * normal;
        right = base - 0.5 * headWidth * normal;

        startData = normalizedXYToData([qYNorm(i); qXNorm(i)], yLim, xLim);
        baseData = normalizedXYToData(base, yLim, xLim);
        tipData = normalizedXYToData(tip, yLim, xLim);
        leftData = normalizedXYToData(left, yLim, xLim);
        rightData = normalizedXYToData(right, yLim, xLim);

        line(ax, [startData(1), baseData(1)], [startData(2), baseData(2)], ...
            'Color', arrowColor, ...
            'LineWidth', 0.55, ...
            'Clipping', 'on', ...
            'HandleVisibility', 'off');

        patch(ax, ...
            [tipData(1), leftData(1), rightData(1)], ...
            [tipData(2), leftData(2), rightData(2)], ...
            arrowColor, ...
            'EdgeColor', 'none', ...
            'FaceAlpha', 0.85, ...
            'Clipping', 'on', ...
            'HandleVisibility', 'off');
    end

    if ~holdState
        hold(ax, 'off');
    end
end


function dataPoint = normalizedXYToData(normPoint, yLim, xLim)
    dataY = yLim(1) + normPoint(1) * diff(yLim);
    dataX = xLim(1) + normPoint(2) * diff(xLim);
    dataPoint = [dataY; dataX];
end


function [speed, beta] = spatialCurrentField(x, y, wave)
    lx = getStructField(wave, 'x_wavelength', 45);
    ly = getStructField(wave, 'y_wavelength', 35);
    sx = sin(2*pi*x/max(lx, eps));
    cy = cos(2*pi*y/max(ly, eps));

    speed = getStructField(wave, 'V_c0', 0) ...
        + getStructField(wave, 'V_c_amp', 0) * (0.5 + 0.5*sx.*cy);
    speed = max(speed, 0);

    beta = getStructField(wave, 'beta_c0', 0) ...
        + getStructField(wave, 'beta_amp', 0) .* sin(2*pi*y/max(ly, eps));
end
