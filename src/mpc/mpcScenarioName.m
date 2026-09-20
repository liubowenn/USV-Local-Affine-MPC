function scenario = mpcScenarioName(param)
% mpcScenarioName  Return the filesystem-safe MPC scenario name.

    mode = getStructField(param, 'mode', 'heading');
    switch lower(mode)
        case 'curve'
            curve = getStructField(param, 'curve', struct());
            scenario = ['curve_', getStructField(curve, 'name', ...
                getStructField(curve, 'type', 'sine_s'))];
        case 'heading'
            scenario = ['heading_', getStructField(param, 'heading_ref_type', 'sine')];
        otherwise
            scenario = char(mode);
    end
    scenario = regexprep(char(scenario), '[^\w-]', '_');
end
