function runAutograder(obj)
% RUNAUTOGRADER - Main function to run the Gradescope Autograder.
%   This function configures the Gradescope paths, initializes the parallel pool, creates the test suite, and runs it
%   using the runSuite function. It will also display run diagnostics if prompted when running in parallel.

% Move the tester to the current (source) directory
copyfile(fullfile(obj.AssignmentPath, obj.TesterFile), pwd);

% Add resource files to current (source) directory
resourceFolder = fullfile(obj.AssignmentPath, obj.ResourceFolder);
if isfolder(resourceFolder)
    copyfile(resourceFolder, pwd)
end

% Create student and solution folders as namespaces and move files
mkdir('+student');
mkdir('+solution');
copyfile(obj.SubmissionPath, '+student');
copyfile(obj.AssignmentPath, '+solution');

% Attempt to load the parallel pool. Sometimes Gradescope/AWS bugs and this can fail to load.
if obj.UseParallel
    if ~canUseParallelPool
        warning("The parallel toolbox isn't installed or licensed properly. Changing to serial execution.");
        obj.UseParallel = false;
    else
        try
            pool = gcp('nocreate');
            if isempty(pool)
                parpool(obj.ParallelPool); % Create new pool if it doesn't exist
            end
        catch E
            % If there is an issue initializing the toolbox, change to serial
            warning("The parallel toobox didn't load successfully. Changing to serial execution.\n%s", getReport(E))
            obj.UseParallel = false;
        end
    end
end

% Set Matlab array size limit to % of RAM; this limits unresponsive timeouts
if obj.UseParallel
    parfevalOnAll(@setArrayLimit, 0, obj.MaxMemPercent);
else
    setArrayLimit(obj.MaxMemPercent);
end

% Create runner and suite
runner = testrunner();
suite = testsuite(obj.TesterFile);

% Run tests
obj.Results = obj.runSuite(runner, suite);

% Parse results and create results.json for Gradescope
obj.parseResults();

% Cleanup
clearArrayLimit() % No need on workers as we assume pool will shut down
end

function setArrayLimit(val)
% Helper function to set array size limit
s = settings;
s.matlab.desktop.workspace.ArraySizeLimit.TemporaryValue = val;
end

function clearArrayLimit()
% Helper function to clear the array size limit
s = settings;
if hasTemporaryValue(s.matlab.desktop.workspace.ArraySizeLimit)
    clearTemporaryValue(s.matlab.desktop.workspace.ArraySizeLimit)
end
end
