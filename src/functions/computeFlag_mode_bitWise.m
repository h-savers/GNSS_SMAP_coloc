function y = computeFlag_mode_bitWise(x)
binX = dec2bin(x);

modeBin = mode(binX);
y = bin2dec(modeBin);
end