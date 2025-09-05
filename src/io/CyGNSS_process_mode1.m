function CyGNSSproduct_atResolution = CyGNSS_process_mode1(Resolution, cygnss_data, cygnss_vars, doy_s, numcols, numrows)

doy_all=cygnss_data.DoY;
index=find(doy_s==doy_all);
read_vars=cell(size(cygnss_vars));
splat = cygnss_data.SPLAT;
splon = cygnss_data.SPLON;
splon(splon==180)=179.66;
splon(splon>180)=splon(splon>180)-360;
[cygnss_c,cygnss_r]=easeconv_grid(splat(index),splon(index),Resolution);

vars_after_accum = cell(size(cygnss_vars));
CyGNSS_product = struct;

for i=1:numel(cygnss_vars) % initialize the varibales in the structure

    var = genvarname(cygnss_vars{i}); %to save after using index 
    newvar = [var char('_n')]; %to save after accumarray

    if size(cygnss_data.(cygnss_vars{i}))==size(doy_all) % check for some variables with one value like "year"

        eval([var ' =cygnss_data.(cygnss_vars{i})(index);']);
        read_vars{i} = eval(var); %to svae the read variables in a structure

        
        newvar2 = [var char('_atRes')]; %to save after matrix size correction
        correct_matrix = NaN(numrows, numcols);
        
        if string(var)=="QC" %check for quality flag which needs "computeFlag_mode_bitWise" function
            eval([newvar '=accumarray([cygnss_r cygnss_c],(cell2mat(read_vars(i))),[],@computeFlag_mode_bitWise,-9999);']);
            vars_after_accum{i} = eval(newvar); %to svae the read variables in a structure
            [a,b] = size(vars_after_accum{i});
            correct_matrix(1:a, 1:b) = cell2mat(vars_after_accum(i));
            correct_matrix(correct_matrix==-9999)=NaN;
            CyGNSS_product.(string(cygnss_vars(i))) = correct_matrix(:);

        else
            eval([newvar ' = accumarray([cygnss_r cygnss_c],(cell2mat(read_vars(i))),[],@computemean,-9999);']);
            vars_after_accum{i} = eval(newvar); %to svae the read variables in a structure
            [a,b] = size(vars_after_accum{i});
            correct_matrix(1:a, 1:b) = cell2mat(vars_after_accum(i));
            correct_matrix(correct_matrix==-9999)=NaN;
            CyGNSS_product.(string(cygnss_vars(i))) = correct_matrix(:);
        end

    else
        eval([var ' =cygnss_data.(cygnss_vars{i});']);
        read_vars{i} = eval(var); %to svae the read variables in a structure
        CyGNSS_product.(string(cygnss_vars(i))) = cell2mat(read_vars(i)); %to svae the read variables in a structure
    end

    clear (string(var))
end
CyGNSSproduct_atResolution = CyGNSS_product;

end
