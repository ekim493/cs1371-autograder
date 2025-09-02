function run(obj)
% RUN - Main Tester evaluation method.
%   This method will execute the student and solution functions, propagate any errors, and evaluate check functions as
%   defined by the object's properties. 

% Get paths to code based on namespace folders
studentPath = fullfile('+student', [obj.FunctionName, '.m']); % Student requires .m for mtree
solutionPath = fullfile('+solution', [obj.FunctionName]); % Only check existance of soln
studentFunction = sprintf('student.%s', obj.FunctionName);
solutionFunction = sprintf('solution.%s', obj.FunctionName);

% Return if there is no student or solution function
if ~exist(studentPath, 'file')
    error('HWStudent:noFunc', 'Undefined function or script ''%s''. Was this file submitted?', obj.FunctionName);
end
if ~exist(solutionPath, 'file')
    error('TestRunner:noSoln', 'The solution function was not included');
end

% See if the solution function is a script. If so, then save the caller's workspace variables into loadVars
% to pass in as arguments later. The try-catch with nargout is used as the solution file should be pcoded,
% and mtree and other methods to read the file will not work
try
    solutionNumOut = nargout(solutionFunction);
    solutionIsFunction = true;
catch
    solutionIsFunction = false;
end

% Check if student submitted the same kind of file
try
    studentIsFunction = isequal(mtree(studentPath, '-file').FileType, 'FunctionFile');
catch
    error('HWStudent:fileRead', 'There was an error reading your file. Please contact the HW TAs or double-check your submission.');
end
if solutionIsFunction && ~studentIsFunction
    error('HWStudent:notFunc', 'A function was expected, but you submitted a script instead.');
elseif ~solutionIsFunction && studentIsFunction
    error('HWStudent:notScript', 'A script was expected, but you submitted a function instead.');
end

% Display input variables in command window for debugging
fprintf('\nTestcase: %s\n', obj.TestCaseName);
for i = 1:length(obj.Inputs)
    fprintf('\n%s =\n%s\n', obj.InputNames{i}, TestRunner.toChar(obj.Inputs{i}, parse=false))
end

% Run solution code
close all; % Close any opened figures
if solutionIsFunction
    % Run as function. Use evalc to suppress function outputs
    try
        [~, solnValues{1:solutionNumOut}] = evalc(sprintf('%s(obj.SolnInputs{:})', solutionFunction));
    catch E
        error('TestRunner:solnError', 'The solution function threw an error: \n%s', getReport(E));
    end
else
    % Run solution script
    [solnNames, solnValues] = obj.runScript(solutionFunction);
    % See if CheckedVariables is specified and extract checked variables only
    if ~isempty(obj.CheckedVariables)
        isChecked = ismember(solnNames, obj.CheckVariables);
        if numel(solnNames) ~= numel(obj.CheckedVariables)
            warning('TestRunner:checkedMismatch', ...
                'There were specified checked variables that the solution script did not generate.');
        end
        solnNames = solnNames(isChecked);
        solnValues = solnValues(isChecked);
    end
end

% Check if image was created with the default name. If true, give the image a temporary filename instead. If
% false, assume the image was created with the '_soln' suffix.
if ~isempty(obj.RunCheckImages) && exist(obj.RunCheckImages, 'file')
    name = tempname;
    copyfile(obj.RunCheckImages, name);
    delete(obj.RunCheckImages);
    solnImage = name;
else
    [file, ext] = strtok(obj.RunCheckImages, '.');
    solnImage = [file, '_soln', ext];
end

% Check if text file was created with the default name. If true, give the file a temporary filename instead.
% If false, assume the file was created with the '_soln' suffix.
if ~isempty(obj.RunCheckTextFiles) && exist(obj.RunCheckTextFiles, 'file')
    name = tempname;
    copyfile(obj.RunCheckTextFiles, name);
    delete(obj.RunCheckTextFiles);
    solnTextFile = name;
else
    [file, ext] = strtok(obj.RunCheckTextFiles, '.');
    solnTextFile = [file, '_soln', ext];
end

% Run student code
if obj.RunCheckPlots
    figure;
end
if studentIsFunction
    if numel(obj.Inputs) ~= nargin(studentFunction)
        error('HWStudent:inputArgs', '%d input(s) to the function were expected, but your function had %d.', numel(obj.Inputs), nargin(obj.FunctionName));
    end

    % Run as function. Use evalc to suppress function outputs
    try
        [~, outputValues{1:nargout(studentFunction)}] = evalc(sprintf('%s(obj.Inputs{:})', studentFunction));
    catch exception
        % If an array size limit error was thrown with evalc, then the student function attempted to
        % output too much text to the command window (most likely unsuppressed imread or similar)
        if strcmp(exception.identifier, 'MATLAB:array:SizeLimitExceeded')
            error('HWStudent:exceedDiarySize', ['Matlab attempted to display %s characters to the command window and exceeded the allocated memory capacity (%s). ' ...
                'Ensure that you have suppressed your lines of code using semicolons.'], extractAfter(exception.arguments{1}, 'x'), exception.arguments{3});
        else
            fclose all; % Close files in case they were opened and function errored before fclose was reached
            rethrow(exception);
        end
    end

    % If outputNames was never initialized, then give each output the default name of 'output #'
    if isempty(obj.OutputNames)
        outputNames = arrayfun(@(x) ['output' num2str(x)], 1:numel(solnValues), 'UniformOutput', false);
    else
        outputNames = obj.OutputNames;
    end
else
    % Run as script.
    [outputNames, outputValues] = obj.runScript(studentFunction);
    varsNoExist = ~ismember(solnNames, outputNames);
    if any(varsNoExist)
        vars = strjoin(solnNames(varsNoExist), ', ');
        error('HWStudent:varNotAssigned', 'The following variables were not found: %s.', vars);
    end
end

% Run relevant check functions
if obj.RunCheckCalls
    obj.checkCalls(studentFunction);
end
if obj.RunCheckAllEqual
    obj.checkAllEqual(outputValues, solnValues, outputNames);
end
if obj.RunCheckFilesClosed
    obj.checkFilesClosed();
end
if ~isempty(obj.RunCheckTextFiles)
    obj.checkTextFiles(obj.RunCheckTextFiles, solnTextFile);
end
if obj.RunCheckPlots
    obj.checkPlots();
end
if ~isempty(obj.RunCheckImages)
    obj.checkImages(obj.RunCheckImages, solnImage);
end
end
