%% Modify these variables
% Whether to use the parallel toolbox. This enables timeouts.
useParallel = true;
% Timeout duration for each testcase. Enabled if useParallel = true.
localTimeout = 30;
% Source folder where the assignment folder can be found.
sourceFolder = 'cs1371';
% Folder where code to grade can be found.
submissionFolder = 'submissions';
% Name of the assignment.
assignmentName = input('Enter assignment name: ', 's');

%% Main script
runLocalTester(useParallel, localTimeout, sourceFolder, assignmentName, submissionFolder);

function runLocalTester(useParallel, localTimeout, sourceFolder, assignmentName, submissionFolder)
% Find paths of interest
currPath = pwd;
mainPath = fileparts(currPath);
assignmentPath = fullfile(mainPath, sourceFolder, assignmentName);
c = onCleanup(@()cleanupFnc(currPath, mainPath, assignmentPath, submissionFolder));
% Work in the src directory but have submission and assignment folder in path
cd(fullfile(mainPath, 'src'))
addpath(fullfile(mainPath, submissionFolder))
addpath(assignmentPath)
pause(0.1);
% Run autograder
runTester(useParallel, localTimeout, assignmentName);
% Open results file
filePath = fullfile(currPath, 'results.json');
movefile('results.json', filePath)
open(filePath)
end

function cleanupFnc(initPath, mainPath, assignmentPath, submissionFolder)
% On cleanup, delete files created during run
files = dir();
files = files(~[files.isdir]);
fileNames = {files.name};
% List of files to ignore. Will also ignore all .m files
ignoreFiles = {'run_autograder', 'Allowed_Functions.json'};
for i = 1:length(fileNames)
    if ~(any(strcmp(fileNames{i}, ignoreFiles)) || endsWith(fileNames{i}, '.m'))
        delete(fileNames{i});
    end
end
% Return to original directory
cd(initPath);
rmpath(fullfile(mainPath, submissionFolder))
rmpath(assignmentPath)
end