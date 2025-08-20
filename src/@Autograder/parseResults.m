function parseResults(obj)
% PARSERESULTS - Parses the results of a test run and creates the final results json file.
%   This function parses the output of runSuite, assigns each test case the proper number of points, and then creates
%   the final results.json file for Gradescope to use. 
%
%   The autograder relies on test tags to group problems. Each problem should be grouped and tagged with the problem
%   name/number, the number of points to assign, and how the points should be assigned (either 'penalty', 'standard', or
%   'grouped'). 
%
%   The problem number is used to sort the problems, the 'penalty' scoring will deduct a certain percentage (set by the
%   property PenaltyScore), 'standard' scoring will give each test case the points stated, and 'grouped' scoring will
%   sum up all of the problems to the stated point total.

% Sort results based on problem name
[~, ind] = sort(obj.Results.problem);
results = obj.Results(ind, :); % Will use local variable

% Get the score for each test case and the total
totalScore = 0;
maxScore = 0;
multiplier = 1;
problemNames = unique(results.problem);
for i = 1:numel(problemNames)
    problem = problemNames{i};
    testCaseMask = strcmp(problem, results.problem);
    scoring = unique(results.scoring(testCaseMask));

    if numel(scoring) > 1
        obj.throwError('Each unique problem should only have one type of scoring assigned to it.')
    end

    % Extract scoring parts
    parts = regexp(scoring, '([a-zA-Z]+)=([+/\-x]?)(\d+\.?\d*)', 'tokens', 'once');
    if isempty(parts)
        obj.throwError('One of the problems had invalid tag(s).')
    end
    type = parts{1};
    operator = parts{2};
    value = str2double(parts{3});

    % Get properties of problem
    isEach = strcmpi(type, 'each');
    numParts = sum(testCaseMask);
    numPassed = sum(results.passed(testCaseMask));
    numFailed = sum(~results.passed(testCaseMask));

    % Calculate points for the problem
    if isEach
        pointsPerPart = value;
    else
        pointsPerPart = value / numParts;
    end
    pointTotal = pointsPerPart * numParts;

    % Assign points
    switch operator
        case '' % Standard scoring
            if isEach
                % Passed test cases
                scores = results.passed(testCaseMask) * pointsPerPart;
                results.score(testCaseMask) = scores;
                totalScore = totalScore + sum(scores);
                % Possible score
                results.max_score(testCaseMask) = pointsPerPart;
                maxScore = maxScore + pointTotal;
            else
                % Passed test cases
                scores = results.passed(testCaseMask) * pointsPerPart;
                results.score(testCaseMask) = scores;
                totalScore = totalScore + sum(scores);
                % Possible score
                results.max_score(testCaseMask) = pointsPerPart;
                maxScore = maxScore + pointTotal;
            end
        case '+' % Extra credit
            totalScore = totalScore + numPassed * pointsPerPart;
        case '-' % Penalty scoring
            totalScore = totalScore - numFailed * pointTotal;
        case 'x' % Multiplicative scoring
            multiplier = multiplier * (value ^ numPassed);
        case '/' % Penaltiy multiplicative scoring
            multiplier = multiplier * (value ^ numFailed);
    end
end

% Get final score
totalScore = totalScore * multiplier;
totalScore = max(totalScore, 0); % Non-negative

% Prepare table for Gradescope formatting
results.output_format = repmat('html', height(results), 1);
results = removevars(results, {'passed', 'scoring', 'problem'}); % Remove unnecessary vars
results.max_score = round(results.max_score, 2);
results.score = round(results.score, 2);

% Create final json structure and add fields
json = struct('score', round(totalScore, 2), 'max_score', round(maxScore, 2), 'tests', results);
json.visibility = obj.Visibility;
json.output = obj.GlobalOutput;
json.output_format = obj.OutputFormat;
json.stdout_visibility = obj.StdoutVisibility;

% Write json structure to final results.json file
json = jsonencode(json, PrettyPrint=true);
fh = fopen(fullfile(pwd, 'results.json'), 'w');
fprintf(fh, json);
fclose(fh);
end
