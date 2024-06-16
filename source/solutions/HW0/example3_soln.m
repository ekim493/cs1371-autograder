function [out1, out2] = example3_soln(arr)
[r, ~] = size(arr);
count = 0;
for i = 1:r
    if mod(sum(arr(i, :)), 2) ~= 0
        arr(i, :) = 2 * arr(i, :);
        count = count + 1;
    end
end
out1 = arr;
out2 = count;