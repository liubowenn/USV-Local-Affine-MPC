function [psi_ref, e_y] = curveGuidance(V, curve, cfg)
% curveGuidance  Compute path-following reference heading and cross-track error.

    method = getStructField(cfg, 'guidance', 'frenet_los');
    switch lower(method)
        case 'frenet_los'
            delta = getStructField(cfg, 'los_delta', 18);
            [psi_ref, e_y] = curveFrenetLOS(V, curve, delta);
        otherwise
            error('curveGuidance:UnknownMethod', ...
                'Unknown curve guidance method: %s. Use ''frenet_los''.', method);
    end
end
