function checkCalls(obj)
% CHECKCALLS - Check a function file's calls.
%   This function will check if the function in question calls or does not call certain functions or use
%   certain operations. A list of allowed functions and operations should be specified in a file with the
%   named defined by Autograder.FunctionListName. 
%   
%   Operations are defined the keywords that appear when the function iskeyword is called, and must be in all caps. 
%   You can add additional operations by setting the Autograder.AdditionalOPS property. It will run the final result 
%   through the testCase object using verifyTrue. 
%   
%   The following object properties can be used to modify the list of calls this function checks:
%       bannedFuncs - List of additional banned functions.
%       includeFuncs - List of functions that must be included.
%       allowedFuncs - List of functions that should bypass the ban restriction.

% Find name of function to test
funcFile = obj.FunctionName;

% Create full list of banned and allowed functions
list = jsondecode(fileread(Autograder.FunctionListName));
allowed = [list.ALLOWED; list.ALLOWED_OPS; obj.AllowedFuncs'];
msg = [];
banned = obj.BannedFuncs';
include = obj.IncludeFuncs;

calls = TestRunner.getCalls(which(funcFile)); % Get list of function calls

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
obj.TestCase.verifyTrue(hasPassed, msg);
end
