function SMAPproduct_atResolution=SMAP_process(SMAPproduct, Target_Resolution, numcols, numrows, SMAP_resolution, sm_c, sm_r, SMAPQualityFlagFilter)

if Target_Resolution ==36
    roughness_coefficient(:,:,1)=SMAPproduct.roughness_coefficient;
    latitude(:,:,1)=SMAPproduct.latitude;
    longitude(:,:,1)=SMAPproduct.longitude;
    albedo(:,:,1)=SMAPproduct.albedo;
    soil_moisture_error(:,:,1)=SMAPproduct.soil_moisture_error;
    soil_moisture=SMAPproduct.soil_moisture;
    vegetation_opacity(:,:,1)=SMAPproduct.vegetation_opacity;
    vegetation_water_content(:,:,1)=SMAPproduct.vegetation_water_content;


elseif Target_Resolution==25
    
    if SMAP_resolution==9

        if SMAPQualityFlagFilter=="no"
            roughness_coefficient_nearest(:,:,1)=imresize(SMAPproduct.roughness_coefficient, [numrows,numcols],'nearest');
            latitude_nearest(:,:,1)=imresize(SMAPproduct.latitude, [numrows,numcols],'nearest');
            longitude_nearest(:,:,1)=imresize(SMAPproduct.longitude, [numrows,numcols],'nearest');
            albedo_nearest(:,:,1)=imresize(SMAPproduct.albedo, [numrows,numcols],'nearest');
            soil_moisture_error_nearest(:,:,1)=imresize(SMAPproduct.soil_moisture_error, [numrows,numcols],'nearest');
            soil_moisture_nearest=imresize(SMAPproduct.soil_moisture, [numrows,numcols],'nearest');
            vegetation_opacity_nearest(:,:,1)=imresize(SMAPproduct.vegetation_opacity, [numrows,numcols],'nearest');
            vegetation_water_content_nearest(:,:,1)=imresize(SMAPproduct.vegetation_water_content, [numrows,numcols],'nearest');
    
            SMAPproduct_atResolution.nearest.roughness_coefficient = roughness_coefficient_nearest;
            SMAPproduct_atResolution.nearest.latitude = latitude_nearest;
            SMAPproduct_atResolution.nearest.longitude = longitude_nearest;
            SMAPproduct_atResolution.nearest.albedo = albedo_nearest;
            SMAPproduct_atResolution.nearest.soil_moisture_error = soil_moisture_error_nearest;
            SMAPproduct_atResolution.nearest.soil_moisture = soil_moisture_nearest;
            SMAPproduct_atResolution.nearest.vegetation_opacity = vegetation_opacity_nearest;
            SMAPproduct_atResolution.nearest.vegetation_water_content = vegetation_water_content_nearest;
    
    
            roughness_coefficient_mean(:,:,1)=accumarray([sm_c(:) sm_r(:)], SMAPproduct.roughness_coefficient(:),[],@computemean);
            latitude_mean(:,:,1)=accumarray([sm_c(:) sm_r(:)], SMAPproduct.latitude(:),[],@computemean);
            longitude_mean(:,:,1)=accumarray([sm_c(:) sm_r(:)], SMAPproduct.longitude(:),[],@computemean);
            albedo_mean(:,:,1)=accumarray([sm_c(:) sm_r(:)], SMAPproduct.albedo(:),[],@computemean);
            soil_moisture_error_mean(:,:,1)=accumarray([sm_c(:) sm_r(:)], SMAPproduct.soil_moisture_error(:),[],@computemean);
            soil_moisture_mean=accumarray([sm_c(:) sm_r(:)], SMAPproduct.soil_moisture(:),[],@computemean);
            vegetation_opacity_mean(:,:,1)=accumarray([sm_c(:) sm_r(:)], SMAPproduct.vegetation_opacity(:),[],@computemean);
            vegetation_water_content_mean(:,:,1)=accumarray([sm_c(:) sm_r(:)], SMAPproduct.vegetation_water_content(:),[],@computemean);
    
            SMAPproduct_atResolution.mean.roughness_coefficient = roughness_coefficient_mean';
            SMAPproduct_atResolution.mean.latitude = latitude_mean';
            SMAPproduct_atResolution.mean.longitude = longitude_mean';
            SMAPproduct_atResolution.mean.albedo = albedo_mean';
            SMAPproduct_atResolution.mean.soil_moisture_error = soil_moisture_error_mean';
            SMAPproduct_atResolution.mean.soil_moisture = soil_moisture_mean';
            SMAPproduct_atResolution.mean.vegetation_opacity = vegetation_opacity_mean';
            SMAPproduct_atResolution.mean.vegetation_water_content = vegetation_water_content_mean';

        elseif SMAPQualityFlagFilter=="yes"
            
            %%% filtered based on first bit
            roughness_coefficient_nearest(:,:,1)=imresize(SMAPproduct.Filtered_B0.roughness_coefficient, [numrows,numcols],'nearest');
            latitude_nearest(:,:,1)=imresize(SMAPproduct.Filtered_B0.latitude, [numrows,numcols],'nearest');
            longitude_nearest(:,:,1)=imresize(SMAPproduct.Filtered_B0.longitude, [numrows,numcols],'nearest');
            albedo_nearest(:,:,1)=imresize(SMAPproduct.Filtered_B0.albedo, [numrows,numcols],'nearest');
            soil_moisture_error_nearest(:,:,1)=imresize(SMAPproduct.Filtered_B0.soil_moisture_error, [numrows,numcols],'nearest');
            soil_moisture_nearest=imresize(SMAPproduct.Filtered_B0.soil_moisture, [numrows,numcols],'nearest');
            vegetation_opacity_nearest(:,:,1)=imresize(SMAPproduct.Filtered_B0.vegetation_opacity, [numrows,numcols],'nearest');
            vegetation_water_content_nearest(:,:,1)=imresize(SMAPproduct.Filtered_B0.vegetation_water_content, [numrows,numcols],'nearest');
    
            SMAPproduct_atResolution.Filtered_B0.nearest.roughness_coefficient = roughness_coefficient_nearest;
            SMAPproduct_atResolution.Filtered_B0.nearest.latitude = latitude_nearest;
            SMAPproduct_atResolution.Filtered_B0.nearest.longitude = longitude_nearest;
            SMAPproduct_atResolution.Filtered_B0.nearest.albedo = albedo_nearest;
            SMAPproduct_atResolution.Filtered_B0.nearest.soil_moisture_error = soil_moisture_error_nearest;
            SMAPproduct_atResolution.Filtered_B0.nearest.soil_moisture = soil_moisture_nearest;
            SMAPproduct_atResolution.Filtered_B0.nearest.vegetation_opacity = vegetation_opacity_nearest;
            SMAPproduct_atResolution.Filtered_B0.nearest.vegetation_water_content = vegetation_water_content_nearest;
    
    
            roughness_coefficient_mean(:,:,1)=accumarray([sm_c(:) sm_r(:)], SMAPproduct.Filtered_B0.roughness_coefficient(:),[],@computemean);
            latitude_mean(:,:,1)=accumarray([sm_c(:) sm_r(:)], SMAPproduct.Filtered_B0.latitude(:),[],@computemean);
            longitude_mean(:,:,1)=accumarray([sm_c(:) sm_r(:)], SMAPproduct.Filtered_B0.longitude(:),[],@computemean);
            albedo_mean(:,:,1)=accumarray([sm_c(:) sm_r(:)], SMAPproduct.Filtered_B0.albedo(:),[],@computemean);
            soil_moisture_error_mean(:,:,1)=accumarray([sm_c(:) sm_r(:)], SMAPproduct.Filtered_B0.soil_moisture_error(:),[],@computemean);
            soil_moisture_mean=accumarray([sm_c(:) sm_r(:)], SMAPproduct.Filtered_B0.soil_moisture(:),[],@computemean);
            vegetation_opacity_mean(:,:,1)=accumarray([sm_c(:) sm_r(:)], SMAPproduct.Filtered_B0.vegetation_opacity(:),[],@computemean);
            vegetation_water_content_mean(:,:,1)=accumarray([sm_c(:) sm_r(:)], SMAPproduct.Filtered_B0.vegetation_water_content(:),[],@computemean);
    
            SMAPproduct_atResolution.Filtered_B0.mean.roughness_coefficient = roughness_coefficient_mean';
            SMAPproduct_atResolution.Filtered_B0.mean.latitude = latitude_mean';
            SMAPproduct_atResolution.Filtered_B0.mean.longitude = longitude_mean';
            SMAPproduct_atResolution.Filtered_B0.mean.albedo = albedo_mean';
            SMAPproduct_atResolution.Filtered_B0.mean.soil_moisture_error = soil_moisture_error_mean';
            SMAPproduct_atResolution.Filtered_B0.mean.soil_moisture = soil_moisture_mean';
            SMAPproduct_atResolution.Filtered_B0.mean.vegetation_opacity = vegetation_opacity_mean';
            SMAPproduct_atResolution.Filtered_B0.mean.vegetation_water_content = vegetation_water_content_mean';

            %%% filtered based on third bit
            roughness_coefficient_nearest(:,:,1)=imresize(SMAPproduct.Filtered_B2.roughness_coefficient, [numrows,numcols],'nearest');
            latitude_nearest(:,:,1)=imresize(SMAPproduct.Filtered_B2.latitude, [numrows,numcols],'nearest');
            longitude_nearest(:,:,1)=imresize(SMAPproduct.Filtered_B2.longitude, [numrows,numcols],'nearest');
            albedo_nearest(:,:,1)=imresize(SMAPproduct.Filtered_B2.albedo, [numrows,numcols],'nearest');
            soil_moisture_error_nearest(:,:,1)=imresize(SMAPproduct.Filtered_B2.soil_moisture_error, [numrows,numcols],'nearest');
            soil_moisture_nearest=imresize(SMAPproduct.Filtered_B2.soil_moisture, [numrows,numcols],'nearest');
            vegetation_opacity_nearest(:,:,1)=imresize(SMAPproduct.Filtered_B2.vegetation_opacity, [numrows,numcols],'nearest');
            vegetation_water_content_nearest(:,:,1)=imresize(SMAPproduct.Filtered_B2.vegetation_water_content, [numrows,numcols],'nearest');
    
            SMAPproduct_atResolution.Filtered_B2.nearest.roughness_coefficient = roughness_coefficient_nearest;
            SMAPproduct_atResolution.Filtered_B2.nearest.latitude = latitude_nearest;
            SMAPproduct_atResolution.Filtered_B2.nearest.longitude = longitude_nearest;
            SMAPproduct_atResolution.Filtered_B2.nearest.albedo = albedo_nearest;
            SMAPproduct_atResolution.Filtered_B2.nearest.soil_moisture_error = soil_moisture_error_nearest;
            SMAPproduct_atResolution.Filtered_B2.nearest.soil_moisture = soil_moisture_nearest;
            SMAPproduct_atResolution.Filtered_B2.nearest.vegetation_opacity = vegetation_opacity_nearest;
            SMAPproduct_atResolution.Filtered_B2.nearest.vegetation_water_content = vegetation_water_content_nearest;
    
    
            roughness_coefficient_mean(:,:,1)=accumarray([sm_c(:) sm_r(:)], SMAPproduct.Filtered_B2.roughness_coefficient(:),[],@computemean);
            latitude_mean(:,:,1)=accumarray([sm_c(:) sm_r(:)], SMAPproduct.Filtered_B2.latitude(:),[],@computemean);
            longitude_mean(:,:,1)=accumarray([sm_c(:) sm_r(:)], SMAPproduct.Filtered_B2.longitude(:),[],@computemean);
            albedo_mean(:,:,1)=accumarray([sm_c(:) sm_r(:)], SMAPproduct.Filtered_B2.albedo(:),[],@computemean);
            soil_moisture_error_mean(:,:,1)=accumarray([sm_c(:) sm_r(:)], SMAPproduct.Filtered_B2.soil_moisture_error(:),[],@computemean);
            soil_moisture_mean=accumarray([sm_c(:) sm_r(:)], SMAPproduct.Filtered_B2.soil_moisture(:),[],@computemean);
            vegetation_opacity_mean(:,:,1)=accumarray([sm_c(:) sm_r(:)], SMAPproduct.Filtered_B2.vegetation_opacity(:),[],@computemean);
            vegetation_water_content_mean(:,:,1)=accumarray([sm_c(:) sm_r(:)], SMAPproduct.Filtered_B2.vegetation_water_content(:),[],@computemean);
    
            SMAPproduct_atResolution.Filtered_B2.mean.roughness_coefficient = roughness_coefficient_mean';
            SMAPproduct_atResolution.Filtered_B2.mean.latitude = latitude_mean';
            SMAPproduct_atResolution.Filtered_B2.mean.longitude = longitude_mean';
            SMAPproduct_atResolution.Filtered_B2.mean.albedo = albedo_mean';
            SMAPproduct_atResolution.Filtered_B2.mean.soil_moisture_error = soil_moisture_error_mean';
            SMAPproduct_atResolution.Filtered_B2.mean.soil_moisture = soil_moisture_mean';
            SMAPproduct_atResolution.Filtered_B2.mean.vegetation_opacity = vegetation_opacity_mean';
            SMAPproduct_atResolution.Filtered_B2.mean.vegetation_water_content = vegetation_water_content_mean';

        end

    elseif SMAP_resolution==36

        if SMAPQualityFlagFilter=="no"

            roughness_coefficient(:,:,1)=imresize(SMAPproduct.roughness_coefficient,[numrows,numcols],'bilinear');
            latitude(:,:,1)=imresize(SMAPproduct.latitude,[numrows,numcols],'bilinear');
            longitude(:,:,1)=imresize(SMAPproduct.longitude,[numrows,numcols],'bilinear');
            albedo(:,:,1)=imresize(SMAPproduct.albedo,[numrows,numcols],'bilinear');
            soil_moisture_error(:,:,1)=imresize(SMAPproduct.soil_moisture_error,[numrows,numcols],'bilinear');
            soil_moisture=imresize(SMAPproduct.soil_moisture,[numrows,numcols],'bilinear');
            vegetation_opacity(:,:,1)=imresize(SMAPproduct.vegetation_opacity,[numrows,numcols],'bilinear');
            vegetation_water_content(:,:,1)=imresize(SMAPproduct.vegetation_water_content,[numrows,numcols],'bilinear');
    
    
            SMAPproduct_atResolution.roughness_coefficient = roughness_coefficient;
            SMAPproduct_atResolution.latitude = latitude;
            SMAPproduct_atResolution.longitude = longitude;
            SMAPproduct_atResolution.albedo = albedo;
            SMAPproduct_atResolution.soil_moisture_error = soil_moisture_error;
            SMAPproduct_atResolution.soil_moisture = soil_moisture;
            SMAPproduct_atResolution.vegetation_opacity = vegetation_opacity;
            SMAPproduct_atResolution.vegetation_water_content = vegetation_water_content;
            
        elseif SMAPQualityFlagFilter=="yes"

            roughness_coefficient(:,:,1)=imresize(SMAPproduct.Filtered_B0.roughness_coefficient,[numrows,numcols],'bilinear');
            latitude(:,:,1)=imresize(SMAPproduct.Filtered_B0.latitude,[numrows,numcols],'bilinear');
            longitude(:,:,1)=imresize(SMAPproduct.Filtered_B0.longitude,[numrows,numcols],'bilinear');
            albedo(:,:,1)=imresize(SMAPproduct.Filtered_B0.albedo,[numrows,numcols],'bilinear');
            soil_moisture_error(:,:,1)=imresize(SMAPproduct.Filtered_B0.soil_moisture_error,[numrows,numcols],'bilinear');
            soil_moisture=imresize(SMAPproduct.Filtered_B0.soil_moisture,[numrows,numcols],'bilinear');
            vegetation_opacity(:,:,1)=imresize(SMAPproduct.Filtered_B0.vegetation_opacity,[numrows,numcols],'bilinear');
            vegetation_water_content(:,:,1)=imresize(SMAPproduct.Filtered_B0.vegetation_water_content,[numrows,numcols],'bilinear');
    
    
            SMAPproduct_atResolution.Filtered_B0.roughness_coefficient = roughness_coefficient;
            SMAPproduct_atResolution.Filtered_B0.latitude = latitude;
            SMAPproduct_atResolution.Filtered_B0.longitude = longitude;
            SMAPproduct_atResolution.Filtered_B0.albedo = albedo;
            SMAPproduct_atResolution.Filtered_B0.soil_moisture_error = soil_moisture_error;
            SMAPproduct_atResolution.Filtered_B0.soil_moisture = soil_moisture;
            SMAPproduct_atResolution.Filtered_B0.vegetation_opacity = vegetation_opacity;
            SMAPproduct_atResolution.Filtered_B0.vegetation_water_content = vegetation_water_content;
    
    
           
            roughness_coefficient(:,:,1)=imresize(SMAPproduct.Filtered_B2.roughness_coefficient,[numrows,numcols],'bilinear');
            latitude(:,:,1)=imresize(SMAPproduct.Filtered_B2.latitude,[numrows,numcols],'bilinear');
            longitude(:,:,1)=imresize(SMAPproduct.Filtered_B2.longitude,[numrows,numcols],'bilinear');
            albedo(:,:,1)=imresize(SMAPproduct.Filtered_B2.albedo,[numrows,numcols],'bilinear');
            soil_moisture_error(:,:,1)=imresize(SMAPproduct.Filtered_B2.soil_moisture_error,[numrows,numcols],'bilinear');
            soil_moisture=imresize(SMAPproduct.Filtered_B2.soil_moisture,[numrows,numcols],'bilinear');
            vegetation_opacity(:,:,1)=imresize(SMAPproduct.Filtered_B2.vegetation_opacity,[numrows,numcols],'bilinear');
            vegetation_water_content(:,:,1)=imresize(SMAPproduct.Filtered_B2.vegetation_water_content,[numrows,numcols],'bilinear');
    
    
            SMAPproduct_atResolution.Filtered_B2.roughness_coefficient = roughness_coefficient;
            SMAPproduct_atResolution.Filtered_B2.latitude = latitude;
            SMAPproduct_atResolution.Filtered_B2.longitude = longitude;
            SMAPproduct_atResolution.Filtered_B2.albedo = albedo;
            SMAPproduct_atResolution.Filtered_B2.soil_moisture_error = soil_moisture_error;
            SMAPproduct_atResolution.Filtered_B2.soil_moisture = soil_moisture;
            SMAPproduct_atResolution.Filtered_B2.vegetation_opacity = vegetation_opacity;
            SMAPproduct_atResolution.Filtered_B2.vegetation_water_content = vegetation_water_content;

        end
    
    end

end


end