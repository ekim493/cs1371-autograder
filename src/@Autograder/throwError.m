function throwError(obj, msg)
% THROWERROR - Throws an autograder related error.
%   If an error is thrown and IsGradescope is set to true, it will print the error message to the results.json. If an
%   error is thrown and IsGradescope is false, it will simply rethrow the error.

if obj.IsGradescope
    report = ['The autograder ran into an unexpected error while running your function. ' ...
        'Please contact the TAs for assistance and provide them with the following information:\n' char(msg)];
    json = struct('score', 0, 'output', report);
    json = jsonencode(json, PrettyPrint=true);
    fh = fopen('results.json', 'w');
    fprintf(fh, json);
    fclose(fh);
else
    error(msg);
end
end
