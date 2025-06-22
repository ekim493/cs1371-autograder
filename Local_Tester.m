%% Modify these variables
useParallel = true;
localTimeout = 30;
sourceFolder = 'cs1371';
assignmentName = input('Enter assignment name: ', 's'); % Keep as prompt or change to manual input

%% Main script
runLocalTester(useParallel, localTimeout, sourceFolder, assignmentName);

function runLocalTester(useParallel, localTimeout, sourceFolder, assignmentName)
mainPath = pwd;
assignmentPath = fullfile(sourceFolder, assignmentName);
c = onCleanup(@()cleanupFnc(mainPath, assignmentPath));
addpath('submissions')
addpath(assignmentPath)
cd('src')
pause(0.1);
runTester(useParallel, localTimeout, assignmentName);
movefile("results.json", "..")
open("../results.json")
end

function cleanupFnc(mainPath, assignmentPath)
files = dir();
files = files(~[files.isdir]);
for file = {files.name}
    if ~(strcmp(file{1}, 'run_autograder') || ...
            strcmp(file{1}, 'README.md') || ...
            strcmp(file{1}, 'Allowed_Functions.json') || ...
            endsWith(file{1}, '.m'))
        delete(file{1});
    end
end
cd(mainPath);
rmpath('submissions')
rmpath(assignmentPath)
end