function label = mpcMethodLabel(name)
% mpcMethodLabel  Convert controller keys or saved labels to publication labels.

    switch lower(char(name))
        case {'mss', 'nomoto-tuned pid'}
            label = 'Nomoto-tuned PID';
        case {'nc', 'mpc-global lssvm', 'mpc-global ls-svm'}
            label = 'MPC-Global LS-SVM';
        case {'kmeans', 'mpc-k-means-lssvm', 'mpc-k-means ls-svm'}
            label = 'MPC-K-means LS-SVM';
        case {'gp', 'mpc-global gp'}
            label = 'MPC-Global GP';
        case {'fcm', 'ours', 'proposed', 'this work'}
            label = 'This work';
        otherwise
            label = char(name);
    end
end
