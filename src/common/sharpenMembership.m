function membership = sharpenMembership(membership, beta)
    membership = max(membership(:), 1e-12);
    membership = membership .^ beta;
    membership = membership / max(sum(membership), 1e-12);
end


