classdef configFile_Hydro < Singleton
    properties
        data
        %
        startDay
        endDay
        Target_Resolution
        smap_path
        modis_path
        smos_path
        hydro_file
        product_path
        SMAPQualityFlagFilter
        hydro_processing
        SMAP_resolution
        SNR_threshold
    end
    
    methods(Access=private)
        function newobj = configFile_Hydro(path)

            confID=fopen(path, 'r');
            if confID==-1
                error('Unable to open the file')
            end
            fclose(confID);
            
            read = string(splitlines(fileread(path)));
            expr = "(?<key>.+?)=(?<value>.*)";
            newobj.data = regexp(read, expr, 'names');
            newobj.data(cellfun(@isempty, newobj.data)) = [];
            newobj.data = cellfun(@(x) struct('key', x.key, 'value', x.value), newobj.data);
            newobj.check_configurations();

        end

        function value = get(obj, key)
            
            element = obj.data(find([obj.data.key] == key));
            
            if isempty(element)
                throw(MException('INPUT:ERROR', "Cannot find [" + key + "] in configuration file."))
            else
                value = element.value;
            end
        end

        function value = get_number(obj, key)
            % Mandatory numeric key, no default. Errors on a missing or
            % duplicate key or a non-numeric value, so a typo cannot
            % silently fall back to another value.
            element = obj.data(strtrim([obj.data.key]) == key);

            if isempty(element)
                throw(MException('INPUT:ERROR', "Cannot find [" + key + "] in configuration file."))
            end
            if numel(element) > 1
                throw(MException('INPUT:ERROR', "[" + key + "] appears more than once in configuration file."))
            end

            text = strtrim(element.value);
            value = str2double(text);
            if isnan(value) && ~strcmpi(text, "NaN")
                throw(MException('INPUT:ERROR', "[" + key + "] must be a number (or NaN to disable), got '" + text + "'."))
            end
        end

        function check_path(~, path, type)
            path = strrep(path, "/", "//");
            path = strrep(path, "\", "\\");
            if type == "dir"
                if ~isfolder(path)
                    msg = path + " folder does not exist. Please check the configuration file and try again";
                    throw( MException('PATH:ERROR', msg) )
                end
            elseif type == "file"
                if ~isfile(path)
                    msg = path +  " file does not exist. Please check the configuration file and try again";
                    throw( MException('PATH:ERROR', msg) )
                end
            end
        end

        function check_configurations(obj)
            % check keys
            obj.Target_Resolution = str2num(obj.get("Target_Resolution"));
            obj.startDay = obj.get("startDay");
            obj.endDay = obj.get("endDay");
            obj.smap_path = obj.get("smap_path");
            obj.modis_path = obj.get("modis_path");
            obj.smos_path = obj.get("smos_path");
            obj.hydro_file = obj.get("hydro_file");
            obj.product_path = obj.get("product_path");
            obj.SMAPQualityFlagFilter = obj.get("SMAPQualityFlagFilter");
            obj.hydro_processing = obj.get("hydro_processing");
            obj.SMAP_resolution = str2num(obj.get("SMAP_resolution"));
            % HydroGNSS SNR threshold in dB passed to apply_general_filter
            % (ThrSNR): points with SNR_1_L below it lose their _1_L
            % values. NaN disables the SNR filter. Mandatory, no default.
            obj.SNR_threshold = obj.get_number("SNR_threshold");

            obj.check_path(fullfile(obj.smap_path), "dir")
            obj.check_path(fullfile(obj.modis_path), "dir")
            obj.check_path(fullfile(obj.smos_path), "dir")
            obj.check_path(obj.hydro_file, "file");
            obj.check_path(obj.product_path, "dir");

        end
    end
    
    methods(Static)
        function obj = instance(varargin)
            persistent uniqueInstance
            if isempty(uniqueInstance)
                path = varargin{1};
                obj = configFile_Hydro(path);
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end


    end
    
end
