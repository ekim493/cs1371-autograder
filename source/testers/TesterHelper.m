classdef TesterHelper
    % TESTERHELPER  This class includes methods to help grade and check HW functions. See documentation 
    % for a full list of functions and descriptions.

    methods (Static)
        function out = toChar(in, varargin)

            % TOCHAR    Convert the input into a character.
            %
            % C = toChar(A) takes in any input type and converts it into a string of characters.
            % By default:
            %   - Structures are converted to tables so all fields and values can be displayed.
            %   - If the input is a string that ends with '.txt' and a corresponding txt file exists,
            %   the contents of the file will be output.
            %   - Numeric and logical vectors have a '[' and ']' to indicate the beginning and end.
            %
            % C = toChar(A, FLAG) modifies the output string based on the FLAG.
            %
            %   FLAG can be:
            %       'i' - Interactive output. If the input is a complex data type (not a char,
            %       numeric, or logical) and exists as a variable, it instead outputs a clickable
            %       hyperlink to open that variable in Matlab. Alternatively, if the input is a
            %       string that indicates an existing file, it will also output a hyperlink to open
            %       that file in Matlab. Files with image extensions '.png', '.jpg', and '.jpeg'
            %       will display as a figure in Matlab if the hyperlink is clicked.
            %       'c' - Compact display. Displays numeric and logical vectors in a more condensed
            %       format.
            %       'h' - html output. Reformats the output to be purely in html format.
            %       's' - Sort fields. Sorts the fields if the input is a structure.

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
                    [~, c] = size(out);
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
            if any(strcmpi(varargin, 'h'))
                out(out == '"') = '''';
                out = strrep(out, newline, '\n');
            end
        end

        function [hasPassed, msg] = checkPlots(varargin)
            
            % CHECKPLOTS    Check and compare a plot against the solution's.
            %
            % [tf, msg] = checkPlots() will read in the currently open figures and output true if
            % the figures match up, and false if they don't. If tf is false, msg will contain a
            % string with more details on why the test failed. Otherwise, msg will be empty.
            %
            % [tf, msg] = checkPlots('html') will also include the figure comparison as embedded
            % html data in msg if tf is false.
            %
            % For checkPlots to work, at least 2 figures must be opened. This function only checks
            % the first 4 figures, so ensure 'close all' was called before the plots were created.
            % Ensure the student plot is created first, followed by the solution plot. The solution
            % plot must not override the student's, so 'figure' must be called.
            %
            % Example:
            %   close all;
            %   studentFunc();
            %   figure;
            %   solutionFunc();
            %   [tf, msg] = checkPlots();
            %
            % checkPlots does not current support or check the following:
            %   - Annotations, UI elements, colorbars, or other graphic elements
            %   - Plots generated with functions other than plot() (such as scatter())
            %   - 3D plots, or any plots with a z axis
            %   - Text styles or font size
            %   - Box styling, tick marks, tick labels, and similar 
            %   - Similar plots with a margin of error

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

            %% Plot check
            sAxes = findobj(sFig, 'Type', 'axes');
            cAxes = findobj(cFig, 'Type', 'axes');
            sNotAxes = findobj(sFig.Children, 'flat', '-not', 'Type', 'axes', '-not', 'Type', 'Legend');
            cNotAxes = findobj(cFig.Children, 'flat', '-not', 'Type', 'axes', '-not', 'Type', 'Legend');
            if numel(cNotAxes) > 0
                warning('Only axes and legends are checked. Annotations, UI elements, and other elements aren''t checked.');
            elseif numel(sNotAxes) ~= numel(cNotAxes)
                msg = 'Your plot contains extraneous elements. Ensure you don''t have additional UI elements, annotations, or similar.';
                hasPassed = false;
                return
            end
            if isempty(cAxes)
                error('The solution produced no plot.');
            end
            if isempty(sAxes)
                msg = 'Your plot is empty.';
                hasPassed = false;
                return
            end

            %% Number of subplot check
            if numel(sAxes) ~= numel(cAxes)
                msg = sprintf('Expected %d subplot(s), but your solution produced %d subplot(s).', numel(cAxes), numel(sAxes));
                hasPassed = false;
                return
            end

            %% Subplot grid check               
            sAxesPos = {sAxes.Position}';
            cAxesPos = {cAxes.Position}';
            % We use strings to represent subplot locations. Sort them to ensure plotting out of
            % order still works.
            [sAxesPos, sInd] = sort(join([string(cellfun(@(pos) pos(1), sAxesPos)), string(cellfun(@(pos) pos(2), sAxesPos))], ','));
            [cAxesPos, cInd] = sort(join([string(cellfun(@(pos) pos(1), cAxesPos)), string(cellfun(@(pos) pos(2), cAxesPos))], ',')); 
            if any(sAxesPos ~= cAxesPos)
                msg = 'The subplot positions do not match.';
                hasPassed = false;
                return
            end
            
            %% Data check              
            sAxes = sAxes(sInd);
            cAxes = cAxes(cInd);
            % Loop through every subplot
            for i = 1:numel(cAxes)
                if numel(findobj([cAxes(i).Children], '-not', 'Type', 'Line')) > 0
                    warning('Plots created with functions other than plot() will not be checked.');
                end
                sAxesPlots = findobj(sAxes(i), 'Type', 'Line');
                cAxesPlots = findobj(cAxes(i), 'Type', 'Line');
                sMap = TesterHelper.mapPlot(sAxesPlots);
                cMap = TesterHelper.mapPlot(cAxesPlots);   
                if ~isequal(sMap, cMap)
                    msg = 'Incorrect data in plot(s)';
                end
            end
            

            %% Other checks
            for i = 1:numel(cAxes)
                if ~isequal(sAxes(i).XLabel.String, cAxes(i).XLabel.String)
                    msg = sprintf('%s\\nIncorrect x-label', msg);
                end
                if ~isequal(sAxes(i).YLabel.String, cAxes(i).YLabel.String)
                    msg = sprintf('%s\\nIncorrect y-label', msg);
                end
                if ~isequal(sAxes(i).Title.String, cAxes(i).Title.String)
                    msg = sprintf('%s\\nIncorrect title', msg);
                end
                if ~isequal(sAxes(i).XLim, cAxes(i).XLim)
                    msg = sprintf('%s\\nIncorrect x limits', msg);
                end
                if ~isequal(sAxes(i).YLim, cAxes(i).YLim)
                    msg = sprintf('%s\\nIncorrect y-label', msg);
                end
                if ~isempty(cAxes(i).Legend)
                    if isempty(sAxes(i).Legend)
                        msg = sprintf('%s\\nMissing legend(s)', msg);
                    end
                    if ~isequal(sAxes(i).Legend.String, cAxes(i).Legend.String)
                        msg = sprintf('%s\\nIncorrect legend text', msg);
                    end
                    if ~isequal(sAxes(i).Legend.Location, cAxes(i).Legend.Location)
                        msg = sprintf('%s\\nIncorrect legend location', msg);
                    end
                end

                if ~isempty(msg)
                    break
                end              
            end

            %% Output
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
                end
            else
                hasPassed = true;
            end
        end

        function map = mapPlot(lines)

            % MAPPLOT   Create a dictionary defining all points and line segments.
            %
            % M = mapPlot(L) will taken in an array of Line objects and output a dictionary with all
            % points and line segments in the array.
            %
            % M's keys will be a 1x1 cell array containing a numeric vector. For points, this vector
            % will be [x-coord, y-coord]. For line segments, this vector will be [x-coord1,
            % y-coord1, x-coord2, y-coord2].
            %
            % M's values will be a 1xN cell array. For points, N will be 4 and will store the marker
            % style, marker size, edge color, and face color in that order. For line segments, N
            % will be 3 and will store line color, line style, and line width in that order.

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
                    key = num2cell([line.XData(1:end-1)', line.YData(1:end-1)', line.XData(2:end)', line.YData(2:end)'], 2);
                    data = {{line.Color, line.LineStyle, line.LineWidth}};
                    map = insert(map, key, data);
                end
            end
        end

        function varargout = checkImages(varargin)

            % CHECKIMAGES  Check and compare an image against the solution's image.
            %
            % tf = checkImages(F) will read in the image with file name F and compare it to its
            % corresponding image solution, which is the file name with '_soln' attached. It will
            % return true if the images match and false otherwise.
            %
            % tf = checkImages(USER, EXPECTED) will read in two images and compare them, where USER is
            % the file name of the user generated image and EXPECTED is the file name of the
            % expected image.
            %
            % checkImages(...) will display a figure comparison of the two images.
            %
            % [tf, msg] = checkImages(...) also returns a message with a clickable hyperlink which will
            % call this function without any outputs (display the comparison figure). 
            % msg will be empty if tf is true.
            %
            % [tf, html] = checkImages(..., 'html') returns the figure comparison as embedded html data.

            if any(contains(varargin, 'html'))
                html = true;
            else
                html = false;
            end
            varargin(contains(varargin, 'html')) = [];

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
            end
        end

        function varargout = compareImg(varargin)

            % COMPAREIMG    Compare two images or figures.
            %
            % compareImg(USER, EXPECTED) will read in two figures or two image filenames and display
            % a figure comparsion.
            %
            % H = compareImg(USER, EXPECTED) will output the figure comparsion as embedded html
            % data, H, using base64.
            %
            % H = compareImg() will output embedded html data of the currently open figure window.

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

        function [hasPassed, msg] = checkCalls(funcFile, varargin)

            % CHECKCALLS    Check a function file's calls.
            %
            % tf = checkCalls(F) will read in the name of the .m function file, F, as a
            % string. It will return true if no banned functions or operations as specified in the
            % 'Banned_Functions.json' file are present and false otherwise.
            %
            % [tf, msg] = checkCalls(F) also returns a message indicating why this test failed.
            %
            % [tf, msg] = checkCalls(F, FLAG, LIST, ...) adds additional requirements to the function file.
            %
            %   FLAG can be: 
            %       'banned' - Add additional banned functions
            %       'include' - Add functions that must be included
            %
            %   LIST is a list of functions corresponding to the flag before it. If there are
            %   multiple, it must be in a cell array. All operations must be in ALL CAPS.
            % 
            % Example:
            %   [tf, msg] = TesterHelper.checkCalls('myFunc.m', 'banned', {'max', 'min'}, 'include', 'WHILE')

            list = jsondecode(fileread('Banned_Functions.json'));
            banned = [list.BANNED; list.BANNED_OPS];
            msg = [];
            include = '';
            if nargin > 1
                if any(strcmpi(varargin, 'banned'))
                    banned = [banned varargin{find(strcmpi(varargin, 'banned')) + 1}];
                elseif any(strcmpi(varargin, 'include'))
                    include = varargin{find(strcmpi(varargin, 'include')) + 1};
                end
            end
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
        end

        function calls = getCalls(path)

            % GETCALLS  Return all built-in function calls and operations that a function used.
            %
            % C = getCalls(P) will read in the path P of a function file and output all functions it
            % calls and operations that it used as a cell array of characters, C.
            %
            % All operations such as while, for, switch, are indicated in ALL CAPS.
            %
            % This code runs on the mtree function which is not officially supported. Any helper functions
            % that the student calls will also be checked.
            %
            % This code was taken directly from the CS1371 organization repository.
            %
            % See also mtree

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

        function [isClosed, varargout] = checkFilesClosed()

            % CHECKFILESCLOSED  Check if all files have been properly closed.
            %
            % tf = checkFilesClosed() returns true if all files have been properly closed, and false
            % if there are files that are still open.
            %
            % [tf, msg] = checkFilesClosed() also returns a message indicating the number of files
            % still open.

            stillOpen = openedFiles();
            fclose all;
            if ~isempty(stillOpen)
                isClosed = false;
                varargout{1} = sprintf('%d file(s) still open!', length(stillOpen));
            else
                isClosed = true;
            end
        end


        function testDir(func, varargin)

            % TESTDIR   Test if the relevant functions are in the current directory. 
            % 
            % If the relevant file is not found, it throws an error with the first function or file 
            % it found that did not exist.
            % 
            % All inputs should be a string with the name of the function. Example: 'myFunc'
            % 
            % testDir(func) tests if the function func and its corrresponding solution, func_soln, 
            % is in the current directory.
            %
            % testDir(func, file1, file2, ...) tests if the function, its corresponding solution, 
            % and all listed files are in the current directory.

            if (~exist([func '_soln'], 'file'))
                error('hwTester:solnFunctionNotFound', 'The function %s''s solution code was not found.\nEnsure you are working in the correct directory and that the tester is placed in your HW folder.', func); 
            end
            if (~exist(func, 'file'))
                error('hwTester:userFunctionNotFound', 'The function %s does not exist or is in a different directory.\nCheck to make sure both the tester and the function are located in the same folder.', func)
            end
            for i = 1:length(varargin)
                if (~exist(varargin{i}, 'file'))
                    error('hwTester:fileNotFound', 'The file %s was not found.\nEnsure you are working in the correct directory and that the tester is placed in your HW folder.', varargin{i}); 
                end
            end
        end

        function out = inputs

            % INPUTS    Outputs a header than can be used to display diagnostics.
            %
            % Looks like the following:
            %
            % INPUTS
            % ------

            out = sprintf('<strong>Inputs</strong>\n%s\n', repelem('-', 6));
        end
        
        function out = outputs

            % OUTPUTS   Outputs a header than can be used to display diagnostics.
            %
            % Looks like the following:
            %
            % -------
            % OUTPUTS
            % -------

            out = sprintf('\n%s\n<strong>Outputs</strong>\n%s\n', repelem('-', 7), repelem('-', 7));
        end

    end
end
