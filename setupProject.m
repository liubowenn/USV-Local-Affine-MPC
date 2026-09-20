function rootDir = setupProject()
% setupProject  Initialize MATLAB paths for this project.
%
% Output:
%   rootDir - Absolute project root directory.

    rootDir = fileparts(mfilename('fullpath'));

    addpath(genpath(fullfile(rootDir, 'src')));
    addpath(genpath(fullfile(rootDir, 'scripts')));
    % Add runtime dependencies only; vendor tests/code generators stay off path.
    addpath(fullfile(rootDir, 'external', 'LSSVM'));
    addpath(fullfile(rootDir, 'external', 'MSS', 'GNC'));
    addpath(fullfile(rootDir, 'external', 'MSS', 'HYDRO'));
    if ispc && strcmp(computer('arch'), 'win64')
        addpath(fullfile(rootDir, 'external', 'osqp-matlab', ...
            'osqp-0.6.2-matlab-windows64'));
    end

    if exist('osqp', 'class') ~= 8 && exist('osqp', 'file') ~= 2
        warning('setupProject:OsqpNotFound', ...
            ['OSQP was not found on the MATLAB path. ', ...
             'Set param.qp_solver=''quadprog'' or check external/osqp-matlab.']);
    end
end
