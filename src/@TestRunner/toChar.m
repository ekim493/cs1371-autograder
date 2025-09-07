function out = toChar(in, opts)
% TOCHAR - Convert the input into a character.
%   This function takes in any input and converts it into a character vector.
%           - Structures are converted to tables so all fields and values can be displayed.
%           - If parse is true and the input is a string that ends with '.txt' and a corresponding txt file exists,
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
%       parse (logical) - Parse the output to make it html safe and add size/type. Default = true.
%       cap (double) - Number of rows to cap at. Set to -1 to uncap. Default = 20.
%       precision (double) - Number of digits to output for doubles. Default = 10.

arguments
    in
    opts.parse (1, 1) logical = true
    opts.cap (1, 1) double = 20
    opts.precision (1, 1) double = 10
end

[r, c, l] = size(in);
if isempty(in)
    out = '[]';
elseif l > 1
    % If there are more than 2 dimensions
    out = char(formattedDisplayText(in, 'UseTrueFalseForLogical', true, 'LineSpacing', 'compact', 'SuppressMarkup',true));
elseif isstruct(in)
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
elseif ischar(in) || isstring(in)
    % Convert string into char
    if isstring(in)
        out = char(in);
    else
        out = in;
    end
    % Read inputs
    if r == 1 && opts.parse && endsWith(in, '.txt') && exist(in, 'file')
        out = char(strjoin(readlines(in), newline));
        % If text file was empty, return file name instead
        if isempty(out)
            out = in;
        end
    else
        % Default char and string conversion
        out = [repmat('''', r, 1) out repmat('''', r, 1)];
        out = char(formattedDisplayText(out, 'UseTrueFalseForLogical', true, 'LineSpacing', 'compact', 'SuppressMarkup', true));
    end
elseif isnumeric(in)
    if r == 1
        if c == 1
            % Single number
            out = num2str(in, opts.precision);
        else
            % Numeric vector
            out = mat2str(in, opts.precision);
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
end

% Remove newline at the end
if out(end) == newline
    out(end) = [];
end
if opts.cap > 0
    new = strfind(out, newline);
    if numel(new) > opts.cap
        out = out(1:new(opts.cap));
        out = [out '<strong>Additional lines have been suppressed.</strong>'];
    end
end
% Parse string
if opts.parse
    % Add padding if its not there currently
    if ~startsWith(out, '   ')
        out = ['   ' out]; % Add to start
    end
    out = regexprep(out, '(\n)(?! {3})', '$1   '); % Add to lines
    % HTML parsing
    out = strrep(out, '\', '&#92;');
    out = strrep(out, '&', '&amp;');
    out = strrep(out, '<', '&lt;');
    out = strrep(out, '>', '&gt;');
    % Add header
    if l > 1
        pref = sprintf('(%dx%dx%d %s):', r, c, l, class(in));
    else
        pref = sprintf('(%dx%d %s):', r, c, class(in));
    end
    out = sprintf('%s\n%s', pref, out);
end
end
