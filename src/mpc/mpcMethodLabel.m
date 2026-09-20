function label = mpcMethodLabel(name)
% mpcMethodLabel  Convert a controller field name to a publication label.

    switch lower(char(name))
        case 'mss'
            label = 'Nomoto-tuned PID';
        case 'nc'
            label = 'MPC-Global LSSVM';
        case 'kmeans'
            label = 'MPC-K-means-LSSVM';
        case 'gp'
            label = 'MPC-Global GP';
        case 'fcm'
            label = 'Ours';
        otherwise
            label = upper(char(name));
    end
end
