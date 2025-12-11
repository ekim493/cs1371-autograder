function [hasPassed, msg] = checkImages(obj, userFile, solnFile)
% CHECKIMAGES - Check and compare an image against the solution's.
%   This function will read in an image filename (defined by the property RunCheckImages) and compare it to
%   its corresponding image solution with a small tolerance. The final result is run through the testCase
%   object using verifyTrue. The outputType property does affect this function, and the 'full' output
%   includes an image comparison.
%
%   Input Arguments
%       userFile (char) - User image file name.
%       solnFile (char) - Solution image file name.
% 
%   Output Arguments
%       hasPassed - True if the images matched, false if not.
%       msg - Character message indicating why the test failed. Is empty if tf is true.

% Check if images can be accessed
if ~exist(solnFile, 'file')
    error('TestRunner:noImage', 'The solution image wasn''t found');
elseif ~exist(userFile, 'file')
    obj.TestCase.verifyTrue(false, sprintf('The image ''%s'' wasn''t found. Did you create an image with the right filename?', userFile));
    return;
end
% Image comparison by comparing image arrays
user = imread(userFile);
expected = imread(solnFile);
[rUser,cUser,lUser] = size(user);
[rExp,cExp,lExp] = size(expected);
if rUser == rExp && cUser == cExp && lUser == lExp
    diff = abs(double(user) - double(expected));
    isDiff = any(diff(:) > obj.ImageTolerance);
    if isDiff
        hasPassed = false;
        msg = 'The image output does not match the expected image.';
    else
        return;
    end
else
    hasPassed = false;
    msg = sprintf('The dimensions of the image do not match the expected image.\nActual size: %dx%dx%d\nExpected size: %dx%dx%d', ...
        rUser, cUser, lUser, rExp, cExp, lExp);
end

% Output formatting
switch obj.OutputType
    case 'none'
        msg = '';
    case 'full'
        filename = TestRunner.compareImg(userFile, solnFile);
        msg = sprintf('%s\nIMAGEFILE:%s', msg, filename);
end
obj.TestCase.verifyTrue(hasPassed, msg);
end
