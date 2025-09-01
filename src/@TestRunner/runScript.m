function [newVars, varValues] = runScript(testRunnerObj, scriptNameToRun)
% RUNSCRIPT - Run a script with the input name.
%   This function runs a Matlab script and gathers the names of the variables created and their values.
%   Using longer function input names to avoid clashing with any script variables.

% Unpack variables
for i = 1:numel(testRunnerObj.SolnInputs)
    eval(sprintf('%s=testRunnerObj.SolnInputs{i};', testRunnerObj.InputNames{i}))
end
variablesBeforeScript = who;
[~] = evalc(scriptNameToRun); % Run, suppress output
variablesAfterScript = who;
newVars = setdiff(variablesAfterScript, variablesBeforeScript);
newVars(strcmp(newVars, 'variablesBeforeScript')) = []; % Remove storage variable
varValues = cell(1, numel(newVars));
for i = 1:numel(newVars)
    varValues(i) = {eval(newVars{i})};
end
end
