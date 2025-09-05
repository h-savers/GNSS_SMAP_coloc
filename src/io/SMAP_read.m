function SMAPproduct=SMAP_read(file_path, qfs, SMAP_resolution, SMAPQualityFlagFilter)

if SMAP_resolution==36
    IN_COLS=964;
    IN_ROWS=406;
elseif SMAP_resolution==9
    IN_COLS=3856;
    IN_ROWS=1624;
end

%%%% creating the quality flag mask %%%%

% % quality_flagAM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/retrieval_qual_flag');
% % flipped_quality_flagAM = flip(quality_flagAM);
% % quality_flagAM_mask = uint16(zeros(IN_COLS, IN_ROWS));
% % for m=1:length(qfs)
% %     flag = uint16(qfs(length(qfs) + 1 - m) * 2^(m-1));
% %     tmp_qf = uint16(zeros(IN_COLS, IN_ROWS));
% %     tmp_qf(bitand(flipped_quality_flagAM, flag) > 0) = 1;
% %     quality_flagAM_mask = bitor(quality_flagAM_mask, tmp_qf);
% % end
% %
% % quality_flagPM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/retrieval_qual_flag_dca_pm');
% % flipped_quality_flagPM = flip(quality_flagPM);
% % quality_flagPM_mask = uint16(zeros(IN_COLS, IN_ROWS));
% % for m=1:length(qfs)
% %     flag = uint16(qfs(length(qfs) + 1 - m) * 2^(m-1));
% %     tmp_qf = uint16(zeros(IN_COLS, IN_ROWS));
% %     tmp_qf(bitand(flipped_quality_flagPM, flag) > 0) = 1;
% %     quality_flagPM_mask = bitor(quality_flagPM_mask, tmp_qf);
% % end


if SMAPQualityFlagFilter=="yes"

    quality_flagAM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/retrieval_qual_flag');
    quality_flagAM_mask_B0 = bitget(quality_flagAM, 1); % Recommended Quality % 0: Soil moisture retrieval has recommended quality
                                                                              % 1: Soil moisture retrieval doesn%t have recommended quality
    quality_flagAM_mask_B2 = bitget(quality_flagAM, 3); % Retrieval Successful % 0: Soil moisture retrieval was successful
                                                                               % 1: Soil moisture retrieval was not successful
    
    quality_flagPM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/retrieval_qual_flag_dca_pm');
    quality_flagPM_mask_B0 = bitget(quality_flagPM, 1); % Recommended Quality % 0: Soil moisture retrieval has recommended quality
                                                                              % 1: Soil moisture retrieval doesn%t have recommended quality
    quality_flagPM_mask_B2 = bitget(quality_flagPM, 3); % Retrieval Successful % 0: Soil moisture retrieval was successful
                                                                               % 1: Soil moisture retrieval was not successful
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% reading variables and apply the quality flag mask %%%%

