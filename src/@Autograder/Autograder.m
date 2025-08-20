classdef Autograder
    % AUTOGRADER - Class to run the Gradescope Autograder.
    %   Run the autograder by initializing the class with the relevant properties.

    properties
        % Full path to the assignment contents (solutions and testers. Set automatically if IsGradescope is true.
        AssignmentPath (1, :) char
        % Whether the autograder is being run for Gradescope. Defaults to true if on Linux platform.
        IsGradescope (1, 1) logical

        % Whether or not to run the autograder using the parallel toolbox. Required tor test case timeouts.
        UseParallel (1, 1) logical = true
        % Input to the parpool function to launch parallel workers.
        ParallelPool = 'Processes'
        % Timeout in seconds for each test case.
        TestcaseTimeout (1, 1) double = 30

        % Maximum number of characters to output per test case.
        MaxOutputLength (1, 1) double = 20000
        % Limit size of arrays as a percentage of maximum RAM. Helps minimize crashes.
        MaxMemPercent (1, 1) double = 1
        % Size of output images (width, height)
        ImageSize (1, 2), double = [760, 240]
        % Time in seconds for the delay in monitoring futures.
        MonitorDelay (1, 1) double = 0.1;

        % The following options pertain to the Gradescope json file
        % Optional text relevant to the entire submission.
        GlobalOutput = ''
        % Format of the GlobalOutput text.
        OutputFormat = 'html'
        % Whether the test cases should be visible. Can be 'hidden', 'after_due_date', 'after_published', or 'visible'.
        Visibility = 'visible'
        % Whether the command window output should be visible. Same options as visibility.
        StdoutVisibility = 'hidden'
    end

    properties (Constant)
        % Name of file that has function list
        FunctionListName = 'Function_List.json'
        % Additional operators to detect
        AdditionalOPS = {'BANG'}
        % Figure quality
        FigureSize = [100, 100, 380, 120];
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

            % Store class properties
            for prop = string(fieldnames(opts))'
                obj.(prop) = opts.(prop);
            end

            % Check whether system is Linux
            if isempty(obj.IsGradescope)
                if isunix && ~ismac
                    obj.IsGradescope = true;
                else
                    obj.IsGradescope = false;
                end
            end

            if obj.IsGradescope
                % Retrieve assignment information from Gradescope metadata
                try
                    submission = jsondecode(fileread('/autograder/submission_metadata.json'));
                    assignmentName = submission.assignment.title;
                    obj.AssignmentPath = fullfile('/autograder/assignments', assignmentName);
                catch
                    obj.throwError('The Gradescope submission metadata was not found.');
                end
            elseif isempty(obj.AssignmentPath)
                obj.throwError('Missing assignment path. If running the autograder locally, the "AssignmentPath" property must be set.')
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
