function [psi_ref, e_y] = curveFrenetLOS(V, curve, delta)
% curveFrenetLOS  Frenet-frame line-of-sight heading guidance.
%
% The vessel state V uses [u; v; r; y; x; psi]. The projection is performed
% on the XY path, and the heading is interpolated along arc length.

    x = V(4);
    y = V(5);
    proj = projectToCurve(x, y, curve);
    psi_path = curveHeading(proj.s, curve);
    e_y = -(x - proj.x) * sin(psi_path) + (y - proj.y) * cos(psi_path);
    psi_ref = wrapToPi(psi_path - atan(e_y / delta));
end

function psi_path = curveHeading(s, curve)
    psi_path = interp1(curve.s, curve.psi, s, 'linear', 'extrap');
end
