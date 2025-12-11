function run(obj)
% RUN - Main Tester evaluation method.
%   This method will execute the student and solution functions, propagate any errors, and evaluate check functions as
%   defined by the object's properties. It supports running both scripts and functions.
%   
%   The student code should located in a folder called '+student' and the solution code should be located in a folder
%   called '+solution'. The Autograder class should do this automatically.
%
%   Errors caused by invalid setup are propagated with the 'TestRunner' identifier, and special errors caused by the
%   student are propagated with the 'HWStudent' identifier. Minor parsing is done with some error messages.
%
%   Images and text files created by the solution which are tested are moved to a temporary filename as defined by
%   the tempname function.

% Get paths to code based on namespace folders
studentPath = fullfile('+student', [obj.FunctionName, '.m']); % Student requires .m for mtree
solutionPath = fullfile('+solution', [obj.FunctionName]); % Only check existence of soln
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
    stuTree = mtree(studentPath, '-file');
    studentIsFunction = isequal(stuTree.FileType, 'FunctionFile');
catch
    error('HWStudent:fileRead', 'There was an error reading your file. Please contact the HW TAs or double-check your submission.');
end
if solutionIsFunction && ~studentIsFunction
    error('HWStudent:notFunc', 'A function was expected, but you submitted a script instead.');
elseif ~solutionIsFunction && studentIsFunction
    error('HWStudent:notScript', 'A script was expected, but you submitted a function instead.');
elseif ~solutionIsFunction && ~studentIsFunction
    % If both scripts, append any input variables
    obj.AllowedFuncs = [obj.AllowedFuncs; obj.InputNames];
end

% Check for invalid expression/syntax errors
errNodes = stuTree.mtfind('Kind', 'ERR');
if ~isempty(errNodes)
    try
        [~] = evalc(studentFunction);
    catch E
        error('HWStudent:syntaxError', E.message);
    end
elseif obj.RunCheckCalls
    % If not invalid, check calls for potentially disabled functions
    obj.checkCalls(studentFunction);
end

% Add failure message to diagnostics
if ~isempty(obj.FailureMessage)
    obj.TestCase.onFailure(sprintf('FailureMessage:<%s>', obj.FailureMessage))
end

% Create string of input variables and add to diagnostics
inputStr = '';
for i = 1:length(obj.Inputs)
    inputStr = sprintf('%s%s =\n%s\n', inputStr, obj.InputNames{i}, TestRunner.toChar(obj.Inputs{i}, parse=false));
end
obj.TestCase.onFailure(inputStr(1:end-1)); % Remove newline at end

% Run solution code
close all; % Close any opened figures
if solutionIsFunction
    % Run as function. Use evalc to suppress function outputs
    try
        [~, solnValues{1:solutionNumOut}] = evalc(sprintf('%s(obj.SolnInputs{:})', solutionFunction));
    catch E
        error('TestRunner:solnError', 'The solution function threw an error: \n%s', getReport(E, 'basic'));
    end
else
    % Run solution script
    try
        [solnNames, solnValues] = obj.runScript(solutionFunction);
    catch E
        error('TestRunner:solnError', 'The solution script threw an error: \n%s', getReport(E, 'basic'));
    end
    % See if CheckedVariables is specified and extract checked variables only
    if ~isempty(obj.CheckedVariables)
        isChecked = ismember(solnNames, obj.CheckedVariables);
        solnNames = solnNames(isChecked);
        solnValues = solnValues(isChecked);
        if ~all(ismember(obj.CheckedVariables, solnNames))
            warning('TestRunner:checkedMismatch', ...
                'There were specified checked variables that the solution script did not generate.');
        end
    end
end

% Check if image was created with the default name. If true, give the image a temporary filename instead. If
% false, assume the image was created with the '_soln' suffix.
if ~isempty(obj.RunCheckImages) && exist(obj.RunCheckImages, 'file')
    name = tempname;
    movefile(obj.RunCheckImages, name);
    solnImage = name;
else
    [file, ext] = strtok(obj.RunCheckImages, '.');
    solnImage = [file, '_soln', ext];
end

% Check if text file was created with the default name. If true, give the file a temporary filename instead.
% If false, assume the file was created with the '_soln' suffix.
if ~isempty(obj.RunCheckTextFiles) && exist(obj.RunCheckTextFiles, 'file')
    name = tempname;
    movefile(obj.RunCheckTextFiles, name);
    solnTextFile = name;
else
    [file, ext] = strtok(obj.RunCheckTextFiles, '.');
    solnTextFile = [file, '_soln', ext];
end

% Check if solution has files still opened
stillOpen = openedFiles();
if ~isempty(stillOpen)
    fclose all;
    warning('Solution function has files left open. Ensure they are all fclosed.')
end

% Run student code
if obj.RunCheckPlots
    figure;
end
if studentIsFunction
    try
        numStudentIn = nargin(studentFunction);
    catch E
        % Sometimes invalid functions will cuase nargin to error
        error('HWStudent:narginErr', E.message);
    end
    if numel(obj.Inputs) ~= numStudentIn
        error('HWStudent:inputArgs', '%d input(s) to the function were expected, but your function had %d.', numel(obj.Inputs), numStudentIn);
    end

    % Run as function. Use evalc to suppress function outputs
    try
        [~, outputValues{1:nargout(studentFunction)}] = evalc(sprintf('%s(obj.Inputs{:})', studentFunction));
    catch E
            fclose all; % Close files in case they were opened and function errored before fclose was reached
            rethrow(E);
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
    if obj.RunCheckAllEqual
        varsNoExist = ~ismember(solnNames, outputNames);
        if any(varsNoExist)
            vars = strjoin(solnNames(varsNoExist), ', ');
            error('HWStudent:varNotAssigned', 'The following variables were not found: %s.', vars);
        else
            % Extract only the variables we care about
            varsOfInterest = ismember(outputNames, solnNames);
            outputNames = outputNames(varsOfInterest);
            outputValues = outputValues(varsOfInterest);
        end
    end
end

% Run relevant check functions
if obj.RunCheckAllEqual
    obj.checkAllEqual(outputValues, solnValues, outputNames);
end
if obj.RunCheckFilesClosed
    obj.checkFilesClosed();
else
    fclose all; % Close all files to not interrupt next iteration
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
