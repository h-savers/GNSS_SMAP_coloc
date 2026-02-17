
function y = computemean_datetime(x)
y = datetime(mean(posixtime(x),'omitnan'),'ConvertFrom','posixtime');
end
