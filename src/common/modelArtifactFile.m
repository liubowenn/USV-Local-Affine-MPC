function filePath = modelArtifactFile(fileName, source)
    if nargin < 2
        source = [];
    end
    sourceName = artifactSourceName(source);
    baseDir = fullfile('results', 'model_learned', sourceName, 'trained_models');
    if ~exist('fileName', 'var') || isempty(fileName)
        filePath = baseDir;
    else
        filePath = fullfile(baseDir, fileName);
    end
end
