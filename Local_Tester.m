assignment_name = input('Enter assignment name:    ');

addpath("Submissions\")
addpath(sprintf('source/solutions/%s', strrep(assignment_name, 'X', 'W')))
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
