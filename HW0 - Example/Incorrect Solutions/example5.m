function example5(fn)
fh = fopen(fn);
fhw = fopen('new.txt', 'w');
line = fgets(fh);
line = upper(line);
while ischar(line)
    fprintf(fhw, (line));
    line = fgets(fh);
end