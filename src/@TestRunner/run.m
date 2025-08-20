function run(obj)
% RUN - Main Tester evaluation method.
%   This method will execute the runFunc method, propagate any errors, and evaluate check functions as
%   defined by the object's properties. The results of the check funtions will be executed directly on the
%   testCase object. 

if ~exist([obj.FunctionName, '.m'], 'file')
    error('HWStudent:noFunc', 'Undefined function or script ''%s''. Was this file submitted?', obj.FunctionName);
end

% See if the solution function is a script. If so, then save the caller's workspace variables into loadVars
% to pass in as arguments later. The try-catch with nargout is used as the solution file should be pcoded,
% and mtree and other methods to read the file will not work
try
    nargout(which(sprintf('%s_soln', obj.FunctionName)));
    loadVars = [];
catch
    loadVars = tempname;
    evalin('caller', sprintf('save(''%s'')', loadVars));
end

% Display input variables in command window for debugging
fprintf('\nTestcase: %s\n', obj.TestCaseName);
for i = 1:length(obj.Inputs)
    fprintf('\n%s =\n%s\n', obj.InputNames{i}, TestRunner.toChar(obj.Inputs{i}))
end

% Run functions
[outputs, solns, names, checks] = obj.runFunc(loadVars);

% Run relevant check functions
if obj.RunCheckCalls
    obj.checkCalls();
end
if obj.RunCheckAllEqual
    obj.checkAllEqual(outputs, solns, names);
end
if obj.RunCheckFilesClosed
    obj.TestCase.verifyTrue(checks.files{1}, checks.files{2});
end
if ~isempty(obj.RunCheckTextFiles)
    obj.checkTextFiles(obj.RunCheckTextFiles, checks.textFile);
end
if obj.RunCheckPlots
    obj.TestCase.verifyTrue(checks.plot{1}, checks.plot{2});
end
if ~isempty(obj.RunCheckImages)
    obj.checkImages(obj.RunCheckImages, checks.image);
end
end
