function runTester(useParallel)
%% OS check
% If Matlab is being run on Linux, assume it is the autograder and import the assignment name from Gradescope.
% Otherwise, use a local testing metadata file, which should be located in the /Submissions folder.
if isunix && ~ismac
    try
        submission = jsondecode(fileread('/autograder/submission_metadata.json')); % Import assignment name from gradescope
    catch
        error('The submission metadata wasn''t found.');
    end
else
    submission = jsondecode(fileread('../Submissions/submission_metadata.json')); % For local testing
end
assignment_name = submission.assignment.title;

%% Run tester
addpath('testers')
addpath('/autograder/submission');
runner = testrunner();
suite = testsuite(sprintf('%sTester', assignment_name));
results = runSuite(runner, suite, useParallel, 10);

%% Points per test case
problems = unique(extractBefore(results.name, '_'));
for i = 1:numel(problems)
    test_cases = contains(results.name, problems(i));
    level = str2double(extractAfter(results.level(find(test_cases, 1)), 'L'));
    if level <= 0 || level > 3
        results.max_score(test_cases) = 0;
    else
        results.max_score(test_cases) = round(level / sum(test_cases), 2);
    end
end

%% Parse
totalScore = 0;
for i = 1:height(results)
    results.output_format(i) = "html";
    if results.passed(i)
        results.score(i) = results.max_score(i);
        results.status(i) = "passed";
        totalScore = totalScore + results.max_score(i);
    else
        results.score(i) = 0;
        results.status(i) = "failed";
    end
end

%% Find all level 0 test cases and deduct score if any of them failed
% Create a cell array containing all the function names then find the ones that are level 0.
% If any of the level 0s failed a test case, then half the total score.

if ~all(results.passed(strcmp(results.level, 'L0')))
    totalScore = totalScore / 2;
end
results.passed = [];
results.level = [];

%% Output
json = struct('visibility', 'visible', 'score', totalScore, 'tests', results);


%% Global Edits (optional)
if false
    json.output = ''; % If a global text output is required, edit this value here.
    json.output_format = 'html'; % If the output text needs special formatting.
    tests = []; % Running this line will delete all prior test cases.
    json.score = 0; % If the global score needs to be modified
    json.visibility = 'after_due_date'; % If test case visibility needs to be changed. This can also be modified in the HW#Scores.json file.
    json.stdout_visibility = 'visible'; % If the command window output should be visible to students.
end

%% Write json structure to final results.json file
json = jsonencode(json, PrettyPrint=true);
fh = fopen(fullfile(pwd, 'results.json'), 'w');
fprintf(fh, json);
fclose('all');
end