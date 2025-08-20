function out = generateString(opts)
% GENERATESTRING - Generate a random string of characters.
%   This function generates a random string of characters based on the input options. By
%   default, it generates a string of length 5 <= L <= 20, with uppercase characters,
%   and no special characters, numbers, or spaces. The generator works by pulling from a
%   pool of valid characters, with each character getting equal probability.
%
%   Syntax
%       C = generateString()
%       C = generateString(NAME=VALUE)
%
%   Name-Value Arguments
%       length (double) - Specify the length (or number of columns) of output. Input a single number for a
%                         specific length, or enter a 1x2 vector in the [MIN, MAX] format. Default = [5, 20]
%       height (double) - Specify the height (number of rows) of output. Input a single number for a
%                         specific height, or enter a 1x2 vector in the [MIN, MAX] format. Default = 1.
%       pool (char) - Define a character pool for the generator to pull from. Elements within this
%                     pool have an equal probability to be picked, if no other options are specified. By
%                     default, this pool contains a single instance of all lowercase letters.
%       uppercase (logical) - Add uppercase letters to character pool. Default = false.
%       special (logical) - Adds certain special characters to character pool. Default = false.
%       numbers (logical) - Add digits 0-9 to the character pool. Default = false.
%       sentence (logical) - Adds spaces at a frequency to replicate sentence structure. Default = false.
%       match (char) - Create a random string by matching character patterns from the input. Specify any
%                      characters from the pool with 'a'. This pool of characters is modified by the other arguments.
%                      Specify consonants as 'c' or 'C', vowels as 'v' or 'V', digits as 'd', special
%                      characters as 's', and any other character by inputting it directly. Escape the
%                      characters using '\'. Escape characters only work with height of 1. y is defined as a consonant.
%       stringType (logical) - If true, it will return the string as a string class instead of char class.

arguments
    opts.length (1, :) double = [5, 20]
    opts.height (1, :) double = 1
    opts.uppercase (1, 1) logical = false
    opts.special (1, 1) logical = false
    opts.numbers (1, 1) logical = false
    opts.sentence (1, 1) logical = false
    opts.match char = ''
    opts.pool (1, :) char = 'abcdefghijklmnopqrstuvwxyz'
    opts.stringType (1, 1) logical = false
end

% Define character pool
c_pool = opts.pool;
if opts.uppercase
    c_pool = [c_pool 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'];
end
if ~islogical(opts.special)
    c_pool = [c_pool opts.special];
elseif opts.special
    c_pool = [c_pool '!#$%()*+-./:;=?@'];
end
if opts.numbers
    c_pool = [c_pool '0123456789'];
end

if isempty(opts.match)
    % If no match string is given, define size.
    if isscalar(opts.length)
        c = opts.length;
    else
        c = randi(opts.length);
    end
    if isscalar(opts.height)
        r = opts.height;
    else
        r = randi(opts.height);
    end
    out = char(zeros([r, c]));
    exp = char(out + 'a'); % All characters can be any character input defined by c_pool
else
    % If a match string is given, simply define the output size.
    exp = opts.match;
    [r, c] = size(exp);
    if r == 1
        len = length(exp) - numel(strfind(exp, '\'));
        out = char(zeros([1, len]));
    else
        out = char(zeros([r, c]));
    end
end

if ~opts.sentence
    % Not sentence option. Have 2 indicies in case escape character used.
    i = 1; % Index of exp
    j = 1; % Index of out
    while i <= numel(exp)
        switch exp(i)
            case '\'
                i = i + 1;
                out(j) = exp(i);
            case 'a'
                pool = c_pool;
                out(j) = pool(randi(numel(pool)));
            case 'A'
                pool = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
                out(j) = pool(randi(numel(pool)));
            case 'c'
                pool = 'bcdfghjklmnpqrstvwxyz';
                out(j) = pool(randi(numel(pool)));
            case 'C'
                pool = 'BCDFGHJKLMNPQRSTVWXYZ';
                out(j) = pool(randi(numel(pool)));
            case 'v'
                pool = 'aeiou';
                out(j) = pool(randi(numel(pool)));
            case 'V'
                pool = 'AEIOU';
                out(j) = pool(randi(numel(pool)));
            case 'd'
                pool = '0123456789';
                out(j) = pool(randi(numel(pool)));
            case 's'
                pool = '!#$%()*+-./:;=?@';
                out(j) = pool(randi(numel(pool)));
            otherwise
                out(j) = exp(i);
        end
        i = i + 1;
        j = j + 1;
    end
    return
else
    % Sentence option. Iterate through string, increasing space probability every time.
    prob = 0;
    for i = 1:numel(out)
        p = rand();
        if p < prob
            out(i) = ' ';
            prob = 0;
        else
            out(i) = c_pool(randi(numel(c_pool)));
            prob = prob + 0.05;
        end
    end
    % Remove ending space if needed
    if r == 1 && out(end) == ' '
        out(end) = c_pool(randi(numel(c_pool)));
    end
end

if opts.stringType
    out = string(out);
end
end
