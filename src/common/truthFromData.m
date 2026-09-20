function truth = truthFromData(XX)
    truth.u = XX(:, 1);
    truth.v = XX(:, 2);
    truth.r = XX(:, 3);
    truth.psi = XX(:, 6);
    if size(XX, 2) >= 5
        truth.x = XX(:, 4);
        truth.y = XX(:, 5);
    end
end


