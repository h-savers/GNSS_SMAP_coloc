function Combining(configurationPath)

%%%%%%%%%%%%%%%%%% reading configuration file %%%%%%%%%%%%%%%%%%
config = configFile.instance(configurationPath);

processMode = config.processMode; % This parameter determines that if we are following the previous approach (=1)
                                  % or the new one which is processing day by day (=2)

qfs = str2num(char(num2cell(char(config.SMAPQualityFlagFilter))));
qfs = reshape(qfs,1,[]);

SMAPQualityFlagFilter = config.SMAPQualityFlagFilter;

Target_Resolution = config.Target_Resolution;
smap_path = config.smap_path;
CyGNSS_processing = config.CyGNSS_processing; % if yes the CyGNSS data is also processed
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

if processMode==1
    files = dir(fullfile(smap_path, '*.h5'));
    
    if SMAP_resolution==9
        SMAPproduct_stacked.nearest.latitude=[];
        SMAPproduct_stacked.nearest.longitude=[];
        SMAPproduct_stacked.nearest.vegetation_opacity=[];
        SMAPproduct_stacked.nearest.roughness_coefficient=[];
        SMAPproduct_stacked.nearest.soil_moisture=[];
        SMAPproduct_stacked.nearest.soil_moisture_error=[];
        SMAPproduct_stacked.nearest.albedo=[];
        SMAPproduct_stacked.nearest.vegetation_water_content=[];

        SMAPproduct_stacked.mean.latitude=[];
        SMAPproduct_stacked.mean.longitude=[];
        SMAPproduct_stacked.mean.vegetation_opacity=[];
        SMAPproduct_stacked.mean.roughness_coefficient=[];
        SMAPproduct_stacked.mean.soil_moisture=[];
        SMAPproduct_stacked.mean.soil_moisture_error=[];
        SMAPproduct_stacked.mean.albedo=[];
        SMAPproduct_stacked.mean.vegetation_water_content=[];

    elseif SMAP_resolution==36
        SMAPproduct_stacked.latitude=[];
        SMAPproduct_stacked.longitude=[];
        SMAPproduct_stacked.vegetation_opacity=[];
        SMAPproduct_stacked.roughness_coefficient=[];
        SMAPproduct_stacked.soil_moisture=[];
        SMAPproduct_stacked.soil_moisture_error=[];
        SMAPproduct_stacked.albedo=[];
        SMAPproduct_stacked.vegetation_water_content=[];
    end
    
    
    if CyGNSS_processing=="yes" 
        cygnss_data = load(config.cygnss_file); %load data
        cygnss_vars = fieldnames(cygnss_data);
    
        CyGNSS_stacked=struct;
    
        for i=1:numel(cygnss_vars) % initialize the varibales in the structure
            CyGNSS_stacked.(string(cygnss_vars(i)))=[];
        end
    end
    
    
    for i=1:length(files)
        
        filename(i,:)=string(files(i).name);
        filesplit=strsplit(string(filename(i)),'_');
        d=(filesplit{1,5});
        file_path=fullfile(smap_path,'\',filename(i));
        datetosmap=datetime(d,'InputFormat','yyyyMMdd ','Format','yyyy.MM.dd');
        doy_s=day(datetosmap,'dayofyear');
        year=datestr(datetosmap, 'yyyy');
    
        SMAPproduct = SMAP_read(file_path, qfs, SMAP_resolution, SMAPQualityFlagFilter);% read SMAP data
        SMAPproduct_atResolution = SMAP_process(SMAPproduct, Target_Resolution, numcols, numrows, SMAP_resolution, sm_c, sm_r, SMAPQualityFlagFilter); % pre-process CyGNSS data
    
        %%%%%%populating the smap products
        if SMAP_resolution==9

            SMAPproduct_stacked.nearest.latitude=[SMAPproduct_stacked.nearest.latitude; SMAPproduct_atResolution.nearest.latitude(:)];
            SMAPproduct_stacked.nearest.longitude=[SMAPproduct_stacked.nearest.longitude; SMAPproduct_atResolution.nearest.longitude(:)];
            SMAPproduct_stacked.nearest.roughness_coefficient=[SMAPproduct_stacked.nearest.roughness_coefficient; SMAPproduct_atResolution.nearest.roughness_coefficient(:)];
            SMAPproduct_stacked.nearest.vegetation_opacity=[SMAPproduct_stacked.nearest.vegetation_opacity; SMAPproduct_atResolution.nearest.vegetation_opacity(:)];
            SMAPproduct_stacked.nearest.soil_moisture=[SMAPproduct_stacked.nearest.soil_moisture; SMAPproduct_atResolution.nearest.soil_moisture(:)];
            SMAPproduct_stacked.nearest.albedo=[SMAPproduct_stacked.nearest.albedo;SMAPproduct_atResolution.nearest.albedo(:)];
            SMAPproduct_stacked.nearest.soil_moisture_error=[SMAPproduct_stacked.nearest.soil_moisture_error; SMAPproduct_atResolution.nearest.soil_moisture_error(:)];
            SMAPproduct_stacked.nearest.vegetation_water_content=[SMAPproduct_stacked.nearest.vegetation_water_content;SMAPproduct_atResolution.nearest.vegetation_water_content(:)];

            SMAPproduct_stacked.mean.latitude=[SMAPproduct_stacked.mean.latitude; SMAPproduct_atResolution.mean.latitude(:)];
            SMAPproduct_stacked.mean.longitude=[SMAPproduct_stacked.mean.longitude; SMAPproduct_atResolution.mean.longitude(:)];
            SMAPproduct_stacked.mean.roughness_coefficient=[SMAPproduct_stacked.mean.roughness_coefficient; SMAPproduct_atResolution.mean.roughness_coefficient(:)];
            SMAPproduct_stacked.mean.vegetation_opacity=[SMAPproduct_stacked.mean.vegetation_opacity; SMAPproduct_atResolution.mean.vegetation_opacity(:)];
            SMAPproduct_stacked.mean.soil_moisture=[SMAPproduct_stacked.mean.soil_moisture; SMAPproduct_atResolution.mean.soil_moisture(:)];
            SMAPproduct_stacked.mean.albedo=[SMAPproduct_stacked.mean.albedo;SMAPproduct_atResolution.mean.albedo(:)];
            SMAPproduct_stacked.mean.soil_moisture_error=[SMAPproduct_stacked.mean.soil_moisture_error; SMAPproduct_atResolution.mean.soil_moisture_error(:)];
            SMAPproduct_stacked.mean.vegetation_water_content=[SMAPproduct_stacked.mean.vegetation_water_content;SMAPproduct_atResolution.mean.vegetation_water_content(:)];

        elseif SMAP_resolution==36

            SMAPproduct_stacked.latitude=[SMAPproduct_stacked.latitude; SMAPproduct_atResolution.latitude(:)];
            SMAPproduct_stacked.longitude=[SMAPproduct_stacked.longitude; SMAPproduct_atResolution.longitude(:)];
            SMAPproduct_stacked.roughness_coefficient=[SMAPproduct_stacked.roughness_coefficient; SMAPproduct_atResolution.roughness_coefficient(:)];
            SMAPproduct_stacked.vegetation_opacity=[SMAPproduct_stacked.vegetation_opacity; SMAPproduct_atResolution.vegetation_opacity(:)];
            SMAPproduct_stacked.soil_moisture=[SMAPproduct_stacked.soil_moisture; SMAPproduct_atResolution.soil_moisture(:)];
            SMAPproduct_stacked.albedo=[SMAPproduct_stacked.albedo;SMAPproduct_atResolution.albedo(:)];
            SMAPproduct_stacked.soil_moisture_error=[SMAPproduct_stacked.soil_moisture_error; SMAPproduct_atResolution.soil_moisture_error(:)];
            SMAPproduct_stacked.vegetation_water_content=[SMAPproduct_stacked.vegetation_water_content;SMAPproduct_atResolution.vegetation_water_content(:)];

        end
        %%%%%%
    
        if CyGNSS_processing == "yes" % pre-process CyGNSS data
            CyGNSSproduct_atResolution = CyGNSS_process_mode1(Target_Resolution, cygnss_data, cygnss_vars, doy_s, numcols, numrows);
        
        %%%%%%populating the cygnss products
            for k=1:numel(cygnss_vars) % initialize the varibales in the structure
                CyGNSS_stacked.(string(cygnss_vars(k))) = [CyGNSS_stacked.(string(cygnss_vars(k))); CyGNSSproduct_atResolution.(string(cygnss_vars(k)))];
            end
        
        end
    
    
    end % end of reading all days
    
    %%%%%%%%%%%%%% Masking to get all cygnss data (at the moment only for 25km resolution) %%%%%%%%%%%%%%%
    temp_days = CyGNSS_stacked.DoY;
    temp_days = temp_days(~isnan(temp_days));
    temp_days = unique(temp_days);
    firstDay = temp_days(1);
    lastDay = temp_days(end);
    nDyas = lastDay-firstDay+1;

    if CyGNSS_processing=="yes"

        mask = load('LandMask_EASEgrid25km.mat');
        mask = repmat(mask.mask(:),nDyas,1);
        idNaN = find(isnan(mask));
    
        for k=1:numel(cygnss_vars) % masking the land based on land mask of EASE grid v2.0
            temp = CyGNSS_stacked.(string(cygnss_vars(k)));
            temp(idNaN) = NaN;
            CyGNSS_stacked.(string(cygnss_vars(k))) = temp;
        end
    end


%_____________________________ Processing day by day _____________________________%
elseif processMode==2

    cygnss_path = config.cygnss_path;
    startDay = config.startDay;
    
    SampleDay = startDay; % justto use to initialize the cygnss product structure
    startDay = datetime(startDay, 'InputFormat', 'yyyyMMdd', 'Format', 'yyyy.MM.dd');
    endDay = config.endDay;
    endDay = datetime(endDay, 'InputFormat', 'yyyyMMdd', 'Format', 'yyyy.MM.dd');

    nDyas = daysact(startDay, endDay)+1;
    
% %     folders = dir(fullfile(smap_path));
% %     valid = ~ismember({folders.name}, {'.', '..'});
% %     validfolders = folders(valid);
% %     names = {validfolders.name};
% %     names = names';
% %     startID = find(names==startDay_str);% this is index of the day of the year for the start day in the files of smap directory

    if SMAP_resolution==9

        if SMAPQualityFlagFilter=="no"

            SMAPproduct_stacked.nearest.latitude=[];
            SMAPproduct_stacked.nearest.longitude=[];
            SMAPproduct_stacked.nearest.vegetation_opacity=[];
            SMAPproduct_stacked.nearest.roughness_coefficient=[];
            SMAPproduct_stacked.nearest.soil_moisture=[];
            SMAPproduct_stacked.nearest.soil_moisture_error=[];
            SMAPproduct_stacked.nearest.albedo=[];
            SMAPproduct_stacked.nearest.vegetation_water_content=[];
    
            SMAPproduct_stacked.mean.latitude=[];
            SMAPproduct_stacked.mean.longitude=[];
            SMAPproduct_stacked.mean.vegetation_opacity=[];
            SMAPproduct_stacked.mean.roughness_coefficient=[];
            SMAPproduct_stacked.mean.soil_moisture=[];
            SMAPproduct_stacked.mean.soil_moisture_error=[];
            SMAPproduct_stacked.mean.albedo=[];
            SMAPproduct_stacked.mean.vegetation_water_content=[];

        elseif SMAPQualityFlagFilter=="yes"

            SMAPproduct_stacked.Filtered_B0.nearest.latitude=[];
            SMAPproduct_stacked.Filtered_B0.nearest.longitude=[];
            SMAPproduct_stacked.Filtered_B0.nearest.vegetation_opacity=[];
            SMAPproduct_stacked.Filtered_B0.nearest.roughness_coefficient=[];
            SMAPproduct_stacked.Filtered_B0.nearest.soil_moisture=[];
            SMAPproduct_stacked.Filtered_B0.nearest.soil_moisture_error=[];
            SMAPproduct_stacked.Filtered_B0.nearest.albedo=[];
            SMAPproduct_stacked.Filtered_B0.nearest.vegetation_water_content=[];
    
            SMAPproduct_stacked.Filtered_B0.mean.latitude=[];
            SMAPproduct_stacked.Filtered_B0.mean.longitude=[];
            SMAPproduct_stacked.Filtered_B0.mean.vegetation_opacity=[];
            SMAPproduct_stacked.Filtered_B0.mean.roughness_coefficient=[];
            SMAPproduct_stacked.Filtered_B0.mean.soil_moisture=[];
            SMAPproduct_stacked.Filtered_B0.mean.soil_moisture_error=[];
            SMAPproduct_stacked.Filtered_B0.mean.albedo=[];
            SMAPproduct_stacked.Filtered_B0.mean.vegetation_water_content=[];


            SMAPproduct_stacked.Filtered_B2.nearest.latitude=[];
            SMAPproduct_stacked.Filtered_B2.nearest.longitude=[];
            SMAPproduct_stacked.Filtered_B2.nearest.vegetation_opacity=[];
            SMAPproduct_stacked.Filtered_B2.nearest.roughness_coefficient=[];
            SMAPproduct_stacked.Filtered_B2.nearest.soil_moisture=[];
            SMAPproduct_stacked.Filtered_B2.nearest.soil_moisture_error=[];
            SMAPproduct_stacked.Filtered_B2.nearest.albedo=[];
            SMAPproduct_stacked.Filtered_B2.nearest.vegetation_water_content=[];
    
            SMAPproduct_stacked.Filtered_B2.mean.latitude=[];
            SMAPproduct_stacked.Filtered_B2.mean.longitude=[];
            SMAPproduct_stacked.Filtered_B2.mean.vegetation_opacity=[];
            SMAPproduct_stacked.Filtered_B2.mean.roughness_coefficient=[];
            SMAPproduct_stacked.Filtered_B2.mean.soil_moisture=[];
            SMAPproduct_stacked.Filtered_B2.mean.soil_moisture_error=[];
            SMAPproduct_stacked.Filtered_B2.mean.albedo=[];
            SMAPproduct_stacked.Filtered_B2.mean.vegetation_water_content=[];

        end

    elseif SMAP_resolution==36
        SMAPproduct_stacked.latitude=[];
        SMAPproduct_stacked.longitude=[];
        SMAPproduct_stacked.vegetation_opacity=[];
        SMAPproduct_stacked.roughness_coefficient=[];
        SMAPproduct_stacked.soil_moisture=[];
        SMAPproduct_stacked.soil_moisture_error=[];
        SMAPproduct_stacked.albedo=[];
        SMAPproduct_stacked.vegetation_water_content=[];
    end
    
    
    if CyGNSS_processing=="yes"  % just load a cygnss data as a sample to initialize the structure of output product


        cygnss_file = strjoin([cygnss_path,'\',SampleDay,'_extended.mat'], '');
        cygnss_data = load(cygnss_file, 'DDM_NBRCS', 'EIRP', 'IndexDC', ...
                'KURTOSIS', 'KURTOSIS_DOPP_0', 'QC', 'SNR', 'SPLAT', ...
                'SPLON', 'THETA', 'DoY', 'TE_WIDTH', 'REFLECTIVITY_LINEAR', 'SS_r', 'PHI_Initial_sp_az_orbit', 'NF'); %load data
        cygnss_vars = fieldnames(cygnss_data);
    
        CyGNSS_stacked=struct;
    
        for i=1:numel(cygnss_vars) % initialize the varibales in the structure
            CyGNSS_stacked.(string(cygnss_vars(i)))=[];
        end
        CyGNSS_stacked.negative_reflects_num = [];
    end
    

    valid_dates = startDay:endDay;

    for i=1:nDyas
        
        
        disp(['day : ' datestr(valid_dates(i))]);

        folder_path = fullfile(smap_path, string(valid_dates(i)), '\');
        files = dir(fullfile(folder_path, '*.h5'));
        file_name = files.name;
        file_path=fullfile(folder_path, '\', file_name);
        
        SMAPproduct = SMAP_read(file_path, qfs, SMAP_resolution, SMAPQualityFlagFilter);% read SMAP data
        SMAPproduct_atResolution = SMAP_process(SMAPproduct, Target_Resolution, numcols, numrows, SMAP_resolution, sm_c, sm_r, SMAPQualityFlagFilter); % pre-process CyGNSS data
    
        %%%%%%populating the smap products
        if SMAP_resolution==9
            
            if SMAPQualityFlagFilter=="no"
            
                %%% filtered based on first bit
                SMAPproduct_stacked.nearest.latitude=[SMAPproduct_stacked.nearest.latitude; SMAPproduct_atResolution.nearest.latitude(:)];
                SMAPproduct_stacked.nearest.longitude=[SMAPproduct_stacked.nearest.longitude; SMAPproduct_atResolution.nearest.longitude(:)];
                SMAPproduct_stacked.nearest.roughness_coefficient=[SMAPproduct_stacked.nearest.roughness_coefficient; SMAPproduct_atResolution.nearest.roughness_coefficient(:)];
                SMAPproduct_stacked.nearest.vegetation_opacity=[SMAPproduct_stacked.nearest.vegetation_opacity; SMAPproduct_atResolution.nearest.vegetation_opacity(:)];
                SMAPproduct_stacked.nearest.soil_moisture=[SMAPproduct_stacked.nearest.soil_moisture; SMAPproduct_atResolution.nearest.soil_moisture(:)];
                SMAPproduct_stacked.nearest.albedo=[SMAPproduct_stacked.nearest.albedo;SMAPproduct_atResolution.nearest.albedo(:)];
                SMAPproduct_stacked.nearest.soil_moisture_error=[SMAPproduct_stacked.nearest.soil_moisture_error; SMAPproduct_atResolution.nearest.soil_moisture_error(:)];
                SMAPproduct_stacked.nearest.vegetation_water_content=[SMAPproduct_stacked.nearest.vegetation_water_content;SMAPproduct_atResolution.nearest.vegetation_water_content(:)];
    
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
                SMAPproduct_stacked.Filtered_B0.nearest.latitude=[SMAPproduct_stacked.Filtered_B0.nearest.latitude; SMAPproduct_atResolution.Filtered_B0.nearest.latitude(:)];
                SMAPproduct_stacked.Filtered_B0.nearest.longitude=[SMAPproduct_stacked.Filtered_B0.nearest.longitude; SMAPproduct_atResolution.Filtered_B0.nearest.longitude(:)];
                SMAPproduct_stacked.Filtered_B0.nearest.roughness_coefficient=[SMAPproduct_stacked.Filtered_B0.nearest.roughness_coefficient; SMAPproduct_atResolution.Filtered_B0.nearest.roughness_coefficient(:)];
                SMAPproduct_stacked.Filtered_B0.nearest.vegetation_opacity=[SMAPproduct_stacked.Filtered_B0.nearest.vegetation_opacity; SMAPproduct_atResolution.Filtered_B0.nearest.vegetation_opacity(:)];
                SMAPproduct_stacked.Filtered_B0.nearest.soil_moisture=[SMAPproduct_stacked.Filtered_B0.nearest.soil_moisture; SMAPproduct_atResolution.Filtered_B0.nearest.soil_moisture(:)];
                SMAPproduct_stacked.Filtered_B0.nearest.albedo=[SMAPproduct_stacked.Filtered_B0.nearest.albedo;SMAPproduct_atResolution.Filtered_B0.nearest.albedo(:)];
                SMAPproduct_stacked.Filtered_B0.nearest.soil_moisture_error=[SMAPproduct_stacked.Filtered_B0.nearest.soil_moisture_error; SMAPproduct_atResolution.Filtered_B0.nearest.soil_moisture_error(:)];
                SMAPproduct_stacked.Filtered_B0.nearest.vegetation_water_content=[SMAPproduct_stacked.Filtered_B0.nearest.vegetation_water_content;SMAPproduct_atResolution.Filtered_B0.nearest.vegetation_water_content(:)];
    
                SMAPproduct_stacked.Filtered_B0.mean.latitude=[SMAPproduct_stacked.Filtered_B0.mean.latitude; SMAPproduct_atResolution.Filtered_B0.mean.latitude(:)];
                SMAPproduct_stacked.Filtered_B0.mean.longitude=[SMAPproduct_stacked.Filtered_B0.mean.longitude; SMAPproduct_atResolution.Filtered_B0.mean.longitude(:)];
                SMAPproduct_stacked.Filtered_B0.mean.roughness_coefficient=[SMAPproduct_stacked.Filtered_B0.mean.roughness_coefficient; SMAPproduct_atResolution.Filtered_B0.mean.roughness_coefficient(:)];
                SMAPproduct_stacked.Filtered_B0.mean.vegetation_opacity=[SMAPproduct_stacked.Filtered_B0.mean.vegetation_opacity; SMAPproduct_atResolution.Filtered_B0.mean.vegetation_opacity(:)];
                SMAPproduct_stacked.Filtered_B0.mean.soil_moisture=[SMAPproduct_stacked.Filtered_B0.mean.soil_moisture; SMAPproduct_atResolution.Filtered_B0.mean.soil_moisture(:)];
                SMAPproduct_stacked.Filtered_B0.mean.albedo=[SMAPproduct_stacked.Filtered_B0.mean.albedo;SMAPproduct_atResolution.Filtered_B0.mean.albedo(:)];
                SMAPproduct_stacked.Filtered_B0.mean.soil_moisture_error=[SMAPproduct_stacked.Filtered_B0.mean.soil_moisture_error; SMAPproduct_atResolution.Filtered_B0.mean.soil_moisture_error(:)];
                SMAPproduct_stacked.Filtered_B0.mean.vegetation_water_content=[SMAPproduct_stacked.Filtered_B0.mean.vegetation_water_content;SMAPproduct_atResolution.Filtered_B0.mean.vegetation_water_content(:)];

                %%% filtered based on third bit
                SMAPproduct_stacked.Filtered_B2.nearest.latitude=[SMAPproduct_stacked.Filtered_B2.nearest.latitude; SMAPproduct_atResolution.Filtered_B2.nearest.latitude(:)];
                SMAPproduct_stacked.Filtered_B2.nearest.longitude=[SMAPproduct_stacked.Filtered_B2.nearest.longitude; SMAPproduct_atResolution.Filtered_B2.nearest.longitude(:)];
                SMAPproduct_stacked.Filtered_B2.nearest.roughness_coefficient=[SMAPproduct_stacked.Filtered_B2.nearest.roughness_coefficient; SMAPproduct_atResolution.Filtered_B2.nearest.roughness_coefficient(:)];
                SMAPproduct_stacked.Filtered_B2.nearest.vegetation_opacity=[SMAPproduct_stacked.Filtered_B2.nearest.vegetation_opacity; SMAPproduct_atResolution.Filtered_B2.nearest.vegetation_opacity(:)];
                SMAPproduct_stacked.Filtered_B2.nearest.soil_moisture=[SMAPproduct_stacked.Filtered_B2.nearest.soil_moisture; SMAPproduct_atResolution.Filtered_B2.nearest.soil_moisture(:)];
                SMAPproduct_stacked.Filtered_B2.nearest.albedo=[SMAPproduct_stacked.Filtered_B2.nearest.albedo;SMAPproduct_atResolution.Filtered_B2.nearest.albedo(:)];
                SMAPproduct_stacked.Filtered_B2.nearest.soil_moisture_error=[SMAPproduct_stacked.Filtered_B2.nearest.soil_moisture_error; SMAPproduct_atResolution.Filtered_B2.nearest.soil_moisture_error(:)];
                SMAPproduct_stacked.Filtered_B2.nearest.vegetation_water_content=[SMAPproduct_stacked.Filtered_B2.nearest.vegetation_water_content;SMAPproduct_atResolution.Filtered_B2.nearest.vegetation_water_content(:)];
    
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

            SMAPproduct_stacked.latitude=[SMAPproduct_stacked.latitude; SMAPproduct_atResolution.latitude(:)];
            SMAPproduct_stacked.longitude=[SMAPproduct_stacked.longitude; SMAPproduct_atResolution.longitude(:)];
            SMAPproduct_stacked.roughness_coefficient=[SMAPproduct_stacked.roughness_coefficient; SMAPproduct_atResolution.roughness_coefficient(:)];
            SMAPproduct_stacked.vegetation_opacity=[SMAPproduct_stacked.vegetation_opacity; SMAPproduct_atResolution.vegetation_opacity(:)];
            SMAPproduct_stacked.soil_moisture=[SMAPproduct_stacked.soil_moisture; SMAPproduct_atResolution.soil_moisture(:)];
            SMAPproduct_stacked.albedo=[SMAPproduct_stacked.albedo;SMAPproduct_atResolution.albedo(:)];
            SMAPproduct_stacked.soil_moisture_error=[SMAPproduct_stacked.soil_moisture_error; SMAPproduct_atResolution.soil_moisture_error(:)];
            SMAPproduct_stacked.vegetation_water_content=[SMAPproduct_stacked.vegetation_water_content;SMAPproduct_atResolution.vegetation_water_content(:)];

        end
        %%%%%%

        if CyGNSS_processing == "yes" % pre-process CyGNSS data

            datee = datetime(valid_dates(i), 'InputFormat', 'yyyy.MM.dd', 'Format', 'yyyyMMdd');
            cygnss_file = strjoin([cygnss_path,'\',string(datee),'_extended.mat'], '');
            cygnss_data = load(cygnss_file, 'DDM_NBRCS', 'EIRP', 'IndexDC', ...
                'KURTOSIS', 'KURTOSIS_DOPP_0', 'QC', 'SNR', 'SPLAT', ...
                'SPLON', 'THETA', 'DoY', 'TE_WIDTH', 'REFLECTIVITY_LINEAR', 'SS_r', 'PHI_Initial_sp_az_orbit', 'NF'); %load data
            cygnss_vars = fieldnames(cygnss_data);


            CyGNSSproduct_atResolution = CyGNSS_process_mode2(Target_Resolution, cygnss_data, cygnss_vars, numcols, numrows);

            %%%%%%populating the cygnss products
            for k=1:numel(cygnss_vars) % initialize the varibales in the structure
                CyGNSS_stacked.(string(cygnss_vars(k))) = [CyGNSS_stacked.(string(cygnss_vars(k))); CyGNSSproduct_atResolution.(string(cygnss_vars(k)))];
            end
            CyGNSS_stacked.negative_reflects_num = [CyGNSS_stacked.negative_reflects_num, CyGNSSproduct_atResolution.negative_reflects_num];
        end

    end
    %%%%%%%%%%%%%% Masking to get all cygnss data (at the moment only for 25km resolution) %%%%%%%%%%%%%%%
    startYear = datestr(startDay, 'yyyy');
    endYear = datestr(endDay, 'yyyy');
    if startYear==endYear
        year = startYear;
    else
        year = [startYear, '&', endYear];
    end
    firstDay = day(startDay,'dayofyear');
    lastDay = day(endDay,'dayofyear');

    if CyGNSS_processing=="yes"

        mask = load('LandMask_EASEgrid25km.mat');
        mask = repmat(mask.mask(:),nDyas,1);
        idNaN = find(isnan(mask));
    
        for k=1:numel(cygnss_vars) % masking the land based on land mask of EASE grid v2.0
            
            if size(CyGNSS_stacked.(string(cygnss_vars(k))),1)==nDyas*numrows*numcols
                temp = CyGNSS_stacked.(string(cygnss_vars(k)));
                temp(idNaN) = NaN;
                CyGNSS_stacked.(string(cygnss_vars(k))) = temp;
            end
        end
    end


end


%%%%%% saving the products %%%%%%%
days = ['days' num2str(firstDay) 'to' num2str(lastDay)];
name=(product_path + '\collocateddata_SS_check' + num2str(year) + '_' + days + '_' + num2str(Target_Resolution) + '.mat');
save(name,'Target_Resolution', 'SMAPproduct_stacked', 'CyGNSS_stacked', '-v7.3');

end