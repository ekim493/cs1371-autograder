function notifyWeb(msg)
% NOTIFYERROR - Sends a message to the webhook url.
%   The file 'env/webhook.url' should contain a text string with the webhook url. By default, this
%   function is not used within the autograder and should be implemented manually where desired.
%
%   The message will be appended with a link to the student submission. The function can be customized
%   to print custom messages, for example if 'error' is input.

persistent hasRun % Only notify once per run

if isempty(hasRun)
    try
        url = fileread(fullfile('env', 'webhook.url'));
        submission = jsondecode(fileread('/autograder/submission_metadata.json'));
        link = sprintf('https://www.gradescope.com/courses/%d/assignments/%d/submissions/%d', ...
                        submission.assignment.course_id, submission.assignment.id, submission.id);
        switch msg
            case 'error'
                str = ['⚠️ An autograder error was detected. Link: ' link];
            case 'cheat'
                str = ['A student was detected cheating. Link: ' link];
            otherwise
                str = sprintf('%s. Link: %s', msg, link);
        end
        data = struct('content', str);
        webwrite(url, data);
        disp('Autograder notice sent.');
    catch
        warning('Autograder notice failed to send.');
    end
    hasRun = true;
end
end