if SMAPQualityFlagFilter=="no"
    soil_moistureAM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/soil_moisture');
    soil_moisturePM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/soil_moisture_dca_pm');
    soil_moisture(:, :, 1) = soil_moistureAM';
    soil_moisture(:, :, 2) = soil_moisturePM';
    soil_moisture(soil_moisture == -9999) = NaN;
    soil_moisture = mean(soil_moisture, 3, "omitnan");
    SMAPproduct.soil_moisture = soil_moisture;
    
    latitudeAM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/latitude');
    latitudePM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/latitude_pm');
    latitude(:, :, 1) = latitudeAM';
    latitude(:, :, 2) = latitudePM';
    latitude(latitude == -9999) = nan;
    latitude = mean(latitude, 3, "omitnan");
    SMAPproduct.latitude = latitude;
    
    longitudeAM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/longitude'); 
    longitudePM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/longitude_pm');
    longitude(:, :, 1) = longitudeAM';
    longitude(:, :, 2) = longitudePM';
    longitude(longitude == -9999) = nan;
    longitude = mean(longitude, 3, "omitnan");
    SMAPproduct.longitude = longitude;
    
    vegetation_water_contentAM=h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/vegetation_water_content');
    vegetation_water_contentPM=h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/vegetation_water_content_pm');
    vegetation_water_content(:,:,1)=vegetation_water_contentAM';
    vegetation_water_content(:,:,2)=vegetation_water_contentPM';
    vegetation_water_content(vegetation_water_content == -9999) = NaN;
    vegetation_water_content = mean(vegetation_water_content, 3, "omitnan");
    SMAPproduct.vegetation_water_content = vegetation_water_content;
    
    roughness_coefficientAM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/roughness_coefficient');
    roughness_coefficientPM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/roughness_coefficient_pm');
    roughness_coefficient(:, :, 1) = roughness_coefficientAM';
    roughness_coefficient(:, :, 2) = roughness_coefficientPM';
    roughness_coefficient(roughness_coefficient == -9999) = NaN;
    roughness_coefficient = mean(roughness_coefficient, 3, "omitnan");
    SMAPproduct.roughness_coefficient = roughness_coefficient;
    
    albedoAM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/albedo');
    albedoPM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/albedo_pm');
    albedo(:,:,1) = albedoAM';
    albedo(:,:,2) = albedoPM';
    albedo(albedo == -9999) = NaN;
    albedo = mean(albedo, 3, "omitnan");
    SMAPproduct.albedo = albedo;
    
    soil_moisture_errorAM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/soil_moisture_error');
    soil_moisture_errorPM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/soil_moisture_error_pm');
    soil_moisture_error(:, :, 1) = soil_moisture_errorAM';
    soil_moisture_error(:, :, 2) = soil_moisture_errorPM';
    soil_moisture_error(soil_moisture_error == -9999) = nan;
    soil_moisture_error = mean(soil_moisture_error, 3, "omitnan");
    SMAPproduct.soil_moisture_error = soil_moisture_error;
    
    
    vegetation_opacityAM=h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/vegetation_opacity');
    vegetation_opacityPM=h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/vegetation_opacity_dca_pm');
    vegetation_opacity(:,:,1)=vegetation_opacityAM';
    vegetation_opacity(:,:,2)=vegetation_opacityPM';
    vegetation_opacity(vegetation_opacity == -9999) = NaN;
    vegetation_opacity = mean(vegetation_opacity, 3, "omitnan");
    SMAPproduct.vegetation_opacity = vegetation_opacity;


