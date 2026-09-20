function path = dataFile(filename, source)
    if ~exist('source', 'var')
        source = [];
    end
    if isModelMetadataFile(filename)
        sourceName = artifactSourceName(source);
        baseDir = fullfile('results', 'model_learned', sourceName, 'cluster_info');
    else
        baseDir = dataRoot(source);
    end
    if exist(baseDir, 'dir') ~= 7
        mkdir(baseDir);
    end
    path = fullfile(baseDir, filename);
end

function tf = isModelMetadataFile(filename)
    name = char(filename);
    tf = startsWith(name, 'cluster_index') || ...
         startsWith(name, 'clusters') || ...
         startsWith(name, 'clusterTail');
end
