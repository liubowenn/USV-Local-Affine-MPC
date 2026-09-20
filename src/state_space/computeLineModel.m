function [A, B, b] = computeLineModel(modelu, modelv, modelr)
    au = (modelu.alpha' * modelu.xtrain)';
    bu = modelu.b;
    av = (modelv.alpha' * modelv.xtrain)';
    bv = modelv.b;
    ar = (modelr.alpha' * modelr.xtrain)';
    br = modelr.b;
    A = [au(1), au(2), au(3);
         av(1), av(2), av(3);
         ar(1), ar(2), ar(3)];
    B = [au(4), au(5);
         av(4), av(5);
         ar(4), ar(5)];
    b = [bu; bv; br];
    if isDeltaModel(modelu) || isDeltaModel(modelv) || isDeltaModel(modelr)
        A = eye(3) + A;
    end
end
function tf = isDeltaModel(model)
    tf = isfield(model, 'prediction_target') && strcmpi(model.prediction_target, 'delta');
end


