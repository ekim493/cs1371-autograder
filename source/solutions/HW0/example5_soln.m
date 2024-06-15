function example5_soln(fn)
fh = fopen(fn);
fhw = fopen('new_soln.txt', 'w');
line = fgets(fh);
while ischar(line)
    fprintf(fhw, upper(line));
    line = fgets(fh);
end
fclose(fh);
fclose(fhw);