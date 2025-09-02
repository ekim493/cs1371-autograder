function parseResults(obj)
% PARSERESULTS - Parses the results of a test run and creates the final results json file.
%   This function parses the output of runSuite, assigns each test case the proper number of points, and then creates
%   the final results.json file for Gradescope to use. 
%
%   The autograder relies on test tags to group problems. Each problem should be grouped and tagged with the problem
%   name/number and how points should be assigned. This should be 'N' (standard scoring), '+N' (bonus points), '-N'
%   (penalty scoring), 'xN' (multiplicative scoring), and '/N' (penalty multiplicative scoring). Multiplication is done
%   before any bonus points are added or subtracted. Anything other than standard scoring does not impact the maximum
%   score that the assignment is out of. Multiplication is compounding. The final score cannot be lower than 0.
%
%   The scores should be prefixed with how scores are distributed. Set a prefix of 'each=' for each part in the problem
%   to be assigned the listed number of points. Set a prefix of 'total=' for the sum of all the parts to be assigned the 
%   points listed.

% Sort results based on problem name
[~, ind] = sort(obj.Results.tags);
results = obj.Results(ind, :); % Will use local variable

% Get the score for each test case and the total
totalScore = 0;
extraPoints = 0;
multiplier = 1;
problemNames = unique(results.tags);
for i = 1:numel(problemNames)
    problem = problemNames{i};
    testCaseMask = strcmp(problem, results.tags);
    scoring = unique(results.scoring(testCaseMask));

    if numel(scoring) > 1
        obj.throwError('Each unique problem should only have one type of scoring assigned to it.')
    end

    % Extract scoring parts
    parts = regexp(scoring, '([a-zA-Z]+)=([+/\-x]?)(\d+\.?\d*)', 'tokens', 'once');
    if isempty(parts)
        obj.throwError('One of the problems had invalid scoring tag(s).')
    end
    type = parts{1};
    operator = parts{2};
    value = str2double(parts{3});
    if isnan(value)
        obj.throwError('Invalid point value in scoring tag.');
    end

    % Get properties of problem
    isEach = strcmpi(type, 'each');
    numParts = sum(testCaseMask);
    numPassed = sum(results.passed(testCaseMask));
    numFailed = sum(~results.passed(testCaseMask));
    allPassed = all(results.passed(testCaseMask));

    % Calculate points for the problem
    if isEach
        pointsPerPart = value;
    else
        pointsPerPart = value / numParts;
    end

    % Assign points
    switch operator
        case '' % Standard scoring
            % Passed test cases
            scores = results.passed(testCaseMask) .* pointsPerPart;
            results.score(testCaseMask) = scores;
            totalScore = totalScore + sum(scores);
            % Possible score
            results.max_score(testCaseMask) = pointsPerPart;
        case '+' % Extra credit
            results.score(testCaseMask) = pointsPerPart;
            extraPoints = extraPoints + numPassed * pointsPerPart;
        case '-' % Penalty scoring
            results.score(testCaseMask) = -pointsPerPart;
            extraPoints = extraPoints - numFailed * pointsPerPart;
        case 'x' % Multiplicative scoring
            if isEach
                multiplier = multiplier * (value ^ numPassed);
            elseif allPassed
                multiplier = multiplier * value;
            end
        case '/' % Penalty multiplicative scoring
            if isEach
                multiplier = multiplier * (value ^ numFailed);
            elseif ~allPassed
                multiplier = multiplier * value;
            end
        otherwise
            obj.throwError('Invalid operator in scoring tag.')
    end
end

% Get final score
totalScore = totalScore * multiplier;
totalScore = totalScore + extraPoints;
totalScore = max(totalScore, 0); % Non-negative

% Add status field to results
results.status = repmat("failed", height(results), 1);
results.status(results.passed) = "passed";

% Prepare table for Gradescope formatting
results = removevars(results, {'passed', 'scoring'}); % Remove unnecessary vars
results.max_score = round(results.max_score, 2);
results.score = round(results.score, 2);

% Create final json structure and add fields
json = struct('score', round(totalScore, 2), 'tests', results, 'test_output_format', 'html');
json.visibility = obj.Visibility;
json.output = obj.GlobalOutput;
json.output_format = obj.OutputFormat;
json.stdout_visibility = obj.StdoutVisibility;

% Write json structure to final results.json file
json = jsonencode(json, PrettyPrint=true);
writelines(json, fullfile(pwd, 'results.json'));
end
