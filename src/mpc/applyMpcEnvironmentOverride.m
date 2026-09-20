function param = applyMpcEnvironmentOverride(param)
    modeOverride = getenv('MPC_MODE');
    if ~isempty(modeOverride)
        param.mode = modeOverride;
    end

    scenarioName = getenv('MPC_CURVE_SCENARIO');
    if isempty(scenarioName)
        return;
    end

    preset = curveScenarioPreset(scenarioName);
    param.mode = 'curve';
    param.curve = mergeStruct(param.curve, preset.curve);
    if isfield(preset, 'wave')
        param.wave = mergeStruct(param.wave, preset.wave);
    end
    if isfield(preset, 'mp')
        param = mergeStruct(param, preset.mp);
    end
end

function out = mergeStruct(out, in)
    fields = fieldnames(in);
    for i = 1:numel(fields)
        out.(fields{i}) = in.(fields{i});
    end
end


