function [outputs, solns, names, checks] = runFunc(obj, loadVars)
% RUNFUNC - Helper function for RUN. Can be run in the background using parfeval.
%   This function run's the solution code (should be named FUNCNAME_soln), the student's code, checkPlots
%   (if desired), and checkFilesClosed (if desired).
%
%   Input Arguments
%       loadVars (char) - Path to a mat file containing variable data from main caller. This is only
%       necessary if the code being checked is a script with inputs given in the tester file. The run
%       function will create this automatically if the code being tested is a script.
%
%   Output Arguments
%       outputs - Cell array of all student outputs.
%       solns - Cell array of all solution outputs.
%       names - Cell array of names of output variables. This is either by the outputNames property for functions,
%               the variable name in the solution script (VARNAME_soln), or by default it will be 'output#'.
%       checks - Structure containing the results of the checkPlots and checkFilesClosed methods.

checks = struct();

% Run solution code
close all;
if ~exist(sprintf('%s_soln', obj.FunctionName), 'file')
    error('TestRunner:noSoln', 'The solution function wasn''t included');
end
if isempty(loadVars)
    % Run as function. Use evalc to suppress function outputs
    [~, solns{1:nargout(sprintf('%s_soln', obj.FunctionName))}] = evalc(sprintf('%s_soln(obj.SolnInputs{:})', obj.FunctionName));
else
    % Run as script. Load variables then evaluate
    load(loadVars); %#ok<LOAD>
    eval(sprintf('%s_soln', obj.FunctionName));
    vars = who;
    solnVars = vars(endsWith(vars, '_soln')); % Extract solutions var names
end

% Check if image was created with the default name. If true, give the image a temporary filename instead. If
% false, assume the image was created with the '_soln' extension.
if ~isempty(obj.RunCheckImages) && exist(obj.RunCheckImages, 'file')
    name = tempname;
    copyfile(obj.RunCheckImages, name);
    delete(obj.RunCheckImages);
    checks.image = name;
else
    [file, ext] = strtok(obj.RunCheckImages, '.');
    checks.image = [file, '_soln', ext];
end

% Check if text file was created with the default name. If true, give the file a temporary filename instead.
% If false, assume the file was created with the '_soln' extension.
if ~isempty(obj.RunCheckTextFiles) && exist(obj.RunCheckTextFiles, 'file')
    name = tempname;
    copyfile(obj.RunCheckTextFiles, name);
    delete(obj.RunCheckTextFiles);
    checks.textFile = name;
else
    [file, ext] = strtok(obj.RunCheckTextFiles, '.');
    checks.textFile = [file, '_soln', ext];
end

% Run student code
if obj.RunCheckPlots
    figure;
end
try
    isFunc_student = isequal(mtree(which(obj.FunctionName), '-file').FileType, 'FunctionFile');
catch
    error('HWStudent:fileRead', 'There was an error reading your file. Please contact the HW TAs or check the submission file.');
end
if isempty(loadVars) && ~isFunc_student
    error('HWStudent:notFunc', 'A function was expected, but you submitted a script instead.');
elseif ~isempty(loadVars) && isFunc_student
    error('HWStudent:notScript', 'A script was expected, but you submitted a function instead.');
else
    if isFunc_student
        if numel(obj.Inputs) ~= nargin(obj.FunctionName)
            error('HWStudent:inputArgs', '%d input(s) to the function were expected, but your function had %d.', numel(obj.Inputs), nargin(obj.FunctionName));
        end

        % Run as function. Use evalc to suppress function outputs
        try
            [~, outputs{1:nargout(obj.FunctionName)}] = evalc(sprintf('%s(obj.Inputs{:})', obj.FunctionName));
        catch exception
            % If an array size limit error was thrown with evalc, then the student function attempted to
            % output too much text to the command window (most likely unsuppressed imread or similar)
            if strcmp(exception.identifier, 'MATLAB:array:SizeLimitExceeded') && strcmp(exception.stack(1).name, 'TestRunner.runFunc')
                error('HWStudent:exceedDiarySize', ['Matlab attempted to display %s characters to the command window and exceeded the allocated memory capacity (%s). ' ...
                    'Ensure that you have suppressed your lines of code using semicolons.'], extractAfter(exception.arguments{1}, 'x'), exception.arguments{3});
            else
                fclose all;
                rethrow(exception);
            end
        end

        % If outputNames was never initialized, then give each output the default name of 'output #'
        if isempty(obj.OutputNames)
            names = arrayfun(@(x) ['output' num2str(x)], 1:numel(outputs), 'UniformOutput', false);
        else
            names = obj.OutputNames;
        end
    else
        % Run as script. Load variables then evaluate
        load(loadVars); %#ok<LOAD>
        eval(obj.FunctionName);
        % Collect relevant variables, using solnVars as the basis for which variables to find
        solns = cell(1, numel(solnVars));
        outputs = cell(1, numel(solnVars));
        names = cellfun(@(x) extractBefore(x, '_soln'), solnVars, 'UniformOutput', false);
        for i = 1:length(solnVars)
            try
                outputs(i) = {eval(names{i})};
            catch
                error('HWStudent:varNotAssigned', 'Variable ''%s'' (and possibly others) was not found', names{i});
            end
            solns(i) = {eval(solnVars{i})};
        end
    end
end

% Run relevant checks. These checks must be run in the background during the intial parfeval call.
if obj.RunCheckPlots
    [hasPassed, msg] = obj.checkPlots();
    checks.plot = {hasPassed, msg};
end
if obj.RunCheckFilesClosed
    [hasPassed, msg] = obj.checkFilesClosed();
    checks.files = {hasPassed, msg};
end
end
