function proj = projectToCurve(x, y, curve)
% projectToCurve  Project a point onto the nearest sampled curve segment.
%
% The returned projection contains x, y, and arc-length coordinate s.

    dist2 = (curve.x - x).^2 + (curve.y - y).^2;
    [~, idx] = min(dist2);
    i0 = max(1, idx - 2);
    i1 = min(numel(curve.x) - 1, idx + 2);

    best_dist2 = inf;
    proj.x = curve.x(idx);
    proj.y = curve.y(idx);
    proj.s = curve.s(idx);

    for i = i0:i1
        p0 = [curve.x(i), curve.y(i)];
        p1 = [curve.x(i+1), curve.y(i+1)];
        seg = p1 - p0;
        len2 = sum(seg.^2);
        if len2 < eps
            tau = 0;
        else
            tau = dot([x, y] - p0, seg) / len2;
            tau = min(max(tau, 0), 1);
        end

        p = p0 + tau * seg;
        d2 = sum(([x, y] - p).^2);
        if d2 < best_dist2
            best_dist2 = d2;
            proj.x = p(1);
            proj.y = p(2);
            proj.s = curve.s(i) + tau * (curve.s(i+1) - curve.s(i));
        end
    end
end
