function calls = getCalls(path, additionalOPS)
% GETCALLS - Return all built-in function calls and operations that a function used.
%   This function will output all built-in functions and operations that a particular function called in a
%   cell array of characters. All operations (use iskeyword() for a list) are indicated in caps. Additional
%   keywords/operators can be defined using the Autograder.AdditionalOPS property. Intended as a helper function 
%   for checkCalls.
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
% This code was taken from the Georgia Tech CS1371 organization repository.
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
    calls = [calls TestRunner.getCalls([fld filesep localCalls{l} '.m'], additionalOPS)]; %#ok<AGROW>
end

% Add operations
if isrow(additionalOPS)
    additionalOPS = additionalOPS';
end
keywords = [iskeyword(); additionalOPS];
OPS = cellfun(@upper, keywords, 'UniformOutput', false);
calls = [calls reshape(string(info.mtfind('Kind', OPS).kinds), 1, [])];
calls = unique(calls);
end
