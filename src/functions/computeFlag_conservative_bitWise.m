
function y = computeFlag_conservative_bitWise(x)
[c d]=size(x); 
t = []; 
for i=1:c
    B = [];
    for j=1:32
    t(i, 1) = bitget(int32(x(i, 1)), j);
    B = [B; t(i, 1)];
    end
M = mode(B);
t = [t; M];
end

y=mode(t);