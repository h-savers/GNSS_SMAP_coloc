function Combining_Hydro(configurationPath)
    
    %%%%%%%%%%%%%%%%%% reading configuration file %%%%%%%%%%%%%%%%%%
    config = configFile_Hydro.instance(configurationPath);
    
    qfs = str2num(char(num2cell(char(config.SMAPQualityFlagFilter))));
    qfs = reshape(qfs,1,[]);
    
    SMAPQualityFlagFilter = config.SMAPQualityFlagFilter;
    
    Target_Resolution = config.Target_Resolution;
    smap_path = config.smap_path;
    modis_path = config.modis_path;
    smos_path = config.smos_path;
    HydroGNSS_processing = config.hydro_processing; % if yes the HydroGNSS data is also processed
    product_path = config.product_path;
    SMAP_resolution = config.SMAP_resolution;
    
    %%% preparing row/col from lat/lon for accumarray for 25km resolution
    %%% SMAP
    load("LatLon_SMAP_9km.mat");
    [longitude_a2, latitude_a2] = meshgrid(longitude_a, latitude_a);
    [sm_c,sm_r]=easeconv_grid(latitude_a2,longitude_a2,25);
    %%%
    %%% MODIS
    load("lat_lon_modis.mat")
    lon_modis=lon_modis+0.025;lat_modis=lat_modis-0.025;
    lat_modis((lat_modis>=85))=85;lat_modis(lat_modis<=-85)=-85;
    lat_modis=repmat(lat_modis,[1,7200]);
    lon_modis=repmat(lon_modis,[3600,1]);
    [modis_c,modis_r]=easeconv_grid(lat_modis,lon_modis,25);
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
    
    MODISproduct_stacked.Modis_ndvi = [];
    MODISproduct_stacked.Modis_ndwi = [];
    MODISproduct_stacked.Modis_LST_ave = [];
    MODISproduct_stacked.Modis_LST_dif = [];
    MODISproduct_stacked.Modis_ndvi_full_map = [];
    MODISproduct_stacked.Modis_ndwi_full_map = [];
    MODISproduct_stacked.Modis_LST_ave_full_map = [];
    MODISproduct_stacked.Modis_LST_dif_full_map = [];
    
    SMOSproduct_stacked.soil_moisture = [];
    SMOSproduct_stacked.soil_moisture_full_map = [];
    
    if HydroGNSS_processing=="yes"
        HydroGNSS_data = load(config.hydro_file); %load data

        SixHourDir = HydroGNSS_data.SixHourDir;
        constellation = HydroGNSS_data.constellation;
        id_GPS=find(constellation=="GPS");
        id_Galileo=find(constellation=="Galileo");

        HydroGNSS_data = rmfield(HydroGNSS_data, 'constellation');
        HydroGNSS_data = rmfield(HydroGNSS_data, 'SixHourDir');
        HydroGNSS_vars = fieldnames(HydroGNSS_data);

        %%% GPS-only and Galileo-only views: same data with the other
        %%% constellation's rows blanked out (NaN/NaT). The merged
        %%% HydroGNSS_data keeps every row.
        HydroGNSS_GPS_data     = HydroGNSS_data;
        HydroGNSS_Galileo_data = HydroGNSS_data;

        %%% Sparse in-loop storage: only non-NaN values are kept.
        %%% flat_index = linear cell index into the numcols-by-numrows EASE map.
        %%% day_id     = 1..nDays of the source day for the record.
        %%% block_id   = 1..4 of the 6-hour block (1=H00, 2=H06, 3=H12, 4=H18).
        %%% These three bookkeeping vectors are shared across all variables of
        %%% a given product (combined / GPS-only / Galileo-only) because every
        %%% variable in a 6-hour block shares the same valid-cell set
        %%% (defined by ~isnan(specularPointLat) after gridding).
        %%% They are discarded before saving; the .mat output format is unchanged.
        HydroGNSS_stacked         = struct;
        HydroGNSS_GPS_stacked     = struct;
        HydroGNSS_Galileo_stacked = struct;
        HydroGNSS_stacked.flat_index         = uint32([]);
        HydroGNSS_stacked.day_id             = uint16([]);
        HydroGNSS_stacked.block_id           = uint8([]);
        HydroGNSS_GPS_stacked.flat_index     = uint32([]);
        HydroGNSS_GPS_stacked.day_id         = uint16([]);
        HydroGNSS_GPS_stacked.block_id       = uint8([]);
        HydroGNSS_Galileo_stacked.flat_index = uint32([]);
        HydroGNSS_Galileo_stacked.day_id     = uint16([]);
        HydroGNSS_Galileo_stacked.block_id   = uint8([]);
        for i=1:numel(HydroGNSS_vars)
            HydroGNSS_stacked.(string(HydroGNSS_vars(i)))         = [];
            HydroGNSS_GPS_stacked.(string(HydroGNSS_vars(i)))     = [];
            HydroGNSS_Galileo_stacked.(string(HydroGNSS_vars(i))) = [];

            if HydroGNSS_vars(i)=="timeUTC"
                HydroGNSS_GPS_data.(string(HydroGNSS_vars(i)))(id_Galileo)=NaT;
                HydroGNSS_Galileo_data.(string(HydroGNSS_vars(i)))(id_GPS)=NaT;
            else
                HydroGNSS_GPS_data.(string(HydroGNSS_vars(i)))(id_Galileo)=NaN;
                HydroGNSS_Galileo_data.(string(HydroGNSS_vars(i)))(id_GPS)=NaN;
            end
        end

        % ---------- masking ----------
        % % suffixes = ["_1_L","_5_L"];
        suffixes ="_1_L";

        seaMask=load('D:\Hamed\SML2OP\Auxiliary_Data\SEA_MASK_20240212.mat', 'SEA_MASK_25km');
        seaMask=seaMask.SEA_MASK_25km;

        HydroGNSS_data         = apply_general_filter(HydroGNSS_data,         suffixes, seaMask);
        HydroGNSS_GPS_data     = apply_general_filter(HydroGNSS_GPS_data,     suffixes, seaMask);
        HydroGNSS_Galileo_data = apply_general_filter(HydroGNSS_Galileo_data, suffixes, seaMask);

        %%% convert SNR to linear before gridding
        HydroGNSS_data.SNR_1_L = 10.^(HydroGNSS_data.SNR_1_L/10);
        HydroGNSS_data.SNR_1_R = 10.^(HydroGNSS_data.SNR_1_R/10);
        HydroGNSS_data.SNR_5_L = 10.^(HydroGNSS_data.SNR_5_L/10);
        HydroGNSS_data.SNR_5_R = 10.^(HydroGNSS_data.SNR_5_R/10);

        HydroGNSS_GPS_data.SNR_1_L = 10.^(HydroGNSS_GPS_data.SNR_1_L/10);
        HydroGNSS_GPS_data.SNR_1_R = 10.^(HydroGNSS_GPS_data.SNR_1_R/10);
        HydroGNSS_GPS_data.SNR_5_L = 10.^(HydroGNSS_GPS_data.SNR_5_L/10);
        HydroGNSS_GPS_data.SNR_5_R = 10.^(HydroGNSS_GPS_data.SNR_5_R/10);

        HydroGNSS_Galileo_data.SNR_1_L = 10.^(HydroGNSS_Galileo_data.SNR_1_L/10);
        HydroGNSS_Galileo_data.SNR_1_R = 10.^(HydroGNSS_Galileo_data.SNR_1_R/10);
        HydroGNSS_Galileo_data.SNR_5_L = 10.^(HydroGNSS_Galileo_data.SNR_5_L/10);
        HydroGNSS_Galileo_data.SNR_5_R = 10.^(HydroGNSS_Galileo_data.SNR_5_R/10);
        %%%

    end

    hours = ["H00", "H06", "H12", "H18"];
    
    %%% Pre-load the two days before startDay so the first iteration can
    %%% gap-fill MODIS / SMAP VWC,VOD / SM_full_map from D-1 and D-2.
    %%% Use integer day subtraction (avoids shadowing by the local `days`
    %%% string assigned later in this file).
    prev2 = process_one_day(valid_dates(1) - 2, smos_path, modis_path, smap_path, ...
        Target_Resolution, modis_c, modis_r, qfs, SMAP_resolution, ...
        SMAPQualityFlagFilter, numcols, numrows, sm_c, sm_r);
    prev1 = process_one_day(valid_dates(1) - 1, smos_path, modis_path, smap_path, ...
        Target_Resolution, modis_c, modis_r, qfs, SMAP_resolution, ...
        SMAPQualityFlagFilter, numcols, numrows, sm_c, sm_r);
    
    for i=1:nDays
    
        disp(['day : ' datestr(valid_dates(i))]);
    
        detail_date = datevec(valid_dates(i));
        doy = day(valid_dates(i),'dayofyear');
        datae_yy = detail_date(:,1);
    
        %%%%% process current day (SMOS + MODIS + SMAP)
        current = process_one_day(valid_dates(i), smos_path, modis_path, smap_path, ...
            Target_Resolution, modis_c, modis_r, qfs, SMAP_resolution, ...
            SMAPQualityFlagFilter, numcols, numrows, sm_c, sm_r);
        SMOSproduct_atResolution  = current.SMOS;
        MODISproduct_atResolution = current.MODIS;
        SMAPproduct_atResolution  = current.SMAP;
    
        %%%%% smos stacking (orig + gap-filled from D-1, D-2)
        SMOSproduct_stacked.soil_moisture = [SMOSproduct_stacked.soil_moisture; SMOSproduct_atResolution.soil_moisture];
        SMOSproduct_stacked.soil_moisture_full_map = [SMOSproduct_stacked.soil_moisture_full_map; ...
            coalesce3(SMOSproduct_atResolution.soil_moisture, prev1.SMOS.soil_moisture, prev2.SMOS.soil_moisture)];
    
        %%%%% modis stacking (orig + gap-filled from D-1, D-2)
        MODISproduct_stacked.Modis_ndvi    = [MODISproduct_stacked.Modis_ndvi;    MODISproduct_atResolution.Modis_ndvi];
        MODISproduct_stacked.Modis_ndwi    = [MODISproduct_stacked.Modis_ndwi;    MODISproduct_atResolution.Modis_ndwi];
        MODISproduct_stacked.Modis_LST_ave = [MODISproduct_stacked.Modis_LST_ave; MODISproduct_atResolution.Modis_LST_ave];
        MODISproduct_stacked.Modis_LST_dif = [MODISproduct_stacked.Modis_LST_dif; MODISproduct_atResolution.Modis_LST_dif];
        MODISproduct_stacked.Modis_ndvi_full_map    = [MODISproduct_stacked.Modis_ndvi_full_map;    coalesce3(MODISproduct_atResolution.Modis_ndvi,    prev1.MODIS.Modis_ndvi,    prev2.MODIS.Modis_ndvi)];
        MODISproduct_stacked.Modis_ndwi_full_map    = [MODISproduct_stacked.Modis_ndwi_full_map;    coalesce3(MODISproduct_atResolution.Modis_ndwi,    prev1.MODIS.Modis_ndwi,    prev2.MODIS.Modis_ndwi)];
        MODISproduct_stacked.Modis_LST_ave_full_map = [MODISproduct_stacked.Modis_LST_ave_full_map; coalesce3(MODISproduct_atResolution.Modis_LST_ave, prev1.MODIS.Modis_LST_ave, prev2.MODIS.Modis_LST_ave)];
        MODISproduct_stacked.Modis_LST_dif_full_map = [MODISproduct_stacked.Modis_LST_dif_full_map; coalesce3(MODISproduct_atResolution.Modis_LST_dif, prev1.MODIS.Modis_LST_dif, prev2.MODIS.Modis_LST_dif)];
    
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
    
                %%% gap-filled (D, D-1, D-2) for soil_moisture, vegetation_opacity, vegetation_water_content
                SMAPproduct_stacked.mean.soil_moisture_full_map           = [SMAPproduct_stacked.mean.soil_moisture_full_map;           coalesce3(SMAPproduct_atResolution.mean.soil_moisture,           prev1.SMAP.mean.soil_moisture,           prev2.SMAP.mean.soil_moisture)];
                SMAPproduct_stacked.mean.vegetation_opacity_full_map      = [SMAPproduct_stacked.mean.vegetation_opacity_full_map;      coalesce3(SMAPproduct_atResolution.mean.vegetation_opacity,      prev1.SMAP.mean.vegetation_opacity,      prev2.SMAP.mean.vegetation_opacity)];
                SMAPproduct_stacked.mean.vegetation_water_content_full_map= [SMAPproduct_stacked.mean.vegetation_water_content_full_map;coalesce3(SMAPproduct_atResolution.mean.vegetation_water_content,prev1.SMAP.mean.vegetation_water_content,prev2.SMAP.mean.vegetation_water_content)];
    
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
    
                %%% gap-filled (D, D-1, D-2) — B0
                SMAPproduct_stacked.Filtered_B0.mean.soil_moisture_full_map           = [SMAPproduct_stacked.Filtered_B0.mean.soil_moisture_full_map;           coalesce3(SMAPproduct_atResolution.Filtered_B0.mean.soil_moisture,           prev1.SMAP.Filtered_B0.mean.soil_moisture,           prev2.SMAP.Filtered_B0.mean.soil_moisture)];
                SMAPproduct_stacked.Filtered_B0.mean.vegetation_opacity_full_map      = [SMAPproduct_stacked.Filtered_B0.mean.vegetation_opacity_full_map;      coalesce3(SMAPproduct_atResolution.Filtered_B0.mean.vegetation_opacity,      prev1.SMAP.Filtered_B0.mean.vegetation_opacity,      prev2.SMAP.Filtered_B0.mean.vegetation_opacity)];
                SMAPproduct_stacked.Filtered_B0.mean.vegetation_water_content_full_map= [SMAPproduct_stacked.Filtered_B0.mean.vegetation_water_content_full_map;coalesce3(SMAPproduct_atResolution.Filtered_B0.mean.vegetation_water_content,prev1.SMAP.Filtered_B0.mean.vegetation_water_content,prev2.SMAP.Filtered_B0.mean.vegetation_water_content)];
    
                %%% filtered based on third bit
    
                SMAPproduct_stacked.Filtered_B2.mean.latitude=[SMAPproduct_stacked.Filtered_B2.mean.latitude; SMAPproduct_atResolution.Filtered_B2.mean.latitude(:)];
                SMAPproduct_stacked.Filtered_B2.mean.longitude=[SMAPproduct_stacked.Filtered_B2.mean.longitude; SMAPproduct_atResolution.Filtered_B2.mean.longitude(:)];
                SMAPproduct_stacked.Filtered_B2.mean.roughness_coefficient=[SMAPproduct_stacked.Filtered_B2.mean.roughness_coefficient; SMAPproduct_atResolution.Filtered_B2.mean.roughness_coefficient(:)];
                SMAPproduct_stacked.Filtered_B2.mean.vegetation_opacity=[SMAPproduct_stacked.Filtered_B2.mean.vegetation_opacity; SMAPproduct_atResolution.Filtered_B2.mean.vegetation_opacity(:)];
                SMAPproduct_stacked.Filtered_B2.mean.soil_moisture=[SMAPproduct_stacked.Filtered_B2.mean.soil_moisture; SMAPproduct_atResolution.Filtered_B2.mean.soil_moisture(:)];
                SMAPproduct_stacked.Filtered_B2.mean.albedo=[SMAPproduct_stacked.Filtered_B2.mean.albedo;SMAPproduct_atResolution.Filtered_B2.mean.albedo(:)];
                SMAPproduct_stacked.Filtered_B2.mean.soil_moisture_error=[SMAPproduct_stacked.Filtered_B2.mean.soil_moisture_error; SMAPproduct_atResolution.Filtered_B2.mean.soil_moisture_error(:)];
                SMAPproduct_stacked.Filtered_B2.mean.vegetation_water_content=[SMAPproduct_stacked.Filtered_B2.mean.vegetation_water_content;SMAPproduct_atResolution.Filtered_B2.mean.vegetation_water_content(:)];
    
                %%% gap-filled (D, D-1, D-2) — B2
                SMAPproduct_stacked.Filtered_B2.mean.soil_moisture_full_map           = [SMAPproduct_stacked.Filtered_B2.mean.soil_moisture_full_map;           coalesce3(SMAPproduct_atResolution.Filtered_B2.mean.soil_moisture,           prev1.SMAP.Filtered_B2.mean.soil_moisture,           prev2.SMAP.Filtered_B2.mean.soil_moisture)];
                SMAPproduct_stacked.Filtered_B2.mean.vegetation_opacity_full_map      = [SMAPproduct_stacked.Filtered_B2.mean.vegetation_opacity_full_map;      coalesce3(SMAPproduct_atResolution.Filtered_B2.mean.vegetation_opacity,      prev1.SMAP.Filtered_B2.mean.vegetation_opacity,      prev2.SMAP.Filtered_B2.mean.vegetation_opacity)];
                SMAPproduct_stacked.Filtered_B2.mean.vegetation_water_content_full_map= [SMAPproduct_stacked.Filtered_B2.mean.vegetation_water_content_full_map;coalesce3(SMAPproduct_atResolution.Filtered_B2.mean.vegetation_water_content,prev1.SMAP.Filtered_B2.mean.vegetation_water_content,prev2.SMAP.Filtered_B2.mean.vegetation_water_content)];
    
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
    
                %%% gap-filled (D, D-1, D-2)
                SMAPproduct_stacked.soil_moisture_full_map           = [SMAPproduct_stacked.soil_moisture_full_map;           coalesce3(SMAPproduct_atResolution.soil_moisture,           prev1.SMAP.soil_moisture,           prev2.SMAP.soil_moisture)];
                SMAPproduct_stacked.vegetation_opacity_full_map      = [SMAPproduct_stacked.vegetation_opacity_full_map;      coalesce3(SMAPproduct_atResolution.vegetation_opacity,      prev1.SMAP.vegetation_opacity,      prev2.SMAP.vegetation_opacity)];
                SMAPproduct_stacked.vegetation_water_content_full_map= [SMAPproduct_stacked.vegetation_water_content_full_map;coalesce3(SMAPproduct_atResolution.vegetation_water_content,prev1.SMAP.vegetation_water_content,prev2.SMAP.vegetation_water_content)];
    
            elseif SMAPQualityFlagFilter=="yes"
        
                SMAPproduct_stacked.Filtered_B0.latitude=[SMAPproduct_stacked.Filtered_B0.latitude; SMAPproduct_atResolution.Filtered_B0.latitude(:)];
                SMAPproduct_stacked.Filtered_B0.longitude=[SMAPproduct_stacked.Filtered_B0.longitude; SMAPproduct_atResolution.Filtered_B0.longitude(:)];
                SMAPproduct_stacked.Filtered_B0.roughness_coefficient=[SMAPproduct_stacked.Filtered_B0.roughness_coefficient; SMAPproduct_atResolution.Filtered_B0.roughness_coefficient(:)];
                SMAPproduct_stacked.Filtered_B0.vegetation_opacity=[SMAPproduct_stacked.Filtered_B0.vegetation_opacity; SMAPproduct_atResolution.Filtered_B0.vegetation_opacity(:)];
                SMAPproduct_stacked.Filtered_B0.soil_moisture=[SMAPproduct_stacked.Filtered_B0.soil_moisture; SMAPproduct_atResolution.Filtered_B0.soil_moisture(:)];
                SMAPproduct_stacked.Filtered_B0.albedo=[SMAPproduct_stacked.Filtered_B0.albedo;SMAPproduct_atResolution.Filtered_B0.albedo(:)];
                SMAPproduct_stacked.Filtered_B0.soil_moisture_error=[SMAPproduct_stacked.Filtered_B0.soil_moisture_error; SMAPproduct_atResolution.Filtered_B0.soil_moisture_error(:)];
                SMAPproduct_stacked.Filtered_B0.vegetation_water_content=[SMAPproduct_stacked.Filtered_B0.vegetation_water_content;SMAPproduct_atResolution.Filtered_B0.vegetation_water_content(:)];
    
                %%% gap-filled (D, D-1, D-2) — B0
                SMAPproduct_stacked.Filtered_B0.soil_moisture_full_map           = [SMAPproduct_stacked.Filtered_B0.soil_moisture_full_map;           coalesce3(SMAPproduct_atResolution.Filtered_B0.soil_moisture,           prev1.SMAP.Filtered_B0.soil_moisture,           prev2.SMAP.Filtered_B0.soil_moisture)];
                SMAPproduct_stacked.Filtered_B0.vegetation_opacity_full_map      = [SMAPproduct_stacked.Filtered_B0.vegetation_opacity_full_map;      coalesce3(SMAPproduct_atResolution.Filtered_B0.vegetation_opacity,      prev1.SMAP.Filtered_B0.vegetation_opacity,      prev2.SMAP.Filtered_B0.vegetation_opacity)];
                SMAPproduct_stacked.Filtered_B0.vegetation_water_content_full_map= [SMAPproduct_stacked.Filtered_B0.vegetation_water_content_full_map;coalesce3(SMAPproduct_atResolution.Filtered_B0.vegetation_water_content,prev1.SMAP.Filtered_B0.vegetation_water_content,prev2.SMAP.Filtered_B0.vegetation_water_content)];
    
                SMAPproduct_stacked.Filtered_B2.latitude=[SMAPproduct_stacked.Filtered_B2.latitude; SMAPproduct_atResolution.Filtered_B2.latitude(:)];
                SMAPproduct_stacked.Filtered_B2.longitude=[SMAPproduct_stacked.Filtered_B2.longitude; SMAPproduct_atResolution.Filtered_B2.longitude(:)];
                SMAPproduct_stacked.Filtered_B2.roughness_coefficient=[SMAPproduct_stacked.Filtered_B2.roughness_coefficient; SMAPproduct_atResolution.Filtered_B2.roughness_coefficient(:)];
                SMAPproduct_stacked.Filtered_B2.vegetation_opacity=[SMAPproduct_stacked.Filtered_B2.vegetation_opacity; SMAPproduct_atResolution.Filtered_B2.vegetation_opacity(:)];
                SMAPproduct_stacked.Filtered_B2.soil_moisture=[SMAPproduct_stacked.Filtered_B2.soil_moisture; SMAPproduct_atResolution.Filtered_B2.soil_moisture(:)];
                SMAPproduct_stacked.Filtered_B2.albedo=[SMAPproduct_stacked.Filtered_B2.albedo;SMAPproduct_atResolution.Filtered_B2.albedo(:)];
                SMAPproduct_stacked.Filtered_B2.soil_moisture_error=[SMAPproduct_stacked.Filtered_B2.soil_moisture_error; SMAPproduct_atResolution.Filtered_B2.soil_moisture_error(:)];
                SMAPproduct_stacked.Filtered_B2.vegetation_water_content=[SMAPproduct_stacked.Filtered_B2.vegetation_water_content;SMAPproduct_atResolution.Filtered_B2.vegetation_water_content(:)];
    
                %%% gap-filled (D, D-1, D-2) — B2
                SMAPproduct_stacked.Filtered_B2.soil_moisture_full_map           = [SMAPproduct_stacked.Filtered_B2.soil_moisture_full_map;           coalesce3(SMAPproduct_atResolution.Filtered_B2.soil_moisture,           prev1.SMAP.Filtered_B2.soil_moisture,           prev2.SMAP.Filtered_B2.soil_moisture)];
                SMAPproduct_stacked.Filtered_B2.vegetation_opacity_full_map      = [SMAPproduct_stacked.Filtered_B2.vegetation_opacity_full_map;      coalesce3(SMAPproduct_atResolution.Filtered_B2.vegetation_opacity,      prev1.SMAP.Filtered_B2.vegetation_opacity,      prev2.SMAP.Filtered_B2.vegetation_opacity)];
                SMAPproduct_stacked.Filtered_B2.vegetation_water_content_full_map= [SMAPproduct_stacked.Filtered_B2.vegetation_water_content_full_map;coalesce3(SMAPproduct_atResolution.Filtered_B2.vegetation_water_content,prev1.SMAP.Filtered_B2.vegetation_water_content,prev2.SMAP.Filtered_B2.vegetation_water_content)];
            end
        end
        %%%%%%
    
        if HydroGNSS_processing == "yes" % pre-process HydroGNSS data
    
            datePattern = string(valid_dates(i), "yyyy-MM") + "\" + string(valid_dates(i), "dd");
    
            %%% Sparse stacking: for each 6-hour block of each product, find
            %%% the cells that received any observation (defined by
            %%% ~isnan(specularPointLat) after gridding) and append only those
            %%% values plus shared bookkeeping (flat_index, day_id, block_id).
            %%% Three views are gridded in parallel: combined (GPS+Galileo),
            %%% GPS-only, and Galileo-only. The dense (nDays*nCells)x4
            %%% layout per variable is restored at save time.
            for h = 1:numel(hours) %%% loop over 6 hour blocks

                targetPattern = datePattern + "\" + hours(h);
                idx_6hour = find(SixHourDir == targetPattern);

                % Grid this 6-hour block. Empty blocks return a full NaN grid
                % from HydroGNSS_process; the valid-cell sets below will be
                % empty and nothing gets appended for that block.
                HydroGNSSproduct_atResolution = HydroGNSS_process( ...
                Target_Resolution, HydroGNSS_data, HydroGNSS_vars, idx_6hour, numcols, numrows);

                HydroGNSSproduct_GPS_atResolution = HydroGNSS_process( ...
                Target_Resolution, HydroGNSS_GPS_data, HydroGNSS_vars, idx_6hour, numcols, numrows);

                HydroGNSSproduct_Galileo_atResolution = HydroGNSS_process( ...
                Target_Resolution, HydroGNSS_Galileo_data, HydroGNSS_vars, idx_6hour, numcols, numrows);

                %%% convert SNR to dB after gridding
                HydroGNSSproduct_atResolution.SNR_1_L = 10*log10(HydroGNSSproduct_atResolution.SNR_1_L);
                HydroGNSSproduct_atResolution.SNR_1_R = 10*log10(HydroGNSSproduct_atResolution.SNR_1_R);
                HydroGNSSproduct_atResolution.SNR_5_L = 10*log10(HydroGNSSproduct_atResolution.SNR_5_L);
                HydroGNSSproduct_atResolution.SNR_5_R = 10*log10(HydroGNSSproduct_atResolution.SNR_5_R);

                HydroGNSSproduct_GPS_atResolution.SNR_1_L = 10*log10(HydroGNSSproduct_GPS_atResolution.SNR_1_L);
                HydroGNSSproduct_GPS_atResolution.SNR_1_R = 10*log10(HydroGNSSproduct_GPS_atResolution.SNR_1_R);
                HydroGNSSproduct_GPS_atResolution.SNR_5_L = 10*log10(HydroGNSSproduct_GPS_atResolution.SNR_5_L);
                HydroGNSSproduct_GPS_atResolution.SNR_5_R = 10*log10(HydroGNSSproduct_GPS_atResolution.SNR_5_R);

                HydroGNSSproduct_Galileo_atResolution.SNR_1_L = 10*log10(HydroGNSSproduct_Galileo_atResolution.SNR_1_L);
                HydroGNSSproduct_Galileo_atResolution.SNR_1_R = 10*log10(HydroGNSSproduct_Galileo_atResolution.SNR_1_R);
                HydroGNSSproduct_Galileo_atResolution.SNR_5_L = 10*log10(HydroGNSSproduct_Galileo_atResolution.SNR_5_L);
                HydroGNSSproduct_Galileo_atResolution.SNR_5_R = 10*log10(HydroGNSSproduct_Galileo_atResolution.SNR_5_R);

                %%% find valid cells per product (shared across vars within a product)
                valid_all = uint32(find(~isnan(HydroGNSSproduct_atResolution.specularPointLat)));
                valid_GPS = uint32(find(~isnan(HydroGNSSproduct_GPS_atResolution.specularPointLat)));
                valid_GAL = uint32(find(~isnan(HydroGNSSproduct_Galileo_atResolution.specularPointLat)));

                n_all = numel(valid_all);
                n_GPS = numel(valid_GPS);
                n_GAL = numel(valid_GAL);

                %%% append bookkeeping
                HydroGNSS_stacked.flat_index = [HydroGNSS_stacked.flat_index; valid_all];
                HydroGNSS_stacked.day_id     = [HydroGNSS_stacked.day_id;     repmat(uint16(i), n_all, 1)];
                HydroGNSS_stacked.block_id   = [HydroGNSS_stacked.block_id;   repmat(uint8(h),  n_all, 1)];

                HydroGNSS_GPS_stacked.flat_index = [HydroGNSS_GPS_stacked.flat_index; valid_GPS];
                HydroGNSS_GPS_stacked.day_id     = [HydroGNSS_GPS_stacked.day_id;     repmat(uint16(i), n_GPS, 1)];
                HydroGNSS_GPS_stacked.block_id   = [HydroGNSS_GPS_stacked.block_id;   repmat(uint8(h),  n_GPS, 1)];

                HydroGNSS_Galileo_stacked.flat_index = [HydroGNSS_Galileo_stacked.flat_index; valid_GAL];
                HydroGNSS_Galileo_stacked.day_id     = [HydroGNSS_Galileo_stacked.day_id;     repmat(uint16(i), n_GAL, 1)];
                HydroGNSS_Galileo_stacked.block_id   = [HydroGNSS_Galileo_stacked.block_id;   repmat(uint8(h),  n_GAL, 1)];

                %%% append only valid values per variable (shared index per product)
                for k = 1:numel(HydroGNSS_vars)
                    varName = string(HydroGNSS_vars(k));
                    v_all = HydroGNSSproduct_atResolution.(varName);
                    v_GPS = HydroGNSSproduct_GPS_atResolution.(varName);
                    v_GAL = HydroGNSSproduct_Galileo_atResolution.(varName);
                    HydroGNSS_stacked.(varName)         = [HydroGNSS_stacked.(varName);         v_all(valid_all)];
                    HydroGNSS_GPS_stacked.(varName)     = [HydroGNSS_GPS_stacked.(varName);     v_GPS(valid_GPS)];
                    HydroGNSS_Galileo_stacked.(varName) = [HydroGNSS_Galileo_stacked.(varName); v_GAL(valid_GAL)];
                end
            end
        end
    
        %%% rotate the gap-fill buffer: today becomes yesterday, yesterday becomes day-before
        prev2 = prev1;
        prev1 = current;
    
    end % end of reading all days
    
    %%%%%%%%%%%%%% Masking to get all HydroGNSS data (at the moment only for 25km resolution) %%%%%%%%%%%%%%%
    if HydroGNSS_processing=="yes"

        mask = load('LandMask_EASEgrid25km.mat');
        mask = mask.mask';
        ocean_lin = uint32(find(isnan(mask(:))));   % linear cell indices that are ocean

        %%% Drop sparse records whose flat_index falls on ocean cells.
        %%% Filter once per product (combined / GPS / Galileo), then subset
        %%% every per-variable value vector with the same logical mask.
        product_names = {'HydroGNSS_stacked', 'HydroGNSS_GPS_stacked', 'HydroGNSS_Galileo_stacked'};
        for p = 1:numel(product_names)
            pn = product_names{p};
            S  = eval(pn);
            keep = ~ismember(S.flat_index, ocean_lin);

            S.flat_index = S.flat_index(keep);
            S.day_id     = S.day_id(keep);
            S.block_id   = S.block_id(keep);
            for k = 1:numel(HydroGNSS_vars)
                vn = string(HydroGNSS_vars(k));
                if vn == "year"
                    S.(vn) = datae_yy;
                else
                    v = S.(vn);
                    S.(vn) = v(keep);
                end
            end

            % write back
            switch pn
                case 'HydroGNSS_stacked',         HydroGNSS_stacked         = S;
                case 'HydroGNSS_GPS_stacked',     HydroGNSS_GPS_stacked     = S;
                case 'HydroGNSS_Galileo_stacked', HydroGNSS_Galileo_stacked = S;
            end
            clear S
        end
    end
    
    firstDay = day(startDay, 'dayofyear');
    lastDay = day(endDay, 'dayofyear');
    
    %%%%%% saving the products %%%%%%%
    days = ['days' num2str(firstDay) 'to' num2str(lastDay)];
    name=(product_path + '\collocated_data_HydroGNSS_' + num2str(datae_yy) + '_' + days + '_' + num2str(Target_Resolution) + 'km_GPS&Galileo.mat');

    %%% Stream the output as a v7.3 matfile so we never need all three
    %%% reconstructed dense products in RAM simultaneously. SMAP/SMOS/MODIS
    %%% go in as-is; each HydroGNSS product is rebuilt one variable at a
    %%% time and the sparse store for that product is cleared right after.
    if exist(name, 'file'); delete(name); end
    m = matfile(name, 'Writable', true);
    m.Target_Resolution    = Target_Resolution;
    m.hours                = hours;
    m.SMAPproduct_stacked  = SMAPproduct_stacked;
    m.SMOSproduct_stacked  = SMOSproduct_stacked;
    m.MODISproduct_stacked = MODISproduct_stacked;

    if HydroGNSS_processing=="yes"
        nCells = numcols*numrows;
        nRows  = nDays * nCells;

        product_names = {'HydroGNSS_stacked', 'HydroGNSS_GPS_stacked', 'HydroGNSS_Galileo_stacked'};
        for p = 1:numel(product_names)
            pn = product_names{p};
            switch pn
                case 'HydroGNSS_stacked',         S = HydroGNSS_stacked;
                case 'HydroGNSS_GPS_stacked',     S = HydroGNSS_GPS_stacked;
                case 'HydroGNSS_Galileo_stacked', S = HydroGNSS_Galileo_stacked;
            end

            % precompute the global (row, col) of every sparse record
            global_row = (double(S.day_id) - 1) * nCells + double(S.flat_index);
            col_ix     = double(S.block_id);
            lin        = sub2ind([nRows, 4], global_row, col_ix);

            % build the dense struct one variable at a time
            out = struct;
            for k = 1:numel(HydroGNSS_vars)
                vn = string(HydroGNSS_vars(k));
                if vn == "year"
                    out.(vn) = datae_yy;
                else
                    dense = NaN(nRows, 4);
                    dense(lin) = S.(vn);
                    out.(vn) = dense;
                    clear dense
                end
            end

            m.(pn) = out;
            clear out S

            % free the sparse store for this product immediately
            switch pn
                case 'HydroGNSS_stacked',         HydroGNSS_stacked         = [];
                case 'HydroGNSS_GPS_stacked',     HydroGNSS_GPS_stacked     = [];
                case 'HydroGNSS_Galileo_stacked', HydroGNSS_Galileo_stacked = [];
            end
        end
    end