elseif SMAPQualityFlagFilter=="yes"

    %%% filtering based on first bit
    
    soil_moistureAM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/soil_moisture');
    soil_moistureAM(find(quality_flagAM_mask_B0==1)) = NaN;
    soil_moisturePM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/soil_moisture_dca_pm');
    soil_moisturePM(find(quality_flagPM_mask_B0==1)) = NaN;    
    soil_moisture(:, :, 1) = soil_moistureAM';
    soil_moisture(:, :, 2) = soil_moisturePM';
    soil_moisture(soil_moisture == -9999) = NaN;
    soil_moisture = mean(soil_moisture, 3, "omitnan");
    SMAPproduct.Filtered_B0.soil_moisture = soil_moisture;
    
    latitudeAM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/latitude');
    latitudeAM(find(quality_flagAM_mask_B0==1)) = NaN;
    latitudePM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/latitude_pm');
    latitudePM(find(quality_flagPM_mask_B0==1)) = NaN;
    latitude(:, :, 1) = latitudeAM';
    latitude(:, :, 2) = latitudePM';
    latitude(latitude == -9999) = nan;
    latitude = mean(latitude, 3, "omitnan");
    SMAPproduct.Filtered_B0.latitude = latitude;
    
    longitudeAM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/longitude');
    longitudeAM(find(quality_flagAM_mask_B0==1)) = NaN;
    longitudePM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/longitude_pm');
    longitudePM(find(quality_flagPM_mask_B0==1)) = NaN;
    longitude(:, :, 1) = longitudeAM';
    longitude(:, :, 2) = longitudePM';
    longitude(longitude == -9999) = nan;
    longitude = mean(longitude, 3, "omitnan");
    SMAPproduct.Filtered_B0.longitude = longitude;
    
    vegetation_water_contentAM=h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/vegetation_water_content');
    vegetation_water_contentAM(find(quality_flagAM_mask_B0==1)) = NaN;
    vegetation_water_contentPM=h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/vegetation_water_content_pm');
    vegetation_water_contentPM(find(quality_flagPM_mask_B0==1)) = NaN;
    vegetation_water_content(:,:,1)=vegetation_water_contentAM';
    vegetation_water_content(:,:,2)=vegetation_water_contentPM';
    vegetation_water_content(vegetation_water_content == -9999) = NaN;
    vegetation_water_content = mean(vegetation_water_content, 3, "omitnan");
    SMAPproduct.Filtered_B0.vegetation_water_content = vegetation_water_content;
    
    roughness_coefficientAM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/roughness_coefficient');
    roughness_coefficientAM(find(quality_flagAM_mask_B0==1)) = NaN;
    roughness_coefficientPM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/roughness_coefficient_pm');
    roughness_coefficientPM(find(quality_flagPM_mask_B0==1)) = NaN;
    roughness_coefficient(:, :, 1) = roughness_coefficientAM';
    roughness_coefficient(:, :, 2) = roughness_coefficientPM';
    roughness_coefficient(roughness_coefficient == -9999) = NaN;
    roughness_coefficient = mean(roughness_coefficient, 3, "omitnan");
    SMAPproduct.Filtered_B0.roughness_coefficient = roughness_coefficient;
    
    albedoAM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/albedo');
    albedoAM(find(quality_flagAM_mask_B0==1)) = NaN;
    albedoPM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/albedo_pm');
    albedoPM(find(quality_flagPM_mask_B0==1)) = NaN;
    albedo(:,:,1) = albedoAM';
    albedo(:,:,2) = albedoPM';
    albedo(albedo == -9999) = NaN;
    albedo = mean(albedo, 3, "omitnan");
    SMAPproduct.Filtered_B0.albedo = albedo;
    
    soil_moisture_errorAM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/soil_moisture_error');
    soil_moisture_errorAM(find(quality_flagAM_mask_B0==1)) = NaN;
    soil_moisture_errorPM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/soil_moisture_error_pm');
    soil_moisture_errorPM(find(quality_flagPM_mask_B0==1)) = NaN;
    soil_moisture_error(:, :, 1) = soil_moisture_errorAM';
    soil_moisture_error(:, :, 2) = soil_moisture_errorPM';
    soil_moisture_error(soil_moisture_error == -9999) = nan;
    soil_moisture_error = mean(soil_moisture_error, 3, "omitnan");
    SMAPproduct.Filtered_B0.soil_moisture_error = soil_moisture_error;
    
    
    vegetation_opacityAM=h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/vegetation_opacity');
    vegetation_opacityAM(find(quality_flagAM_mask_B0==1)) = NaN;
    vegetation_opacityPM=h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/vegetation_opacity_dca_pm');
    vegetation_opacityPM(find(quality_flagPM_mask_B0==1)) = NaN;
    vegetation_opacity(:,:,1)=vegetation_opacityAM';
    vegetation_opacity(:,:,2)=vegetation_opacityPM';
    vegetation_opacity(vegetation_opacity == -9999) = NaN;
    vegetation_opacity = mean(vegetation_opacity, 3, "omitnan");
    SMAPproduct.Filtered_B0.vegetation_opacity = vegetation_opacity;


    %%% filtering based on third bit
    
    soil_moistureAM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/soil_moisture');
    soil_moistureAM(find(quality_flagAM_mask_B2==1)) = NaN;
    soil_moisturePM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/soil_moisture_dca_pm');
    soil_moisturePM(find(quality_flagPM_mask_B2==1)) = NaN;    
    soil_moisture(:, :, 1) = soil_moistureAM';
    soil_moisture(:, :, 2) = soil_moisturePM';
    soil_moisture(soil_moisture == -9999) = NaN;
    soil_moisture = mean(soil_moisture, 3, "omitnan");
    SMAPproduct.Filtered_B2.soil_moisture = soil_moisture;
    
    latitudeAM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/latitude');
    latitudeAM(find(quality_flagAM_mask_B2==1)) = NaN;
    latitudePM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/latitude_pm');
    latitudePM(find(quality_flagPM_mask_B2==1)) = NaN;
    latitude(:, :, 1) = latitudeAM';
    latitude(:, :, 2) = latitudePM';
    latitude(latitude == -9999) = nan;
    latitude = mean(latitude, 3, "omitnan");
    SMAPproduct.Filtered_B2.latitude = latitude;
    
    longitudeAM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/longitude');
    longitudeAM(find(quality_flagAM_mask_B2==1)) = NaN;
    longitudePM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/longitude_pm');
    longitudePM(find(quality_flagPM_mask_B2==1)) = NaN;
    longitude(:, :, 1) = longitudeAM';
    longitude(:, :, 2) = longitudePM';
    longitude(longitude == -9999) = nan;
    longitude = mean(longitude, 3, "omitnan");
    SMAPproduct.Filtered_B2.longitude = longitude;
    
    vegetation_water_contentAM=h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/vegetation_water_content');
    vegetation_water_contentAM(find(quality_flagAM_mask_B2==1)) = NaN;
    vegetation_water_contentPM=h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/vegetation_water_content_pm');
    vegetation_water_contentPM(find(quality_flagPM_mask_B2==1)) = NaN;
    vegetation_water_content(:,:,1)=vegetation_water_contentAM';
    vegetation_water_content(:,:,2)=vegetation_water_contentPM';
    vegetation_water_content(vegetation_water_content == -9999) = NaN;
    vegetation_water_content = mean(vegetation_water_content, 3, "omitnan");
    SMAPproduct.Filtered_B2.vegetation_water_content = vegetation_water_content;
    
    roughness_coefficientAM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/roughness_coefficient');
    roughness_coefficientAM(find(quality_flagAM_mask_B2==1)) = NaN;
    roughness_coefficientPM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/roughness_coefficient_pm');
    roughness_coefficientPM(find(quality_flagPM_mask_B2==1)) = NaN;
    roughness_coefficient(:, :, 1) = roughness_coefficientAM';
    roughness_coefficient(:, :, 2) = roughness_coefficientPM';
    roughness_coefficient(roughness_coefficient == -9999) = NaN;
    roughness_coefficient = mean(roughness_coefficient, 3, "omitnan");
    SMAPproduct.Filtered_B2.roughness_coefficient = roughness_coefficient;
    
    albedoAM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/albedo');
    albedoAM(find(quality_flagAM_mask_B2==1)) = NaN;
    albedoPM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/albedo_pm');
    albedoPM(find(quality_flagPM_mask_B2==1)) = NaN;
    albedo(:,:,1) = albedoAM';
    albedo(:,:,2) = albedoPM';
    albedo(albedo == -9999) = NaN;
    albedo = mean(albedo, 3, "omitnan");
    SMAPproduct.Filtered_B2.albedo = albedo;
    
    soil_moisture_errorAM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/soil_moisture_error');
    soil_moisture_errorAM(find(quality_flagAM_mask_B2==1)) = NaN;
    soil_moisture_errorPM = h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/soil_moisture_error_pm');
    soil_moisture_errorPM(find(quality_flagPM_mask_B2==1)) = NaN;
    soil_moisture_error(:, :, 1) = soil_moisture_errorAM';
    soil_moisture_error(:, :, 2) = soil_moisture_errorPM';
    soil_moisture_error(soil_moisture_error == -9999) = nan;
    soil_moisture_error = mean(soil_moisture_error, 3, "omitnan");
    SMAPproduct.Filtered_B2.soil_moisture_error = soil_moisture_error;
    
    
    vegetation_opacityAM=h5read(file_path,'/Soil_Moisture_Retrieval_Data_AM/vegetation_opacity');
    vegetation_opacityAM(find(quality_flagAM_mask_B2==1)) = NaN;
    vegetation_opacityPM=h5read(file_path,'/Soil_Moisture_Retrieval_Data_PM/vegetation_opacity_dca_pm');
    vegetation_opacityPM(find(quality_flagPM_mask_B2==1)) = NaN;
    vegetation_opacity(:,:,1)=vegetation_opacityAM';
    vegetation_opacity(:,:,2)=vegetation_opacityPM';
    vegetation_opacity(vegetation_opacity == -9999) = NaN;
    vegetation_opacity = mean(vegetation_opacity, 3, "omitnan");
    SMAPproduct.Filtered_B2.vegetation_opacity = vegetation_opacity;

end

end