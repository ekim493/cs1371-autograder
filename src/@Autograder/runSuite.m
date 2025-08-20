function results = runSuite(obj, runner, suite)
% RUNSUITE - Returns a table of results after running a test suite
%   This function takes in a runner and a test suite. If UseParallel is set to true, then it will run each test case 
%   individually using parfeval, and it will cancel the job after TestcaseTimeout seconds. Otherwise,
%   it will simply run the suite on the input TestRunner.
%
%   Input Arguments
%       runner - matlab.unittest.TestRunner object to run test cases using.
%       suite - matlab.unittest.TestSuite object containing all the test cases to be run.
%
%   Output Arguments
%       results - Table containing the following data: name of test case, level of test case, logical pass/fail, output
%       from createTestOutput(), and display text containing command window output of each Future (empty if useParallel
%       is false).

arguments
    obj
    runner (1, 1) {mustBeA(runner, 'matlab.unittest.TestRunner')}
    suite (:, :) {mustBeA(suite, 'matlab.unittest.TestSuite')}
end

disp('Running Test Suite...')

group(1:numel(suite)) = parallel.FevalFuture; % Preallocate

if obj.UseParallel
    % Create data queue to display test case information from workers
    dataQueue = parallel.pool.DataQueue;
    afterEach(dataQueue, @disp);
    % Run each test on parfeval for parallel execution.
    for i = 1:numel(suite)
        group(i) = parfeval(@runSuiteWorker, 1, runner, suite(i), dataQueue);
    end
    % Once all Futures are queued, monitor their state. Cancel any Futures that have been running for
    % more than "timeout" amount of seconds. Run until all cases have finished (or timed out).
    while ~all(strcmp({group.State}, 'finished'))
        cancel(group([group.RunningDuration] > duration(0, 0, obj.TestcaseTimeout)));
        pause(obj.MonitorDelay);
    end
else
    group = run(runner, suite);
end

% Create results table
results = table(Size=[numel(suite),5], VariableTypes={'string', 'string', 'string', 'logical', 'cell'}, ...
    Variablenames={'name', 'problem', 'scoring', 'passed', 'output'});
for i = 1:numel(suite)
    results.name(i) = suite(i).ProcedureName; % Assign test case name
    try
        % Assign problem name and scoring fields
        tags = suite(i).Tags;
        isScoring = contains(tags, '=');
        results.problem(i) = suite(i).Tags{~isScoring};
        results.scoring(i) = suite(i).Tags{isScoring};
    catch
        obj.throwError('Tags for this homework assignment are invalid or are not present.')
    end
    if obj.UseParallel
        % If a Future was canceled, it will always have a RunningDuration > timeout and sometimes an error message
        if isempty(group(i).Error) && seconds(group(i).RunningDuration) < obj.TestcaseTimeout
            testresult = fetchOutputs(group(i));
            results.passed(i) = testresult.Passed;
            results.output{i} = obj.createTestOutput(testresult);
        else
            results.output{i} = sprintf( ...
                ['Verification failed in %s.\\n    ----------------\\n    Test Diagnostic:\\n    ----------------\\n    ' ...
                'This function timed out because it took longer than %d seconds to run. Is there an infinite loop?'], ...
                results.name(i), obj.TestcaseTimeout);
        end
    else
        testResult = group(i);
        results.passed(i) = testResult.Passed;
        results.output{i} = obj.createTestOutput(testResult);
    end
end
end

function results = runSuiteWorker(runner, suite, dataQueue)
% Helper function to run the test suite on the worker. Prints the report to the command window for diagnostics.

results = run(runner, suite);
report = results.Details.DiagnosticRecord.Report;
report = sprintf('%s\n%s\n%s\n.', repmat('=', 1, 80), report, repmat('=', 1, 80)); % Replicate display
send(dataQueue, report);
end