end


%%% Local helpers
function out = process_one_day(d, smos_path, modis_path, smap_path, ...
    Target_Resolution, modis_c, modis_r, qfs, SMAP_resolution, ...
    SMAPQualityFlagFilter, numcols, numrows, sm_c, sm_r)
    % Run the SMOS/MODIS/SMAP daily pipelines for date d and return all three
    % gridded products in one struct. Used both for the current day in the
    % main loop and for pre-loading the two prior days that feed the
    % _full_map gap-fill.
    
    dv = datevec(d);
    yy = dv(1); mm = dv(2); dd = dv(3);
    
    % --- SMOS ---
    folder_path_smos = fullfile(smos_path, string(yy), string(mm), string(dd));
    files = dir(fullfile(folder_path_smos, '*.nc'));
    file_name_smos_a = '';
    file_name_smos_d = '';
    for k = 1:numel(files)
        name = files(k).name;
        if contains(name, 'CLF31A')
            file_name_smos_a = name;
        elseif contains(name, 'CLF31D')
            file_name_smos_d = name;
        end
    end
    file_path_smos_a = fullfile(folder_path_smos, file_name_smos_a);
    file_path_smos_d = fullfile(folder_path_smos, file_name_smos_d);
    out.SMOS = SMOS_process(file_path_smos_a, file_path_smos_d);
    
    % --- MODIS ---
    folder_path_MOD09CMG = fullfile(modis_path, 'MOD09CMG', string(yy), string(mm), string(dd));
    files_MOD09CMG = dir(fullfile(folder_path_MOD09CMG, '*.hdf'));
    file_path_MOD09CMG = fullfile(folder_path_MOD09CMG, files_MOD09CMG.name);
    
    folder_path_MOD11C1 = fullfile(modis_path, 'MOD11C1', string(yy), string(mm), string(dd));
    files_MOD11C1 = dir(fullfile(folder_path_MOD11C1, '*.hdf'));
    file_path_MOD11C1 = fullfile(folder_path_MOD11C1, files_MOD11C1.name);
    
    out.MODIS = MODIS_process(file_path_MOD09CMG, file_path_MOD11C1, Target_Resolution, modis_c, modis_r);
    
    % --- SMAP ---
    folder_path_smap = fullfile(smap_path, string(yy), string(mm), string(dd));
    files_smap = dir(fullfile(folder_path_smap, '*.h5'));
    if numel(files_smap) > 1
        % Multiple SMAP granules for the same day (e.g. *_001.h5 and *_002.h5).
        % Pick the one with the highest trailing _NNN suffix before .h5.
        suffixes = zeros(numel(files_smap), 1);
        for k = 1:numel(files_smap)
            tok = regexp(files_smap(k).name, '_(\d+)\.h5$', 'tokens', 'once');
            if ~isempty(tok)
                suffixes(k) = str2double(tok{1});
            end
        end
        [~, ix] = max(suffixes);
        files_smap = files_smap(ix);
    end
    file_path_smap = fullfile(folder_path_smap, files_smap.name);
    
    SMAPraw  = SMAP_read(file_path_smap, qfs, SMAP_resolution, SMAPQualityFlagFilter);
    out.SMAP = SMAP_process(SMAPraw, Target_Resolution, numcols, numrows, SMAP_resolution, sm_c, sm_r, SMAPQualityFlagFilter);
end


function v = coalesce3(a, b, c)
    % Per-pixel coalesce: start from a, fill NaNs from b, then from c.
    % Inputs may be any shape; output is a column vector.
    v = a(:);
    b = b(:);
    c = c(:);
    m = isnan(v); v(m) = b(m);
    m = isnan(v); v(m) = c(m);
end