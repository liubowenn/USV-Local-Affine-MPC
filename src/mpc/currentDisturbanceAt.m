function current_cmd = currentDisturbanceAt(V, wave, t)
% currentDisturbanceAt  Evaluate temporal or spatial current disturbance.
%
% Output:
%   current_cmd = [beta_c; V_c], where beta_c is current direction (rad)
%   and V_c is current speed (m/s). The vessel model consumes this vector.

    if ~getStructField(wave, 'enabled', true)
        current_cmd = [0; 0];
        return;
    end

    mode = getStructField(wave, 'mode', 'temporal');
    switch lower(mode)
        case 'spatial'
            x = V(4);
            y = V(5);
            lx = getStructField(wave, 'x_wavelength', 45);
            ly = getStructField(wave, 'y_wavelength', 35);
            sx = sin(2*pi*x/max(lx, eps));
            cy = cos(2*pi*y/max(ly, eps));
            V_c = getStructField(wave, 'V_c0', 0) ...
                + getStructField(wave, 'V_c_amp', 0) * (0.5 + 0.5*sx*cy);
            beta_c = getStructField(wave, 'beta_c0', 0) ...
                + getStructField(wave, 'beta_amp', 0) * sin(2*pi*y/max(ly, eps));

        otherwise
            V_c = getStructField(wave, 'V_c0', 0) ...
                + getStructField(wave, 'V_c_amp', 0) ...
                  * sin(getStructField(wave, 'freq1', 0) * t) ...
                + getStructField(wave, 'V_c_amp2', 0) ...
                  * cos(getStructField(wave, 'freq2', 0) * t);
            beta_c = getStructField(wave, 'beta_c0', 0) ...
                + getStructField(wave, 'beta_amp', 0) * sin(0.6*t);
    end

    current_cmd = [beta_c; max(V_c, 0)];
end
