function HydroGNSSproduct_GPS_atResolution = HydroGNSS_process(Resolution, hydrognss_product, hydrognss_vars, idx_6hour, numcols, numrows)

read_vars=cell(size(hydrognss_vars));
splat = hydrognss_product.specularPointLat;
splon = hydrognss_product.specularPointLon;
splon(splon==180)=179.66;
splon(splon>180)=splon(splon>180)-360;

% idx_6hour: indices into full-length vectors for this 6-hour block.
% index: positions within that subset where specular lat is valid.
% abs_idx: actual row indices into hydrognss_product (must not use index alone).
idx_6hour = idx_6hour(:);
subset_lat = splat(idx_6hour);
index = find(~isnan(subset_lat));
abs_idx = idx_6hour(index);
[hydrognss_c,hydrognss_r]=easeconv_grid3(splat(abs_idx),splon(abs_idx),Resolution);

% % doy_all=hydrognss_product.dayOfYear;
% % index=find(36==doy_all);
% % [hydrognss_c,hydrognss_r]=easeconv_grid(splat(index),splon(index),Resolution);

vars_after_accum = cell(size(hydrognss_vars));
HydroGNSS_product = struct;

for i=1:numel(hydrognss_vars) % initialize the varibales in the structure

    var = genvarname(hydrognss_vars{i}); %to save after using index 
    newvar = [var char('_n')]; %to save after accumarray

    if size(hydrognss_product.(hydrognss_vars{i}))==size(splat) % check for some variables with one value like "year"

        eval([var ' =hydrognss_product.(hydrognss_vars{i})(abs_idx);']);
        read_vars{i} = eval(var); %to svae the read variables in a structure

        
        newvar2 = [var char('_atRes')]; %to save after matrix size correction
        % Keep SML2OP convention: first dim is column-indexed, second dim is row-indexed.
        correct_matrix = NaN(numcols, numrows);
        
         if string(var)=="qualityFlags" || string(var)=="qualityFlags_2"%check for quality flag which needs "computeFlag_mode_bitWise" function
            eval([newvar '=accumarray([hydrognss_c hydrognss_r],(cell2mat(read_vars(i))),[],@computeFlag_mode_bitWise,-9999);']);

        elseif string(var)=="notToBeUsed" || string(var)=="notRecommended"
            eval([newvar '=accumarray([hydrognss_c hydrognss_r], cell2mat(read_vars(i)), [], @computeLogical_mode, -9999);']);

        elseif string(var)=="timeUTC"
            t = posixtime(read_vars{i});
            eval([newvar '=accumarray([hydrognss_c hydrognss_r], t, [], @mean, -9999);']);

        elseif string(var)=="constellation"
            continue
            
        else
            eval([newvar ' = accumarray([hydrognss_c hydrognss_r],(double(cell2mat(read_vars(i)))),[],@computemean, -9999);']);
        end

        vars_after_accum{i} = eval(newvar); %to svae the read variables in a structure
        [a,b] = size(vars_after_accum{i});
        correct_matrix(1:a, 1:b) = cell2mat(vars_after_accum(i));
        correct_matrix(correct_matrix==-9999)=NaN;
        HydroGNSS_product.(string(hydrognss_vars(i))) = correct_matrix(:);

    else
        eval([var ' =hydrognss_product.(hydrognss_vars{i});']);
        read_vars{i} = eval(var); %to svae the read variables in a structure
        HydroGNSS_product.(string(hydrognss_vars(i))) = cell2mat(read_vars(i)); %to svae the read variables in a structure
    end

    clear (string(var))
end
HydroGNSSproduct_GPS_atResolution = HydroGNSS_product;

end
