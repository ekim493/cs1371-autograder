function out = example4_soln(ca, num)
[~, ind] = sort(cell2mat(ca(:, 4)));
ca = ca(ind, :);
toPlot = ca(num, :);
plot(toPlot{1}, toPlot{2}, toPlot{3});
out = ca;
end