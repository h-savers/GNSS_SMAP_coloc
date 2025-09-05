classdef configFile < Singleton
    properties
        data
        %
        processMode
        startDay
        endDay
        Target_Resolution
        smap_path
        cygnss_path
        cygnss_file
        product_path
        SMAPQualityFlagFilter
        CyGNSS_processing
        SMAP_resolution
    end
    
    methods(Access=private)
        function newobj = configFile(path)

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
            obj.processMode = str2num(obj.get("processMode"));
            obj.Target_Resolution = str2num(obj.get("Target_Resolution"));
            obj.startDay = obj.get("startDay");
            obj.endDay = obj.get("endDay");
            obj.smap_path = obj.get("smap_path");
            obj.cygnss_path = obj.get("cygnss_path");
            obj.cygnss_file = obj.get("cygnss_file");
            obj.product_path = obj.get("product_path");
            obj.SMAPQualityFlagFilter = obj.get("SMAPQualityFlagFilter");
            obj.CyGNSS_processing = obj.get("CyGNSS_processing");
            obj.SMAP_resolution = str2num(obj.get("SMAP_resolution"));

            obj.check_path(fullfile(obj.smap_path), "dir")
            obj.check_path(fullfile(obj.cygnss_path), "dir")
            obj.check_path(obj.cygnss_file, "file");
            obj.check_path(obj.product_path, "dir");

        end
    end
    
    methods(Static)
        function obj = instance(varargin)
            persistent uniqueInstance
            if isempty(uniqueInstance)
                path = varargin{1};
                obj = configFile(path);
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end


    end
    
end
