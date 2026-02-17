function SMAPproduct_atResolution = stack_SMAP(SMAP_resolution,SMAPQualityFlagFilter, SMAPproduct_stacked, SMAPproduct_atResolution)

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

end

