function out = generateCellArray(opts)
% GENERATECELLARRAY - Generates a simple cell array containing various data types.
%   This function generates a cell array containing a random data type, including doubles, vectors, logical
%   vectors, and strings. By default, it will generate all of them with a size of c = [3, 5] and r = 1.
%
%   Name-Value Arguments
%       rows (double) - Specify the number of rows the cell array should have. Specify a range of possible
%                       values by inputing a (1, 2) double vector. Default = 1.
%       columns (double) - Specify the number of rows the cell array should have. Specify a range of possible
%                          values by inputing a (1, 2) double vector. Default = [3, 5].
%       doubles (logical) - Specify whether the cell array should contain single doubles. These doubles will
%                           be random integers in the range specified by doubleRange. Default = true.
%       vectors (logical) - Specify whether the cell array should contain vectors of doubles. These doubles
%                           will be random integers in the range specified by doubleRange, and the vector
%                           will be 1 to 5 in length. Default = true.
%       strings (logical) - Specify whether the cell array should contain vectors of chars. These chars will
%                           be a random string of 5 to 10 lowercase letters. Default = true.
%       logicals (logical) - Specify whether the cell array should contain vectors of logicals. The length
%                             of this vector will be 1 to 5. Default = true.
%       doubleRange (double) - Specify a range of values for all random double number generation. Default =
%                              [0, 100].
%       stringIsSent (logical) - Specify whether the strings should be generated in a sentence like format.
%                                This will include spaces and increase the length to 20 to 40. Default = false.

arguments
    opts.rows (1, :) double = 1
    opts.columns (1, :) double = [3, 5]
    opts.vectors (1, 1) logical = true
    opts.doubles (1, 1) logical = true
    opts.strings (1, 1) logical = true
    opts.logicals (1, 1) logical = true
    opts.doubleRange (1, 2) double = [0, 100]
    opts.stringIsSent (1, 1) logical = false
end

if isscalar(opts.rows)
    r = opts.rows;
else
    r = randi(opts.rows);
end
if isscalar(opts.columns)
    c = opts.columns;
else
    c = randi(opts.columns);
end
ca = cell([r, c]);
pos = 'vdsl';
pos = pos([opts.vectors, opts.doubles, opts.strings, opts.logicals]);
for i = 1:numel(ca)
    type = pos(randi(numel(pos)));
    switch type
        case 'v'
            ca{i} = randi(opts.doubleRange, [1, randi(5)]);
        case 'd'
            ca{i} = randi(opts.doubleRange);
        case 's'
            if opts.stringIsSent
                ca{i} = utils.generateString(sentence=true, length=[20, 40]);
            else
                ca{i} = utils.generateString(length=[5, 10]);
            end
        case 'l'
            ca{i} = logical(randi([0, 1], [1, randi(5)]));
    end
end
out = ca;
end
