function pack = buildValidationPlotPack(data, predictions, labels, caseName, Ts)
% buildValidationPlotPack  Package validation truth and predictions for plots.

    truth = truthFromData(data(1:end-1, :));
    N = length(truth.u);

    pack = emptyValidationPlotPack();
    pack.name = caseName;
    pack.t = Ts:Ts:N*Ts;
    pack.truth = truth;
    pack.predictions = predictions;
    pack.labels = labels;
    pack.data = data;
end
