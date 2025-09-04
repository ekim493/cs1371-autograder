classdef TestRunner
    % TESTRUNNER - Runs checks on individual test cases.
    %   This class manages and runs checks on individual test cases. To use this class, create an instance, set the
    %   relevant properties, then call the run() method. See the repository documentation for more info.

    properties
        FunctionName (1, :) char % Name of the function to be tested. If not set, the prefix before '_Test' is used.

        % The following are check properties that should be set depending on the test case.
        RunCheckAllEqual (1, 1) logical = true % Whether the checkAllEqual method should be run. Default = true.
        RunCheckCalls (1, 1) logical = true % Whether the checkCalls method should be run. Default = true.
        RunCheckFilesClosed (1, 1) logical = false % Whether the checkFilesClosed method should be run. Default = false.
        RunCheckImages char = '' % The name of the image for checkImages to check. If empty, it will not run. Default = ''.
        RunCheckPlots (1, 1) logical = false % Whether the checkPlots method should be run. Default = false.
        RunCheckTextFiles char = '' % The name of the text file for checkTextFiles to check. If empty, it will not run. Default = ''.

        % The following are properties that modify how checks behave.
        CheckedVariables cell = {} % Script variables to check. If empty, it will check all variables that the solution script generates.
        OutputType char = 'full' % Amount of information that the output should display. Set to 'full', 'limit', or 'none'. Default = 'full'.
        AllowedFuncs cell = {} % Functions that are allowed to be used, regardless if they are not in the function list.
        BannedFuncs cell = {} % Functions that are banned, regardless if they are in the function list.
        IncludeFuncs cell = {} % Functions that must be used by the student.
        ImageTolerance (1, 1) double = 10 % The tolerance level for checkImages. Default = 10.
        TextRule char = 'default' % How strict checkTextFiles should be. Set to 'default', 'strict', or 'loose'. Default = 'default'.
        NumTolerance (1, 1) double = 0.001 % Absolute tolerance for numerical comparisons in verifyEqual. Default = 0.001.

        % The following are QoL properties that change display names.
        InputNames cell % Names of inputs (to display for debugging). Set automatically. Will be 'input#' if there was no name.
        OutputNames cell % Add optional output names to variables instead of the default 'output#'.

        % The following are properties set automatically. Do not modify unless you understand its purpose.
        TestCase % The testCase object to perform verifications on.
        Inputs % The inputs to the function being tested.
        SolnInputs % The inputs to the solution function (if they are different).
    end

    methods
        function obj = TestRunner(varargin, opts)

            % TestRunner - Constructor for TestRunner.
            %   The inputs to this constructor should be the inputs to the student's function. Any object properties can
            %   be set using the Name-Value pair format. If no function name is provided, it will attempt to retrieve it
            %   from the caller's name (assumed it is called FUNCNAME_Test#). If no testCase object is provided, it will
            %   attempt to retrieve it from the caller's workspace.

            arguments (Repeating)
                varargin
            end
            arguments
                opts.?TestRunner
            end

            % Store inputs to constructor as function inputs
            obj.Inputs = varargin;
            obj.SolnInputs = varargin;

            % Retrieve input names from the caller's workspace variable name
            for i = 1:length(obj.Inputs)
                inputName = inputname(i);
                if isempty(inputName)
                    obj.InputNames{i} = sprintf('input%d', i);
                else
                    obj.InputNames{i} = inputname(i);
                end
            end

            % Store opts
            for prop = string(fieldnames(opts))'
                obj.(prop) = opts.(prop);
            end

            % Look for testCase object in caller workspace
            if isempty(obj.TestCase)
                try
                    obj.TestCase = evalin('caller', 'testCase');
                catch
                    error('TestRunner:noTestCase', 'Error retrieving the testCase object from the caller.');
                end
            end

            % Look for function name from the name of the caller function
            if isempty(obj.FunctionName)
                try
                    stack = dbstack;
                    obj.FunctionName = char(extractBetween(stack(2).name, '.', '_Test'));
                catch
                    error('TestRunner:funcName', 'Error retrieving the name of the function being tested.');
                end
            end
        end

        % Other methods
        run(obj)
        [varNames, varValues] = runScript(obj, scriptName)
        checkAllEqual(obj, outputs, solns, names)
        [hasPassed, msg] = checkCalls(obj, funcName)
        [hasPassed, msg] = checkImages(obj, user_fn, expected_fn)
        [hasPassed, msg] = checkPlots(obj)
        [hasPassed, msg] = checkTextFiles(obj, user_fn, soln_fn)
        [isClosed, msg] = checkFilesClosed(obj)
    end

    methods (Static)
        % Static methods
        varargout = compareImg(varargin)
        calls = getCalls(path, additionalOPS)
        map = mapPlot(lines)
        out = toChar(in)
    end
end
