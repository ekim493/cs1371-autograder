function out = generateSpec(opts)
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
    opts.lines (1, 1) logical = true
    opts.points (1, 1) logical = true
    opts.colors (1, 1) logical = true
end

out = [];
if opts.lines
    lineSpecs = {'-', ':', '-.', '--'};
    out = [lineSpecs{randi(numel(lineSpecs))}];
end
if opts.points
    pointSpecs = '.ox+*sdp';
    out = [out pointSpecs(randi(numel(pointSpecs)))];
end
if opts.colors
    colorSpecs = 'rgbcmyk';
    out = [out colorSpecs(randi(numel(colorSpecs)))];
end
end
