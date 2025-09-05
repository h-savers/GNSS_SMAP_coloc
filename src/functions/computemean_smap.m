function y = computemean_smap(x,n)
x(x==-9999)=NaN ;
y = mean(x,n, 'omitnan');
end
