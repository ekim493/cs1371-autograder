function checkImages(obj, user_fn, expected_fn)
% CHECKIMAGES - Check and compare an image against the solution's.
%   This function will read in an image filename (defined by the property runCheckImages) and compare it to
%   its corresponding image solution with a small tolerance. The final result is run through the testCase
%   object using verifyTrue. The outputType property does affect this function, and the full output
%   includes an image comparison.
%
%   Input Arguments
%       user_fn (char) - User image file name.
%       expected_fn (char) - Expected image file name.

% Check if images can be accessed
if ~exist(expected_fn, 'file')
    error('TestRunner:noImage', 'The solution image wasn''t found');
elseif ~exist(user_fn, 'file')
    obj.TestCase.verifyTrue(false, sprintf('The image ''%s'' wasn''t found. Did you create an image with the right filename?', user_fn));
    return;
end
% Image comparsion by comparing image arrays
user = imread(user_fn);
expected = imread(expected_fn);
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
    msg = sprintf('The dimensions of the image do not match the expected image.\n    Actual size: %dx%dx%d\n    Expected size: %dx%dx%d', rUser, cUser, lUser, rExp, cExp, lExp);
end

% Output formatting
switch obj.OutputType
    case 'none'
        msg = '';
    case 'compare'
        filename = TestRunner.compareImg(user_fn, expected_fn);
        msg = strrep(msg, newline, '\n');
        msg = sprintf('%s\\nIMAGEFILE:%s', msg, filename);
end
obj.TestCase.verifyTrue(hasPassed, msg);
end
