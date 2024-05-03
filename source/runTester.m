function runTester
submission = jsondecode(fileread('/autograder/submission_metadata.json'));
assignment_name = submission.assignment.title; % Import this from gradescope metadata

%% Run tester with suppressed output
[~, tests] = evalc("runtests(sprintf('./testers/%sTester.m', assignment_name))");

%% Parse through the results of the tester and create a structure with relevant data
% Store the results in the results structure
% results.name will store the name of the test cases run
% results.passed will store whether or not they passed the test case
% results.details will store details of why the student's code failed. It is empty otherwise.
%
% Any strings passed into a .json cannot contain a formatted string from matlab,
% so sprintf cannot be used. For failed cases, we replace the formatted '\n' by masking it,
% replacing it with a temp character '`', and then replacing it with the escape sequence. The double
% quotes are also replaced with single quotes.
% 
% The diagnostic output cuts output past "Framework Diagnostics", which means the tester is
% responsible for outputting the relevant data to gradescope.
%
% If a student code errors, the exception is read in and a message is generated. The student's
% script will also be read to output the relevant line to gradescope.

results = struct();
json = jsondecode(fileread(sprintf('./testers/%sScores.json', assignment_name)));
for i = 1:length(tests)
    results(i).name = extractAfter(tests(i).Name, '/');
    results(i).passed = tests(i).Passed;
    if tests(i).Incomplete
        try
            exception = tests(i).Details.DiagnosticRecord.Exception;
            line_num = exception.stack(1).line;
            if strcmp(exception.stack(1).name, extractBefore(results(i).name, '_'))
                script = strip(readlines(sprintf('%s.m', extractBefore(results(i).name, '_'))));
                line = strip(script(line_num));
                results(i).output = ['An error occured while running your function.\n    ---------------------\n    Description: ' exception.message '\n    Location: line ' num2str(line_num), '\n    Code: ', char(line)];
            else
                results(i).output = ['An error occured while running your function.\n    ---------------------\n    Description: ' exception.message];
            end
        catch
            results(i).output = 'An unknown error has occured while running your function.';
        end
    elseif tests(i).Failed
        out = tests(i).Details.DiagnosticRecord.Report;
        out(out == 10) = '`';
        out = strrep(out, '`', '\n');
        out = strrep(out, '"', '''');
        out = extractBefore(out, '\n    ---------------------\n    Framework Diagnostic');
        results(i).output = out;
    end
end

%% Determine the points per test case
% Find the number of test cases present for each function and divide from the max score for that
% function. points_per_tests is stored under the json structure at json.tests.
%
% An error is thrown if this does not work. Most likely, there is a discrepancy between the
% Scores.json file provided and the tester.m provided.

try
    for i = 1:length(json.tests)
        json.tests(i).points_per_test = json.tests(i).max_score / sum(contains({results.name}, json.tests(i).name));
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

try
    for i = 1:length(results)
        if results(i).passed
            results(i).score = json.tests(strcmp({json.tests.name}, extractBefore(results(i).name, '_'))).points_per_test;
        else
            results(i).score = 0;
        end
        results(i).max_score = json.tests(strcmp({json.tests.name}, extractBefore(results(i).name, '_'))).points_per_test;
    end
catch
    error('There was an error assigning each test case the proper number of points. Was there a typo somewhere in the json or tester?');
end

%% Parse through results to create cell array containing each test case
% Gradescope doesn't like it when a field is empty and Matlab doesn't like jagged structures,
% so we compromise by splitting up the structure, removing empty fields, and placing the smaller
% structures into cells.
% If there is no ouput text to display (ie. results.output is empty), it will get removed and added
% to a cell.

results = rmfield(results, 'passed'); % No need for field anymore
tests = cell(length(results), 1);
for i = 1:length(results)
    if isempty(results(i).output)
        tests{i} = rmfield(results(i), 'output');
    else
        tests{i} = results(i);
    end
end

%% Write json structure to final results.json file
json.tests = tests;
json = jsonencode(json);
fh = fopen(fullfile(pwd, 'results.json'), 'w');
fprintf(fh, json);
fclose('all');
end