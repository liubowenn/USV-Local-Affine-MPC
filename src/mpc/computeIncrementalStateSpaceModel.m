function [Phf, Gamma, H, lb, ub, Cblk, Qblk] = computeIncrementalStateSpaceModel(A, B, opts, b)
    % Build the prediction model used by the incremental MPC controller.
    %
    % Learned model:
    %   x_m(k+1) = A*x_m(k) + B*u(k) + b,  x_m = [u; v; r].
    %
    % MPC augmented state:
    %   xi = [du; dv; dr; dpsi; u; psi].
    % This supports heading-only tracking or [surge speed; heading] tracking.
    if ~exist('b', 'var') || isempty(b)
        b = zeros(size(A, 1), 1);
    end
    b = b(:);
    if numel(b) ~= size(A, 1) || any(~isfinite(b))
        error('computeIncrementalStateSpaceModel:InvalidBias', ...
            'Bias vector b must be finite and match the state dimension.');
    end
    Ts = opts.Ts;
    Np = opts.Np;
    Qpsi = opts.Qpsi;
    Qu = getStructField(opts, 'Qu', 0);
    trackU = getStructField(opts, 'mpc_track_u', false);
    Rdu = opts.Rdu;
    Du_lim = opts.Du_lim(:);
    if isscalar(Du_lim)
        Du_lim = repmat(Du_lim, 2, 1);
    end

    % Add heading dynamics by integrating yaw rate over one sample.
    Apsf = [A, zeros(3,1);
            0 0 Ts 1];
    Bpsf = [B; 0 0];

    % Accumulate absolute surge speed and heading from their increments.
    Cacc = [1 0 0 0;
            0 0 0 1];
    Abar = [Apsf, zeros(4,2);
            Cacc*Apsf, eye(2)];
    Bbar = [Bpsf;
            Cacc*Bpsf];
    if trackU
        % Output order is [surge speed; heading].
        Cbar = [0 0 0 0 1 0;
                0 0 0 0 0 1];
        Qstep = diag([Qu, Qpsi]);
    else
        % Heading-only output keeps the original MPC behavior.
        Cbar = [0 0 0 0 0 1];
        Qstep = Qpsi;
    end
    [nx, ~] = size(Abar);
    [~, nu] = size(Bbar);
    Phf = zeros(nx*Np, nx);
    Gamma = zeros(nx*Np, nu*Np);
    for i = 1:Np
        Phf((i-1)*nx+1:i*nx, :) = Abar^i;
        for j = 1:i
            Gamma((i-1)*nx+1:i*nx, (j-1)*nu+1:j*nu) = ...
                Abar^(i-j) * Bbar;
        end
    end
    Cblk = kron(eye(Np), Cbar);
    Qblk = kron(eye(Np), Qstep);
    H = Gamma' * Cblk' * Qblk * Cblk * Gamma + kron(eye(Np), Rdu);
    H = 0.5 * (H + H.');
    lb = repmat(-Du_lim, Np, 1);
    ub = repmat(Du_lim, Np, 1);
end
