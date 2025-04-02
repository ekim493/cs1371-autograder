function runTester(useParallel, timeout)
% RUNTESTER - Main function to run the Gradescope autograder.
%   This function finds the relevant assignment name using the submission metadata, and creates the test suite and calls
%   the runSuite() function. From those results, it will display the diagnostics, calculate the points scored for the
%   assignment, and create the final "results.json" file necessary for Gradescope.
%   
%   Input Arguments
%       useParallel - Whether runSuite() should run in parallel using parfeval.
%       timeout - Timeout of parfeval in seconds. Only relevant if useParallel = true.
%
%   By default, the following scoring assignment is used: Any incorrect level 0 problems deduct 50% from the final
%   score. Level 1-3 problems award 1-3 points total, divided by the number of test cases per problem. Level >=4
%   problems award no points.


% OS check. If Matlab is being run on Linux, assume it is the autograder and import the assignment name from Gradescope.
% Otherwise, use a local testing metadata file, which should be located in the ./Submissions folder.
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

% Check parallel toolbox status. Sometimes Gradescope/AWS bugs and the parallel toolbox fails to load.
if useParallel
    try
        gcp();
    catch E
        % If there is an issue initializing the toolbox, run in single threading instead
        disp("The parallel toobox isn't loading. Changing to series execution...")
        useParallel = false;
    end
end

% Add paths and copy dir if necessary
addpath('testers')
addpath(['solutions' filesep assignment_name]);
if isunix && ~ismac
    addpath('/autograder/submission');
    if exist(fullfile('solutions',assignment_name, 'dir'), 'dir')
        copyfile(fullfile('solutions', assignment_name, 'dir', '*'), '/autograder/source')
    end
end

% Run tester
runner = testrunner();
suite = testsuite(sprintf('%sTester', assignment_name));
results = runSuite(runner, suite, useParallel, timeout);

% Display Diagnostics. Skip if run in series and display is empty. Only get rid of first line indicating
% "Running HW#Tester".
for i = 1:height(results)
    if ~isempty(results.display{i})
        disp(extractAfter(results.display{i}, ['Tester' newline]));
    end
end

% Points per test case
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

% Parse table to assign necessary fields
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

% Level 0 Deduction
if ~all(results.passed(strcmp(results.level, 'L0')))
    totalScore = totalScore / 2;
end

% Remove unnecessary columns
results.passed = [];
results.level = [];
results.display = [];

% Output
json = struct('visibility', 'visible', 'score', totalScore, 'tests', results);

% Global Edits (optional)
if false
    json.output = ''; %#ok<UNRCH> % If a global text output is required, edit this value here.
    json.output_format = 'html'; % If the output text needs special formatting.
    tests = []; % Running this line will delete all prior test cases.
    json.score = 0; % If the global score needs to be modified
    json.visibility = 'after_due_date'; % If test case visibility needs to be changed.
    json.stdout_visibility = 'visible'; % If the command window output should be visible to students.
end

% Write json structure to final results.json file
json = jsonencode(json, PrettyPrint=true);
fh = fopen(fullfile(pwd, 'results.json'), 'w');
fprintf(fh, json);
fclose(fh);
end