function runAutograder(obj)
% RUN - Main function to run the Gradescope Autograder.
%   This function configures the Gradescope paths, initializes the parallel pool, creates the test suite, and runs it
%   using the runSuite function. It will also display run diagnostics if prompted when running in parallel.

addpath(obj.AssignmentPath); % Add assignment path

% Configure Gradescope paths
if obj.IsGradescope
    addpath('/autograder/submission');
    % Add dir files to source directory
    if isfolder(fullfile(obj.AssignmentPath, 'dir'))
        copyfile(fullfile(obj.AssignmentPath, 'dir', '*'), '/autograder/source')
    end
end

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

runner = testrunner(); % Create runner
% Search for testsuite class
files = dir(obj.AssignmentPath);
for i = 1:numel(files)
    [~, fileName, ~] = fileparts(files(i).name);
    metadata = meta.class.fromName(fileName);
    if ~isempty(metadata) && any(strcmp({metadata.SuperclassList.Name}, 'matlab.unittest.TestCase'))
        suite = testsuite(fileName); % Create suite. Don't use full path here or it will change to that directory.
        break
    end
end

% Run suite
if ~exist('suite', 'var')
    obj.throwError()
end
obj.Results = obj.runSuite(runner, suite);

% Parse results and create results.json for Gradescope
obj.parseResults();

% Cleanup
rmpath(obj.AssignmentPath)
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
