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
mainPath = fileparts(fileparts(mfilename('fullpath')));
currPath = pwd;
submissionPath = fullfile(mainPath, opts.SubmissionFolder);
assignmentPath = fullfile(mainPath, opts.SourceFolder, assignmentName);
% Setup
initFiles = dir(currPath);
c = onCleanup(@()cleanupFnc(currPath, initFiles));
% Run autograder
Autograder(ResultsPath=mainPath, AssignmentPath=assignmentPath, SubmissionPath=submissionPath, UseParallel=opts.UseParallel);
% Open results file
open(fullfile(mainPath, 'results.json'));
end

function cleanupFnc(currPath, initFiles)
% On cleanup, delete files created during run
initFiles = initFiles(~[initFiles.isdir]);
files = dir(currPath);
fileNames = {files(~[files.isdir]).name};
initNames = {initFiles.name};
newFiles = setdiff(fileNames, initNames);
for i = 1:length(newFiles)
    if ~strcmp(newFiles{i}, 'results.json') % Ignore results if in currPath
        delete(fullfile(currPath, newFiles{i}));
    end
end
% Remove namespaces
rmdir(fullfile(currPath, '+solution'), 's');
rmdir(fullfile(currPath, '+student'), 's');
close('all');
end
