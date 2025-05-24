function encrypt(base, folder)
% Check for folder
source = fullfile(base, folder);
if ~exist(source, 'dir')
    error('The specificed source folder does not exist');
end

% Copy files
target = fullfile(base, 'temp');
copyfile(source, target);

% Pcode and delete remnants
files = {dir(target).name};
files = files(3:end);
for file = files
    delete(fullfile(target, file{1}, '*.p')); % Delete if temp file not deleted properly
    pcode(fullfile(target, file{1}), '-inplace');
    delete(fullfile(target, file{1}, '*.m'));
    delete(fullfile(target, file{1}, '*.asv'));
end