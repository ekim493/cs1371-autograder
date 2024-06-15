function st = example6_soln(st, field, val)
for i = 1:length(val)
    st(i).(field) = val(i);
end