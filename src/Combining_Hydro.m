function Combining_Hydro(configurationPath)

%%%%%%%%%%%%%%%%%% reading configuration file %%%%%%%%%%%%%%%%%%
config = configFile_Hydro.instance(configurationPath);

qfs = str2num(char(num2cell(char(config.SMAPQualityFlagFilter))));
qfs = reshape(qfs,1,[]);

SMAPQualityFlagFilter = config.SMAPQualityFlagFilter;

Target_Resolution = config.Target_Resolution;
smap_path = config.smap_path;
HydroGNSS_processing = config.hydro_processing; % if yes the HydroGNSS data is also processed
product_path = config.product_path;
SMAP_resolution = config.SMAP_resolution;

%%% preparing row/col from lat/lon for accumarray for 25km resolution
load("LatLon_SMAP_9km.mat");
[longitude_a2, latitude_a2] = meshgrid(longitude_a, latitude_a);
[sm_c,sm_r]=easeconv_grid(latitude_a2,longitude_a2,25);
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if Target_Resolution==36
    numcols=964;
    numrows=406;

elseif Target_Resolution==25
    numcols=1388;
    numrows=584;
end



startDay = config.startDay;

SampleDay = startDay; % justto use to initialize the HydroGNSS product structure
startDay = datetime(startDay, 'InputFormat', 'yyyyMMdd', 'Format', 'yyyy.MM.dd');
endDay = config.endDay;
endDay = datetime(endDay, 'InputFormat', 'yyyyMMdd', 'Format', 'yyyy.MM.dd');

valid_dates = startDay:endDay;
detail_dates = datevec(valid_dates);
nDays = length(valid_dates);

%%%% Initializing the vectors
SMAPproduct_stacked = initialize_SMAPproduct_stacked(SMAP_resolution, SMAPQualityFlagFilter);

if HydroGNSS_processing=="yes" 
    HydroGNSS_data = load(config.hydro_file); %load data
    
    constellation = HydroGNSS_data.constellation;
    id_GPS=find(constellation=="GPS");
    id_Galileo=find(constellation=="Galileo");

    HydroGNSS_data = rmfield(HydroGNSS_data, 'constellation');
    HydroGNSS_vars = fieldnames(HydroGNSS_data);
    HydroGNSS_GPS_data = HydroGNSS_data;
    HydroGNSS_Galileo_data = HydroGNSS_data;

    HydroGNSS_GPS_stacked=struct;
    HydroGNSS_Galileo_stacked=struct;

    for i=1:numel(HydroGNSS_vars) % initialize the varibales in the structure
        HydroGNSS_GPS_stacked.(string(HydroGNSS_vars(i)))=[];
        HydroGNSS_Galileo_stacked.(string(HydroGNSS_vars(i)))=[];
        
        if HydroGNSS_vars(i)=="timeUTC"
            HydroGNSS_GPS_data.(string(HydroGNSS_vars(i)))(id_Galileo)=NaT;
            HydroGNSS_Galileo_data.(string(HydroGNSS_vars(i)))(id_GPS)=NaT;
        else
            HydroGNSS_GPS_data.(string(HydroGNSS_vars(i)))(id_Galileo)=NaN;
            HydroGNSS_Galileo_data.(string(HydroGNSS_vars(i)))(id_GPS)=NaN;
        end
    end
end

clear HydroGNSS_data

