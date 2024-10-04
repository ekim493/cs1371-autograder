assignment_name = 'HW0'; % Edit

addpath("Submissions\")
addpath(sprintf('source/solutions/%s', assignment_name))
cd("source\")
metadata = jsondecode(fileread('../submission_metadata.json'));
metadata.assignment.title = assignment_name;
json = jsonencode(metadata);
fh = fopen('../Submissions/submission_metadata.json', 'w');
fprintf(fh, json);
fclose(fh);
runTester();
cd("../")
movefile("./source/results.json", "./")
open("results.json")
