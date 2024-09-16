classdef TesterHelper
    % TESTERHELPER - This class includes methods to help grade and check HW functions. See documentation 
    %                for a full list of functions and descriptions.

    methods (Static)
        %% Check functions

        function checkAllEqual(options)

            % CHECKALLEQUAL - Check and compare all solution variables against the student's.
            %   This function compares all variables in the caller's workspace that ends with '_soln' against the 
            %   variables that don't with Matlab's unittest verifyEqual function. This function can only be used in a
            %   testing environment and assumes a testCase object exists in the caller.
            %
            %   Syntax
            %       checkAllEqual()
            %       checkAllEqual(Name=Value)
            %
            %   Name-Value Arguments
            %       html (logical) - Output diagnostic in html format. Default = true.
            %       output (char) - Change how much information should be output in the diagnostic:
            %           'full' (default) - Output full comparison information.
            %           'limit' - Only ouput which variables are incorrect instead of a comparison.
            %           'none' - No output text.
            
            arguments
                options.html (1, 1) logical = true
                options.output char = 'full'
            end

            try
                testCase = evalin('caller', 'testCase');
            catch
                error('A testCase object must exist in the caller''s workspace.');
            end

            vars = evalin('caller', 'who');
            solns = vars(endsWith(vars, '_soln')); % Extract variable names

            % Loop through variables and compare each one
            for i = 1:length(solns)
                try
                    student = evalin('caller', vars{strcmp(vars, extractBefore(solns{i}, '_soln'))});
                catch
                    error('Variable %s (and possibly others) was not found', extractBefore(solns{i}, '_soln'));
                end
                soln = evalin('caller', solns{i}); % Extract variable data
                if strcmpi(options.output, 'none')
                    continue
                elseif strcmpi(options.output, 'limit')
                    msg = sprintf('Variable %s does not match the solution''s.', extractBefore(solns{i}, '_soln'));
                elseif strcmpi(options.output, 'full')
                    if options.html
                        msg = ['<u>', extractBefore(solns{i}, '_soln'), '</u>\n', '    Actual output (' class(student) '):\n    ' TesterHelper.toChar(student, html=true) '\n    Expected output (' class(soln) '):\n    ' TesterHelper.toChar(soln, html=true)];
                    else
                        msg = sprintf('Actual output:\n%s\nExpected output:\n%s', TesterHelper.toChar(student), TesterHelper.toChar(soln));
                    end
                end
                testCase.verifyEqual(student, soln, msg, "AbsTol", 0.001);
            end
        end

        function [hasPassed, msg] = checkCalls(varargin, additional)
            
            % CHECKCALLS - Check a function file's calls.
            %   This function will check if the function in question calls or does not call certain functions or use
            %   certain operations. A list of allowed functions and operations should be specified in a file called
            %   'Allowed_Functions.json'. Operations are defined the keywords that appear when the function iskeyword is 
            %   called, and must be in all caps. If no output arguments are specified, then it is assumed the
            %   function is being used in a testing environment and a testCase object exists in the caller. 
            %
            %   Syntax
            %       [tf, msg] = checkCalls(func)
            %       [tf, msg] = checkCalls(func, Name=Value)
            %       checkCalls(func, Name=Value)
            %       checkCalls(Name=Value)
            %
            %   Input Arguments
            %       func - Name of the function to test as a character vector. If unspecified, it retrieves the name of
            %              the caller function and uses the appropriate substring (called should be named FUNCNAME_TEST#).
            %
            %   Name-Value Arguments
            %       banned (cell) - List of additional banned functions.
            %       include (cell) - List of functions that must be included.
            %       allow (cell) - List of functions that should bypass the ban restriction.
            %
            %   Output Arguments
            %       tf - True if the function passed all checks, and false if a banned function is present or an
            %            included function is not.
            %       msg - Character message indicating which functions are banned or missing. Is empty if tf is true.
            % 
            %   Examples
            %       [tf, msg] = TesterHelper.checkCalls('myFunc', banned={'max', 'min'}, include={'WHILE'})
            %       TesterHelper.checkCalls()
            
            arguments(Repeating)
                varargin
            end
            arguments
                additional.banned cell = {}
                additional.include cell = {}
                additional.allow cell = {}
            end

            % Find name of function to test
            if nargin > 0 && ischar(varargin{1})
                funcFile = varargin{1};
            else
                try
                    stack = dbstack;
                    funcFile = char(extractBetween(stack(2).name, '.', '_Test'));
                catch
                    error('Error retrieving the name of the function being tested.');
                end
            end

            % Create full list of banned and allowed functions
            list = jsondecode(fileread('Allowed_Functions.json'));
            allowed = [list.ALLOWED; list.ALLOWED_OPS; additional.allow'];
            msg = [];
            banned = additional.banned';
            include = additional.include;

            calls = TesterHelper.getCalls(which(funcFile)); % Get list of function calls

            % Find banned functions and unused functions
            bannedCalls = [calls(ismember(calls, banned)), calls(~ismember(calls, allowed))];
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

            % Run tester
            if nargout == 0
                try
                    testCase = evalin('caller', 'testCase');
                    testCase.verifyTrue(hasPassed, msg);
                catch
                    error('If no outputs are specified, a testCase object must be present in the caller''s workspace.');
                end
            end
        end

        function [isClosed, msg] = checkFilesClosed(varargin)

            % CHECKFILESCLOSED - Check if all files have been properly closed.
            %   This function will check to ensure that all files have been closed using fclose. If any files are still
            %   open, it will close them. If no output arguments are specified, then it is assumed the function is being 
            %   used in a testing environment and a testCase object exists in the caller.
            %
            %   Syntax
            %       [tf, msg] = checkFilesClosed()
            %       checkFilesClosed()
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
            if nargout == 0
                try
                    testCase = evalin('caller', 'testCase');
                    testCase.verifyTrue(isClosed, msg);
                catch
                    error('If no outputs are specified, a testCase object must be present in the caller''s workspace.');
                end
            end
        end

        function [hasPassed, msg] = checkImages(user_fn, options)

            % CHECKIMAGES - Check and compare an image against the solution's.
            %   This function will read in an image filename and compare it to its corresponding image solution with a
            %   small tolerance. If no output arguments are specified and html = false, it instead displays a figure 
            %   comparison of the two images. If no output arguments are specified and html = true, then it is assumed 
            %   the function is being used in a testing environment and a testCase object exists in the caller.
            %
            %   Syntax
            %       [tf, msg] = checkImages(user_fn)
            %       [tf, msg] = checkImages(user_fn, Name=Value)
            %       checkImages(user_fn)    
            %       checkImages(user_fn, Name=Value)
            %
            %   Input Arguments
            %       user_fn - Filename of the student's image. It will assume the solution image is the filename with '_soln' attached.
            %
            %   Name-Value Arguments
            %       html (logical) - This adds the figure comparison as embedded html data (base64) to the output msg 
            %                        variable. It also calls verifyEqual. If there are no output arguments, its default 
            %                        is true. Otherwise, it is false.
            %       output (char) - Change how much information is contained in msg:
            %           'full' (default) - Output full comparison data, including image.
            %           'limit' - Only output error text.
            %           'none' - Don't output any message.
            %       tolerance (double) - Add RGB value tolerance to the function. Default = 5.
            %       
            %   Output Arguments
            %       tf - True if the images matched, and false if not.
            %       msg - Character message indicating why the test failed, along with a hyperlink to display the
            %             figure comparison. Is empty if tf is true.

            arguments
                user_fn char
                options.html (1, 1) logical
                options.output char = 'full'
                options.tolerance (1, 1) double = 5
            end

            % Input validation
            if ~isfield(options, 'html')
                if nargout == 0
                    options.html = true;
                else
                    options.html = false;
                end
            end
            if nargout == 0 && options.html
                try
                    testCase = evalin('caller', 'testCase');
                catch
                    error('If html is not specified and there are no output arguments, a testCase object must be present in the caller''s workspace.');
                end
            end

            % Solution file name
            [file, ext] = strtok(user_fn, '.');
            expected_fn = [file '_soln' ext];
            
            % Check if images can be accessed
            if ~exist(expected_fn, 'file')
                error('The solution image does not exist');
            elseif ~exist(user_fn, 'file')
                hasPassed = false;
                if options.html
                    msg = 'Your image doesn''t exist. Was it created properly with the right filename?';
                else
                    msg = 'The image does not exist or is in a different directory.';
                end
                return;
            end
            if nargout == 0 && ~options.html
                TesterHelper.compareImg(user_fn, expected_fn); % Open figure comparison
                shg;
                return;
            else
                % Image comparsion
                user = imread(user_fn);
                expected = imread(expected_fn);
                [rUser,cUser,lUser] = size(user);
                [rExp,cExp,lExp] = size(expected);
                if rUser == rExp && cUser == cExp && lUser == lExp
                    diff = abs(double(user) - double(expected));
                    isDiff = any(diff(:) > options.tolerance);
                    if isDiff
                        hasPassed = false;
                        msg = 'The image output does not match the expected image.';
                    else
                        hasPassed = true;
                        msg = [];
                        return;
                    end
                else
                    hasPassed = false;
                    msg = sprintf('The dimensions of the image do not match the expected image.\nActual size: %dx%dx%d\nExpected size: %dx%dx%d', rUser, cUser, lUser, rExp, cExp, lExp);
                end

                % Output
                if strcmpi(options.output, 'none')
                    msg = '';
                elseif strcmpi(options.output, 'full')
                    if options.html
                        base64string = TesterHelper.compareImg(user_fn, expected_fn);
                        msg = strrep(msg, newline, '\n');
                        msg = sprintf('%s\\n%s', msg, base64string);
                    else
                        msg = sprintf('%s\n<a href="matlab: cd(''%s'');TesterHelper.compareImg(''%s'', ''%s'')">Image comparison</a>', msg, pwd, user_fn, expected_fn);
                    end
                end

                if exist('testCase', 'var')
                    testCase.verifyTrue(hasPassed, msg);
                end
            end
        end

        function [hasPassed, msg] = checkPlots(options)
            
            % CHECKPLOTS - Check and compare a plot against the solution's.
            %   This function will read in the currently open figures and compare them. For the function to work, all
            %   figures must be closed and then at least 2 figures must be opened. The student plot should be created
            %   first, followed by the solution plot. The solution plot must not override the student's, so 'figure'
            %   must be called. If no output arguments are specified and html is true, then it is assumed the function 
            %   is being used in a testing environment and a testCase object exists in the caller.
            %
            %   Syntax
            %       [tf, msg] = checkPlots()
            %       [tf, msg] = checkPlots(Name=Value)
            %       checkPlots(Name=Value)
            %
            %   Name-ValueInput Arguments
            %       html (logical) - This adds the figure comparison as embedded html data (base64) to the output msg 
            %                        variable. It also calls verifyEqual. If there are no output arguments, its default 
            %                        is true. Otherwise, it is false.
            %       output (char) - Change how much information is contained in msg:
            %           'full' (default) - Output full comparison data, including image.
            %           'limit' - Only output error text.
            %           'none' - Don't output any message.
            %
            %   Output Arguments
            %       tf - True if the plots matched, false if not.
            %       msg - Character message indicating why the test failed. Is empty if tf is true.
            %
            %   Example
            %       close all;
            %       func();
            %       figure;
            %       func_soln();
            %       [tf, msg] = checkPlots();
            %
            %   checkPlots does not current support or check the following:
            %       - Annotations, tiled layout, UI elements, colorbars, or other graphic elements
            %       - Plots generated with functions other than plot (such as scatter)
            %       - 3D plots, or any plots with a z axis
            %       - Text styles or font size
            %       - Box styling, tick marks, tick labels, and similar
            %       - Similar plots with a margin of error

            arguments
                options.html (1, 1) logical
                options.output char = 'full'
            end

            if ~isfield(options, 'html')
                if nargout == 0
                    options.html = true;
                else
                    options.html = false;
                end
            end

            % Check if figures are open
            if length(findobj('type', 'figure')) < 2
                error('There must be at least 2 figures displayed.');
            end
            
            % sFig - Student, cFig - Correct figure. Need to check next plot in case 'figure' was called in the function.
            sFig = figure(1);
            if numel(sFig.Children) == 0
                sFig = figure(2);
                cFig = figure(3);
            else
                cFig = figure(2);
            end
            if numel(cFig.Children) == 0
                cFig = figure(cFig.Number + 1);
            end
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
                    % Check if any points are outside x and y bounds
                    xLim = sAxes(i).XLim;
                    yLim = sAxes(i).YLim;
                    for j = 1:numel(sMap)
                        if any([sAxesPlots(i).XData] > xLim(2)) || any([sAxesPlots(i).XData] < xLim(1))...
                            || any([sAxesPlots(i).YData] > yLim(2)) || any([sAxesPlots(i).YData] < yLim(1))
                            msg = sprintf('%s\\nThere seems to be data outside of the plot boundaries', msg);
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
                    msg = sprintf('%s\\nIncorrect x-label(s)', msg);
                end
                if ~strcmp(char(sAxes(i).YLabel.String), char(cAxes(i).YLabel.String))
                    msg = sprintf('%s\\nIncorrect y-label(s)', msg);
                end
                if ~strcmp(char(sAxes(i).Title.String), char(cAxes(i).Title.String))
                    msg = sprintf('%s\\nIncorrect title(s)', msg);
                end
                if ~isequal(sAxes(i).XLim, cAxes(i).XLim)
                    msg = sprintf('%s\\nIncorrect x limits', msg);
                end
                if ~isequal(sAxes(i).YLim, cAxes(i).YLim)
                    msg = sprintf('%s\\nIncorrect y limits', msg);
                end
                if ~isequal(sAxes(i).PlotBoxAspectRatio, cAxes(i).PlotBoxAspectRatio)
                    msg = sprintf('%s\\nIncorrect aspect ratio', msg);
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

            % Output
            if ~isempty(msg)
                hasPassed = false;
                if strcmp(msg(1:2), '\n')
                    msg = msg(3:end);
                end
                if options.html
                    base64string = TesterHelper.compareImg(sFig, cFig);
                    msg = strrep(msg, '\n', '\n    ');
                    msg = sprintf('%s\\n%s', msg, base64string);             
                end
            else
                hasPassed = true;
            end

            if nargout == 0 && options.html
                try
                    testCase = evalin('caller', 'testCase');
                    testCase.verifyTrue(hasPassed, msg);
                catch
                    error('If html is not specified and there are no output arguments, a testCase object must be present in the caller''s workspace.');
                end
            end
        end

        function [hasPassed, msg] = checkTxtFiles(user_fn, options)

            % CHECKTXTFILES - Check and compare a text file against the solution's.
            %   This function will read in two text files and compare them. By default, it will ignore an extra newline
            %   at the end of any text file.
            %
            %   Syntax
            %       [tf, msg] = checkTxtFiles(user_fn)
            %       [tf, msg] = checkTxtFiles(___, Name=Value)
            %       checkTxtFiles(___, Name=Value)
            %
            %   Input Arguments
            %       user_fn - Filename of the student's text file. It will assume the solution image is the filename with 
            %              '_soln' attached.
            %
            %   Name-Value Arguments
            %       rule (char) - Indicates how to compare the two text files.
            %           'default' (default) - Compares the two text files character by character, ignoring an extra
            %                                 newline at the end of any text file.
            %           'strict' - Don't ignore the newline at the end of a text file.
            %           'loose' - Ignore capitilization and the newline.
            %       output (char) - Change how much information is contained in msg:
            %           'full' (default) - Output full comparison data, including line by line comparison.
            %           'limit' - Only output error text.
            %           'none' - Don't output any message.
            %       cap (logical) - Indiate whether to cap the output comparsion to 15 lines. Default = false.
            %       html (logical) - Output the comparsion in html format. If there are no output arguments, it's
            %                        default is true. Otherwise, it is false.
            %
            %   Output Arguments
            %       tf - True if the text files matched, false if not.
            %       msg - Character message indicating why the test failed, along with a comparison of the two text
            %       files with the different lines bolded/highlighted. Is empty if tf is true.

            arguments
                user_fn char
                options.rule char = 'default'
                options.output char = 'full'
                options.cap (1, 1) logical = false
                options.html (1, 1) logical
            end

            if ~isfield(options, 'html')
                if nargout == 0
                    options.html = true;
                else
                    options.html = false;
                end
            end
            
            % Read in files
            soln_fn = [user_fn(1:end-4) '_soln.txt'];
            student = readlines(user_fn);
            soln = readlines(soln_fn);

            % Compare using defined rules
            if ~strcmpi(options.rule, 'strict')
                if isempty(char(student(end)))
                    student(end) = [];
                end
                if isempty(char(soln(end)))
                    soln(end) = [];
                end
            end
            n_st = length(student);
            n_sol = length(soln);       
            if strcmpi(options.rule, 'loose')
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

            % Output
            if strcmpi(options.output, 'none')
                msg = '';
            elseif ~hasPassed && strcmpi(options.output, 'full')
                if n_st > 15 && options.cap
                    student = [student(1:15); "Additional rows have been suppressed."];
                end
                if n_sol > 15 && options.cap
                    soln = [soln(1:15); "Additional rows have been suppressed."];
                end
                student(~same) = strcat("<strong>", student(~same), "</strong>");
                soln(~same) = strcat("<strong>", soln(~same), "</strong>");
                if n_st > n_sol
                    student(n_sol+1:end) = strcat("<strong>", student(n_sol+1:end), "</strong>");   
                elseif n_sol > n_st
                    soln(n_st+1:end) = strcat("<strong>", soln(n_st+1:end), "</strong>");
                end
                msg = sprintf('%s\n%s\nActual text file:\n%s\n%s\n%s\nExpected text file:\n%s\n%s', ...
                        msg, repelem('-', 17), repelem('-', 17), char(strjoin(student, '\n')), repelem('-', 17), repelem('-', 17), char(strjoin(soln, '\n')));
                if options.html
                    msg(msg == '"') = '''';
                    msg = strrep(msg, '<strong>', '<mark>'); % Replace with highlight in html
                    msg = strrep(msg, '</strong>', '</mark>');
                    msg = strrep(msg, newline, '\n    ');
                end
            end

            % Run tester
            if nargout == 0 && options.html
                try
                    testCase = evalin('caller', 'testCase');
                    testCase.verifyTrue(hasPassed, msg);
                catch
                    error('If html is not specified and there are no output arguments, a testCase object must be present in the caller''s workspace.');
                end
            end
        end

        %% Helper Functions

        function varargout = compareImg(varargin)

            % COMPAREIMG - Compare two images or figures.
            %   This function will read in two figures or two image filenames and displays a figure comparison between
            %   them. This function can also be used to convert this comparison into html base64 data. Intended as a
            %   helper function for checkImages and checkPlots.
            %
            %   Syntax
            %       compareImg(user, expected)
            %       H = compareImg(user, expected)
            %       H = compareImg()
            %
            %   Input Arguments
            %       user, expected - Filename of the student's image and the expected image OR the student's figure and
            %       the expected figure. If no input arguments are specified, it will output embedded html data of the
            %       currently open figure window.
            %   
            %   Output Arguments
            %       H - Embedded html data of the figure comparison using base64. If no output arguments are specified,
            %       it will display the comparison as a figure.
            %
            %   See also checkImages, checkPlots

            if nargout == 0
                if nargin < 2
                    error('You must have at least 1 output or two inputs.');
                else
                    % Extract relevant data
                    if isa(varargin{1}, 'matlab.ui.Figure')
                        user = getframe(varargin{1}).cdata;
                        expected = getframe(varargin{2}).cdata;
                        type = 'Plot';
                    elseif exist(varargin{1}, 'file')
                        user = imread(varargin{1});
                        expected = imread(varargin{2});
                        type = 'Image';
                    else
                        error('The inputs must either be figures or image files.');
                    end
                    % Plots
                    close all;
                    subplot(1, 2, 1);
                    imshow(user);
                    if nargin == 3
                        title(sprintf('Student %s', type), 'FontSize', 8);
                    else
                        title(sprintf('Student %s', type));
                    end
                    subplot(1, 2, 2);
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
                % Open figure comparsion, then save the figure data using base64
                if nargin == 2
                    TesterHelper.compareImg(varargin{:}); % Recursive call to display figures
                end
                set(gcf, 'Position', [100, 100, 600, 200]); % Size of output image
                saveas(gcf, 'figure.jpg');
                fid = fopen('figure.jpg','rb');
                bytes = fread(fid);
                fclose(fid);
                delete('figure.jpg');
                close;
                encoder = org.apache.commons.codec.binary.Base64; % base64 encoder
                base64string = char(encoder.encode(bytes))';
                varargout{1} = sprintf('<img src=''data:image/png;base64,%s'' width = ''900'' height = ''300''> \n<em>Please use Matlab to view your figure in higher quality.</em>', base64string);
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
                calls = [calls getCalls([fld filesep localCalls{l} '.m'])]; %#ok<AGROW>
            end
        
            % Add operations
            OPS = cellfun(@upper, iskeyword, 'UniformOutput', false);
            calls = [calls reshape(string(info.mtfind('Kind', OPS).kinds), 1, [])];
            calls = unique(calls);
        end

        function out = generateString(options)

            % GENERATESTRING - Generate a random string of characters.
            %   This function generates a random string of characters based on the input options. By
            %   default, it generates a string of length 5 <= L <= 20, with uppercase characters,
            %   and no special characters, numbers, or spaces. The generator works by pulling from a
            %   pool of valid characters, with each character getting equal probability (space being
            %   an exception).
            %
            %   Syntax
            %       C = generateString()
            %       C = generateString(NAME=VALUE)
            %
            %   Name-Value Arguments
            %       maxLength (double) - Maximum length of the output. Default = 20.
            %       minLength (double) - Minimum length of the output. Default = 5.
            %       length (double) - Specify specific length of output.
            %       maxHeight (double) - Maximum height (number of rows) of the output. Default = 1.
            %       height (double) - Specify specific height (number of rows) of output.
            %       uppercase (logical) - Add uppercase letters to output. Default = false.
            %       special (logical/char) - Add certain special characters to output. If only certain special characters 
            %                                are desired, input them as a char vector. Default = false.
            %       numbers (logical) - Add digits 0-9 to output. Default = false.
            %       sentence (logical) - Adds spaces at a frequency to replicate sentence structure. Default = false.  

            arguments
                options.maxLength (1, 1) double = 20
                options.minLength (1, 1) double = 5
                options.length (1, 1) double
                options.maxHeight (1, 1) double = 1
                options.height (1, 1) double
                options.uppercase (1, 1) logical = false
                options.special (1, 1) = false
                options.numbers (1, 1) logical = false
                options.sentence (1, 1) logical = false
            end

            % Define character pool
            pool = 'abcdefghijklmnopqrstuvwxyz';
            if options.uppercase
                pool = [pool 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'];
            end
            if ~islogical(options.special)
                pool = [pool options.special];
            elseif options.special
                pool = [pool '!#$%&()*+-./:;<=>?@'];
            end
            if options.numbers
                pool = [pool '0123456789'];
            end

            % Define size
            if isfield(options, 'length')
                c = options.length;
            else
                c = randi([options.minLength, options.maxLength]);
            end
            if isfield(options, 'height')
                r = options.height;
            else
                r = randi([1, options.maxHeight]);
            end
            out = char(zeros([r, c]));

            % Fill array
            prob = 0;
            for i = 1:numel(out)
                if options.sentence
                    r = rand();
                    if r < prob
                        out(i) = ' ';
                        prob = 0;
                    else
                        out(i) = pool(randi(numel(pool)));
                        prob = prob + 0.05;
                    end
                else
                    out(i) = pool(randi(numel(pool)));
                end
            end
            
            % Remove ending space if needed
            if r == 1 && out(end) == ' '
                out(end) = [];
                if length(out) < options.minLength
                    out(end+1) = pool(randi(numel(pool)));
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
            %           line width in that order.
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
                    key = num2cell([line.XData', line.YData'], 2);
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
                    key = [line.XData(1:end-1)', line.YData(1:end-1)', line.XData(2:end)', line.YData(2:end)'];
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
            %       C - The output character vector representing A.
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

            if isempty(in)
                out = '[]';
            elseif isstruct(in) && ~options.interactive
                try
                    out = struct2table(in);
                catch
                    out = in;
                end
                out = char(formattedDisplayText(out, 'UseTrueFalseForLogical', true, 'LineSpacing', 'compact', 'SuppressMarkup',true));
            elseif ischar(in) || isstring(in)
                % Convert string into char
                if isstring(in)
                    in = char(in);
                end
                [r, ~] = size(in);
                % Interactive inputs
                if r == 1 && options.interactive && exist(in, 'file')
                    if contains(in, '.png') || contains(in, '.jpg') || contains(in, '.jpeg')
                        out = sprintf('<a href="matlab: cd(''%s'');clf;imgDisp=imread(''%s'');imshow(imgDisp);clear imgDisp;shg">%s</a>', pwd, in, in);
                    else
                        out = sprintf('<a href="matlab: cd(''%s'');open(''%s'')">%s</a>', pwd, in, in);
                    end
                elseif r == 1 && contains(in, '.txt') && exist(in, 'file')
                    out = char(strjoin(readlines(in), '\n'));
                else
                    % Default char and string conversion
                    in = [repmat('''', r, 1) in repmat('''', r, 1)];
                    out = char(formattedDisplayText(in, 'UseTrueFalseForLogical', true, 'LineSpacing', 'compact', 'SuppressMarkup', true));
                end
            elseif isnumeric(in)
                [r, c] = size(in);
                if r == 1
                    if c == 1
                        % Single number
                        out = num2str(in, 12);
                    else
                        % Numeric vector
                        out = join(string(in), ', ');
                        out = ['[' char(out) ']'];
                    end
                else
                    % Numeric array
                    out = char(formattedDisplayText(in, 'UseTrueFalseForLogical', true, 'LineSpacing', 'compact', 'SuppressMarkup', true));
                    loc = find(isstrprop(out, 'alphanum'), true);
                    out(loc - 1) = '[';
                    out = [out(1:end-1) ']' out(end)];
                end
            elseif islogical(in)
                [~, c] = size(in);
                out = char(formattedDisplayText(in, 'UseTrueFalseForLogical', true, 'LineSpacing', 'compact', 'SuppressMarkup', true));
                out(out == ' ') = [];
                if c > 1
                    % Logical vectors and arrays
                    out = replace(out, 'true', ', true');
                    out = replace(out, 'false', ', false');
                    out = replace(out, [newline ', '], [newline ' ']);
                    out = ['[' out(3:end-1) ']'];
                end
            else
                out = char(formattedDisplayText(in, 'UseTrueFalseForLogical', true, 'LineSpacing', 'compact', 'SuppressMarkup', true));
            end

            if out(end) == newline
                out(end) = [];
            end
            if options.cap
                new = strfind(out, newline);
                if numel(new) > 20
                    out = out(1:new(20));
                    out = [out '<strong>Additional rows have been suppressed.</strong>'];
                end 
            end
            if options.html
                out = ['   ' out];
                out(out == '"') = '''';
                out = strrep(out, newline, '\n       ');
            end
        end
    end
end
