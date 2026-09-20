function repeatInfo = discoverRepeatedClusterModels(useRepeatedModels)
% discoverRepeatedClusterModels  Locate repeated FCM/K-means model packages.

    if ~exist('useRepeatedModels', 'var') || isempty(useRepeatedModels)
        useRepeatedModels = false;
    end

    repeatInfo = emptyRepeatInfo();
    if ~useRepeatedModels
        return;
    end

    repeatInfo.package = loadRepeatedClusterModelPackage();
    repeatInfo.usePackage = ~isempty(repeatInfo.package);

    if repeatInfo.usePackage
        repeatInfo.fcmTags = repeatInfo.package.FCM.tags;
        repeatInfo.kmeansTags = repeatInfo.package.KMEANS.tags;
    else
        repeatInfo.fcmTags = findRepeatedTags('FCM_REPEAT_');
        repeatInfo.kmeansTags = findRepeatedTags('KMEANS_REPEAT_');
    end

    repeatInfo.enabled = ...
        ~isempty(repeatInfo.fcmTags) && ~isempty(repeatInfo.kmeansTags);
    repeatInfo.fcmBeta = currentFcmBeta();
end

function repeatInfo = emptyRepeatInfo()
    repeatInfo = struct( ...
        'package', [], ...
        'usePackage', false, ...
        'fcmTags', {{}}, ...
        'kmeansTags', {{}}, ...
        'enabled', false, ...
        'fcmBeta', currentFcmBeta());
end

function package = loadRepeatedClusterModelPackage()
    package = [];
    packageFile = repeatedModelFile('repeatedClusterModels.mat');

    if exist(packageFile, 'file') ~= 2
        return;
    end

    s = load(packageFile, 'repeatedClusterModels');
    package = s.repeatedClusterModels;

    if ~isfield(package, 'FCM') || ~isfield(package, 'KMEANS')
        package = [];
    end
end

function tags = findRepeatedTags(prefix)
    files = dir(dataFile(['clusterTail_' prefix '*.mat'], artifactSourceName()));
    tags = cell(1, numel(files));

    for i = 1:numel(files)
        name = files(i).name;
        tags{i} = erase(erase(name, 'clusterTail_'), '.mat');
    end

    pattern = ['^' prefix '\d+$'];
    tags = tags(~cellfun('isempty', regexp(tags, pattern, 'once')));
    tags = sort(tags);
end

function beta = currentFcmBeta()
    beta = 1;

    if exist(fullfile('scripts', 'defaultExperimentConfig.m'), 'file') == 2
        cfg = defaultExperimentConfig();
        beta = getStructField(cfg.weighted_fcm, 'beta', beta);
    end

    if exist(dataFile('clusterTail_FCM.mat', artifactSourceName()), 'file') == 2
        s = load(dataFile('clusterTail_FCM.mat', artifactSourceName()), 'clusterTail');
        beta = getStructField(s.clusterTail, 'fusion_beta', beta);
    end
end
