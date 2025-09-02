function localTester(opts)
arguments
    % Whether to use the parallel toolbox. This enables timeouts.
    opts.useParallel = true;
    % Source folder where the assignment folder can be found.
    opts.sourceFolder = 'cs1371';
    % Folder where code to grade can be found.
    opts.submissionFolder = 'submissions';
end
% Ask user for assignment name
assignmentName = input('Enter assignment name: ', 's');
% Find paths of interest
currPath = pwd;
mainPath = fileparts(currPath);
submissionPath = fullfile(mainPath, opts.submissionFolder);
assignmentPath = fullfile(mainPath, opts.sourceFolder, assignmentName);
% Setup
c = onCleanup(@()cleanupFnc());
% Run autograder
Autograder(AssignmentPath=assignmentPath, SubmissionPath=submissionPath, UseParallel=opts.useParallel);
% Move and open results file
destination = fullfile(mainPath, 'results.json');
movefile(fullfile(currPath, 'results.json'), destination);
open(destination)
end

function cleanupFnc()
% On cleanup, delete files created during run
files = dir();
files = files(~[files.isdir]);
fileNames = {files.name};
% List of files to ignore
ignoreFiles = {'results.json', 'localTester.m', 'encrypt.m', 'run_autograder', 'Function_List.json'};
for i = 1:length(fileNames)
    if ~any(strcmp(fileNames{i}, ignoreFiles))
        delete(fileNames{i});
    end
end
% Remove namespaces
rmdir('+solution', 's');
rmdir('+student', 's');
end
