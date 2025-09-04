function [isClosed, msg] = checkFilesClosed(obj)
% CHECKFILESCLOSED - Check if all files have been properly closed.
%   This function will check to ensure that all files have been closed using fclose. If any files are still
%   open, it will close them. The final result will be run through the testCase verifyTrue function.
%
%   Output Arguments
%       isClosed - True if all files were properly closed, and false if not.
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
obj.TestCase.verifyTrue(isClosed, msg);
end
