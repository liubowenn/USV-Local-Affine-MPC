function K = gpLinearKernel(Xm, Xn, theta)
    sigma_f = exp(theta(1));
    sigma_b = exp(theta(2));
    K = (sigma_f^2) * (Xm * Xn') + sigma_b^2;
end


