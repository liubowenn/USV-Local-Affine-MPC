function exportPaperFigures(figureDirectory)
% exportPaperFigures  Export complete edited publication figures as PNG files.
% Source FIG files remain local. Experiments and README tables are unchanged.
    narginchk(1, 1);
    root = fileparts(fileparts(mfilename('fullpath')));
    sourceNames = {'mss_open_loop_all_maneuvers', ...
        'heading_tracking_both_environments', 'trajectory_tracking_both_environments'};
    outputNames = {'mss_open_loop_predictions', ...
        'heading_tracking_both_environments', 'trajectory_tracking_both_environments'};
    for k = 1:numel(sourceNames)
        assert(isfile(fullfile(figureDirectory, [sourceNames{k}, '.fig'])), ...
            'Source figure not found: %s', sourceNames{k});
    end
    assetDirectory = fullfile(root, 'docs', 'assets');
    if ~isfolder(assetDirectory), mkdir(assetDirectory); end
    for k = 1:numel(sourceNames)
        fig = openfig(fullfile(figureDirectory, [sourceNames{k}, '.fig']), 'invisible');
        cleanup = onCleanup(@() close(fig));
        drawnow;
        legends = findall(fig, 'Type', 'legend');
        for j = 1:numel(legends)
            legends(j).String = paperLabels(legends(j).String);
        end
        drawnow;
        exportgraphics(fig, fullfile(assetDirectory, [outputNames{k}, '.png']), ...
            'Resolution', 200, 'BackgroundColor', 'white');
        clear cleanup;
    end
end

function labels = paperLabels(labels)
    labels = cellstr(string(labels));
    labels = strrep(labels, 'Global LSSVM', 'Global LS-SVM');
    labels = strrep(labels, 'K-means-LSSVM', 'K-means LS-SVM');
    labels = strrep(labels, 'MPC-global LSSVM', 'MPC-Global LS-SVM');
    labels = strrep(labels, 'MPC-k-means-LSSVM', 'MPC-K-means LS-SVM');
    labels = strrep(labels, 'MPC-global GP', 'MPC-Global GP');
    labels = strrep(labels, 'Ours', 'This work');
end
