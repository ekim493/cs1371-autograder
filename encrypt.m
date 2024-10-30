function encrypt
copyfile("source\", "sourceP\");
% Solutions folder
cd("sourceP\solutions");
files = {dir().name};
files = files(4:end);
for i = 1:length(files)
    if contains(files(i), 'HW')
        delete(sprintf("%s/*.p", files{i}));
        pcode(files{i}, '-inplace');
        delete(sprintf("%s/*.m", files{i}));
        delete(sprintf("%s/*.asv", files{i}));
    end
end
delete(".gitignore");
delete("*.md");

% Testers folder
cd("..")
cd("testers")
delete("*.asv");
delete(".gitignore");
delete("*.p");
delete("*.md");
files = {dir().name};
files = files(4:end);
for i = 1:length(files)
    if contains(files(i), 'Tester')
        pcode(files{i}, '-inplace');
    end
end
delete("*.m");

cd("..")
% Base dir
files = dir();
for i = 1:length(files)
    if ~files(i).isdir && ~strcmp(files(i).name, 'run_autograder')
        if strcmp(files(i).name, 'runTester.m')
            pcode(files(i).name);
            delete(files(i).name);
        else
            delete(files(i).name);
        end
    end
end
cd("..")