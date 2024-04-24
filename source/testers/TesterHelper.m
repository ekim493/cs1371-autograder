classdef TesterHelper
    methods (Static)
        %
        % toChar converts the input into a character
        % Inputs:
        %   in (any type) - The input to convert to a string
        %   varargin - Specifies formatting for outputs
        %       's' - simplified output (either hyperlink or condensed display for vectors)
        %       'sorted' - sorts the field names for display if structure
        %       
        % Outputs:
        %   out (char) - Character representation of the input
        %
        function out = toChar(in, varargin)
            if isstruct(in)
                if any(strcmpi(varargin, 's'))
                    out = sprintf('<a href="matlab: cd(''%s'');open(''%s'')">%s</a>', pwd, inputname(1), inputname(1));
                else
                    out = struct2table(in);
                    if any(strcmpi(varargin, 'sorted'))
                        out = struct2table(in);
                        [~, ind] = sort(out.Properties.VariableNames);
                        out = out(:, ind);
                    end
                    out = char(formattedDisplayText(out, 'UseTrueFalseForLogical', true, 'LineSpacing', 'compact'));
                end
            elseif istable(in) || iscell(in)
                if any(strcmpi(varargin, 's'))
                    out = sprintf('<a href="matlab: cd(''%s'');open(''%s'')">%s</a>', pwd, inputname(1), inputname(1));
                else
                out = char(formattedDisplayText(in, 'UseTrueFalseForLogical', true, 'LineSpacing', 'compact'));
                end
            elseif islogical(in)
                if in
                    out = 'true';
                else
                    out = 'false';
                end
            elseif ischar(in)
                if contains(in, '.png') || contains(in, '.jpg') || contains(in, '.jpeg')
                    out = sprintf('<a href="matlab: cd(''%s'');clf;imgDisp=imread(''%s'');imshow(imgDisp);clear imgDisp;shg">%s</a>', pwd, in, in);
                elseif contains(in, '.txt')
                    if any(strcmpi(varargin, 's'))
                        out = sprintf('<a href="matlab: cd(''%s'');open(''%s'')">%s</a>', pwd, in, in);
                    else
                        out = char(strjoin(readlines(in), '\n'));
                    end
                else
                    [r, ~] = size(in);
                    in = [repmat('''', r, 1) in repmat('''', r, 1)];
                    out = char(formattedDisplayText(in));
                end
            elseif ismatrix(in)
                if any(strcmpi(varargin, 's'))
                    [~, c] = size(in);
                    out = join(string(in), ', ');
                    if c > 1
                        out = char(join(out, '\n '));
                    else
                        out = char(out);
                    end
                    out = ['[' out ']'];
                else
                    out = char(formattedDisplayText(in));
                    loc = find(isstrprop(out, 'digit'), true);
                    out(loc - 1) = '[';
                    out = [out(1:end-1) ']' out(end)];
                end
            else
                out = char(formattedDisplayText(in, 'UseTrueFalseForLogical', true, 'LineSpacing', 'compact'));
            end
        end

        %
        % checkImg checks the input image against the solution and outputs correctness and an error message
        % Inputs:
        %   If 1 input, calls the function again with the solution image
        %   If 2 inputs, compares the images within a specific tolerance
        % Output:
        %   If 0 outputs, it displays a figure comparison of the two input images
        %   If 2 outputs, 
        %       The first output is a (logical) signifying correctness
        %       The second output is a sentence with the error. Will say: image does not
        %       exist, is the wrong size, or that the images do not match with a clickable hyperlink
        %       to call this function again with 0 outputs. If the figures matched, it will return
        %       [].
        %
        function varargout = checkImg(varargin)
            if (nargin == 1)
                user = varargin{1};
                [file, ext] = strtok(varargin{1}, '.');
                expected = [file '_soln' ext];
                [varargout{1}, varargout{2}] = TesterHelper.checkImg(user, expected);
                return;
            end
            user_fn = varargin{1};
            expected_fn = varargin{2};
            if (~exist(user_fn, 'file') || ~exist(expected_fn, 'file')) 
                varargout{1} = false;
                varargout{2} = 'The image(s) do not exist or are in a different directory.';
                return;
            end
            user = imread(user_fn);
            expected = imread(expected_fn);
            if (nargout == 0)
                clf;
                subplot(1, 2, 1);
                imshow(user);
                title('Actual Image');
                subplot(1, 2, 2);
                imshow(expected);
                title('Expected Image');
                shg;
                return;
            else
                tolerance = 25;
                [rUser,cUser,lUser] = size(user);
                [rExp,cExp,lExp] = size(expected);
                if rUser == rExp && cUser == cExp && lUser == lExp
                    diff = abs(double(user) - double(expected));
                    isDiff = any(diff(:)>tolerance);
                    if isDiff
                        varargout{1} = false;
                        varargout{2} = sprintf('The image output does not match the expected value.\n<a href="matlab: cd(''%s'');TesterHelper.checkImg(''%s'', ''%s'')">Image comparison</a>', pwd, user_fn, expected_fn);
                    else
                        varargout{1} = true;
                        varargout{2} = [];
                    end
                else
                    varargout{1} = false;
                    varargout{2} = sprintf('The dimensions of the image do not match the expected image output.\nActual size: %dx%dx%d, Expected size: %dx%dx%d\n<a href="matlab:TesterHelper.checkImg(''%s'', ''%s'')">Image comparison</a>', rUser, cUser, lUser, rExp, cExp, lExp, user_fn, expected_fn);
                end
            end
        end

        %
        % testDir Tests if the relevant functions are in the current directory
        % Throws an error if not
        %
        function testDir(func, varargin)
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

        % Header for inputs (diagnostics)
        function out = inputs
            out = sprintf('<strong>Inputs</strong>\n%s\n', repelem('-', 6));
        end

        % Header for outputs (diagnostics)
        function out = outputs
            out = sprintf('\n%s\n<strong>Outputs</strong>\n%s\n', repelem('-', 7), repelem('-', 7));
        end
    end
end
