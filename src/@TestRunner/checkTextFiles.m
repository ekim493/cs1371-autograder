function [hasPassed, msg] = checkTextFiles(obj, userFile, solnFile)
% CHECKTEXTFILES - Check and compare a text file against the solution's.
%   This function will read in a text file and compare it to its corresponding solution file. The comparison
%   depends on the textRule property, where 'default' will ignore the extra newline character at the end of
%   either text file, 'strict' will not ignore the newline, and 'loose' will also ignore capitalization.
%   The final result is run through the testCase object using verifyTrue. The outputType property does affect
%   this function, and the full output includes a line by line comparison between the two text files, with
%   different lines highlighted.
%
%   Input Arguments
%       userFile, solnFile - Filename of the student's text file and the expected text file
%
%   Output Arguments
%       hasPassed - True if the text file comparison passed and false if not.
%       msg - Character message containing text file comparison. Is empty if hasPassed is true.

% Check for files
if ~exist(solnFile, 'file')
    error('TestRunner:noFile', 'The solution text file wasn''t found');
end
if ~exist(userFile, 'file')
    obj.TestCase.verifyTrue(false, ['Your solution did not produce a text file when one was expected. ' ...
        'Was it created properly with the right filename?'])
    return
end
student = readlines(userFile);
soln = readlines(solnFile);

% Compare using defined rules
if ~strcmpi(obj.TextRule, 'strict')
    if isempty(char(student(end)))
        student(end) = [];
    end
    if isempty(char(soln(end)))
        soln(end) = [];
    end
end
n_st = length(student);
n_sol = length(soln);
if strcmpi(obj.TextRule, 'loose')
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

% Output formatting. <mark> only works for html (use <strong> locally). Limit output display to 20 lines.
if strcmpi(obj.OutputType, 'none')
    msg = '';
elseif ~hasPassed && strcmpi(obj.OutputType, 'full')
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
end

obj.TestCase.verifyTrue(hasPassed, msg)
end
