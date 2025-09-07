classdef Autograder
    % AUTOGRADER - Class to run the Gradescope Autograder.
    %   This class manages the running and grading of student code. The class constructor sets up the properties and
    %   calls the runAutograder method, which initializes the environment and runs the test suite.
    %
    %   To use this class inside for Gradescope, have the run_autograder script instantiate the class. Properties of the
    %   class can be inputs to the initializer as name-value pairs. See the repository documentation for more info.
    %
    %   Hardcoded paths to the container can be found in the constructor.

    properties
        % Whether the autograder is being run for Gradescope. Defaults to true if on Linux platform.
        IsGradescope (1, 1) logical = false
        % Full path to the assignment folder (solutions and testers). Set automatically if IsGradescope is true.
        AssignmentPath (1, :) char
        % Full path to submission folder. Set automatically if IsGradescope is true.
        SubmissionPath (1, :) char
        % Full path to results folder, where the results.json file will go. Set automatically if IsGradescope is true.
        ResultsPath (1, :) char
        % Filename of tester located in the assignment folder. If not set, it will search for the first file which
        % inherits the 'matlab.unittest.TestCase' class.
        TesterFile (1, :) char

        % Whether or not to run the autograder using the parallel toolbox. Required tor test case timeouts.
        UseParallel (1, 1) logical = true
        % Input to the parpool function to launch parallel workers if UseParallel is true.
        ParallelPool = 'Processes'
        % Timeout in seconds for each test case. Requires UseParallel to be true to work.
        TestcaseTimeout (1, 1) double = 30

        % Optional text relevant to the entire submission.
        GlobalOutput = ''
        % Format of the output text (should be left alone in most cases).
        OutputFormat = 'html'
        % Whether the test cases should be visible. Can be 'hidden', 'after_due_date', 'after_published', or 'visible'.
        Visibility = 'visible'
        % Whether the command window output should be visible. Same options as visibility.
        StdoutVisibility = 'hidden'
    end

    properties (Constant)
        % Maximum number of characters to output per test case.
        MaxOutputLength (1, 1) double = 20000
        % Limit size of arrays as a percentage of maximum RAM. Helps minimize crashes.
        MaxMemPercent (1, 1) double = 1
        % Size of output images (width, height) in Gradescope.
        ImageSize (1, 2) double = [760, 240]
        % Figure quality (xPos, yPos, width, height). Increasing this value may cause images not to display properly.
        FigureSize = [100, 100, 380, 120];
        % Time in seconds for the delay in monitoring for function timeouts.
        MonitorDelay (1, 1) double = 0.1
        % Name of file that has function list
        FunctionListName = 'Function_List.json'
        % Name of folder inside each assignment that contains additional resources/files
        ResourceFolder = 'resources';
    end

    properties (SetAccess=private)
        % Results of the autograder run as a table.
        Results
    end

    methods
        function obj = Autograder(opts)
            arguments
                opts.?Autograder
            end

            % Check if system is Linux
            if isunix && ~ismac
                obj.IsGradescope = true;
            end

            % Store class properties
            for prop = string(fieldnames(opts))'
                obj.(prop) = opts.(prop);
            end

            if obj.IsGradescope
                % Retrieve assignment information from Gradescope metadata
                try
                    submission = jsondecode(fileread('/autograder/submission_metadata.json'));
                    assignmentName = submission.assignment.title;
                catch
                    obj.throwError('The Gradescope submission metadata was not found.');
                end
                % Set Gradescope paths
                obj.AssignmentPath = fullfile('/autograder/assignments', assignmentName);
                obj.SubmissionPath = '/autograder/submission';
                obj.ResultsPath = '/autograder/results';
            elseif isempty(obj.AssignmentPath) || isempty(obj.SubmissionPath)
                obj.throwError('Missing paths. If running the autograder locally, the path properties must be set.')
            end

            % Search for TesterName if not given
            if isempty(obj.TesterFile)
                addpath(obj.AssignmentPath); % metadata only works using file name, so add to path to search
                files = dir(obj.AssignmentPath);
                for i = 1:numel(files)
                    [~, filename, ext] = fileparts(files(i).name);
                    metadata = meta.class.fromName(filename);
                    if ~isempty(metadata) && any(strcmp({metadata.SuperclassList.Name}, 'matlab.unittest.TestCase'))
                        obj.TesterFile = [filename, ext];
                        break
                    end
                end
                if isempty(obj.TesterFile)
                    obj.throwError(['The test class was not found. Was a tester included which inherits ' ...
                        'the matlab.unittest.TestCase class?']);
                end
                rmpath(obj.AssignmentPath);
            end

            obj.runAutograder() % Run the autograder
        end

        % Other methods
        runAutograder(obj)
        throwError(obj, msg)
        results = runSuite(obj)
        parseResults(obj)
        outMsg = createTestOutput(obj, testCase)
    end
end
