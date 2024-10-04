function runTester
if isunix && ~ismac
    try
        submission = jsondecode(fileread('/autograder/submission_metadata.json')); % Import assignment name from gradescope
    catch
        error('The submission metadata wasn''t found.');
    end
else
    submission = jsondecode(fileread('submission_metadata.json')); % For local testing
end
assignment_name = submission.assignment.title;


%% Run tester
addpath('./testers')
suite = testsuite(sprintf('%sTester', assignment_name));
runner = testrunner();
tests = run(runner, suite);

%% Parse through the results of the tester and create a structure with relevant data
% Store the results in the results structure
% results.name will store the name of the test cases run
% results.passed will store whether or not they passed the test case
% results.details will store details of why the student's code failed. It is empty otherwise.
%
% Any strings passed into a .json cannot contain a formatted string from matlab,
% so sprintf cannot be used. For failed cases, we replace the formatted newline character by
% replacing it with the escape sequence '\n'. The double quotes are also replaced with single quotes.
% 
% The diagnostic output cuts output past "Framework Diagnostics", which means the tester is
% responsible for outputting the relevant data to gradescope. We iterate in the event that a test
% case has multiple verifications.
%
% If a student code errors, the report generated by the diagnostic is output, and anything past the
% 'Error in HWX... line is cut off.

results = struct();
json = jsondecode(fileread(sprintf('%sScores.json', assignment_name)));
for i = 1:length(tests)
    results(i).name = extractAfter(tests(i).Name, '/');
    results(i).passed = tests(i).Passed;
    if tests(i).Incomplete
        out = tests(i).Details.DiagnosticRecord.Report;
        if contains(out, 'Error in TesterHelper')
            results(i).output = 'The autograder ran into an unexpected error while running your function. Please contact the TAs for assistance.';
        else
            out = erase(out, [newline '    Error using evalc']);
            out = strrep(out, newline, '\n');
            out = char(extractBetween(out, '\n    --------------\n    Error Details:\n    --------------\n', '\n    \n    Error in H'));
            out = ['An error occured while running your function.\n    --------------\n    Error Details:\n    --------------\n' out];
        end
    elseif tests(i).Failed
        out = ['Verification failed in ' results(i).name '.\n    ----------------\n    Test Diagnostic:'];
        for j = 1:length(tests(i).Details.DiagnosticRecord)
            % Temp string created in case multiple verifications were run for one test case.
            temp = tests(i).Details.DiagnosticRecord(j).Report;
            temp = strrep(temp, newline, '\n');
            temp = char(extractBetween(temp, 'Test Diagnostic:\n    ----------------\n', '\n    ---------------------\n    Framework Diagnostic'));
            if isempty(temp) % If there is an issue and no output diagnostic is provided, simply skip output display.
                out = [];
                continue;
            end
            out = [out '\n    ----------------\n' temp];
        end
    end
    out = regexprep(out, '(\\)(?!n)', '\\\\'); % Blackslash error fix
    out = strrep(out, '"', ''''); % Replace double quotes with single
    out(out < 32) = '�'; % Remove illegal ascii characters
    out = strrep(out, '%', '%%'); % fprintf percent sign fix
    results(i).output = out; % Out stores a string with the output message to display to students.
end

%% Determine the points per test case
% Find the number of test cases present for each function and divide from the max score for that
% function. points_per_tests is stored under the json structure at json.tests.
%
% An error is thrown if this does not work. Most likely, there is a discrepancy between the
% Scores.json file provided and the tester.m provided.

try
    for i = 1:length(json.tests)
        if json.tests(i).level == 0 || json.tests(i).level > 3
            json.tests(i).points_per_test = 0;
        else
            json.tests(i).points_per_test = round(json.tests(i).level / sum(contains({results.name}, json.tests(i).name)), 2);
        end
    end
catch
    error('There was an error assigning the number of points per test case. Was there a typo somewhere in the json or tester?');
end

%% Iterate through results and assign each test case the proper number of points
% If the test case passed, assign points_per_test as their score.
% Otherwise, assign 0 points.
% Always assign max_score = points_per_test.
%
% An error is thrown if this does not work. Most likely, there is a discrepancy between the
% Scores.json file provided and the tester.m provided.

totalScore = 0;
try
    for i = 1:length(results)
        toFind = split(results(i).name, '_');
        toFind = toFind{1};
        if results(i).passed
            results(i).score = json.tests(strcmp({json.tests.name}, toFind)).points_per_test;
            results(i).status = 'passed';
            totalScore = totalScore + results(i).score;
        else
            results(i).score = 0;
            results(i).status = 'failed';
        end
        results(i).max_score = json.tests(strcmp({json.tests.name}, toFind)).points_per_test;
    end
catch
    error('There was an error assigning each test case the proper number of points. Was there a typo somewhere in the json or tester?');
end


%% Find all level 0 test cases and deduct score if any of them failed
% Create a cell array containing all the function names then find the ones that are level 0.
% If any of the level 0s failed a test case, then half the total score.

level_0 = {json.tests([json.tests.level] == 0).name};
prefixes = cellfun(@(x) split(x, '_'), {results.name}, 'UniformOutput', false);
prefixes = cellfun(@(x) x{1}, prefixes, 'UniformOutput', false);
isL0 = ismember(prefixes, level_0);

if ~(all([results(isL0).passed]))
    totalScore = totalScore / 2;
end

%% Parse through results to create cell array containing each test case
% Gradescope doesn't like it when a field is empty and Matlab doesn't like jagged structures,
% so we compromise by splitting up the structure, removing empty fields, and placing the smaller
% structures into cells.
% If there is no ouput text to display (ie. results.output is empty), it will get removed and added
% to a cell.

[results.output_format] = deal('html'); % Add output format
results = rmfield(results, 'passed'); % No need for field anymore
tests = cell(length(results), 1);
if isfield(results, 'output')
    for i = 1:length(results)
        if isempty(results(i).output)
            tests{i} = rmfield(results(i), 'output');
        else
            tests{i} = results(i);
        end
    end
else
    tests = results;
end

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
json.tests = tests;
json.score = totalScore;
json = jsonencode(json);
fh = fopen(fullfile(pwd, 'results.json'), 'w');
fprintf(fh, json);
fclose('all');
end