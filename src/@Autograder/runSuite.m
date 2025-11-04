function results = runSuite(obj, runner, suite)
% RUNSUITE - Returns a table of results after running a test suite
%   This function takes in a runner and a test suite. It runs the test suite either in parallel or in serial depending
%   on the UseParallel property. This function will also print diagnostics to the command window and parse the suite to
%   create a results table.
%
%   Input Arguments
%       runner - matlab.unittest.TestRunner object to run test cases using.
%       suite - matlab.unittest.TestSuite object containing all the test cases to be run.
%
%   Output Arguments
%       results - Table containing the following fields: 
%           name - name of the test case
%           problem - problem name from test tag
%           scoring - tag that has information on how the problem should be scored
%           visibility - visibility of the test case, defaults to the value of the Visibility property unless it was 
%                        specified as a test tag
%           passed - Logical pass/fail
%           output - Diagnostic report, either from createTestOutput or indicates a timeout or autograder issue.

arguments
    obj
    runner (1, 1) {mustBeA(runner, 'matlab.unittest.TestRunner')}
    suite (:, :) {mustBeA(suite, 'matlab.unittest.TestSuite')}
end

disp('Running Test Suite...')

if obj.UseParallel
    group(1:numel(suite)) = parallel.FevalFuture; % Preallocate
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

% Create results table (default passed is false)
results = table(Size=[numel(suite), 6], VariableTypes={'string', 'string', 'string', 'string', 'logical', 'cell'}, ...
    Variablenames={'name', 'problem', 'scoring', 'visibility', 'passed', 'output'});
for i = 1:numel(suite)
    results.name(i) = suite(i).ProcedureName; % Assign test case name
    try
        % Assign properties from tags
        tags = suite(i).Tags;
        isVisibility = startsWith(tags, 'visibility=', 'IgnoreCase', true);
        isScoring = contains(tags, '=') & ~isVisibility;
        isProblem = ~isVisibility & ~isScoring;
        if ~any(isVisibility)
            visibility = obj.Visibility;
        else
            visibility = extractAfter(tags{isVisibility}, 'visibility=');
        end
        results.visibility(i) = visibility;
        results.problem(i) = tags{isProblem};
        results.scoring(i) = tags{isScoring};
    catch
        obj.throwError('Tags for this homework assignment are invalid or are not present.')
    end
    if obj.UseParallel
        if ~isempty(group(i).Error) && strcmp(group(i).Error(1).identifier, 'parallel:fevalqueue:ExecutionCancelled')
            results.output{i} = sprintf( ...
                ['Verification failed in %s.\n    ----------------\n    Test Diagnostic:\n    ----------------\n    ' ...
                'This function timed out because it took longer than %d seconds to run. Is there an infinite loop?'], ...
                results.name(i), obj.TestcaseTimeout);
        elseif ~isempty(group(i).Error)
            % Parse parfeval errors first
            results.output{i} = sprintf(['The autograder ran into an unexpected error:\n%s\n\n' ...
                '<em>Note: If you see this error, you likely have an infinite loop. You can re-submit your work or attempt to fix the issue.\n' ...
                'If the error persists, please contact the HW TAs.</em>'], ...
                group(i).Error.message);
        else
            testresult = fetchOutputs(group(i));
            results.passed(i) = testresult.Passed;
            results.output{i} = obj.createTestOutput(testresult);
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
if isempty(results.Details.DiagnosticRecord)
    send(dataQueue, '.');
else
    for i = 1:numel(results.Details.DiagnosticRecord)
        report = results.Details.DiagnosticRecord(i).Report;
        report = sprintf('%s\n%s\n%s\n', repmat('=', 1, 80), report, repmat('=', 1, 80)); % Replicate display
        send(dataQueue, report);
    end
end
end
