function out = generateSpec(options)
% GENERATESPEC - Generates a random specification for plotting.
%   This function generates a string of characters which can be used as plotting specifications.
%
%   Syntax
%       C = generateSpec(NAME=VALUE)
%
%   Name-Value Arguments
%       lines (logical) - Specify whether line specs should be included (default = true)
%       points (logical) - Specify whether point specs should be included (default = true)
%       colors (logical) - Specify whether color specs should be included (default = true)

arguments
    options.lines (1, 1) logical = true
    options.points (1, 1) logical = true
    options.colors (1, 1) logical = true
end

out = [];
if options.lines
    lineSpecs = {'-', ':', '-.', '--'};
    out = [lineSpecs{randi(numel(lineSpecs))}];
end
if options.points
    pointSpecs = '.ox+*sdp';
    out = [out pointSpecs(randi(numel(pointSpecs)))];
end
if options.colors
    colorSpecs = 'rgbcmyk';
    out = [out colorSpecs(randi(numel(colorSpecs)))];
end
end
