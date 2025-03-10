clear; clc; close all;
assignment_name = input('Enter assignment name: ', 's');
useParallel = true;

addpath("Submissions")
addpath(sprintf('source/solutions/%s', strrep(assignment_name, 'X', 'W')))
metadata = jsondecode(fileread('submission_metadata.json'));
metadata.assignment.title = assignment_name;
json = jsonencode(metadata);
fh = fopen('./Submissions/submission_metadata.json', 'w');
fprintf(fh, json);
fclose(fh);

cd("source")
pause(0.1);
runTester(useParallel);
movefile("results.json", "../")
files = dir();
files = files(~[files.isdir]);
for file = {files.name}
    if ~(strcmp(file{1}, 'run_autograder') || strcmp(file{1}, 'runTester.m') || strcmp(file{1}, 'README.md') || strcmp(file{1}, 'createTestOutput.m'))
        delete(file{1});
    end
end
cd("..")
open("results.json")
