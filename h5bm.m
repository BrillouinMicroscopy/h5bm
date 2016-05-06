classdef h5bm < handle
    properties (Access = private)
        filePath;

        fileHandle;
        write = false;
    end    
    properties (Constant)
        versionstring = 'H5BM-v0.0.1';
    end
    properties (Dependent)
        date;
        version;
        comment;
    end
    
	methods
        %% Constructor
        function obj = h5bm (filePath, flags)
            obj.filePath = filePath;
            if strcmp(flags, 'H5F_ACC_RDONLY')
                if exist(obj.filePath, 'file') ~= 2
                    error('File ''%s'' does not exist.', obj.filePath);
                else
                    obj.fileHandle = H5F.open(filePath, flags, 'H5P_DEFAULT');
                end
            elseif strcmp(flags, 'H5F_ACC_RDWR')
                obj.write = true;
                if exist(obj.filePath, 'file') ~= 2
                    % create the HDF5 file
                    obj.fileHandle = H5F.create(filePath,'H5F_ACC_EXCL','H5P_DEFAULT','H5P_DEFAULT');
                    % set the version attribute
                    type_id = H5T.copy('H5T_C_S1');
                    H5T.set_size (type_id, numel(obj.versionstring));
                    space_id = H5S.create_simple(1,1,1);
                    acpl_id = H5P.create('H5P_ATTRIBUTE_CREATE');
                    attr_id = H5A.create(obj.fileHandle,'version',type_id,space_id,acpl_id);
                    H5A.write(attr_id,type_id,obj.versionstring);
                    H5A.close(attr_id);
                    H5P.close(acpl_id);
                    H5S.close(space_id);
                    H5T.close(type_id);
                else
                    obj.fileHandle = H5F.open(filePath, flags, 'H5P_DEFAULT');
                end
            end
        end
        
        %% Destructor
        function delete (obj)
            H5F.close(obj.fileHandle);
        end
        
        %% Set the date value
        function set.date (obj, datestring)
            obj.writable();
            try
                datum = datetime(datestring);
                datum.TimeZone = 'local';
                datum.Format = 'uuuu-MM-dd''T''HH:mm:ssXXX';
                datum = char(datum);
            catch e
                error(['''%s'' does not seem to be a valid dateformat: ' e.message], datestring);
            end
            type_id = H5T.copy('H5T_C_S1');
            H5T.set_size (type_id, numel(datum));
            space_id = H5S.create_simple(1,1,1);
            acpl_id = H5P.create('H5P_ATTRIBUTE_CREATE');
            try
                attr_id = H5A.open(obj.fileHandle,'date');
            catch
                attr_id = H5A.create(obj.fileHandle,'date',type_id,space_id,acpl_id);
            end
            H5A.write(attr_id,type_id,datum);
            H5A.close(attr_id);
            H5P.close(acpl_id);
            H5S.close(space_id);
            H5T.close(type_id);
        end
        
        %% Get the date
        function date = get.date (obj)
            try
                attr_id = H5A.open(obj.fileHandle, 'date');
                date = transpose(H5A.read(attr_id));
            catch e
                warning(['The attribute ''date'' does not seem to exist: ' e.message]);
                date = '';
            end
        end
        
        %% Set the version
        %  The version attribute is set automatically on file creation.
        function set.version (~, ~)
            warning('You are not allowed to set the version attribute.');
        end
        
        %% Get the version
        function version = get.version (obj)
            try
                attr_id = H5A.open(obj.fileHandle, 'version');
                version = transpose(H5A.read(attr_id));
            catch e
                warning(['The attribute ''version'' does not seem to exist: ' e.message]);
                version = '';
            end
        end
        
        %% Set the comment
        function set.comment (obj, comment)
            obj.writable;
            type_id = H5T.copy('H5T_C_S1');
            H5T.set_size (type_id, numel(comment));
            space_id = H5S.create_simple(1,1,1);
            acpl_id = H5P.create('H5P_ATTRIBUTE_CREATE');
            try
                attr_id = H5A.open(obj.fileHandle,'comment');
            catch
                attr_id = H5A.create(obj.fileHandle,'comment',type_id,space_id,acpl_id);
            end
            H5A.write(attr_id,type_id,comment);
            H5A.close(attr_id);
            H5P.close(acpl_id);
            H5S.close(space_id);
            H5T.close(type_id);
        end
        
        %% Get the comment
        function comment = get.comment (obj)
            try
                attr_id = H5A.open(obj.fileHandle, 'comment');
                comment = transpose(H5A.read(attr_id));
            catch e
                warning(['The attribute ''comment'' does not seem to exist: ' e.message]);
                comment = '';
            end
        end
    end
    methods (Access = private)
        %% Check for write privileges
        function writable (obj)
           if ~obj.write
               error('You are not allowed to write to this file. Use h5bmwrite for write access.');
           end
        end
    end
end