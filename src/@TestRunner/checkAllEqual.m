function checkAllEqual(obj, outputs, solns, names)
% CHECKALLEQUAL - Check and compare all solution variables against the student's.
%   This function compares all data inside 'outputs' with the corresponding data in 'solns' by running it
%   through the verifyEqual function on the testCase object with an absolute tolerance defined by NumTolerance.
%   It will also output a message with a level of detail given by OutputType. 'compare' will output full
%   comparison information, 'variable' will only output which variables are incorrect, and 'none' will have no output text.
%
%   Input Arguments
%       outputs - Cell array of all student outputs.
%       solns - Cell array of all solution outputs.
%       names - Cell array of names of output variables.

if isempty(solns) && isempty(outputs)
    return
end

if numel(solns) ~= numel(outputs)
    obj.TestCase.verifyTrue(false, sprintf('%d output(s) were expected, but your function produced %d.', numel(solns), numel(outputs)));
    return
end

% Loop through variables and compare then
for i = 1:length(solns)
    soln = solns{i};
    student = outputs{i};

    % Determine output message based on outputType
    switch obj.OutputType
        case 'none'
            continue
        case 'variable'
            msg = sprintf('Variable ''%s'' does not match the solution''s.', names{i});
        case 'compare'
            msg = ['<u>', names{i}, '</u>\n', '    Actual output ' TestRunner.toChar(student) '\n    Expected output ' TestRunner.toChar(soln)];
        otherwise
            error('TestRunner:invalidType', 'The output type %s is not valid.', obj.OutputType);
    end

    % Verification call
    if isempty(soln)
        obj.TestCase.verifyEmpty(student, msg);
    else
        obj.TestCase.verifyEqual(student, soln, msg, "AbsTol", obj.NumTolerance);
    end
end
end
