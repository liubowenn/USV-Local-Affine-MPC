function psi_seq = generateHeadingReference(param, Nsim, Ts)
% generateHeadingReference  Generate a heading reference sequence.
%
% Supported types:
%   sine              - fixed-amplitude sinusoid
%   sine_decay        - sinusoid multiplied by exp(-t/tau)
%   sine_rise         - sinusoid multiplied by 1-exp(-t/tau)
%   multi_sine        - sum of multiple sinusoids
%   multi_sine_decay  - multi-sine multiplied by exp(-lambda*t)

    ref_type = getStructField(param, 'heading_ref_type', 'sine');
    t = (0:Nsim-1) * Ts;
    offset = getStructField(param, 'psi_sine_offset', 0);

    switch lower(ref_type)
        case 'sine'
            amp = getStructField(param, 'psi_sine_amp', pi/4);
            period = getStructField(param, 'psi_sine_period', 50);
            psi_seq = offset + amp * sin(2*pi*t/period);

        case 'sine_decay'
            amp = getStructField(param, 'psi_sine_amp', pi/4);
            period = getStructField(param, 'psi_sine_period', 50);
            decayTime = getStructField(param, 'psi_sine_decay_time', 30);
            psi_seq = offset + amp * exp(-t / decayTime) .* sin(2*pi*t/period);

        case 'sine_rise'
            amp = getStructField(param, 'psi_sine_amp', pi/4);
            period = getStructField(param, 'psi_sine_period', 50);
            riseTime = getStructField(param, 'psi_sine_rise_time', 30);
            psi_seq = offset + amp * (1 - exp(-t / riseTime)) .* sin(2*pi*t/period);

        case 'multi_sine'
            [amps, periods, phases] = multiSineParams(param);
            psi_seq = offset + multiSineReference(t, amps, periods, phases);

        case 'multi_sine_decay'
            [amps, periods, phases] = multiSineParams(param);
            decayLambda = getStructField(param, 'psi_multi_sine_decay_lambda', 0);
            psi_seq = offset + exp(-decayLambda * t) ...
                .* multiSineReference(t, amps, periods, phases);

        otherwise
            error('generateHeadingReference:UnknownType', ...
                ['Unknown heading_ref_type: %s. Use ''sine'', ''sine_decay'', ', ...
                '''sine_rise'', ''multi_sine'', or ''multi_sine_decay''.'], ref_type);
    end
end

function [amps, periods, phases] = multiSineParams(param)
    amps = getStructField(param, 'psi_multi_sine_amp', deg2rad([25, 8, 4]));
    periods = getStructField(param, 'psi_multi_sine_period', [30, 12, 7]);
    phases = getStructField(param, 'psi_multi_sine_phase', zeros(size(amps)));
end

function psi = multiSineReference(t, amps, periods, phases)
    amps = amps(:);
    periods = periods(:);
    phases = phases(:);
    if numel(amps) ~= numel(periods) || numel(amps) ~= numel(phases)
        error('multiSineReference:InvalidConfig', ...
            'psi_multi_sine_amp, psi_multi_sine_period, and psi_multi_sine_phase must have the same length.');
    end

    psi = zeros(size(t));
    for i = 1:numel(amps)
        psi = psi + amps(i) * sin(2*pi*t/periods(i) + phases(i));
    end
end
