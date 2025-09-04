function [hasPassed, msg] = checkCalls(obj, funcFile)
% CHECKCALLS - Check a function file's calls.
%   This function will check if the function in question calls or does not call certain functions or use
%   certain operations. A list of allowed functions and operations should be specified in a json file with the
%   name defined by Autograder.FunctionListName property. Disabled functions can also be specified, and if any of these
%   are present in the student's function, an error is thrown.
%   
%   Operations are defined the keywords that appear when the function iskeyword is called, and must be in all caps. 
%   You can add additional operations by in the FunctioNListName file. It will run the final result through the 
%   testCase object using verifyTrue. 
%   
%   The following object properties can be used to modify the list of calls this function checks:
%       BannedFuncs - List of additional banned functions.
%       IncludeFuncs - List of functions that must be included.
%       AllowedFuncs - List of functions that should bypass the ban restriction.
% 
%   Output Arguments
%       hasPassed - True if only valid functions used, false if not.
%       msg - Character message indicating why the test failed. Is empty if tf is true.

% Create full list of banned and allowed functions
list = jsondecode(fileread(Autograder.FunctionListName)); % Read from function list file.
allowed = [list.ALLOWED; list.ALLOWED_OPS; obj.AllowedFuncs'];
msg = [];
banned = obj.BannedFuncs';
include = obj.IncludeFuncs;
disabled = list.DISABLED;

calls = TestRunner.getCalls(which(funcFile), list.ADDITIONAL_OPS); % Get list of function calls

% Check if disabled function was used
if any(ismember(calls, disabled))
    error('HWStudent:disabledFunc', ['You used function(s) that were disabled. ' ...
        'Please remove them or contact the HW TAs if you believe this is an error.']);
end

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
            msg = sprintf('%s\n%s', msg, temp);
        end
    end
end

% Run verification
obj.TestCase.verifyTrue(hasPassed, msg);
end
