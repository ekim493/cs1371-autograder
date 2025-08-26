%% Modify these variables
% Whether to use the parallel toolbox. This enables timeouts.
useParallel = true;
% Source folder where the assignment folder can be found.
sourceFolder = 'autograder';
% Folder where code to grade can be found.
submissionFolder = 'submissions';
% Name of the assignment.
assignmentName = input('Enter assignment name: ', 's');

%% Main script
runLocalTester(useParallel, sourceFolder, assignmentName, submissionFolder);

function runLocalTester(useParallel, sourceFolder, assignmentName, submissionFolder)
% Find paths of interest
currPath = pwd;
mainPath = fileparts(currPath);
submissionPath = fullfile(mainPath, submissionFolder);
assignmentPath = fullfile(mainPath, sourceFolder, assignmentName);
% Setup
addpath(submissionPath)
c = onCleanup(@()cleanupFnc(submissionPath));
% Run autograder
Autograder(AssignmentPath=assignmentPath, UseParallel=useParallel);
% Open results file
filePath = fullfile(currPath, 'results.json');
open(filePath)
end

function cleanupFnc(submissionPath)
% On cleanup, delete files created during run
files = dir();
files = files(~[files.isdir]);
fileNames = {files.name};
% List of files to ignore. Will also ignore all .m files
ignoreFiles = {'results.json', 'localTester.m', 'encrypt.m', 'run_autograder', 'Function_List.json'};
for i = 1:length(fileNames)
    if ~any(strcmp(fileNames{i}, ignoreFiles))
        delete(fileNames{i});
    end
end
% Remove submission directory
rmpath(submissionPath)
end
