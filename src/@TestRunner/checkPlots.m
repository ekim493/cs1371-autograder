function [hasPassed, msg] = checkPlots(obj)
% CHECKPLOTS - Check and compare a plot against the solution's.
%   This function will read in the currently open figures and compare them. For the function to work, all
%   figures must be closed and then at least 2 figures must be opened. The solution plot should be created
%   first, followed by the student plot. The plots must not override one another, so 'figure'
%   must be called. It will assume that a solution plot was created successfully.
%
%   Output Arguments
%       hasPassed - True if the plots matched, false if not.
%       msg - Character message indicating why the test failed. Is empty if tf is true.
%
%   checkPlots does not current support or check the following:
%       - Annotations, tiled layout, UI elements, colorbars, or other graphic elements
%       - Plots generated with functions other than plot (such as scatter)
%       - 3D plots, or any plots with a z axis
%       - Text styles or font size
%       - Box styling, tick marks, tick labels, and similar
%       - Similar plots with a margin of error

% sFig - Student, cFig - Correct figure.
% Will assume that the lower number figure is the solution plot.
figures = findobj('Type', 'figure');
figures = figures(~cellfun(@isempty, {figures.Children})); % Only extract figures with actual plots
figures = sort(figures); % Sort by number
if numel(figures) == 0
    error('TestRunner:noPlot', 'No figures were detected. Was the test case set up properly?');
elseif numel(figures) < 2 % Assume solution plot was created
    hasPassed = false;
    msg = 'Your solution did not create a plot when one was expected.';
    return
else % For now only support 2 figures
    cFig = figures(1);
    sFig = figures(2);
end
i = 1;
if numel(figure(i).Children) == 0
    i = i + 1;
    if numel(figure(i).Children) == 0
        error('TestRunner:noPlot', 'There was no solution plot present.');
    end
end
cFig = figure(i);
i = i + 1;
if numel(figure(i).Children) == 0
    i = i + 1;
    if numel(figure(i).Children) == 0
        hasPassed = false;
        msg = 'Your solution did not create a plot when one was expected.';
        return
    end
end
sFig = figure(i);

msg = [];

% Plot check
sAxes = findobj(sFig, 'Type', 'axes');
cAxes = findobj(cFig, 'Type', 'axes');
sNotAxes = findobj(sFig.Children, 'flat', '-not', 'Type', 'axes', '-not', 'Type', 'Legend');
cNotAxes = findobj(cFig.Children, 'flat', '-not', 'Type', 'axes', '-not', 'Type', 'Legend');
if numel(cNotAxes) > 0
    warning('Only axes and legends are checked. Annotations, UI elements, and other elements aren''t checked.');
elseif numel(sNotAxes) ~= numel(cNotAxes)
    if isa(sFig.Children, 'matlab.graphics.layout.TiledChartLayout')
        msg = 'Your plot uses a tiled layout. Please use subplot instead.'; % Should this be allowed?
    else
        msg = 'Your plot contains extraneous elements. Ensure you don''t have additional UI elements, annotations, or similar.';
    end
    hasPassed = false;
    return
end
if isempty(cAxes) || isempty(sAxes)
    msg = 'Your plot is empty.';
    hasPassed = false;
    return
end

% Number of subplot check
if numel(sAxes) ~= numel(cAxes)
    msg = sprintf('Expected %d subplot(s), but your solution produced %d subplot(s).', numel(cAxes), numel(sAxes));
    hasPassed = false;
    appendImage;
    return
end

% Subplot grid check
sAxesPos = {sAxes.Position}';
cAxesPos = {cAxes.Position}';
% We use strings to represent subplot locations. Sort them to ensure plotting out of order still works.
[sAxesPos, sInd] = sort(join([string(cellfun(@(pos) round(pos(1), 2), sAxesPos)), string(cellfun(@(pos) round(pos(2), 2), sAxesPos))], ','));
[cAxesPos, cInd] = sort(join([string(cellfun(@(pos) round(pos(1), 2), cAxesPos)), string(cellfun(@(pos) round(pos(2), 2), cAxesPos))], ','));
if any(sAxesPos ~= cAxesPos)
    msg = 'The subplot positions do not match.';
    hasPassed = false;
    appendImage;
    return
end

