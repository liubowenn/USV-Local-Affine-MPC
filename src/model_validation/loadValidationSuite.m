function testSuite = loadValidationSuite()
% loadValidationSuite  Load validation datasets for open-loop prediction.

    if exist(dataFile('testSuite.mat'), 'file') == 2
        suiteFile = load(dataFile('testSuite.mat'), 'testSuite');
        testSuite = suiteFile.testSuite;
        testSuite = removeValidationCases(testSuite, {'zigzag15'});
    else
        dataFileStruct = load(dataFile('data_25.mat'), 'data_25');
        testSuite = struct('name', 'data_25', 'data', dataFileStruct.data_25);
    end
end

function testSuite = removeValidationCases(testSuite, namesToRemove)
    if isempty(testSuite)
        return;
    end

    keep = true(size(testSuite));
    for i = 1:numel(testSuite)
        keep(i) = ~any(strcmpi(testSuite(i).name, namesToRemove));
    end
    testSuite = testSuite(keep);
end
