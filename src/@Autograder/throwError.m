function throwError(obj, msg)
% THROWERROR - Throws an autograder related error.
%   If an error is thrown and IsGradescope is set to true, it will print the error message to the results.json. If an
%   error is thrown and IsGradescope is false, it will simply rethrow the error.
%   
%   Arguments
%       msg - Error message

if obj.IsGradescope
    report = ['The autograder ran into an unexpected error while running your function. ' ...
        'Please contact the TAs for assistance and provide them with the following information:' newline char(msg)];
    json = struct('score', 0, 'output', report);
    json = jsonencode(json, PrettyPrint=true);
    writelines(json, fullfile(pwd, 'results.json'));
    warning(report);
    quit(0); % Exit matlab with code 0 so it doesn't rerun
else
    error(msg);
end
end
