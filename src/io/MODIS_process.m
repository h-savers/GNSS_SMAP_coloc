function MODISproduct_atResolution=MODIS_process(file_path_MOD09CMG, file_path_MOD11C1, Target_Resolution, modis_c, modis_r)

mask = load('maskLand_EASE25.mat'); 


%%%%%%%%%%%%%%%%%%%%%%%% ndvi & ndwi part

cloudCover=hdfread(file_path_MOD09CMG,'Coarse Resolution Internal CM');
cloudCover=double(cloudCover);
stBit=bitget(cloudCover,2);

Band1=hdfread(file_path_MOD09CMG,'Coarse Resolution Surface Reflectance Band 1');
Band1=double(Band1);
Band1=Band1*0.0001;
Band1_c=NaN(size(Band1));ind=find(stBit==1);Band1_c(ind)=Band1(ind);
Band1_n=accumarray([modis_c(:) modis_r(:)],Band1_c(:),[],@computemean,-9999);
% % Band1_n=flipdim(Band1_n', 1);
Band1_n=Band1_n';
Band1_n(Band1_n==-9999)=NaN;

Band2=hdfread(file_path_MOD09CMG,'Coarse Resolution Surface Reflectance Band 2');
Band2=double(Band2);
Band2=Band2*0.0001;
Band2_c=NaN(size(Band2));ind=find(stBit==1);Band2_c(ind)=Band2(ind);
Band2_n=accumarray([modis_c(:) modis_r(:)],Band2_c(:),[],@computemean,-9999);
% % Band2_n=flipdim(Band2_n', 1);
Band2_n=Band2_n';
Band2_n(Band2_n==-9999)=NaN;

Band5=hdfread(file_path_MOD09CMG,'Coarse Resolution Surface Reflectance Band 5');
Band5=double(Band5);
Band5=Band5*0.0001;
Band5_c=NaN(size(Band5));ind=find(stBit==1);Band5_c(ind)=Band5(ind);
Band5_n=accumarray([modis_c(:) modis_r(:)],Band5_c(:),[],@computemean,-9999);
% % Band5_n=flipdim(Band5_n', 1);
Band5_n=Band5_n';
Band5_n(Band5_n==-9999)=NaN;  

ndwi = (Band2_n-Band5_n)./(Band2_n+Band5_n); 
ndvi = (Band2_n-Band1_n)./(Band2_n+Band1_n);

id=find(ndwi==0);
id2=find(ndwi>1);
id3=find(ndwi<-1);
ndwi(id)=NaN;
ndwi(id3)=NaN;
ndwi(id2)=NaN;
ndwi=ndwi(:);

id=find(ndvi==0);
id2=find(ndvi>1);
id3=find(ndvi<-1);
ndvi(id)=NaN;
ndvi(id3)=NaN;
ndvi(id2)=NaN;
ndvi=ndvi(:);


%%%%%%%%%%%%%%%%%%%%%%%% LST part

lst_day = hdfread(file_path_MOD11C1, 'LST_Day_CMG');
lst_night = hdfread(file_path_MOD11C1, 'LST_Night_CMG');
QC_day = hdfread(file_path_MOD11C1, 'QC_Day');
QC_night = hdfread(file_path_MOD11C1, 'QC_Night');


lst_day = double(lst_day);
lst_night = double(lst_night);
lst_day(lst_day==0) = NaN;
lst_night(lst_night==0) = NaN;

lst_day = 0.02*lst_day;
lst_night = 0.02*lst_night;
lstC_day = convtemp(lst_day,'K','C');
lstC_night = convtemp(lst_night,'K','C');

%%%%% QC for LST
firstBitd = bitget(QC_day, 1);
secondBitd = bitget(QC_day, 2);
bitMask_d = find(firstBitd==0 & secondBitd==0);

lstC_dayMasked = lstC_day;
lstC_dayMasked(bitMask_d) = NaN;

firstBitn = bitget(QC_night, 1);
secondBitn = bitget(QC_night, 2);
bitMask_n = find(firstBitn==0 & secondBitn==0);

lstC_nightMasked = lstC_night;
lstC_nightMasked(bitMask_n) = NaN;
%%%%%%%

LST_daily_ave_n = (lstC_nightMasked + lstC_dayMasked) / 2;
LST_daily_ave_n(isnan(lstC_nightMasked) | isnan(lstC_dayMasked)) = NaN;
LST_daily_dif_n = lstC_dayMasked-lstC_nightMasked;

LST_daily_ave=accumarray([modis_c(:) modis_r(:)],LST_daily_ave_n(:),[],@computemean,-9999);
LST_daily_ave=LST_daily_ave';
LST_daily_ave=LST_daily_ave(:);
LST_daily_dif=accumarray([modis_c(:) modis_r(:)],LST_daily_dif_n(:),[],@computemean,-9999);
LST_daily_dif=LST_daily_dif';
LST_daily_dif=LST_daily_dif(:);

%%%%%% masking for keeping just land
mask=mask.maskLand(:);
for j=1:size(mask)
    if isnan(mask(j))
        ndwi(j)=NaN;
        ndvi(j)=NaN;
        LST_daily_ave(j)=NaN;
        LST_daily_dif(j)=NaN;
    end
end

MODISproduct_atResolution.Modis_ndwi=ndwi;
MODISproduct_atResolution.Modis_ndvi=ndvi;
MODISproduct_atResolution.Modis_LST_ave=LST_daily_ave;
MODISproduct_atResolution.Modis_LST_dif=LST_daily_dif;









