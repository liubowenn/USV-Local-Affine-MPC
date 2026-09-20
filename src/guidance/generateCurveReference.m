function curve = generateCurveReference(cfg)
% generateCurveReference  Build a sampled reference curve for path following.
%
% The returned curve contains x/y coordinates, unwrapped path heading psi,
% and cumulative arc length s. Guidance functions use s-based interpolation
% so non-monotonic paths such as circles are supported.

    curve_type = getStructField(cfg, 'type', 'sine_s');
    switch lower(curve_type)
        case 'sine_s'
            curve = sineSCurve(cfg);
        case 'circle'
            curve = circleCurve(cfg);
        otherwise
            error('generateCurveReference:UnknownType', ...
                'Unknown curve type: %s', curve_type);
    end
end

function curve = sineSCurve(cfg)
    L = getStructField(cfg, 'length', 450);
    A = getStructField(cfg, 'amplitude', 60);
    lambda = getStructField(cfg, 'wavelength', 220);
    ds = getStructField(cfg, 'ds', 1);
    x = 0:ds:L;
    theta = 2*pi*x/lambda;

    if isfield(cfg, 'amplitude_start') || isfield(cfg, 'amplitude_end')
        A0 = getStructField(cfg, 'amplitude_start', A);
        A1 = getStructField(cfg, 'amplitude_end', A);
        growth = getStructField(cfg, 'amplitude_growth', 'linear');
        switch lower(growth)
            case 'exponential'
                ampLambda = log(A1 / max(A0, eps)) / max(L, eps);
                Aenv = A0 * exp(ampLambda * x);
                dA = ampLambda * Aenv;
            otherwise
                Aenv = A0 + (A1 - A0) * x / max(L, eps);
                dA = (A1 - A0) / max(L, eps);
        end
    else
        Aenv = A * ones(size(x));
        dA = 0;
    end

    y = Aenv .* sin(theta);
    dydx = dA .* sin(theta) + Aenv .* (2*pi/lambda) .* cos(theta);
    psi = atan2(dydx, ones(size(dydx)));

    curve.x = x;
    curve.y = y;
    curve.psi = unwrap(psi);
    curve.s = cumulativeArcLength(x, y);
    curve.L = L;
    curve.A = Aenv;
    curve.lambda = lambda;
end

function curve = circleCurve(cfg)
    R = getStructField(cfg, 'radius', 20);
    ds = getStructField(cfg, 'ds', 0.25);
    dtheta = ds / max(R, eps);
    theta = 0:dtheta:(2*pi - dtheta);
    x = R * sin(theta);
    y = R * (1 - cos(theta));
    psi = unwrap(atan2(sin(theta), cos(theta)));

    curve.x = x;
    curve.y = y;
    curve.psi = psi;
    curve.s = cumulativeArcLength(x, y);
    curve.R = R;
end

function s = cumulativeArcLength(x, y)
    s = [0, cumsum(sqrt(diff(x).^2 + diff(y).^2))];
end
