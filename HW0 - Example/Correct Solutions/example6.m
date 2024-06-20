function st = example6(st, field, val)
for i = 1:length(val)
    st(i).(field) = val(i);
end