% Data check
sAxes = sAxes(sInd);
cAxes = cAxes(cInd);
% Loop through every subplot
for i = 1:numel(cAxes)
    if numel(findobj([cAxes(i).Children], '-not', 'Type', 'Line')) > 0
        warning('Plots created with functions other than plot will not be checked.');
    end
    sAxesPlots = findobj(sAxes(i), 'Type', 'Line');
    cAxesPlots = findobj(cAxes(i), 'Type', 'Line');
    sMap = TestRunner.mapPlot(sAxesPlots);
    cMap = TestRunner.mapPlot(cAxesPlots);

    if ~isequal(sMap, cMap)
        msg = 'Incorrect data and/or style in plot(s)';
        if numel(sMap) ~= numel(cMap)
            msg = sprintf('%s\nIn at least 1 plot, %d line(s) and/or point(s) were expected, but your solution had %d.', msg, numel(cMap), numel(sMap));
        end
        % Check if any points are outside x and y bounds
        xLim = sAxes(i).XLim;
        yLim = sAxes(i).YLim;
        for j = 1:numel(sAxesPlots)
            if any([sAxesPlots(j).XData] > xLim(2)) || any([sAxesPlots(j).XData] < xLim(1))...
                    || any([sAxesPlots(j).YData] > yLim(2)) || any([sAxesPlots(j).YData] < yLim(1))
                % Only add msg if it doesn't exist yet
                if ~contains(msg, 'plot boundaries')
                    msg = sprintf('%s\n<em>Warning: There seems to be data outside of the plot boundaries</em>', msg);
                end
            end
        end
    end
    if ~isempty(msg)
        break
    end
end

% Other checks
for i = 1:numel(cAxes)
    if ~strcmp(char(sAxes(i).XLabel.String), char(cAxes(i).XLabel.String))
        msg = sprintf('%s\nIncorrect x-label(s) (Expected: %s, Actual: %s)', msg, char(cAxes(i).XLabel.String), char(sAxes(i).XLabel.String));
    end
    if ~strcmp(char(sAxes(i).YLabel.String), char(cAxes(i).YLabel.String))
        msg = sprintf('%s\nIncorrect y-label(s) (Expected: %s, Actual: %s)', msg, char(cAxes(i).YLabel.String), char(sAxes(i).YLabel.String));
    end
    if ~strcmp(char(sAxes(i).Title.String), char(cAxes(i).Title.String))
        msg = sprintf('%s\nIncorrect title(s) (Expected: %s, Actual: %s)', msg, char(cAxes(i).Title.String), char(sAxes(i).Title.String));
    end
    if ~isequal(sAxes(i).XLim, cAxes(i).XLim)
        msg = sprintf('%s\nIncorrect x limits', msg);
    end
    if ~isequal(sAxes(i).YLim, cAxes(i).YLim)
        msg = sprintf('%s\nIncorrect y limits', msg);
    end
    if ~all(abs(sAxes(i).PlotBoxAspectRatio - cAxes(i).PlotBoxAspectRatio) < 0.02)
        msg = sprintf('%s\nIncorrect plot size', msg);
    end
    if ~isempty(cAxes(i).Legend)
        if isempty(sAxes(i).Legend)
            msg = sprintf('%s\nMissing legend(s)', msg);
        else
            if ~strcmp(char(sAxes(i).Legend.String), char(cAxes(i).Legend.String))
                msg = sprintf('%s\nIncorrect legend text(s)', msg);
            end
            if ~strcmp(char(sAxes(i).Legend.Location), char(cAxes(i).Legend.Location))
                msg = sprintf('%s\nIncorrect legend location(s)', msg);
            end
        end
    end

    if ~isempty(msg)
        break
    end
end

% Output formatting
if ~isempty(msg)
    hasPassed = false;
    if startsWith(msg, newline)
        msg = msg(2:end);
    end
    appendImage;
else
    hasPassed = true;
end

obj.TestCase.verifyTrue(hasPassed, msg);

    function appendImage
        % Internal function to append image file to end of message
        if strcmpi(obj.OutputType, 'full')
            filename = TestRunner.compareImg(sFig, cFig);
            msg = sprintf('%s\nIMAGEFILE:%s', msg, filename);
        end
    end
end
