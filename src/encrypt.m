function encrypt(base, folder)
% ENCRYPT - Copy files at the source location to a temp folder and pcode all supported files.

source = fullfile(base, folder);
if ~exist(source, 'dir')
    error('The specificed source folder does not exist');
end

% Copy files
target = fullfile(base, 'temp');
copyfile(source, target);

% Pcode and delete remnants
folders = {dir(target).name};
folders = folders(3:end);
for f = folders
    delete(fullfile(target, f{1}, '*.p')); % Delete prior pcoded files (if any)
    pcode(fullfile(target, f{1}), '-inplace');
    delete(fullfile(target, f{1}, '*.m'));
    delete(fullfile(target, f{1}, '*.asv'));
end
