function num = example7(fn)
img = imread(fn);
num = sum(img(:, :, 1) > 100, 'all');
imwrite(img, [fn(1:end-4) '_updated.png']);
end