function out = example8_soln(ca)
out = 0;
for i = 1:length(ca)
    if ismatrix(ca{i})
        out = out + 1;
    end
end
end