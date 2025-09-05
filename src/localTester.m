function localTester(opts)
% LOCALTESTER - Test the autograder locally.
%   Run the autograder locally by pulling from a local submission folder. Note that the source folder and submission
%   folder should be located at the repository root, which is the parent folder of src.

arguments
    % Whether to use the parallel toolbox. This enables timeouts.
    opts.UseParallel = true;
    % Source folder where the assignments can be found.
    opts.SourceFolder = fullfile('examples', 'autograder');
    % Folder where code to be graded can be found.
    opts.SubmissionFolder = 'submission';
end
% Ask user for assignment name
assignmentName = input('Enter assignment name: ', 's');
% Find paths of interest
currPath = fileparts(mfilename('fullpath'));
mainPath = fileparts(currPath);
submissionPath = fullfile(mainPath, opts.SubmissionFolder);
assignmentPath = fullfile(mainPath, opts.SourceFolder, assignmentName);
% Setup
c = onCleanup(@()cleanupFnc(currPath));
% Run autograder
Autograder(ResultsPath=mainPath, AssignmentPath=assignmentPath, SubmissionPath=submissionPath, UseParallel=opts.UseParallel);
% Open results file
open(fullfile(mainPath, 'results.json'));
end

function cleanupFnc(currPath)
% On cleanup, delete files created during run
files = dir(currPath);
files = files(~[files.isdir]);
fileNames = {files.name};
% List of files to ignore
ignoreFiles = {'results.json', 'localTester.m', 'encrypt.m', 'run_autograder', 'Function_List.json'};
for i = 1:length(fileNames)
    if ~any(strcmp(fileNames{i}, ignoreFiles))
        delete(fullfile(currPath, fileNames{i}));
    end
end
% Remove namespaces
rmdir(fullfile('src', '+solution'), 's');
rmdir(fullfile('src', '+student'), 's');
end