for i=1:nDays

    disp(['day : ' datestr(valid_dates(i))]);

    detail_date = datevec(valid_dates(i));
    datae_yy = detail_date(:,1);
    datae_mm = detail_date(:,2);
    datae_dd = detail_date(:,3);
    folder_path = fullfile(smap_path, string(datae_yy), '\', string(datae_mm), '\', string(datae_dd));

    doy = day(valid_dates(i),'dayofyear');

    files = dir(fullfile(folder_path, '*.h5'));
    file_name = files.name;
    file_path=fullfile(folder_path, '\', file_name);

    SMAPproduct = SMAP_read(file_path, qfs, SMAP_resolution, SMAPQualityFlagFilter);% read SMAP data
    SMAPproduct_atResolution = SMAP_process(SMAPproduct, Target_Resolution, numcols, numrows, SMAP_resolution, sm_c, sm_r, SMAPQualityFlagFilter);

    %%%%%%populating the smap products
    if SMAP_resolution==9
        
        if SMAPQualityFlagFilter=="no"
        
            %%% filtered based on first bit
    
            SMAPproduct_stacked.mean.latitude=[SMAPproduct_stacked.mean.latitude; SMAPproduct_atResolution.mean.latitude(:)];
            SMAPproduct_stacked.mean.longitude=[SMAPproduct_stacked.mean.longitude; SMAPproduct_atResolution.mean.longitude(:)];
            SMAPproduct_stacked.mean.roughness_coefficient=[SMAPproduct_stacked.mean.roughness_coefficient; SMAPproduct_atResolution.mean.roughness_coefficient(:)];
            SMAPproduct_stacked.mean.vegetation_opacity=[SMAPproduct_stacked.mean.vegetation_opacity; SMAPproduct_atResolution.mean.vegetation_opacity(:)];
            SMAPproduct_stacked.mean.soil_moisture=[SMAPproduct_stacked.mean.soil_moisture; SMAPproduct_atResolution.mean.soil_moisture(:)];
            SMAPproduct_stacked.mean.albedo=[SMAPproduct_stacked.mean.albedo;SMAPproduct_atResolution.mean.albedo(:)];
            SMAPproduct_stacked.mean.soil_moisture_error=[SMAPproduct_stacked.mean.soil_moisture_error; SMAPproduct_atResolution.mean.soil_moisture_error(:)];
            SMAPproduct_stacked.mean.vegetation_water_content=[SMAPproduct_stacked.mean.vegetation_water_content;SMAPproduct_atResolution.mean.vegetation_water_content(:)];
    
        elseif SMAPQualityFlagFilter=="yes"
    
            %%% filtered based on first bit
    
            SMAPproduct_stacked.Filtered_B0.mean.latitude=[SMAPproduct_stacked.Filtered_B0.mean.latitude; SMAPproduct_atResolution.Filtered_B0.mean.latitude(:)];
            SMAPproduct_stacked.Filtered_B0.mean.longitude=[SMAPproduct_stacked.Filtered_B0.mean.longitude; SMAPproduct_atResolution.Filtered_B0.mean.longitude(:)];
            SMAPproduct_stacked.Filtered_B0.mean.roughness_coefficient=[SMAPproduct_stacked.Filtered_B0.mean.roughness_coefficient; SMAPproduct_atResolution.Filtered_B0.mean.roughness_coefficient(:)];
            SMAPproduct_stacked.Filtered_B0.mean.vegetation_opacity=[SMAPproduct_stacked.Filtered_B0.mean.vegetation_opacity; SMAPproduct_atResolution.Filtered_B0.mean.vegetation_opacity(:)];
            SMAPproduct_stacked.Filtered_B0.mean.soil_moisture=[SMAPproduct_stacked.Filtered_B0.mean.soil_moisture; SMAPproduct_atResolution.Filtered_B0.mean.soil_moisture(:)];
            SMAPproduct_stacked.Filtered_B0.mean.albedo=[SMAPproduct_stacked.Filtered_B0.mean.albedo;SMAPproduct_atResolution.Filtered_B0.mean.albedo(:)];
            SMAPproduct_stacked.Filtered_B0.mean.soil_moisture_error=[SMAPproduct_stacked.Filtered_B0.mean.soil_moisture_error; SMAPproduct_atResolution.Filtered_B0.mean.soil_moisture_error(:)];
            SMAPproduct_stacked.Filtered_B0.mean.vegetation_water_content=[SMAPproduct_stacked.Filtered_B0.mean.vegetation_water_content;SMAPproduct_atResolution.Filtered_B0.mean.vegetation_water_content(:)];
    
            %%% filtered based on third bit
    
            SMAPproduct_stacked.Filtered_B2.mean.latitude=[SMAPproduct_stacked.Filtered_B2.mean.latitude; SMAPproduct_atResolution.Filtered_B2.mean.latitude(:)];
            SMAPproduct_stacked.Filtered_B2.mean.longitude=[SMAPproduct_stacked.Filtered_B2.mean.longitude; SMAPproduct_atResolution.Filtered_B2.mean.longitude(:)];
            SMAPproduct_stacked.Filtered_B2.mean.roughness_coefficient=[SMAPproduct_stacked.Filtered_B2.mean.roughness_coefficient; SMAPproduct_atResolution.Filtered_B2.mean.roughness_coefficient(:)];
            SMAPproduct_stacked.Filtered_B2.mean.vegetation_opacity=[SMAPproduct_stacked.Filtered_B2.mean.vegetation_opacity; SMAPproduct_atResolution.Filtered_B2.mean.vegetation_opacity(:)];
            SMAPproduct_stacked.Filtered_B2.mean.soil_moisture=[SMAPproduct_stacked.Filtered_B2.mean.soil_moisture; SMAPproduct_atResolution.Filtered_B2.mean.soil_moisture(:)];
            SMAPproduct_stacked.Filtered_B2.mean.albedo=[SMAPproduct_stacked.Filtered_B2.mean.albedo;SMAPproduct_atResolution.Filtered_B2.mean.albedo(:)];
            SMAPproduct_stacked.Filtered_B2.mean.soil_moisture_error=[SMAPproduct_stacked.Filtered_B2.mean.soil_moisture_error; SMAPproduct_atResolution.Filtered_B2.mean.soil_moisture_error(:)];
            SMAPproduct_stacked.Filtered_B2.mean.vegetation_water_content=[SMAPproduct_stacked.Filtered_B2.mean.vegetation_water_content;SMAPproduct_atResolution.Filtered_B2.mean.vegetation_water_content(:)];
    
        end
    
    elseif SMAP_resolution==36
    
        if SMAPQualityFlagFilter=="no"
    
            SMAPproduct_stacked.latitude=[SMAPproduct_stacked.latitude; SMAPproduct_atResolution.latitude(:)];
            SMAPproduct_stacked.longitude=[SMAPproduct_stacked.longitude; SMAPproduct_atResolution.longitude(:)];
            SMAPproduct_stacked.roughness_coefficient=[SMAPproduct_stacked.roughness_coefficient; SMAPproduct_atResolution.roughness_coefficient(:)];
            SMAPproduct_stacked.vegetation_opacity=[SMAPproduct_stacked.vegetation_opacity; SMAPproduct_atResolution.vegetation_opacity(:)];
            SMAPproduct_stacked.soil_moisture=[SMAPproduct_stacked.soil_moisture; SMAPproduct_atResolution.soil_moisture(:)];
            SMAPproduct_stacked.albedo=[SMAPproduct_stacked.albedo;SMAPproduct_atResolution.albedo(:)];
            SMAPproduct_stacked.soil_moisture_error=[SMAPproduct_stacked.soil_moisture_error; SMAPproduct_atResolution.soil_moisture_error(:)];
            SMAPproduct_stacked.vegetation_water_content=[SMAPproduct_stacked.vegetation_water_content;SMAPproduct_atResolution.vegetation_water_content(:)];
    
        elseif SMAPQualityFlagFilter=="yes"
    
            SMAPproduct_stacked.Filtered_B0.latitude=[SMAPproduct_stacked.Filtered_B0.latitude; SMAPproduct_atResolution.Filtered_B0.latitude(:)];
            SMAPproduct_stacked.Filtered_B0.longitude=[SMAPproduct_stacked.Filtered_B0.longitude; SMAPproduct_atResolution.Filtered_B0.longitude(:)];
            SMAPproduct_stacked.Filtered_B0.roughness_coefficient=[SMAPproduct_stacked.Filtered_B0.roughness_coefficient; SMAPproduct_atResolution.Filtered_B0.roughness_coefficient(:)];
            SMAPproduct_stacked.Filtered_B0.vegetation_opacity=[SMAPproduct_stacked.Filtered_B0.vegetation_opacity; SMAPproduct_atResolution.Filtered_B0.vegetation_opacity(:)];
            SMAPproduct_stacked.Filtered_B0.soil_moisture=[SMAPproduct_stacked.Filtered_B0.soil_moisture; SMAPproduct_atResolution.Filtered_B0.soil_moisture(:)];
            SMAPproduct_stacked.Filtered_B0.albedo=[SMAPproduct_stacked.Filtered_B0.albedo;SMAPproduct_atResolution.Filtered_B0.albedo(:)];
            SMAPproduct_stacked.Filtered_B0.soil_moisture_error=[SMAPproduct_stacked.Filtered_B0.soil_moisture_error; SMAPproduct_atResolution.Filtered_B0.soil_moisture_error(:)];
            SMAPproduct_stacked.Filtered_B0.vegetation_water_content=[SMAPproduct_stacked.Filtered_B0.vegetation_water_content;SMAPproduct_atResolution.Filtered_B0.vegetation_water_content(:)];
    
            SMAPproduct_stacked.Filtered_B2.latitude=[SMAPproduct_stacked.Filtered_B2.latitude; SMAPproduct_atResolution.Filtered_B2.latitude(:)];
            SMAPproduct_stacked.Filtered_B2.longitude=[SMAPproduct_stacked.Filtered_B2.longitude; SMAPproduct_atResolution.Filtered_B2.longitude(:)];
            SMAPproduct_stacked.Filtered_B2.roughness_coefficient=[SMAPproduct_stacked.Filtered_B2.roughness_coefficient; SMAPproduct_atResolution.Filtered_B2.roughness_coefficient(:)];
            SMAPproduct_stacked.Filtered_B2.vegetation_opacity=[SMAPproduct_stacked.Filtered_B2.vegetation_opacity; SMAPproduct_atResolution.Filtered_B2.vegetation_opacity(:)];
            SMAPproduct_stacked.Filtered_B2.soil_moisture=[SMAPproduct_stacked.Filtered_B2.soil_moisture; SMAPproduct_atResolution.Filtered_B2.soil_moisture(:)];
            SMAPproduct_stacked.Filtered_B2.albedo=[SMAPproduct_stacked.Filtered_B2.albedo;SMAPproduct_atResolution.Filtered_B2.albedo(:)];
            SMAPproduct_stacked.Filtered_B2.soil_moisture_error=[SMAPproduct_stacked.Filtered_B2.soil_moisture_error; SMAPproduct_atResolution.Filtered_B2.soil_moisture_error(:)];
            SMAPproduct_stacked.Filtered_B2.vegetation_water_content=[SMAPproduct_stacked.Filtered_B2.vegetation_water_content;SMAPproduct_atResolution.Filtered_B2.vegetation_water_content(:)];
        end
    end
    %%%%%%

    if HydroGNSS_processing == "yes" % pre-process HydroGNSS data

        HydroGNSSproduct_GPS_atResolution = HydroGNSS_process(Target_Resolution, HydroGNSS_GPS_data, HydroGNSS_vars, doy, numcols, numrows);

        %%%%%%populating the HydroGNSS products
        for k=1:numel(HydroGNSS_vars) % initialize the varibales in the structure
            HydroGNSS_GPS_stacked.(string(HydroGNSS_vars(k))) = [HydroGNSS_GPS_stacked.(string(HydroGNSS_vars(k))); HydroGNSSproduct_GPS_atResolution.(string(HydroGNSS_vars(k)))];
        end

        HydroGNSSproduct_Galileo_atResolution = HydroGNSS_process(Target_Resolution, HydroGNSS_Galileo_data, HydroGNSS_vars, doy, numcols, numrows);

        %%%%%%populating the HydroGNSS products
        for k=1:numel(HydroGNSS_vars) % initialize the varibales in the structure
            HydroGNSS_Galileo_stacked.(string(HydroGNSS_vars(k))) = [HydroGNSS_Galileo_stacked.(string(HydroGNSS_vars(k))); HydroGNSSproduct_Galileo_atResolution.(string(HydroGNSS_vars(k)))];
        end


    end

end % end of reading all days

%%%%%%%%%%%%%% Masking to get all HydroGNSS data (at the moment only for 25km resolution) %%%%%%%%%%%%%%%
temp_days = HydroGNSS_Galileo_stacked.dayOfYear;
temp_days = temp_days(~isnan(temp_days));
temp_days = unique(temp_days);
firstDay = temp_days(1);
lastDay = temp_days(end);
nDays = lastDay-firstDay+1;

if HydroGNSS_processing=="yes"

    mask = load('LandMask_EASEgrid25km.mat');
    mask = repmat(mask.mask(:),nDays,1);
    idNaN = find(isnan(mask));

    for k=1:numel(HydroGNSS_vars) % masking the land based on land mask of EASE grid v2.0
        temp_GPS = HydroGNSS_GPS_stacked.(string(HydroGNSS_vars(k)));
        if string(HydroGNSS_vars(k))=="year"
           HydroGNSS_GPS_stacked.(string(HydroGNSS_vars(k))) = datae_yy;
        else
            temp_GPS(idNaN) = NaN;
            HydroGNSS_GPS_stacked.(string(HydroGNSS_vars(k))) = temp_GPS;
        end
    end

    for k=1:numel(HydroGNSS_vars) % masking the land based on land mask of EASE grid v2.0
        temp_Galileo = HydroGNSS_Galileo_stacked.(string(HydroGNSS_vars(k)));
        if string(HydroGNSS_vars(k))=="year"
           HydroGNSS_Galileo_stacked.(string(HydroGNSS_vars(k))) = datae_yy;
        else
            temp_Galileo(idNaN) = NaN;
            HydroGNSS_Galileo_stacked.(string(HydroGNSS_vars(k))) = temp_Galileo;
        end
    end
end





%%%%%% saving the products %%%%%%%
days = ['days' num2str(firstDay) 'to' num2str(lastDay)];
name=(product_path + '\collocated_data_Hydro' + num2str(datae_yy) + '_' + days + '_' + num2str(Target_Resolution) + 'km.mat');
save(name,'Target_Resolution', 'SMAPproduct_stacked', 'HydroGNSS_GPS_stacked', 'HydroGNSS_Galileo_stacked', '-v7.3');

end