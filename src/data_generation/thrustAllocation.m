function n = thrustAllocation(tau_X, tau_N)
    l1 = 0.395; l2 = -0.395; k = 0.011;
    nn = [1, 1; l1, l2] \ [tau_X; tau_N] * (1 / k);
    n = sqrt(abs(nn));
    if nn(1) < 0, n(1) = -n(1); end
    if nn(2) < 0, n(2) = -n(2); end
end


