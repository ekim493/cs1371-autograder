function results = runSuite(runner, suite, useParallel, timeout)
% RUNSUITE - Returns a table of results after running a test suite
%   This function takes in a runner, a test suite, and parameters to run unit tests. If useParallel is set to true, then
%   it will run each test case individually using parfeval, and it will cancel the job after timeout seconds. Otherwise,
%   it will simply run the suite on the input TestRunner.
%
%   Input Arguments
%       runner - matlab.unittest.TestRunner object to run test cases using.
%       suite - matlab.unittest.TestSuite object containing all the test cases to be run.
%       useParallel - Whether the test cases should be run in parallel using parfeval or not.
%       timeout - Timeout of parfeval running the test cases in seconds. Only relevant if useParallel = true.
%
%   Output Arguments
%       results - Table containing the following data: name of test case, level of test case, logical pass/fail, output
%       from createTestOutput(), and display text containing command window output of each Future (empty if useParallel
%       is false).

arguments
    runner (1, 1) {mustBeA(runner, 'matlab.unittest.TestRunner')}
    suite (:, :) {mustBeA(suite, 'matlab.unittest.TestSuite')}
    useParallel (1, 1) logical = true
    timeout (1, 1) double = 30
end

disp('Running Test Suite...')

if useParallel
    % Run each test on parfeval for parallel execution. Use runSuiteHelper
    for i = 1:numel(suite)
        group(i) = parfeval(@runSuiteHelper, 1, runner, suite(i)); %#ok<AGROW>
    end
    % Once all Futures are queued, monitor their state every 0.01 seconds. Cancel any Futures that have been running for
    % more than "timeout" amount of seconds. Run until all cases have finished (or timed out).
    while ~all(strcmp({group.State}, 'finished'))
        cancel(group([group.RunningDuration] > duration(0, 0, timeout)));
        pause(0.01);
    end
    parfevalOnAll(@fclose,0,'all'); % Clear opened files
else
    group = run(runner, suite);
    fclose('all'); % Clear opened files
end

% Create results table
results = table(Size=[numel(suite),5], VariableTypes={'string', 'string', 'logical', 'cell', 'cell'}, Variablenames={'name', 'level', 'passed', 'output', 'display'});
for i = 1:numel(suite)
    results.name(i) = extractAfter(suite(i).Name, 'Tester/');
    findL = contains(suite(i).Tags, 'L');
    if sum(findL) == 0
        error('HWTester:noTag', 'A level tag was not found for the testcase %s', results.name(i));
    elseif sum(findL) > 1
        error('HWTester:duplicateTag', 'Only one tag containing the character ''L'' should be present for test case %s', results.name(i));
    end
    results.level(i) = suite(i).Tags{findL};
    if useParallel
        results.display{i} = group(i).Diary;
        % If a Future was canceled, it will always have a RunningDuration > timeout and sometimes an error message
        if isempty(group(i).Error) && seconds(group(i).RunningDuration) < timeout
            testresult = fetchOutputs(group(i));
            results.passed(i) = testresult.Passed;
            results.output{i} = createTestOutput(testresult);
        else
            results.output{i} = sprintf('Verification failed in %s.\\n    ----------------\\n    Test Diagnostic:\\n    ----------------\\n    This function timed out because it took longer than %d seconds to run. Is there an infinite loop?', results.name(i), timeout);
        end
    else
        testresult = group(i);
        results.passed(i) = testresult.Passed;
        results.output{i} = createTestOutput(testresult);
    end
end
% Test cases sorted in order within each level, so sort by level to return to original order
[~, ind] = sort(results.level);
results = results(ind, :);
end

function results = runSuiteHelper(runner, suite)
% Helper function to call the run() function. This allows us to call other functions on the same process after the test
% is done. Currently, assuming only 1 test is run, it checks if that test was incomplete. If true, it will close all
% files on that process. This prevents checkFilesClosed on subsequent tests from failing due to an errored function.

    results = run(runner, suite);
    if results(1).Incomplete
        fclose all;
    end
end