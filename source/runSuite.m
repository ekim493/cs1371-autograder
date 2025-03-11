function results = runSuite(runner, suite, useParallel, timeout)
% RUNSUITE - Returns a table of results after running a test suite
%   This function takes in a runner, a test suite, and parameters to run unit tests. If useParallel is set to true, then
%   it will run each test case individually on its own parfeval worker. 
arguments
    runner (1, 1) {mustBeA(runner, 'matlab.unittest.TestRunner')}
    suite (:, :) {mustBeA(suite, 'matlab.unittest.TestSuite')}
    useParallel (1, 1) logical = true
    timeout (1, 1) double = 10
end
disp('Running Test Suite...')
for i = 1:numel(suite)
    if useParallel
        group(i) = parfeval(@run, 1, runner, suite(i)); %#ok<AGROW>
    else
        group(i) = run(runner, suite(i)); %#ok<AGROW>
    end
end
if useParallel
    while ~all(strcmp({group.State}, 'finished'))
        cancel(group([group.RunningDuration] > duration(0, 0, timeout)));
        pause(0.01);
    end
end
results = table(Size=[numel(suite),5], VariableTypes={'string', 'string', 'logical', 'cell', 'cell'}, Variablenames={'name', 'level', 'passed', 'output', 'display'});
for i = 1:numel(suite)
    results.name(i) = extractAfter(suite(i).Name, 'Tester/');
    results.level(i) = suite(i).Tags{1};
    if useParallel
        results.display{i} = group(i).Diary;
        if isempty(group(i).Error) && seconds(group(i).RunningDuration) < timeout
            testresult = fetchOutputs(group(i));
            results.passed(i) = testresult.Passed;
            results.output{i} = createTestOutput(testresult);
        else
            results.output{i} = sprintf('This function timed out because it took longer than %d seconds to run. Is there an infinite loop?', timeout);
        end
    else
        testresult = group(i);
        results.passed(i) = testresult.Passed;
        results.output{i} = createTestOutput(testresult);
    end
end
[~, ind] = sort(results.level);
results = results(ind, :);
end