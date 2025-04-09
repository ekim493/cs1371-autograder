classdef TesterHelper
    % TESTERHELPER - This class includes methods to help grade and check HW functions. To use this class, create an
    % instance and set the relevant properties, then call the run() method. See documention for more details.

    properties
        func (1, :) char % Name of the function to be tested.
        testCase % The testCase object to perform verifications on.

        testCaseName char % Full name of the test case (to display for debugging)
        inputNames cell % Names of inputs (to display for debugging)

        runCheckAllEqual (1, 1) logical = true % Whether the checkAllEqual method should be run. Default = true.
        runCheckCalls (1, 1) logical = true % Whether the checkCalls method should be run. Default = true.
        runCheckFilesClosed (1, 1) logical = false % Whether the checkFilesClosed method should be run. Default = false.
        runCheckImages char = '' % The name of the image for checkImages to check. If empty, it will not run. Default = ''.
        runCheckPlots (1, 1) logical = false % Whether the checkPlots method should be run. Default = false.
        runCheckTextFiles char = '' % The name of the text file for checkTextFiles to check. If empty, it will not run. Default = ''.
        
        allowedFuncs cell = {} % Functions that are allowed to be used, regardless if they are not in the Allowed_Functions list.
        bannedFuncs cell = {} % Functions that are banned, regardless if they are in the Allowed_Functions list.
        includeFuncs cell = {} % Functions that must be used by the student.

        inputs % The inputs to the function being tested.
        solnInputs % The inputs to the solution function (if they are different).
        outputType char = 'full' % Amount of information that the output should display. Set to 'full', 'limit', or 'none'. Default = 'full'.
        outputNames cell % Add optional output names to variables instead of the default 'output#'.
        
        imageTolerance (1, 1) double = 10 % The tolerance level for checkImages. Default = 10.
        textRule char = 'default' % How strict checkTextFiles should be. Set to 'default', 'strict', or 'loose'. Default = 'default'.
        numTolerance (1, 1) double = 0.001 % Absolute tolerance for numerical comparisons in verifyEqual. Default = 0.001.
        maxMemPercent (1, 1) double = 1 % Limit maximum array size as a percentage of RAM. Default = 1.
        
        parallelStrategy char = 'none' % What strategy that should be used to run the tester. Set to 'none', 'thread', or 'process'. Default = 'none'.
        timeout (1, 1) double = 30 % Number of seconds before function execution should be timed out. Note that includes solution function time.
    end

    methods
        function obj = TesterHelper(varargin, opts)

            % TESTERHELPER - Constructor for TESTERHELPER.
            %   The inputs to this constructor should be the inputs to the student's function. Any object properties can
            %   be set using the Name-Value pair format. If no function name is provided, it will attempt to retrieve it
            %   from the caller's name (assumed it is called FUNCNAME_Test#). If no testCase object is provided, it will
            %   attempt to retrieve it from the caller's workspace.

            arguments (Repeating)
                varargin
            end
            arguments
                opts.?TesterHelper
            end

            % By default, store inputs to constructor as function inputs
            obj.inputs = varargin;
            obj.solnInputs = varargin;

            % By default, retrieve input names from the caller's workspace variable name
            for i = 1:length(obj.inputs)
                obj.inputNames(i) = {inputname(i)};
            end

            % Store opts
            for prop = string(fieldnames(opts))'
                obj.(prop) = opts.(prop);
            end

            % Look for testCase object in caller workspace
            if isempty(obj.testCase)
                try
                    obj.testCase = evalin('caller', 'testCase');
                catch
                    error('HWTester:noTestCase', 'Error retrieving the testCase object from the caller.');
                end
            end

            % Look for function name from the name of the caller function
            if isempty(obj.func)
                try
                    stack = dbstack;
                    obj.func = char(extractBetween(stack(2).name, '.', '_Test'));
                    obj.testCaseName = extractAfter(stack(2).name, '.');
                catch
                    error('HWTester:funcName', 'Error retrieving the name of the function being tested.');
                end
            end
        end

        %% Evaluation Functions

        function run(obj)

            % RUN - Main Tester evaluation method.
            %   This method will execute the runFunc method, propagate any errors, and evaluate check functions as
            %   defined by the object's properties. The results of the check funtions will be executed directly on the 
            %   testCase object. The execution of runFunc depends on parallelStrategy, where 'none' will execute the
            %   function as normal, 'thread' will use parfeval on a background worker, and 'process' will use parfeval
            %   on default settings, using current pool (defined by gcp). Note that 'thread' will not work with
            %   runCheckPlots.
            %
            %   The current iteration of the autograder moved parallel execution to the client, so 'none' should be
            %   used. The other options are left in for legacy use.

            if ~exist([obj.func, '.m'], 'file')
                error('HWStudent:noFunc', 'Undefined function or script ''%s''. Was this file submitted?', obj.func);
            end

            % See if the solution function is a script. If so, then save the caller's workspace variables into loadVars
            % to pass in as arguments later. The try-catch with nargout is used as the solution file should be pcoded,
            % and mtree and other methods to read the file will not work
            try 
                nargout(which(sprintf('%s_soln', obj.func)));
                loadVars = [];
            catch
                loadVars = tempname;
                evalin('caller', sprintf('save(''%s'')', loadVars));
            end

            % Display input variables in command window for debugging
            disp(sprintf('\nTestcase: %s', obj.testCaseName)); %#ok<DSPSP>
            for i = 1:length(obj.inputs)
                disp(sprintf('\n%s =\n%s', obj.inputNames{i}, TesterHelper.toChar(obj.inputs{i}))) %#ok<DSPSP>
            end

            % Set Matlab array size limit to % of RAM; this limits unresponsive timeouts
            s = settings;
            s.matlab.desktop.workspace.ArraySizeLimit.TemporaryValue = obj.maxMemPercent;
            
            switch obj.parallelStrategy
                case 'none'
                    [outputs, solns, names, checks] = obj.runFunc(loadVars);
                case 'thread'
                    if obj.runCheckPlots
                        error("runCheckPlots cannot be run if the parallel strategy is set to 'thread' mode.")
                    end
                    f = parfeval(backgroundPool, @obj.runFunc, 4, loadVars);
                case 'process'
                    f = parfeval(@obj.runFunc, 4, loadVars);
            end

            % For parallel execution, use parfeval to evaluate function in the background. Wait for up to obj.timeout 
            % seconds, and if there is no reponse in that time, and infinite loop is assumed.
            if exist('f', 'var')
                ok = wait(f, 'finished', obj.timeout); % Run function with timeout
                if ~ok
                    cancel(f);
                    error('HWStudent:infLoop', 'This function timed out because it took longer than %d seconds to run. Is there an infinite loop?', obj.timeout);
                elseif ~isempty(f.Error)
                    try
                        % If the function threw an error, attempt to recreate the default Matlab error message by
                        % using the error line number and retreiving the relevant line from the function file.
                        lines = readlines([obj.func '.m']);
                        stackLevel = find(strcmpi({f.Error.stack(:).name}, obj.func), true);
                        li = f.Error.stack(stackLevel).line;
                        line = lines(li);
                    catch ME
                        throw(f.Error);
                    end
                    error('HWStudent:function', '%s\n\nError in %s (line %d)\n%s', f.Error.message, obj.func, li, strtrim(line));
                end
                [outputs, solns, names, checks] = fetchOutputs(f);
            end

            % Run relevant check functions
            if obj.runCheckCalls
                obj.checkCalls();
            end
            if obj.runCheckAllEqual
                obj.checkAllEqual(outputs, solns, names);
            end
            if obj.runCheckFilesClosed
                obj.testCase.verifyTrue(checks.files{1}, checks.files{2});
            end
            if ~isempty(obj.runCheckTextFiles)
                obj.checkTextFiles(obj.runCheckTextFiles, checks.textFile);
            end
            if obj.runCheckPlots
                obj.testCase.verifyTrue(checks.plot{1}, checks.plot{2});
            end
            if ~isempty(obj.runCheckImages)
                obj.checkImages(obj.runCheckImages, checks.image);
            end

        end

        function [outputs, solns, names, checks] = runFunc(obj, loadVars)

            % RUNFUNC - Helper function for RUN. Can be run in the background using parfeval.
            %   This function run's the solution code (should be named FUNCNAME_soln), the student's code, checkPlots
            %   (if desired), and checkFilesClosed (if desired).
            %   
            %   Input Arguments
            %       loadVars (char) - Path to a mat file containing variable data from main caller. This is only
            %       necessary if the code being checked is a script with inputs given in the tester file. The run
            %       function will create this automatically if the code being tested is a script.
            %
            %   Output Arguments
            %       outputs - Cell array of all student outputs.
            %       solns - Cell array of all solution outputs.
            %       names - Cell array of names of output variables. This is either by the outputNames property for functions,
            %               the variable name in the solution script (VARNAME_soln), or by default it will be 'output#'.
            %       checks - Structure containing the results of the checkPlots and checkFilesClosed methods.

            checks = struct();

            % Run solution code
            close all;
            if ~exist(sprintf('%s_soln', obj.func), 'file')
                error('HWTester:noSoln', 'The solution function wasn''t included');
            end
            if isempty(loadVars)
                % Run as function. Use evalc to suppress function outputs
                [~, solns{1:nargout(sprintf('%s_soln', obj.func))}] = evalc(sprintf('%s_soln(obj.solnInputs{:})', obj.func));
            else
                % Run as script. Load variables then evaluate
                load(loadVars); %#ok<LOAD>
                eval(sprintf('%s_soln', obj.func));
                vars = who;
                solnVars = vars(endsWith(vars, '_soln')); % Extract solutions var names
            end

            % Check if image was created with the default name. If true, give the image a temporary filename instead. If
            % false, assume the image was created with the '_soln' extension.
            if ~isempty(obj.runCheckImages) && exist(obj.runCheckImages, 'file')
                name = tempname;
                copyfile(obj.runCheckImages, name);
                delete(obj.runCheckImages);
                checks.image = name;
            else
                [file, ext] = strtok(obj.runCheckImages);
                checks.image = [file, '_soln', ext];
            end

            % Check if text file was created with the default name. If true, give the file a temporary filename instead.
            % If false, assume the file was created with the '_soln' extension.
            if ~isempty(obj.runCheckTextFiles) && exist(obj.runCheckTextFiles, 'file')
                name = tempname;
                copyfile(obj.runCheckTextFiles, name);
                delete(obj.runCheckTextFiles);
                checks.textFile = name;
            else
                [file, ext] = strtok(obj.runCheckTextFiles);
                checks.textFile = [file, '_soln', ext];
            end

            % Run student code
            if obj.runCheckPlots
                figure;
            end
            try
                isFunc_student = isequal(mtree(which(obj.func), '-file').FileType, 'FunctionFile');
            catch
                error('HWStudent:fileRead', 'There was an error reading your file. Please contact the TAs or check the submission file.');
            end
            if isempty(loadVars) && ~isFunc_student
                error('HWStudent:notFunc', 'A function was expected, but you submitted a script instead.');
            elseif ~isempty(loadVars) && isFunc_student
                error('HWStudent:notScript', 'A script was expected, but you submitted a function instead.');
            else
                if isFunc_student
                    if numel(obj.inputs) ~= nargin(obj.func)
                        error('HWStudent:inputArgs', '%d input(s) to the function were expected, but your function had %d.', numel(obj.inputs), nargin(obj.func));
                    end

                    % Run as function. Use evalc to suppress function outputs
                    try
                        [~, outputs{1:nargout(obj.func)}] = evalc(sprintf('%s(obj.inputs{:})', obj.func));
                    catch exception
                        % If an array size limit error was thrown with evalc, then the student function attempted to
                        % output too much text to the command window (most likely unsuppressed imread or similar)
                        if strcmp(exception.identifier, 'MATLAB:array:SizeLimitExceeded') && strcmp(exception.stack(1).name, 'TesterHelper.runFunc')
                            error('HWStudent:exceedDiarySize', ['Matlab attempted to display %s characters to the command window and exceeded the allocated memory capacity (%s). ' ...
                                'Ensure that you have suppressed your lines of code using a ";".'], extractAfter(exception.arguments{1}, 'x'), exception.arguments{3});
                        else
                            rethrow(exception);
                        end
                    end

                    % If outputNames was never initialized, then give each output the default name of 'output #'
                    if isempty(obj.outputNames)
                        names = arrayfun(@(x) ['output' num2str(x)], 1:numel(outputs), 'UniformOutput', false);
                    else
                        names = obj.outputNames;
                    end
                else
                    % Run as script. Load variables then evaluate
                    load(loadVars); %#ok<LOAD>
                    eval(obj.func);
                    % Collect relevant variables, using solnVars as the basis for which variables to find
                    solns = cell(1, numel(solnVars));
                    outputs = cell(1, numel(solnVars));
                    names = cellfun(@(x) extractBefore(x, '_soln'), solnVars, 'UniformOutput', false);
                    for i = 1:length(solnVars)
                        try
                            outputs(i) = {eval(names{i})};
                        catch
                            error('HWStudent:varNotAssigned', 'Variable ''%s'' (and possibly others) was not found', names{i});
                        end
                        solns(i) = {eval(solnVars{i})};
                    end
                end
            end

            % Run relevant checks. These checks must be run in the background during the intial parfeval call.
            if obj.runCheckPlots
                [hasPassed, msg] = obj.checkPlots();
                checks.plot = {hasPassed, msg};
            end
            if obj.runCheckFilesClosed
                [hasPassed, msg] = obj.checkFilesClosed();
                checks.files = {hasPassed, msg};
            end
        end

        %% Check Functions

        function checkAllEqual(obj, outputs, solns, names)

            % CHECKALLEQUAL - Check and compare all solution variables against the student's.
            %   This function compares all data inside 'outputs' with the corresppnding data in 'solns' by running it
            %   through the verifyEqual function on the testCase object with an absolute tolerance defined by numTolerance. 
            %   It will also output a message with a level of detail given by obj.outputType. 'full' will output full 
            %   comparison information, 'limit' will only output which variables are incorrect, and 'none' will have no output text.
            %
            %   Input Arguments
            %       outputs - Cell array of all student outputs.
            %       solns - Cell array of all solution outputs.
            %       names - Cell array of names of output variables.
    
            if isempty(solns) && isempty(outputs)
                return
            end

            if numel(solns) ~= numel(outputs)
                obj.testCase.verifyTrue(false, sprintf('%d output(s) were expected, but your function produced %d.', numel(solns), numel(outputs)));
                return
            end
            
            % Loop through variables and compare then
            for i = 1:length(solns)
                soln = solns{i};
                student = outputs{i};
                
                % Determine output message based on outputType
                switch obj.outputType
                    case 'none'
                        continue
                    case 'limit'
                        msg = sprintf('Variable ''%s'' does not match the solution''s.', names{i});
                    case 'full'
                        msg = ['<u>', names{i}, '</u>\n', '    Actual output ' TesterHelper.toChar(student, html=true) '\n    Expected output ' TesterHelper.toChar(soln, html=true)];
                end

                % Verification call
                if isempty(soln)
                    obj.testCase.verifyEmpty(student, msg);
                else
                    obj.testCase.verifyEqual(student, soln, msg, "AbsTol", obj.numTolerance);
                end
            end

        end

        function checkCalls(obj)
            
            % CHECKCALLS - Check a function file's calls.
            %   This function will check if the function in question calls or does not call certain functions or use
            %   certain operations. A list of allowed functions and operations should be specified in a file called
            %   'Allowed_Functions.json'. Operations are defined the keywords that appear when the function iskeyword is 
            %   called, and must be in all caps. It will run the final result through the testCase object using
            %   verifyTrue. The following object properties can be used to modify the list of calls this function checks:
            %       bannedFuncs - List of additional banned functions.
            %       includeFuncs - List of functions that must be included.
            %       allowedFuncs - List of functions that should bypass the ban restriction.
            

            % Find name of function to test
            funcFile = obj.func;

            % Create full list of banned and allowed functions
            list = jsondecode(fileread('Allowed_Functions.json'));
            allowed = [list.ALLOWED; list.ALLOWED_OPS; obj.allowedFuncs'];
            msg = [];
            banned = obj.bannedFuncs';
            include = obj.includeFuncs;

            calls = TesterHelper.getCalls(which(funcFile)); % Get list of function calls

            % Find banned functions and unused functions
            bannedCalls = calls(ismember(calls, banned) | ~ismember(calls, allowed));
            includeCalls = cellstr(setdiff(include, calls));
            if isempty(bannedCalls) && isempty(includeCalls)
                hasPassed = true;
            else
                hasPassed = false;
                if ~isempty(bannedCalls)
                    msg = sprintf('The following banned function(s) were used: %s.', strjoin(bannedCalls, ', '));
                end
                if ~isempty(includeCalls)
                    temp = sprintf('The following function(s) must be included: %s.', strjoin(includeCalls, ', '));
                    if isempty(msg)
                        msg = temp;
                    else
                        msg = [msg '\n    ' temp];
                    end
                end
            end

            % Run verification
            obj.testCase.verifyTrue(hasPassed, msg);
        end

        function checkImages(obj, user_fn, expected_fn)

            % CHECKIMAGES - Check and compare an image against the solution's.
            %   This function will read in an image filename (defined by the property runCheckImages) and compare it to 
            %   its corresponding image solution with a small tolerance. The final result is run through the testCase
            %   object using verifyTrue. The outputType property does affect this function, and the full output 
            %   includes an image comparison.
            % 
            %   Input Arguments
            %       user_fn (char) - User image file name.
            %       expected_fn (char) - Expected image file name.
            
            % Check if images can be accessed
            if ~exist(expected_fn, 'file')
                error('HWTester:noImage', 'The solution image wasn''t found');
            elseif ~exist(user_fn, 'file')
                obj.testCase.verifyTrue(false, sprintf('The image ''%s'' wasn''t found. Did you create an image with the right filename?', user_fn));
                return;
            end
            % Image comparsion by comparing image arrays
            user = imread(user_fn);
            expected = imread(expected_fn);
            [rUser,cUser,lUser] = size(user);
            [rExp,cExp,lExp] = size(expected);
            if rUser == rExp && cUser == cExp && lUser == lExp
                diff = abs(double(user) - double(expected));
                isDiff = any(diff(:) > obj.imageTolerance);
                if isDiff
                    hasPassed = false;
                    msg = 'The image output does not match the expected image.';
                else
                    return;
                end
            else
                hasPassed = false;
                msg = sprintf('The dimensions of the image do not match the expected image.\n    Actual size: %dx%dx%d\n    Expected size: %dx%dx%d', rUser, cUser, lUser, rExp, cExp, lExp);
            end

            % Output formatting
            switch obj.outputType
                case 'none'
                    msg = '';
                case 'full'
                    filename = TesterHelper.compareImg(user_fn, expected_fn);
                    msg = strrep(msg, newline, '\n');
                    msg = sprintf('%s\\nIMAGEFILE:%s', msg, filename);
            end
            obj.testCase.verifyTrue(hasPassed, msg);

        end

        function [hasPassed, msg] = checkPlots(obj)
            
            % CHECKPLOTS - Check and compare a plot against the solution's.
            %   This function will read in the currently open figures and compare them. For the function to work, all
            %   figures must be closed and then at least 2 figures must be opened. The solution plot should be created
            %   first, followed by the student plot. The plots must not override one another, so 'figure'
            %   must be called. The outputType property does affect this function, and the full output includes a figure
            %   comparison.
            %
            %   Output Arguments
            %       tf - True if the plots matched, false if not.
            %       msg - Character message indicating why the test failed. Is empty if tf is true.
            %
            %   checkPlots does not current support or check the following:
            %       - Annotations, tiled layout, UI elements, colorbars, or other graphic elements
            %       - Plots generated with functions other than plot (such as scatter)
            %       - 3D plots, or any plots with a z axis
            %       - Text styles or font size
            %       - Box styling, tick marks, tick labels, and similar
            %       - Similar plots with a margin of error
            
            % sFig - Student, cFig - Correct figure. 
            % Need to check next plot in case 'figure' was called in the function. There are probably better ways to do
            % this, but this works for now.
            i = 1;
            if numel(figure(i).Children) == 0
                i = i + 1;
                if numel(figure(i).Children) == 0
                    error('HWTester:noPlot', 'There was no solution plot present.');
                end
            end
            cFig = figure(i);
            i = i + 1;
            if numel(figure(i).Children) == 0
                i = i + 1;
                if numel(figure(i).Children) == 0
                    hasPassed = false;
                    msg = 'Your solution did not create a plot when one was expected.';
                    return
                end
            end
            sFig = figure(i);

            msg = [];

            % Plot check
            sAxes = findobj(sFig, 'Type', 'axes');
            cAxes = findobj(cFig, 'Type', 'axes');
            sNotAxes = findobj(sFig.Children, 'flat', '-not', 'Type', 'axes', '-not', 'Type', 'Legend');
            cNotAxes = findobj(cFig.Children, 'flat', '-not', 'Type', 'axes', '-not', 'Type', 'Legend');
            if numel(cNotAxes) > 0
                warning('Only axes and legends are checked. Annotations, UI elements, and other elements aren''t checked.');
            elseif numel(sNotAxes) ~= numel(cNotAxes)
                if isa(sFig.Children, 'matlab.graphics.layout.TiledChartLayout')
                    msg = 'Your plot uses a tiled layout. Please use subplot instead.'; % Should this be allowed?
                else
                    msg = 'Your plot contains extraneous elements. Ensure you don''t have additional UI elements, annotations, or similar.';
                end
                hasPassed = false;
                return
            end
            if isempty(cAxes) || isempty(sAxes)
                msg = 'Your plot is empty.';
                hasPassed = false;
                return
            end

            % Number of subplot check
            if numel(sAxes) ~= numel(cAxes)
                msg = sprintf('Expected %d subplot(s), but your solution produced %d subplot(s).', numel(cAxes), numel(sAxes));
                hasPassed = false;
                appendImage;
                return
            end

            % Subplot grid check               
            sAxesPos = {sAxes.Position}';
            cAxesPos = {cAxes.Position}';
            % We use strings to represent subplot locations. Sort them to ensure plotting out of order still works.
            [sAxesPos, sInd] = sort(join([string(cellfun(@(pos) round(pos(1), 2), sAxesPos)), string(cellfun(@(pos) round(pos(2), 2), sAxesPos))], ','));
            [cAxesPos, cInd] = sort(join([string(cellfun(@(pos) round(pos(1), 2), cAxesPos)), string(cellfun(@(pos) round(pos(2), 2), cAxesPos))], ',')); 
            if any(sAxesPos ~= cAxesPos)
                msg = 'The subplot positions do not match.';
                hasPassed = false;
                appendImage;
                return
            end
            
            % Data check              
            sAxes = sAxes(sInd);
            cAxes = cAxes(cInd);
            % Loop through every subplot
            for i = 1:numel(cAxes)
                if numel(findobj([cAxes(i).Children], '-not', 'Type', 'Line')) > 0
                    warning('Plots created with functions other than plot will not be checked.');
                end
                sAxesPlots = findobj(sAxes(i), 'Type', 'Line');
                cAxesPlots = findobj(cAxes(i), 'Type', 'Line');
                sMap = TesterHelper.mapPlot(sAxesPlots);
                cMap = TesterHelper.mapPlot(cAxesPlots);
                
                if ~isequal(sMap, cMap)
                    msg = 'Incorrect data and/or style in plot(s)';
                    if numel(sMap) ~= numel(cMap)
                        msg = sprintf('%s\\nIn at least 1 plot, %d line(s) and/or point(s) were expected, but your solution had %d.', msg, numel(cMap), numel(sMap));
                    end
                    % Check if any points are outside x and y bounds
                    xLim = sAxes(i).XLim;
                    yLim = sAxes(i).YLim;
                    for j = 1:numel(sAxesPlots)
                        if any([sAxesPlots(j).XData] > xLim(2)) || any([sAxesPlots(j).XData] < xLim(1))...
                            || any([sAxesPlots(j).YData] > yLim(2)) || any([sAxesPlots(j).YData] < yLim(1))
                            % Only add msg if it doesn't exist yet
                            if ~contains(msg, 'plot boundaries')
                                msg = sprintf('%s\\n<em>Warning: There seems to be data outside of the plot boundaries</em>', msg);
                            end
                        end
                    end
                end
                if ~isempty(msg)
                    break
                end
            end
            
            % Other checks
            for i = 1:numel(cAxes)
                if ~strcmp(char(sAxes(i).XLabel.String), char(cAxes(i).XLabel.String))
                    msg = sprintf('%s\\nIncorrect x-label(s) (Expected: %s, Actual: %s)', msg, char(cAxes(i).XLabel.String), char(sAxes(i).XLabel.String));
                end
                if ~strcmp(char(sAxes(i).YLabel.String), char(cAxes(i).YLabel.String))
                    msg = sprintf('%s\\nIncorrect y-label(s) (Expected: %s, Actual: %s)', msg, char(cAxes(i).YLabel.String), char(sAxes(i).YLabel.String));
                end
                if ~strcmp(char(sAxes(i).Title.String), char(cAxes(i).Title.String))
                    msg = sprintf('%s\\nIncorrect title(s) (Expected: %s, Actual: %s)', msg, char(cAxes(i).Title.String), char(sAxes(i).Title.String));
                end
                if ~isequal(sAxes(i).XLim, cAxes(i).XLim)
                    msg = sprintf('%s\\nIncorrect x limits', msg);
                end
                if ~isequal(sAxes(i).YLim, cAxes(i).YLim)
                    msg = sprintf('%s\\nIncorrect y limits', msg);
                end
                if ~all(abs(sAxes(i).PlotBoxAspectRatio - cAxes(i).PlotBoxAspectRatio) < 0.02)
                    msg = sprintf('%s\\nIncorrect plot size', msg);
                end
                if ~isempty(cAxes(i).Legend)
                    if isempty(sAxes(i).Legend)
                        msg = sprintf('%s\\nMissing legend(s)', msg);
                    else
                        if ~strcmp(char(sAxes(i).Legend.String), char(cAxes(i).Legend.String))                            
                            msg = sprintf('%s\\nIncorrect legend text(s)', msg);
                        end
                        if ~strcmp(char(sAxes(i).Legend.Location), char(cAxes(i).Legend.Location)) 
                            msg = sprintf('%s\\nIncorrect legend location(s)', msg);
                        end
                    end
                end

                if ~isempty(msg)
                    break
                end              
            end

            % Output formatting
            if ~isempty(msg)
                hasPassed = false;
                if strcmp(msg(1:2), '\n')
                    msg = msg(3:end);
                end
                msg = strrep(msg, '\n', '\n    ');
                appendImage;
            else
                hasPassed = true;
            end

            function appendImage
                % Internal function to append image file to end of message
                if strcmpi(obj.outputType, 'full')
                    filename = TesterHelper.compareImg(sFig, cFig);
                    msg = sprintf('%s\\nIMAGEFILE:%s', msg, filename);  
                end
            end
        end

        function [hasPassed, msg] = checkTextFiles(obj, user_fn, soln_fn)

            % CHECKTEXTFILES - Check and compare a text file against the solution's.
            %   This function will read in a text file and compare it to its corresponding solution file. The comparison
            %   depends on the textRule property, where 'default' will ignore the extra newline character at the end of
            %   either text file, 'strict' will not ignore the newline, and 'loose' will also ignore capitalization. 
            %   The final result is run through the testCase object using verifyTrue. The outputType property does affect 
            %   this function, and the full output includes a line by line comparison between the two text files, with
            %   different lines highlighted.
            %
            %   Input Arguments
            %       user_fn, soln_fn - Filename of the student's text file and the expected text file
            %   
            %   Output Arguments
            %       hasPassed - True if the text file comparison passed and false if not.
            %       msg - Character message containing text file comparison. Is empty if hasPassed is true.

            % Check for files
            if ~exist(soln_fn, 'file')
                error('HWTester:noFile', 'The solution text file wasn''t found');
            end
            if ~exist(user_fn, 'file')
                obj.testCase.verifyTrue(false, ['Your solution did not produce a text file when one was expected. ' ...
                    'Was it created properly with the right filename?'])
                return
            end
            student = readlines(user_fn);
            soln = readlines(soln_fn);

            % Compare using defined rules
            if ~strcmpi(obj.textRule, 'strict')
                if isempty(char(student(end)))
                    student(end) = [];
                end
                if isempty(char(soln(end)))
                    soln(end) = [];
                end
            end
            n_st = length(student);
            n_sol = length(soln);       
            if strcmpi(obj.textRule, 'loose')
                same = strcmpi(student(1:min(n_st, n_sol)), soln(1:min(n_st, n_sol)));
            else
                same = strcmp(student(1:min(n_st, n_sol)), soln(1:min(n_st, n_sol)));
            end
            if n_st ~= n_sol
                hasPassed = false;
                msg = sprintf('The output text has %d lines when %d lines are expected.', length(student), length(soln));
            elseif ~all(same)
                hasPassed = false;
                msg = sprintf('The output text does not match the expected text file.');
            else
                hasPassed = true;
                msg = '';
            end

            % Output formatting. <mark> only works for html, replace with <strong> if the output has to be displayed
            % locally in Matlab. Limit output display to 20 lines.
            if strcmpi(obj.outputType, 'none')
                msg = '';
            elseif ~hasPassed && strcmpi(obj.outputType, 'full')
                if n_st > 20
                    student = [student(1:20); "Additional lines have been suppressed."];
                end
                if n_sol > 20
                    soln = [soln(1:20); "Additional lines have been suppressed."];
                end
                student(~same) = strcat("<mark>", student(~same), "</mark>");
                soln(~same) = strcat("<mark>", soln(~same), "</mark>");
                if n_st > n_sol
                    student(n_sol+1:end) = strcat("<mark>", student(n_sol+1:end), "</mark>");   
                elseif n_sol > n_st
                    soln(n_st+1:end) = strcat("<mark>", soln(n_st+1:end), "</mark>");
                end
                msg = sprintf('%s\n%s\nActual text file:\n%s\n%s\n%s\nExpected text file:\n%s\n%s', ...
                        msg, repelem('-', 16), repelem('-', 16), char(strjoin(student, '\n')), repelem('-', 16), repelem('-', 16), char(strjoin(soln, '\n')));
                msg = strrep(msg, newline, '\n    ');
            end

            obj.testCase.verifyTrue(hasPassed, msg)
        end
    end
  
    methods (Static)
        function [isClosed, msg] = checkFilesClosed(varargin)

            % CHECKFILESCLOSED - Check if all files have been properly closed.
            %   This function will check to ensure that all files have been closed using fclose. If any files are still
            %   open, it will close them.
            %
            %   Output Arguments
            %       tf - True if all files were properly closed, and false if not.
            %       msg - Character message indicating the number of files still left open. Is empty if tf is true.

            stillOpen = openedFiles();
            fclose all;
            if ~isempty(stillOpen)
                isClosed = false;
                msg = sprintf('%d file(s) still open! (Did you fclose?)', length(stillOpen));
            else
                isClosed = true;
                msg = '';
            end
        end
        
        %% Helper Functions

        function varargout = compareImg(varargin)

            % COMPAREIMG - Compare two images or figures.
            %   This function will read in two figures or two image filenames and displays a figure comparison between
            %   them. This function can also save the figure comparsion as a jpg image. Intended as a helper function 
            %   for checkImages and checkPlots.
            %
            %   Syntax
            %       compareImg(user, expected)
            %       F = compareImg(user, expected)
            %       F = compareImg()
            %
            %   Input Arguments
            %       user, expected - Filename of the student's image and the expected image OR the student's figure and
            %       the expected figure. If no input arguments are specified, it will save the currently open figure
            %       window as a jpg.
            %   
            %   Output Arguments
            %       F - Filename of the comparsion image as a jpg. If no output arguments are specified, it will display 
            %           the comparison as a figure.
            %
            %   See also checkImages, checkPlots

            if nargout == 0
                if nargin < 2
                    error('HWTester:arguments', 'You must have at least 1 output or two inputs.');
                else
                    % Extract relevant data
                    if isa(varargin{1}, 'matlab.ui.Figure')
                        fig1 = varargin{1};
                        fig2 = varargin{2};
                        set(fig1, 'Position', [100, 100, 300, 200]);
                        set(fig2, 'Position', [100, 100, 300, 200]);
                        user = getframe(varargin{1}).cdata;
                        expected = getframe(varargin{2}).cdata;
                        type = 'Plot';
                    elseif exist(varargin{1}, 'file')
                        user = imread(varargin{1});
                        expected = imread(varargin{2});
                        type = 'Image';
                    else
                        error('HWTester:arguments', 'The inputs must either be figures or image files.');
                    end
                    % Plots
                    close all;
                    tiledlayout(1, 2, 'TileSpacing', 'none', 'Padding', 'tight');
                    nexttile
                    imshow(user);
                    if nargin == 3
                        title(sprintf('Student %s', type), 'FontSize', 8);
                    else
                        title(sprintf('Student %s', type));
                    end
                    nexttile
                    imshow(expected);
                    if nargin == 3
                        title(sprintf('Solution %s', type), 'FontSize', 8);
                    else
                        title(sprintf('Solution %s', type));
                    end
                    if nargin ~= 3
                        pos = get(gcf, 'Position');
                        pos = [pos(1)-pos(3)*0.3 pos(2) pos(3)*1.6 pos(4)]; % Rescale
                        set(gcf, 'Position', pos);
                    end
                    shg;
                    return;
                end
            else
                % Open figure comparsion, then save the figure data,
                if nargin == 2
                    TesterHelper.compareImg(varargin{:}, 'call'); % Recursive call to display figures
                end
                % Decrease this value if Gradescope is not displaying properly
                set(gcf, 'Position', [100, 100, 380, 120]); % Size of output image.
                set(gcf, 'PaperPositionMode', 'auto');
                filename = [tempname, '.jpg'];
                saveas(gcf, filename);
                close all
                varargout{1} = filename;
            end
        end

        function calls = getCalls(path)

            % GETCALLS - Return all built-in function calls and operations that a function used.
            %   This function will output all built-in functions and operations that a particular function called in a
            %   cell array of characters. All operations (use iskeyword() for a list) are indicated in caps. 
            %   Intended as a helper function for checkCalls.
            %
            %   Syntax
            %       C = getCalls(path)
            %
            %   Arguments
            %       path - path of the function file to retrieve all calls from.
            %       C - cell array containing all function and operations that it called.
            %
            % This code runs on the mtree function which is not officially supported. Any helper functions
            % that the student calls will also be checked.
            %
            % This code was taken directly from the CS1371 organization repository.
            %
            % See also checkCalls, mtree

            [fld, ~, ~] = fileparts(path);
            info = mtree(path, '-file');
            calls = info.mtfind('Kind', {'CALL', 'DCALL'}).Left.stringvals;
            atCalls = info.mtfind('Kind', 'AT').Tree.mtfind('Kind', 'ID').stringvals;
            innerFunctions = info.mtfind('Kind', 'FUNCTION').Fname.stringvals;
            % any calls to inner functions should die
            calls = [calls, atCalls];
            calls(ismember(calls, innerFunctions)) = [];
        
            % For any calls that exist in our current directory, recursively collect their builtin calls
            localFuns = dir([fld filesep '*.m']);
            localFuns = {localFuns.name};
            localFuns = cellfun(@(s)(s(1:end-2)), localFuns, 'uni', false);
            localCalls = calls(ismember(calls, localFuns));
            calls(ismember(calls, localFuns)) = [];
            for l = 1:numel(localCalls)
                calls = [calls TesterHelper.getCalls([fld filesep localCalls{l} '.m'])]; %#ok<AGROW>
            end
        
            % Add operations
            OPS = cellfun(@upper, iskeyword, 'UniformOutput', false);
            calls = [calls reshape(string(info.mtfind('Kind', OPS).kinds), 1, [])];
            calls = unique(calls);
        end

        function out = generateCellArray(options)

            % GENERATECELLARRAY - Generates a simple cell array containing various data types.
            %   This function generates a cell array containing a random data type, including doubles, vectors, logical
            %   vectors, and strings. By default, it will generate all of them with a size of c = [3, 5] and r = 1.
            %
            %   Name-Value Arguments
            %       rows (double) - Specify the number of rows the cell array should have. Specify a range of possible
            %                       values by inputing a (1, 2) double vector. Default = 1.
            %       columns (double) - Specify the number of rows the cell array should have. Specify a range of possible
            %                          values by inputing a (1, 2) double vector. Default = [3, 5].
            %       doubles (logical) - Specify whether the cell array should contain single doubles. These doubles will 
            %                           be random integers in the range specified by doubleRange. Default = true.
            %       vectors (logical) - Specify whether the cell array should contain vectors of doubles. These doubles
            %                           will be random integers in the range specified by doubleRange, and the vector 
            %                           will be 1 to 5 in length. Default = true.
            %       strings (logical) - Specify whether the cell array should contain vectors of chars. These chars will
            %                           be a random string of 5 to 10 lowercase letters. Default = true.
            %       logicals (logicals) - Specify whether the cell array should contain vectors of logicals. The length
            %                             of this vector will be 1 to 5. Default = true.
            %       doubleRange (double) - Specify a range of values for all random double number generation. Default =
            %                              [0, 100].
            %       stringIsSent (logical) - Specify whether the strings should be generated in a sentence like format.
            %                                This will include spaces and increase the length to 20 to 40. Default = false.

            arguments
                options.rows (1, :) double = 1
                options.columns (1, :) double = [3, 5]
                options.vectors (1, 1) logical = true
                options.doubles (1, 1) logical = true
                options.strings (1, 1) logical = true
                options.logicals (1, 1) logical = true
                options.doubleRange (1, 2) double = [0, 100]
                options.stringIsSent (1, 1) logical = false
            end

            if isscalar(options.rows)
                r = options.rows;
            else
                r = randi(options.rows);
            end
            if isscalar(options.columns)
                c = options.columns;
            else
                c = randi(options.columns);
            end
            ca = cell([r, c]);
            pos = 'vdsl';
            pos = pos([options.vectors, options.doubles, options.strings, options.logicals]);
            for i = 1:numel(ca)
                type = pos(randi(numel(pos)));
                switch type
                    case 'v'
                        ca{i} = randi(options.doubleRange, [1, randi(5)]);
                    case 'd'
                        ca{i} = randi(options.doubleRange);
                    case 's'
                        if options.stringIsSent
                            ca{i} = TesterHelper.generateString(sentence=true, length=[20, 40]);
                        else
                            ca{i} = TesterHelper.generateString(length=[5, 10]);
                        end
                    case 'l'
                        ca{i} = logical(randi([0, 1], [1, randi(5)]));
                end
            end
            out = ca;
        end

        function out = generateSpec(options)

            % GENERATESPEC - Generates a random specification for plotting.
            %   This function generates a string of characters which can be used as plotting specifications.
            %
            %   Syntax
            %       C = generateSpec(NAME=VALUE)
            %
            %   Name-Value Arguments
            %       lines (logical) - Specify whether line specs should be included (default = true)
            %       points (logical) - Specify whether point specs should be included (default = true)
            %       colors (logical) - Specify whether color specs should be included (default = true)

            arguments
                options.lines (1, 1) logical = true
                options.points (1, 1) logical = true
                options.colors (1, 1) logical = true
            end

            out = [];
            if options.lines
                lineSpecs = {'-', ':', '-.', '--'};
                out = [lineSpecs{randi(numel(lineSpecs))}];
            end
            if options.points
                pointSpecs = '.ox+*sdp';
                out = [out pointSpecs(randi(numel(pointSpecs)))];
            end
            if options.colors
                colorSpecs = 'rgbcmyk';
                out = [out colorSpecs(randi(numel(colorSpecs)))];
            end
        end

        function out = generateString(options)

            % GENERATESTRING - Generate a random string of characters.
            %   This function generates a random string of characters based on the input options. By
            %   default, it generates a string of length 5 <= L <= 20, with uppercase characters,
            %   and no special characters, numbers, or spaces. The generator works by pulling from a
            %   pool of valid characters, with each character getting equal probability.
            %
            %   Syntax
            %       C = generateString()
            %       C = generateString(NAME=VALUE)
            %
            %   Name-Value Arguments
            %       length (double) - Specify the length (or number of columns) of output. Input a single number for a
            %                         specific length, or enter a 1x2 vector in the [MIN, MAX] format. Default = [5, 20]
            %       height (double) - Specify the height (number of rows) of output. Input a single number for a
            %                         specific height, or enter a 1x2 vector in the [MIN, MAX] format. Default = 1.
            %       pool (char) - Define a character pool for the generator to pull from. Elements within this
            %                     pool have an equal probability to be picked, if no other options are specified. By
            %                     default, this pool contains a single instance of all lowercase letters.
            %       uppercase (logical) - Add uppercase letters to character pool. Default = false.
            %       special (logical) - Adds certain special characters to character pool. Default = false.
            %       numbers (logical) - Add digits 0-9 to the character pool. Default = false.
            %       sentence (logical) - Adds spaces at a frequency to replicate sentence structure. Default = false.
            %       match (char) - Create a pseudorandom string by matching character patterns from the input. Specify any
            %                      characters from the pool with 'a'. This pool of characters is modified by the other arguments. 
            %                      Specify consonants as 'c' or 'C', vowels as 'v' or 'V', digits as 'd', special 
            %                      characters as 's', and any other character by inputting it directly. Escape the 
            %                      characters using '\'. Escape characters only work when r == 1. y is defined as a consonant.

            arguments
                options.length (1, :) double = [5, 20]
                options.height (1, :) double = 1
                options.uppercase (1, 1) logical = false
                options.special (1, 1) logical = false
                options.numbers (1, 1) logical = false
                options.sentence (1, 1) logical = false
                options.match char = ''
                options.pool (1, :) char = 'abcdefghijklmnopqrstuvwxyz'
            end

            % Define character pool
            c_pool = options.pool;
            if options.uppercase
                c_pool = [c_pool 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'];
            end
            if ~islogical(options.special)
                c_pool = [c_pool options.special];
            elseif options.special
                c_pool = [c_pool '!#$%()*+-./:;=?@'];
            end
            if options.numbers
                c_pool = [c_pool '0123456789'];
            end

            if isempty(options.match)
                % If no match string is given, define size.
                if isscalar(options.length)
                    c = options.length;
                else
                    c = randi(options.length);
                end
                if isscalar(options.height)
                    r = options.height;
                else
                    r = randi(options.height);
                end
                out = char(zeros([r, c]));
                exp = char(out + 'a'); % All characters can be any character input defined by c_pool
            else
                % If a match string is given, simply define the output size.
                exp = options.match;
                [r, c] = size(exp);
                if r == 1
                    len = length(exp) - numel(strfind(exp, '\'));
                    out = char(zeros([1, len]));
                else
                    out = char(zeros([r, c]));
                end
            end

            if ~options.sentence
                % Not sentence option. Have 2 indicies in case escape character used.
                i = 1; % Index of exp
                j = 1; % Index of out
                while i <= numel(exp)
                    switch exp(i)
                        case '\'
                            i = i + 1;
                            out(j) = exp(i);
                        case 'a'
                            pool = c_pool;
                            out(j) = pool(randi(numel(pool)));
                        case 'A'
                            pool = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
                            out(j) = pool(randi(numel(pool)));
                        case 'c'
                            pool = 'bcdfghjklmnpqrstvwxyz';
                            out(j) = pool(randi(numel(pool)));
                        case 'C'
                            pool = 'BCDFGHJKLMNPQRSTVWXYZ';
                            out(j) = pool(randi(numel(pool)));
                        case 'v'
                            pool = 'aeiou';
                            out(j) = pool(randi(numel(pool)));
                        case 'V'
                            pool = 'AEIOU';
                            out(j) = pool(randi(numel(pool)));
                        case 'd'
                            pool = '0123456789';
                            out(j) = pool(randi(numel(pool)));
                        case 's'
                            pool = '!#$%()*+-./:;=?@';
                            out(j) = pool(randi(numel(pool)));
                        otherwise
                            out(j) = exp(i);
                    end      
                    i = i + 1;
                    j = j + 1;
                end
                return
            else
                % Sentence option. Iterate through string, increasing space probability every time.
                prob = 0;
                for i = 1:numel(out)
                    p = rand();
                    if p < prob
                        out(i) = ' ';
                        prob = 0;
                    else
                        out(i) = c_pool(randi(numel(c_pool)));
                        prob = prob + 0.05;
                    end
                end
                % Remove ending space if needed
                if r == 1 && out(end) == ' '
                    out(end) = c_pool(randi(numel(c_pool)));
                end
            end
            
        end

        function map = mapPlot(lines)

            % MAPPLOT - Create a dictionary defining all points and line segments.
            %   This function takes in an array of Line objects and outputs a dictionary with all the points and line
            %   segments in the array. Intended as a helper function for checkPlots.
            %
            %   Syntax
            %       M = mapPlot(L)
            %
            %   Arguments
            %       L - Array of Line objects to create a dictionary from.
            %       M - Dictionary of all points and line segments in L. It's keys will be a 1x2 cell array containing a
            %           numeric vector. For points, this vector will be [x-coord, y-coord]. For line segments, this 
            %           vector will be [x-coord1, y-coord1, x-coord2, y-coord2]. It's values will be a 1xN cell array. 
            %           For points, N will be 4 and will store the marker style, marker size, edge color, and face color 
            %           in that order. For line segments, N will be 3 and will store line color, line style, and 
            %           line width in that order. All coordinates will be rounded to 4 decimal places.
            %
            %   See also checkPlots

            map = dictionary();
            for i = 1:numel(lines)
                line = lines(i);
                if ~isempty(line.ZData)
                    warning('3D plotting isn''t supported');
                end
                % Add all drawn points
                if ~strcmp(line.Marker, 'none')
                    key = num2cell([round(line.XData', 4), round(line.YData', 4)], 2);
                    if strcmp(line.MarkerEdgeColor, 'auto')
                        color = line.Color;
                    else
                        color = line.MarkerEdgeColor;
                    end
                    data = {{line.Marker, line.MarkerSize, color, line.MarkerFaceColor}};
                    data = repelem(data, numel(key), 1);
                    map = insert(map, key, data);
                end

                % Add all segments
                if ~strcmp(line.LineStyle, 'none')
                    key = [round(line.XData(1:end-1)', 4), round(line.YData(1:end-1)', 4), ...
                        round(line.XData(2:end)', 4), round(line.YData(2:end)', 4)];
                    needSwap = key(:, 1) > key(:, 3);
                    key(needSwap, :) = key(needSwap, [3 4 1 2]);
                    data = {{line.Color, line.LineStyle, line.LineWidth}};
                    map = insert(map, num2cell(key, 2), data);
                end
            end
        end

        function out = toChar(in, options)

            % TOCHAR - Convert the input into a character.
            %   This function takes in any input and converts it into a character vector.
            %       By default:
            %           - Structures are converted to tables so all fields and values can be displayed.
            %           - If the input is a string that ends with '.txt' and a corresponding txt file exists,
            %             the contents of the file will be output.
            %           - Numeric and logical vectors have a '[' and ']' to indicate the beginning and end.
            %           - Any input that leads to more than twenty rows of characters will have additional rows suppressed.
            %
            %   Syntax
            %       C = toChar(A, Name=Value)
            %
            %   Input/Output Arguments
            %       A - Any input that should be converted into a char.
            %       C - The output character array representing A.
            %
            %   Name-Value Arguments
            %       interactive (char) - If the input is a complex data type (not a char, numeric, or logical) and 
            %                            exists as a variable, it instead outputs a clickable hyperlink to open that 
            %                            variable in Matlab. Alternatively, if the input is a string that indicates an 
            %                            existing file, it will also output a hyperlink to open that file in Matlab. 
            %                            Files with image extensions '.png', '.jpg', and '.jpeg' will display as a figure 
            %                            in Matlab if the hyperlink is clicked. Default = false.
            %       html (logical) - Outputs in html format. Default = false.
            %       cap (logical) - Caps the output to 20 rows. Default = true.

            arguments
                in
                options.interactive = false
                options.html = false
                options.cap = true
            end

            [r, c, l] = size(in);
            if isempty(in)
                out = '[]';
            elseif l > 1
                % If there are more than 2 dimensions
                out = char(formattedDisplayText(in, 'UseTrueFalseForLogical', true, 'LineSpacing', 'compact', 'SuppressMarkup',true));
            elseif isstruct(in) && ~options.interactive
                try
                    % Change into strings or will display as cells in table
                    for i = 1:numel(in)
                        fields = fieldnames(in);
                        for j = 1:numel(fields)
                            if ischar(in(i).(fields{j}))
                                % Replace inner double quotes with \" for display
                                in(i).(fields{j}) = string(strrep(in(i).(fields{j}), '"', '\"'));
                            end
                        end
                    end
                    out = struct2table(in, 'AsArray', true);
                catch
                    out = in;
                end
                out = char(formattedDisplayText(out, 'UseTrueFalseForLogical', true, 'LineSpacing', 'compact', 'SuppressMarkup',true));
                out = regexprep(out, '(?<!\\)"', ''''); % Replace outer double quotes
                out = strrep(out, '\"', '"'); % Replace inner, escaped double quotes
                parseHtml;
            elseif ischar(in) || isstring(in)
                % Convert string into char
                if isstring(in)
                    out = char(in);
                else
                    out = in;
                end
                % Interactive inputs
                if r == 1 && options.interactive && exist(out, 'file')
                    if contains(out, '.png') || contains(out, '.jpg') || contains(out, '.jpeg')
                        out = sprintf('<a href="matlab: cd(''%s'');clf;imgDisp=imread(''%s'');imshow(imgDisp);clear imgDisp;shg">%s</a>', pwd, out, out);
                    else
                        out = sprintf('<a href="matlab: cd(''%s'');open(''%s'')">%s</a>', pwd, out, out);
                    end
                elseif r == 1 && contains(in, '.txt') && exist(in, 'file')
                    out = char(strjoin(readlines(in), '\n'));
                    % If text file was empty, return file name instead
                    if isempty(out)
                        out = in;
                    end
                else
                    % Default char and string conversion
                    out = [repmat('''', r, 1) out repmat('''', r, 1)];
                    out = char(formattedDisplayText(out, 'UseTrueFalseForLogical', true, 'LineSpacing', 'compact', 'SuppressMarkup', true));
                    parseHtml;
                end
            elseif isnumeric(in)
                if r == 1
                    if c == 1
                        % Single number
                        out = num2str(in, 10);
                    else
                        % Numeric vector
                        out = mat2str(in, 10);
                        out = strrep(out, ' ', ', ');
                    end
                else
                    % Numeric array
                    out = char(formattedDisplayText(in, 'UseTrueFalseForLogical', true, 'LineSpacing', 'compact', 'SuppressMarkup', true));
                    loc = find(isstrprop(out, 'alphanum'), true);
                    out(loc - 1) = '[';
                    out = [out(1:end-1) ']' out(end)];
                end
            elseif islogical(in)
                out = char(formattedDisplayText(in, 'UseTrueFalseForLogical', true, 'LineSpacing', 'compact', 'SuppressMarkup', true));
                if contains(out, 'Columns')
                    out = [' [' out(3:end-1) ']'];
                else
                    % Single logical
                    out(out == ' ') = [];
                    if c > 1
                        % Logical vectors and arrays
                        out = replace(out, 'true', ', true');
                        out = replace(out, 'false', ', false');
                        out = replace(out, [newline ', '], [newline ' ']);
                        out = ['[' out(3:end-1) ']'];
                    end
                end
            else
                out = char(formattedDisplayText(in, 'UseTrueFalseForLogical', true, 'LineSpacing', 'compact', 'SuppressMarkup', true));
                parseHtml;
            end

            if out(end) == newline
                out(end) = [];
            end
            if options.cap
                new = strfind(out, newline);
                if numel(new) > 20
                    out = out(1:new(20));
                    out = [out '<strong>Additional lines have been suppressed.</strong>'];
                end 
            end
            if options.html
                if l > 1
                    pref = sprintf('(%dx%dx%d %s):', r, c, l, class(in));
                else
                    pref = sprintf('(%dx%d %s):', r, c, class(in));
                end
                out = [pref '\n       ' out];
                out = strrep(out, newline, '\n       ');
            end

            function parseHtml
                % Internal function to parse output char and replace illegal html characters if necessary
                if options.html
                    out = strrep(out, '&', '&amp;');
                    out = strrep(out, '<', '&lt;');
                    out = strrep(out, '>', '&gt;');
                end
            end
        end
    end
end