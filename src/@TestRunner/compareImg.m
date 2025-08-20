function varargout = compareImg(varargin)
% COMPAREIMG - Compare two images or figures.
%   This function will read in two figures or two image filenames and displays a figure comparison between
%   them. This function can also save the figure comparsion as a jpg image. Intended as a helper function
%   for checkImages and checkPlots. For comparing plots, it is recommended you use mapPlot instead.
%
%   Syntax
%       compareImg(user, expected)
%       F = compareImg(user, expected)
%       F = compareImg()
%
%   Input Arguments
%       user, expected - Filename of the student's image and the expected image OR the student's figure and
%       the expected figure. If no input arguments are specified, it will save the currently open figure
%       window as a jpg.
%
%   Output Arguments
%       F - Filename of the comparsion image as a jpg. If no output arguments are specified, it will display
%           the comparison as a figure.
%
%   See also checkImages, checkPlots, mapPlot

if nargout == 0
    if nargin < 2
        error('TestRunner:arguments', 'You must have at least 1 output or two inputs.');
    else
        % Extract relevant data
        if isa(varargin{1}, 'matlab.ui.Figure')
            fig1 = varargin{1};
            fig2 = varargin{2};
            set(fig1, 'Position', [100, 100, 300, 200]);
            set(fig2, 'Position', [100, 100, 300, 200]);
            user = getframe(varargin{1}).cdata;
            expected = getframe(varargin{2}).cdata;
            type = 'Plot';
        elseif exist(varargin{1}, 'file')
            user = imread(varargin{1});
            expected = imread(varargin{2});
            type = 'Image';
        else
            error('TestRunner:arguments', 'The inputs must either be figures or image files.');
        end
        % Plots
        close all;
        tiledlayout(1, 2, 'TileSpacing', 'none', 'Padding', 'tight');
        nexttile
        imshow(user);
        if nargin == 3
            title(sprintf('Student %s', type), 'FontSize', 8);
        else
            title(sprintf('Student %s', type));
        end
        nexttile
        imshow(expected);
        if nargin == 3
            title(sprintf('Solution %s', type), 'FontSize', 8);
        else
            title(sprintf('Solution %s', type));
        end
        if nargin ~= 3
            pos = get(gcf, 'Position');
            pos = [pos(1)-pos(3)*0.3 pos(2) pos(3)*1.6 pos(4)]; % Rescale
            set(gcf, 'Position', pos);
        end
        shg;
        return;
    end
else
    % Open figure comparsion, then save the figure data,
    if nargin == 2
        TestRunner.compareImg(varargin{:}, 'call'); % Recursive call to display figures
    end
    % Decrease this value if Gradescope is not displaying properly
    set(gcf, 'Position', Autograder.FigureSize); % Size of output image.
    set(gcf, 'PaperPositionMode', 'auto');
    filename = [tempname, '.jpg'];
    saveas(gcf, filename);
    close all
    varargout{1} = filename;
end
end
