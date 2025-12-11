function map = mapPlot(lines)
% MAPPLOT - Create a dictionary defining all points and line segments.
%   This function takes in an array of Line objects and outputs a dictionary with all the points and line
%   segments in the array. Intended as a helper function for checkPlots.
%
%   Syntax
%       M = mapPlot(L)
%
%   Arguments
%       L - Array of Line objects to create a dictionary from.
%       M - Dictionary of all points and line segments in L. It's keys will be a 1x2 cell array containing a
%           numeric vector. For points, this vector will be [x-coord, y-coord]. For line segments, this
%           vector will be [x-coord1, y-coord1, x-coord2, y-coord2]. It's values will be a 1xN cell array.
%           For points, N will be 4 and will store the marker style, marker size, edge color, and face color
%           in that order. For line segments, N will be 3 and will store line color, line style, and
%           line width in that order. All coordinates will be rounded to 4 decimal places.
%
%   See also checkPlots

map = dictionary();
for i = 1:numel(lines)
    line = lines(i);
    if ~isempty(line.ZData)
        warning('3D plotting isn''t supported');
    end
    % Add all drawn points
    if ~strcmp(line.Marker, 'none')
        key = num2cell([round(line.XData', 4), round(line.YData', 4)], 2);
        if strcmp(line.MarkerEdgeColor, 'auto')
            color = line.Color;
        else
            color = line.MarkerEdgeColor;
        end
        data = {{line.Marker, line.MarkerSize, color, line.MarkerFaceColor}};
        data = repelem(data, numel(key), 1);
        map = insert(map, key, data);
    end

    % Add all segments
    if ~strcmp(line.LineStyle, 'none')
        key = [round(line.XData(1:end-1)', 4), round(line.YData(1:end-1)', 4), ...
            round(line.XData(2:end)', 4), round(line.YData(2:end)', 4)];
        needSwap = key(:, 1) > key(:, 3);
        key(needSwap, :) = key(needSwap, [3 4 1 2]);
        data = {{line.Color, line.LineStyle, line.LineWidth}};
        map = insert(map, num2cell(key, 2), data);
    end
end
end
