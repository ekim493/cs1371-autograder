function encrypt
copyfile("source\", "sourceP\");
cd("sourceP\solutions");
files = {dir().name};
files = files(4:end);
for i = 1:length(files)
    if contains(files(i), 'HW')
        delete(sprintf("%s/*.p", files{i}));
        pcode(files{i}, '-inplace');
        delete(sprintf("%s/*.m", files{i}));
    end
end
cd("..")
cd("testers")
delete("*.asv");
delete("*.p");
files = {dir().name};
files = files(4:end);
for i = 1:length(files)
    if contains(files(i), 'Tester')
        pcode(files{i}, '-inplace');
    end
end
delete("*.m");
cd("..\..")