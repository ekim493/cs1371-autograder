function [out1, out2] = example2_soln(word)
mask = word == 'a' | word == 'e' | word == 'i' | word == 'o' | word == 'u';
out1 = word(mask);
out2 = length(mask);
end