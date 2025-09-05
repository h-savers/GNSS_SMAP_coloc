classdef Singleton < handle
    % Unique properties of Singleton.  This can be only accessed
    % with the getter/setter methods via any subclass of Singleton.
    properties(Access=private)
       singletonData = [];
    end
    
    methods(Abstract, Static)
       % This method serves as the global point of access in creating a
       % single instance *or* acquiring a reference to the singleton.
       % If the object doesn't exist, create it otherwise return the
       % existing one in persistent memory.
       % Input:
       %    <none>
       % Output:
       %    obj = reference to a persistent instance of the class
       obj = instance();
    end
    
    methods % Public Access
       % Accessor method for querying the singleton data.
       % Input:
       %   obj = reference to the singleton instance of the subclass
       % Output:
       %   singletonData = internal data store for Singleton object
       function singletonData = getSingletonData(obj)
          singletonData = obj.singletonData;
       end
       
       % Accessor method for modifying the singleton data.
       % Input:
       %   obj = reference to the singleton instance of the subclass
       %   singletonData = new data to set internal data store
       % Output:
       %   <none>
       function setSingletonData(obj, singletonData)
          obj.singletonData = singletonData;
       end
       
    end
 
 end
 