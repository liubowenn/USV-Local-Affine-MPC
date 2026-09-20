function preset = curveScenarioPreset(name)
% curveScenarioPreset  Return named curve-tracking scenario overrides.
%
% This function is used by applyMpcEnvironmentOverride when the environment
% variable MPC_CURVE_SCENARIO is set. It keeps scenario definitions in one
% place for scripts and batch runs.

    switch lower(char(name))
        case 'sine_s'
            preset.curve = sineCurve('sine_s', 50, 20, 50, 3);

        case 'circle'
            preset.curve = circleCurve('circle', 18, 0.25, 4);

        case 'rising_peak_sine_s'
            preset.curve = risingSineCurve('rising_peak_sine_s', ...
                200, 10, 40, 50, 5, 'exponential');

        case 'strong_current_s'
            preset.curve = sineCurve('strong_current_s', 95, 35, 60, 9);
            preset.wave.V_c_amp = 0.2;
            preset.wave.V_c_amp2 = 0.02;
            preset.wave.beta_amp = pi / 10;

        case 'heavy_payload_s'
            preset.curve = sineCurve('heavy_payload_s', 95, 35, 120, 9);
            preset.mp.mp_base = 18;
            preset.mp.mp_amp = 7;
            preset.mp.mp_min = 12;
            preset.mp.mp_max = 28;

        otherwise
            error('curveScenarioPreset:UnknownScenario', ...
                'Unknown curve scenario: %s', name);
    end
end

function curve = sineCurve(name, len, amp, wavelength, losDelta)
    curve.name = name;
    curve.type = 'sine_s';
    curve.length = len;
    curve.amplitude = amp;
    curve.wavelength = wavelength;
    curve.ds = 0.25;
    curve.guidance = 'frenet_los';
    curve.los_delta = losDelta;
    curve.finish_tol = 1;
    curve.finish_radius = 5;
end

function curve = risingSineCurve(name, len, ampStart, ampEnd, wavelength, losDelta, growth)
    curve = sineCurve(name, len, ampEnd, wavelength, losDelta);
    curve.amplitude_start = ampStart;
    curve.amplitude_end = ampEnd;
    curve.amplitude_growth = growth;
end

function curve = circleCurve(name, radius, ds, losDelta)
    curve.name = name;
    curve.type = 'circle';
    curve.radius = radius;
    curve.ds = ds;
    curve.guidance = 'frenet_los';
    curve.los_delta = losDelta;
    curve.finish_tol = 1;
    curve.finish_radius = 5;
end
