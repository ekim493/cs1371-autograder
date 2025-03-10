function encrypt
copyfile("source", "sourceP");

% Solutions folder
cd(['sourceP' filesep 'solutions']);
files = {dir().name};
files = files(3:end);
for file = files
    if contains(file, {'HW', 'HX'})
        delete([file{1} filesep '*.p']);
        pcode(file{1}, '-inplace');
        delete([file{1} filesep '*.m']);
        delete([file{1} filesep '*.asv']);
    else
        delete(file{1});
    end
end

% Testers folder
cd(['..' filesep 'testers'])
delete("*.asv");
delete("*.p");
files = {dir().name};
files = files(3:end);
for file = files
    if contains(file, {'HW', 'HX'})
        pcode(file{1}, '-inplace');
        delete(file{1});
    elseif contains(file, 'Tester')
        continue
    else
        delete(file{1})
    end
end

% Base dir
cd("..")
delete("*.asv");
delete("*.md");

% Return
cd("..")