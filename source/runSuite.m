function results = runSuite(runner, suite, useParallel, timeout)
arguments
    runner (1, 1) {mustBeA(runner, 'matlab.unittest.TestRunner')}
    suite (:, :) {mustBeA(suite, 'matlab.unittest.TestSuite')}
    useParallel (1, 1) logical = true
    timeout (1, 1) double = 10
end
for i = 1:numel(suite)
    if useParallel
        group(i) = parfeval(@run, 1, runner, suite(i)); %#ok<AGROW>
    else
        group(i) = run(runner, suite(i)); %#ok<AGROW>
    end
end
if useParallel
    tic
    while toc < timeout
       if all(strcmp({group.State}, 'finished'))
           break
       end
       pause(0.01);
    end
    if ~all(strcmp({group.State}, 'finished'))
        cancel(group);
    end
    results = table(Size=[numel(suite),4], VariableTypes={'string', 'string', 'logical', 'cell'}, Variablenames={'name', 'level', 'passed', 'output'});
    for i = 1:numel(suite)
        results.name(i) = extractAfter(suite(i).Name, 'Tester/');
        results.level(i) = suite(i).Tags{1};
        if seconds(group(i).RunningDuration) < timeout
            testresult = fetchOutputs(group(i));
            results.passed(i) = testresult.Passed;
            results.output{i} = createTestOutput(testresult);
        else
            results.output{i} = sprintf('This function timed out because it took longer than %d seconds to run. Is there an infinite loop?', timeout);
        end
    end
end
end