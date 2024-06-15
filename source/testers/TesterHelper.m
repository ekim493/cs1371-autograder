classdef TesterHelper
    % TESTERHELPER - This class includes methods to help grade and check HW functions. See documentation 
    %                for a full list of functions and descriptions.

    methods (Static)
        %% Check functions

        function checkAllEqual(varargin)

            % CHECKALLEQUAL - Check and compare all solution variables against the student's.
            %   This function compares all variables in the caller's workspace that ends with '_soln' against the
            %   variables that don't with Matlab's unittest verifyEqual function.
            %
            %   Syntax
            %       checkAllEqual()
            %       checkAllEqual(testCase)
            %       checkAllEqual(___, 'html')
            %
            %   Input Arguments
            %       testCase - TestCase object to run the verifyEqual function on. If unspecified, it looks for a
            %                  variable called 'testCase' in the caller's workspace.
            %       'html' - Outputs the diagnostic in html format.
            
            if nargin == 0 || ~isa(varargin{1}, 'matlab.unittest.TestCase')
                try
                    testCase = evalin('caller', 'testCase');
                catch
                    error('A testCase object must be input to the function or must exist in the caller''s workspace.');
                end
            else
                testCase = varargin{1};
            end
            vars = evalin('caller', 'who');
            solns = vars(endsWith(vars, '_soln'));
            for i = 1:length(solns)
                try
                    student = evalin('caller', vars{strcmp(vars, extractBefore(solns{i}, '_soln'))});
                catch
                    error('The variable %s (and possibly others) was not found', extractBefore(solns{i}, '_soln'));
                end
                soln = evalin('caller', solns{i});
                if any(strcmpi(varargin, 'html'))
                    testCase.verifyEqual(student, soln, ['Actual output:\n' TesterHelper.toChar(student, 'h') '\nExpected Output:\n' TesterHelper.toChar(soln, 'h')]);
                else
                    testCase.verifyEqual(student, soln, sprintf('Actual output:\n%s\nExpected Output:\n%s', TesterHelper.toChar(student), TesterHelper.toChar(soln)));
                end
            end
        end

        function [hasPassed, msg] = checkCalls(varargin, additional)

            % CHECKCALLS - Check a function file's calls.
            %   This function will check if the function in question calls or does not call certain functions or use
            %   certain operations. A list of banned functions and operations should be specified in a file called
            %   'Banned_Functions.json'. 
            %
            %   Syntax
            %       [tf, msg] = checkCalls(func)
            %       [tf, msg] = checkCalls(func, FLAG=LIST, ___)
            %       checkCalls(testCase, func, FLAG=LIST, ___)
            %       checkCalls(___)
            %
            %    Input Arguments
            %       func - Name of the function to test as a character vector. If unspecified, it retrieves the name of
            %              the caller function and uses the appropriate substring (assumes the caller function is named FUNCNAME_TEST#).
            %       FLAG - Specify either 'banned' or 'include' functions.
            %       LIST - List of functions corresponding to the flag before it. Must be a cell array of character
            %              vectors. Operations ('BANG', 'PARFOR', 'SPMD', 'GLOBAL', 'IF', 'SWITCH', 'FOR', 'WHILE') must
            %              be in caps.
            %       testCase - testCase object to run the verifyEqual function on. If unspecified and there are no
            %                  output arguments, it looks for a variable called 'testCase' in the caller's workspace.
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
                additional.banned cell={}
                additional.include cell={}
            end

            if nargin > 0 && ischar(varargin{end})
                funcFile = varargin{end};
            else
                try
                    stack = dbstack;
                    funcFile = char(extractBetween(stack(2).name, '.', '_Test'));
                catch
                    error('Error retrieving the name of the function being tested.');
                end
            end
            list = jsondecode(fileread('Banned_Functions.json'));
            banned = [list.BANNED; list.BANNED_OPS];
            msg = [];
            banned = [banned; additional.banned'];
            include = additional.include;

            calls = TesterHelper.getCalls(which(funcFile));
            
            bannedCalls = calls(ismember(calls, banned));
            includeCalls = cellstr(setdiff(include, calls));
            if isempty(bannedCalls) && isempty(includeCalls)
                hasPassed = true;
            else
                hasPassed = false;
                if ~isempty(bannedCalls)
                    msg = sprintf('The following banned functions were used: %s.', strjoin(bannedCalls, ', '));
                end
                if ~isempty(includeCalls)
                    temp = sprintf('The following functions must be included: %s.', strjoin(includeCalls, ', '));
                    if isempty(msg)
                        msg = temp;
                    else
                        msg = [msg '\n' temp];
                    end
                end
            end

            if nargin > 0 && isa(varargin{1}, 'matlab.unittest.TestCase')
                testCase = varargin{1};
                testCase.verifyTrue(hasPassed, msg);
            elseif nargout == 0
                try
                    testCase = evalin('caller', 'testCase');
                    testCase.verifyTrue(hasPassed, msg);
                catch
                    error('If no outputs are specified, a testCase object must be input to the function or be present in the caller''s workspace.');
                end
            end
        end

        function [isClosed, msg] = checkFilesClosed(varargin)

            % CHECKFILESCLOSED - Check if all files have been properly closed.
            %   This function will check to ensure that all files have been closed using fclose. If any files are still
            %   open, it will close them.
            %
            %   Syntax
            %       [tf, msg] = checkFilesClosed()
            %       checkFilesClosed(testCase)
            %       checkFilesClosed()
            %
            %   Input Arguments
            %       testCase - testCase object to run the verifyEqual function on. If unspecified and there are no
            %                  output arguments, it looks for a variable called 'testCase' in the caller's workspace.
            %
            %   Output Arguments
            %       tf - True if all files were properly closed, and false if not.
            %       msg - Character message indicating the number of files still left open. Is empty if tf is true.

            stillOpen = openedFiles();
            fclose all;
            if ~isempty(stillOpen)
                isClosed = false;
                msg = sprintf('%d file(s) still open!', length(stillOpen));
            else
                isClosed = true;
                msg = '';
            end
            if nargin > 0 && isa(varargin{1}, 'matlab.unittest.TestCase')
                testCase.verifyTrue(isClosed, msg);
            end
        end

        function varargout = checkImages(varargin)

            % CHECKIMAGES - Check and compare an image against the solution's.
            %   This function will read in an image filename and compare it to its corresponding image solution with a
            %   small tolerance. If no output arguments are specified, it instead displays a figure comparison of the
            %   two images.
            %
            %   Syntax
            %       [tf, msg] = checkImages(file)
            %       [tf, msg] = checkImages(user, expected)
            %       [tf, msg] = checkImages(___, 'html')
            %       checkImages(___)
            %       checkImages(testCase,___)      
            %       checkImages(___, 'html')
            %
            %   Input Arguments
            %       file - Filename of the student's image. This will compare it to the solution image, which is the
            %              filname with '_soln' attached.
            %       user, expected - Filename of the student's image and the expected image.
            %       testCase - testCase object to run the verifyEqual function on. If unspecified and there are no
            %                  output arguments, it looks for a variable called 'testCase' in the caller's workspace.
            %       'html' - Adds the figure comparison as embedded html data (base64) to the output msg variable. 
            %                If this argument is specified and there are no output arguments, it looks for a variable 
            %                called 'testCase' in the caller's workspace to run verifyEqual.
            %
            %   Output Arguments
            %       tf - True if the images matched, and false if not.
            %       msg - Character message indicating why the test failed, along with a hyperlink to display the
            %             figure comparison. Is empty if tf is true.

            if any(contains(varargin, 'html'))
                html = true;
            else
                html = false;
            end
            varargin(contains(varargin, 'html')) = [];

            if isa(varargin{1}, 'matlab.unittest.TestCase')
                testCase = varargin{1};
                varargin{1} = [];
            elseif nargout == 0 && html
                try
                    testCase = evalin('caller', 'testCase');
                catch
                    error('If html is specified and there are no output arguments, a testCase object must be input to the function or be present in the caller''s workspace.');
                end
            end

            if isscalar(varargin)
                user_fn = varargin{1};
                [file, ext] = strtok(varargin{1}, '.');
                expected_fn = [file '_soln' ext];
            else
                user_fn = varargin{1};
                expected_fn = varargin{2};
            end
            
            if (~exist(user_fn, 'file') || ~exist(expected_fn, 'file')) 
                varargout{1} = false;
                varargout{2} = 'The image(s) do not exist or are in a different directory.';
                return;
            end
            if (nargout == 0)
                TesterHelper.compareImg(user_fn, expected_fn);
                shg;
                return;
            else
                user = imread(user_fn);
                expected = imread(expected_fn);
                tolerance = 25;
                [rUser,cUser,lUser] = size(user);
                [rExp,cExp,lExp] = size(expected);
                if rUser == rExp && cUser == cExp && lUser == lExp
                    diff = abs(double(user) - double(expected));
                    isDiff = any(diff(:) > tolerance);
                    if isDiff
                        varargout{1} = false;
                        msg = 'The image output does not match the expected image.';
                    else
                        varargout{1} = true;
                        varargout{2} = [];
                        return;
                    end
                else
                    varargout{1} = false;
                    msg = sprintf('The dimensions of the image do not match the expected image.\nActual size: %dx%dx%d\nExpected size: %dx%dx%d', rUser, cUser, lUser, rExp, cExp, lExp);
                end

                if html
                    base64string = TesterHelper.compareImg(user_fn, expected_fn);
                    msg = strrep(msg, newline, '\n');
                    varargout{2} = sprintf('%s\\n%s', msg, base64string);
                else
                    varargout{2} = sprintf('%s\n<a href="matlab: cd(''%s'');TesterHelper.compareImg(''%s'', ''%s'')">Image comparison</a>', msg, pwd, user_fn, expected_fn);
                end

                if exist('testCase', 'var')
                    testCase.verifyTrue(varargout{1}, varargout{2});
                end
            end
        end

        function [hasPassed, msg] = checkPlots(varargin)
            
            % CHECKPLOTS - Check and compare a plot against the solution's.
            %   This function will read in the currently open figures and compare them. For the function to work, all
            %   figures must be closed and then at least 2 figures must be opened. The student plot should be created
            %   first, followed by the solution plot. The solution plot must not override the student's, so 'figure'
            %   must be called.
            %
            %   Syntax
            %       [tf, msg] = checkPlots()
            %       [tf, msg] = checkPlots('html')
            %       checkPlots(testCase, ___)
            %       checkPlots(___)
            %
            %   Input Arguments
            %       'html' - Add a figure comparison as embedded html data to the output msg if tf is false.
            %       testCase - testCase object to run the verifyEqual function on. If unspecified and there are no
            %                  output arguments, it looks for a variable called 'testCase' in the caller's workspace.
            %
            %   Output Arguments
            %       tf - True if the plots matched, false if not.
            %       msg - Character message indicating why the test failed. Is empty if tf is true.
            %
            %   Example
            %       close all;
            %       studentFunc();
            %       figure;
            %       solutionFunc();
            %       [tf, msg] = checkPlots();
            %
            %   checkPlots does not current support or check the following:
            %       - Annotations, tiled layout, UI elements, colorbars, or other graphic elements
            %       - Plots generated with functions other than plot (such as scatter)
            %       - 3D plots, or any plots with a z axis
            %       - Text styles or font size
            %       - Box styling, tick marks, tick labels, and similar
            %       - Similar plots with a margin of error

            if length(findobj('type', 'figure')) < 2
                error('There must be at least 2 figures displayed.');
            end
            
            % sFig - Student, cFig - Correct figure. Need to check next plot in case figure was
            % called in the function.
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
            % We use strings to represent subplot locations. Sort them to ensure plotting out of
            % order still works.
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
                    msg = 'Incorrect data or style in plot(s).';
                    % Check if any points are outside x and y bounds
                    xLim = sAxes(i).XLim;
                    yLim = sAxes(i).YLim;
                    for j = 1:numel(sMap)
                        if any([sAxesPlots(i).XData] > xLim(2)) || any([sAxesPlots(i).XData] < xLim(1))...
                            || any([sAxesPlots(i).YData] > yLim(2)) || any([sAxesPlots(i).YData] < yLim(1))
                            msg = sprintf('%s\\nThere seems to be data outside of the plot boundaries.', msg);
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
                if nargin > 0
                    if any(strcmpi(varargin, 'html'))
                        base64string = TesterHelper.compareImg(sFig, cFig);
                        msg = sprintf('%s\\n%s', msg, base64string);
                    end
                    if isa(varargin{1}, 'matlab.unittest.TestCase')
                        testCase = varargin{1};
                        testCase.verifyTrue(hasPassed, msg);
                    elseif nargout == 0
                        try
                            testCase = evalin('caller', 'testCase');
                            testCase.verifyTrue(hasPassed, msg);
                        catch
                            error('If there are no output arguments, a testCase object must be input to the function or be present in the caller''s workspace.');
                        end
                    end
                end
            else
                hasPassed = true;
            end
        end

        function [hasPassed, msg] = checkTxtFiles(varargin)

            % CHECKTXTFILES - Check and compare a text file against the solution's.
            %   This function will read in two text files and compare them. By default, it will ignore an extra newline
            %   at the end of any text file.
            %
            %   Syntax
            %       [tf, msg] = checkTxtFiles(file)
            %       [tf, msg] = checkTxtFiles(user, expected)
            %       [tf, msg] = checkTxtFiles(___, FLAG)
            %       checkTxtFiles(testCase,___)
            %       checkTxtFiles(___)
            %
            %   Input Arguments
            %       file - Filename of the student's text file. This will compare it to the solution file, which is the
            %              filname with '_soln' attached.
            %       user, expected - Filename of the student's text file and the expected text file.
            %       testCase - testCase object to run the verifyEqual function on. If unspecified and there are no
            %                  output arguments, it looks for a variable called 'testCase' in the caller's workspace.
            %       FLAG - Indicate additional arguments. It can be:
            %           'strict' - Don't ignore the newline at the end of a text file.
            %           'loose' - Ignore capitilization in the check.
            %           'limit' - Don't output the full text comparison in msg.
            %           'uncap' - Disable the 15 line per text file cap in msg.
            %
            %   Output Arguments
            %       tf - True if the text files matched, false if not.
            %       msg - Character message indicating why the test failed, along with a comparison of the two text
            %       files with the different lines bolded. Is empty if tf is true.

            if isa(varargin{1}, 'matlab.unittest.TestCase')
                testCase = varargin{1};
                varargin{1} = [];
            elseif nargout == 0
                try
                    testCase = evalin('caller', 'testCase');
                catch
                    error('If there are no output arguments, a testCase object must be input to the function or be present in the caller''s workspace.');
                end
            end
            
            if numel(varargin) > 1 && endsWith(varargin{2}, '.txt')
                student_fn = varargin{1};
                soln_fn = varargin{2};
            else
                student_fn = varargin{1};
                soln_fn = [student_fn(1:end-4) '_soln.txt'];
            end
            student = readlines(student_fn);
            soln = readlines(soln_fn);
            if ~any(strcmpi(varargin, 'strict'))
                if isempty(char(student(end)))
                    student(end) = [];
                end
                if isempty(char(soln(end)))
                    soln(end) = [];
                end
            end
            n_st = length(student);
            n_sol = length(soln);
                
            if any(strcmpi(varargin, 'loose'))
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

            if ~hasPassed && ~any(strcmpi(varargin, 'limit'))
                if n_st > 15 && ~any(strcmpi(varargin, 'uncap'))
                    student = [student(1:15); "Additional rows have been suppressed."];
                end
                if n_sol > 15 && ~any(strcmpi(varargin, 'uncap'))
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
            end

            if exist('testCase', 'var')
                msg(msg == '"') = '''';
                msg = strrep(msg, newline, '\n');
                testCase.verifyTrue(hasPassed, msg);
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
                    close all;
                    subplot(1, 2, 1);
                    imshow(user);
                    if nargin == 3
                        title(sprintf('Student %s', type), 'FontSize', 6);
                    else
                        title(sprintf('Student %s', type));
                    end
                    subplot(1, 2, 2);
                    imshow(expected);
                    if nargin == 3
                        title(sprintf('Solution %s', type), 'FontSize', 6);
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
                if nargin == 2
                    TesterHelper.compareImg(varargin{:}, 'html');
                end
                set(gcf, 'Position', [100, 100, 300, 100]);
                saveas(gcf, 'figure.png');
                fid = fopen('figure.png','rb');
                bytes = fread(fid);
                fclose(fid);
                delete('figure.png');
                close;
                encoder = org.apache.commons.codec.binary.Base64;
                base64string = char(encoder.encode(bytes))';
                varargout{1} = sprintf('<img src=''data:image/png;base64,%s'' />', base64string);
            end
        end

        function calls = getCalls(path)

            % GETCALLS - Return all built-in function calls and operations that a function used.
            %   This function will output all built-in functions and operations that a particular function called in a
            %   cell array of characters. All operations ('BANG', 'PARFOR', 'SPMD', 'GLOBAL', 'IF', 'SWITCH', 'FOR', 'WHILE')
            %   are indicated in caps. Intended as a helper function for checkCalls.
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
        
            % For any calls that exist in our current directory, recursively
            % collect their builtin calls
            localFuns = dir([fld filesep '*.m']);
            localFuns = {localFuns.name};
            localFuns = cellfun(@(s)(s(1:end-2)), localFuns, 'uni', false);
            localCalls = calls(ismember(calls, localFuns));
            calls(ismember(calls, localFuns)) = [];
            for l = 1:numel(localCalls)
                calls = [calls getCalls([fld filesep localCalls{l} '.m'])]; %#ok<AGROW>
            end
        
            % add any operations
            OPS = {'BANG', 'PARFOR', 'SPMD', 'GLOBAL', 'IF', 'SWITCH', 'FOR', 'WHILE'};
            calls = [calls reshape(string(info.mtfind('Kind', OPS).kinds), 1, [])];
            calls = unique(calls);
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

        function out = toChar(in, varargin)

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
            %       C = toChar(A, FLAG)
            %
            %   Arguments
            %       A - Any input that should be converted into a char.
            %       C - The output character vector representing A.
            %       FLAG - Indicate additional arguments. It can be:
            %           'i' - Interactive output. If the input is a complex data type (not a char,
            %                 numeric, or logical) and exists as a variable, it instead outputs a clickable
            %                 hyperlink to open that variable in Matlab. Alternatively, if the input is a
            %                 string that indicates an existing file, it will also output a hyperlink to open
            %                 that file in Matlab. Files with image extensions '.png', '.jpg', and '.jpeg'
            %                 will display as a figure in Matlab if the hyperlink is clicked.
            %           'c' - Compact display. Displays numeric and logical vectors in a more condensed
            %                 format.
            %           'h' - html output. Reformats the output to be purely in html format.
            %           's' - Sort fields. Sorts the fields if the input is a structure.
            %           'u' - Uncapped length. Ignores the 20 row limit.

            if isstruct(in) && ~any(strcmpi(varargin, 'i'))
                if any(strcmpi(varargin, 's'))
                    in = orderfields(in);
                end
                try
                    out = struct2table(in);
                catch
                    out = in;
                end
                out = char(formattedDisplayText(out, 'UseTrueFalseForLogical', true, 'LineSpacing', 'compact', 'SuppressMarkup',true));
            elseif ischar(in)
                [r, ~] = size(in);
                if r == 1 && any(strcmpi(varargin, 'i')) && exist(in, 'file')
                    if contains(in, '.png') || contains(in, '.jpg') || contains(in, '.jpeg')
                        out = sprintf('<a href="matlab: cd(''%s'');clf;imgDisp=imread(''%s'');imshow(imgDisp);clear imgDisp;shg">%s</a>', pwd, in, in);
                    else
                        out = sprintf('<a href="matlab: cd(''%s'');open(''%s'')">%s</a>', pwd, in, in);
                    end
                elseif r == 1 && contains(in, '.txt') && exist(in, 'file')
                    out = char(strjoin(readlines(in), '\n'));
                else
                    in = [repmat('''', r, 1) in repmat('''', r, 1)];
                    out = char(formattedDisplayText(in, 'UseTrueFalseForLogical', true, 'LineSpacing', 'compact', 'SuppressMarkup', true));
                end
            elseif isnumeric(in) || islogical(in)
                if any(strcmpi(varargin, 'c'))
                    [~, c] = size(in);
                    out = join(string(in), ', ');
                    if c > 1
                        out = sprintf(char(join(out, '\n ')));
                    else
                        out = char(out);
                    end
                    if c ~= 1
                        out = ['[' out ']'];
                    end
                else
                    out = char(formattedDisplayText(in, 'UseTrueFalseForLogical', true, 'LineSpacing', 'compact', 'SuppressMarkup', true));
                    loc = find(isstrprop(out, 'alphanum'), true);
                    [~, c] = size(in);
                    if c ~= 1
                        out(loc - 1) = '[';
                        out = [out(1:end-1) ']' out(end)];
                    end
                end
            else
                if any(strcmpi(varargin, 'i')) && ~isempty(inputname(1))
                    out = sprintf('<a href="matlab: cd(''%s'');open(''%s'')">%s</a>', pwd, inputname(1), inputname(1));
                else
                    out = char(formattedDisplayText(in, 'UseTrueFalseForLogical', true, 'LineSpacing', 'compact', 'SuppressMarkup', true));
                end
            end

            if out(end) == newline
                out(end) = [];
            end
            if ~any(strcmpi(varargin, 'u'))
                new = strfind(out, newline);
                if numel(new) > 20
                    out = out(1:new(20));
                    out = [out '<strong>Additional rows have been suppressed.</strong>'];
                end 
            end
            if any(strcmpi(varargin, 'h'))
                out(out == '"') = '''';
                out = strrep(out, newline, '\n');
            end
        end

    end
end
