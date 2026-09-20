function mask = buildSwitchMask(tauN, radius)
    if ~exist('radius', 'var') || isempty(radius), radius = 10; end
    N = length(tauN);
    mask = false(N, 1);
    switchIdx = find(abs([0; diff(tauN(:))]) > 1e-8);
    for i = 1:length(switchIdx)
        lo = max(1, switchIdx(i) - radius);
        hi = min(N, switchIdx(i) + radius);
        mask(lo:hi) = true;
    end
    if ~any(mask)
        mask(:) = true;
    end
end


