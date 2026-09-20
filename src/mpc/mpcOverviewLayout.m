function pos = mpcOverviewLayout(showCrossTrack, showSpeedTrack, figW, figH)
% mpcOverviewLayout  Return normalized axes positions for the MPC overview.

    if ~exist('figW', 'var') || isempty(figW)
        figW = 7.2;
        figH = 5.8;
    end

    left = 0.056;
    right = 0.030;
    fullW = 1 - left - right;

    topMargin = 0.024;

    xyH = 0.316;
    xyW = xyH * figH / figW;
    xyX = left;
    xyY = 1 - topMargin - xyH;

    colGap = 0.045;
    tauX0 = xyX + xyW + colGap;
    tauW = 1 - right - tauX0;

    tauGap = 0.030;
    tauH = (xyH - tauGap) / 2;

    pos.xy = [xyX, xyY, xyW, xyH];
    pos.tauX = [tauX0, xyY + tauH + tauGap, tauW, tauH];
    pos.tauN = [tauX0, xyY, tauW, tauH];

    lowerTop = xyY - 0.038;

    if showSpeedTrack
        pos = lowerLayoutWithSpeed(pos, left, fullW, lowerTop, showCrossTrack);
    elseif showCrossTrack
        pos = lowerLayoutWithCrossTrack(pos, left, fullW, lowerTop);
    else
        pos = lowerLayoutHeadingOnly(pos, left, fullW, lowerTop);
    end
end

function pos = lowerLayoutWithSpeed(pos, left, fullW, lowerTop, showCrossTrack)
    bottom = 0.045;
    gap = 0.021;

    solveH = 0.084;
    speedH = 0.118;
    headingH = 0.118;
    headingErrH = 0.087;
    crossH = 0.087;

    y = bottom;

    pos.solve = [left, y, fullW, solveH];
    y = y + solveH + gap;

    if showCrossTrack
        pos.cross = [left, y, fullW, crossH];
        y = y + crossH + gap;
    end

    pos.headingErr = [left, y, fullW, headingErrH];
    y = y + headingErrH + gap;

    pos.heading = [left, y, fullW, headingH];
    y = y + headingH + gap;

    pos.speed = [left, y, fullW, speedH];
    pos = shiftDownIfNeeded(pos, lowerTop);
end

function pos = lowerLayoutWithCrossTrack(pos, left, fullW, lowerTop)
    bottom = 0.065;
    gap = 0.030;

    solveH = 0.082;
    crossH = 0.092;
    headingErrH = 0.130;
    headingH = 0.130;

    y = bottom;

    pos.solve = [left, y, fullW, solveH];
    y = y + solveH + gap;

    pos.cross = [left, y, fullW, crossH];
    y = y + crossH + gap;

    pos.headingErr = [left, y, fullW, headingErrH];
    y = y + headingErrH + gap;

    pos.heading = [left, y, fullW, headingH];
    pos = shiftDownIfNeeded(pos, lowerTop);
end

function pos = lowerLayoutHeadingOnly(pos, left, fullW, lowerTop)
    bottom = 0.070;
    gap = 0.040;

    solveH = 0.088;
    headingErrH = 0.155;
    headingH = 0.155;

    y = bottom;

    pos.solve = [left, y, fullW, solveH];
    y = y + solveH + gap;

    pos.headingErr = [left, y, fullW, headingErrH];
    y = y + headingErrH + gap;

    pos.heading = [left, y, fullW, headingH];
    pos = shiftDownIfNeeded(pos, lowerTop);
end

function pos = shiftDownIfNeeded(pos, lowerTop)
    fields = fieldnames(pos);
    movable = setdiff(fields, {'xy', 'tauX', 'tauN'});
    topUsed = -inf;

    for i = 1:numel(movable)
        p = pos.(movable{i});
        topUsed = max(topUsed, p(2) + p(4));
    end

    if topUsed <= lowerTop
        return;
    end

    shift = topUsed - lowerTop;
    for i = 1:numel(movable)
        p = pos.(movable{i});
        p(2) = p(2) - shift;
        pos.(movable{i}) = p;
    end
end
