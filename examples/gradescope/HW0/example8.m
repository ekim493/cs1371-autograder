function out = example8(ca)
i = 1;
out = 0;
while i <= length(ca)
    if ismatrix(ca{i})
        out = out + 1;
    end
end
end