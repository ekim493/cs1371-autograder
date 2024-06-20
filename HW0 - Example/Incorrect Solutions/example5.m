function example5(fn)
fh = fopen(fn);
fhw = fopen('new.txt', 'w');
line = fgets(fh);
while ischar(line)
    fprintf(fhw, (line));
    line = fgets(fh);
end