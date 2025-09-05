function y = computeFlag_mode_bitWise_smap(x, y, n)
bin(:,:,1) = dec2bin(x);
bin(:,:,2) = dec2bin(y);

% % binX = dec2bin(x);
% % binY = dec2bin(y);
% % bin = [binX binY];

% % binX = reshape(dec2bin(x), size(x));
% % binY = reshape(dec2bin(y), size(y));
% % bin = [binX binY];

% % bin = dec2bin(x, n);
modeBin = round(mean(bin, n));
y = bin2dec(modeBin);
end