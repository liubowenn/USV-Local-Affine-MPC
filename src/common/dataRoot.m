function root = dataRoot(source)
    if ~exist('source', 'var') || isempty(source)
        source = 'mss';
        envSource = getenv('MPC_DATA_SOURCE');
        if ~isempty(envSource)
            source = envSource;
        elseif exist('defaultExperimentConfig', 'file') == 2
            cfg = defaultExperimentConfig();
            if isfield(cfg, 'data') && isfield(cfg.data, 'source')
                source = cfg.data.source;
            end
        end
    end
    switch lower(char(source))
        case {'mss', 'mssdata'}
            root = fullfile('data', 'mss');
        case {'usv', 'usvsimu', 'usv_simulator', 'usv_simulatordata'}
            root = fullfile('data', 'usv_simulator');
        otherwise
            root = char(source);
    end
end
