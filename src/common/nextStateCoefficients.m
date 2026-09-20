function [a, b] = nextStateCoefficients(model, stateIdx)
    a = (model.alpha' * model.xtrain)';
    b = model.b;
    if isfield(model, 'prediction_target') && strcmpi(model.prediction_target, 'delta')
        a(stateIdx) = a(stateIdx) + 1;
    end
end


