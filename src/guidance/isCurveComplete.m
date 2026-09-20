function tf = isCurveComplete(V, curve, cfg)
% isCurveComplete  Check whether the vessel has reached the end of a path.

    finish_tol = getStructField(cfg, 'finish_tol', 1);
    finish_radius = getStructField(cfg, 'finish_radius', 5);
    proj = projectToCurve(V(4), V(5), curve);
    endpoint_dist = hypot(V(4) - curve.x(end), V(5) - curve.y(end));
    tf = proj.s >= curve.s(end) - finish_tol && endpoint_dist <= finish_radius;
end
