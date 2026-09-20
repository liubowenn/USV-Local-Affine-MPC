function filePath = mpcResultFile(fileName, source, scenario)
    if ~exist('source', 'var')
        source = [];
    end
    if ~exist('scenario', 'var')
        scenario = [];
    end
    sourceName = artifactSourceName(source);
    baseDir = fullfile(projectRoot(), 'results', 'mpc', sourceName);
    if ~isempty(scenario)
        baseDir = fullfile(baseDir, char(scenario));
    end
    if ~exist('fileName', 'var') || isempty(fileName)
        filePath = relativeToCurrentFolder(baseDir);
    else
        filePath = relativeToCurrentFolder(fullfile(baseDir, fileName));
    end
end
function rootDir = projectRoot()
    rootDir = fullfile(fileparts(mfilename('fullpath')), '..', '..');
    rootDir = char(java.io.File(rootDir).getCanonicalPath());
end
function relPath = relativeToCurrentFolder(absPath)
    absPath = char(java.io.File(absPath).getCanonicalPath());
    currentPath = char(java.io.File(pwd).getCanonicalPath());
    try
        currentUri = java.io.File([currentPath, filesep]).toURI();
        targetUri = java.io.File(absPath).toURI();
        relPath = char(currentUri.relativize(targetUri).getPath());
        if isempty(relPath) || strcmp(relPath, targetUri.getPath())
            relPath = char(java.nio.file.Paths.get(currentPath).relativize( ...
                java.nio.file.Paths.get(absPath)).toString());
        end
    catch
        relPath = absPath;
    end
    relPath = strrep(relPath, '/', filesep);
end



