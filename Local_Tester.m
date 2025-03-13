clear; clc; close all;
assignment_name = input('Enter assignment name: ', 's');
useParallel = true;
timeout = 30;

addpath("Submissions")
addpath(sprintf('source/solutions/%s', assignment_name))
metadata = jsondecode(fileread('submission_metadata.json'));
metadata.assignment.title = assignment_name;
json = jsonencode(metadata);
fh = fopen('./Submissions/submission_metadata.json', 'w');
fprintf(fh, json);
fclose(fh);

cd("source")
pause(0.1);
runTester(useParallel, timeout);
movefile("results.json", "../")
files = dir();
files = files(~[files.isdir]);
for file = {files.name}
    if ~(strcmp(file{1}, 'run_autograder') || strcmp(file{1}, 'README.md') || endsWith(file{1}, '.m'))
        delete(file{1});
    end
end
cd("..")
open("results.json")
