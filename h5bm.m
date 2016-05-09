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
        resolutionX;
        resolutionY;
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
                datum = obj.parseDate(datestring);
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
        
        %% Set the resolution in x-direction
        function set.resolutionX (obj, resolutionX)
            group_id = obj.payloadHandle();
            type_id = H5T.copy('H5T_NATIVE_DOUBLE');
            space_id = H5S.create_simple(1,1,1);
            acpl_id = H5P.create('H5P_ATTRIBUTE_CREATE');
            try
                attr_id = H5A.open(group_id,'resolution-x');
            catch
                attr_id = H5A.create(group_id,'resolution-x',type_id,space_id,acpl_id);
            end
            H5A.write(attr_id,type_id,resolutionX);
            H5A.close(attr_id);
            H5P.close(acpl_id);
            H5S.close(space_id);
            H5T.close(type_id);
        end
        
        %% Get the resolution in x-direction
        function resolutionX = get.resolutionX (obj)
            group_id = obj.payloadHandle();
            try
                attr_id = H5A.open(group_id, 'resolution-x');
                resolutionX = transpose(H5A.read(attr_id));
            catch e
                warning(['The attribute ''resolution-x'' does not seem to exist: ' e.message]);
                resolutionX = '';
            end
        end
        
        %% Set the resolution in y-direction
        function set.resolutionY (obj, resolutionY)
            group_id = obj.payloadHandle();
            type_id = H5T.copy('H5T_NATIVE_DOUBLE');
            space_id = H5S.create_simple(1,1,1);
            acpl_id = H5P.create('H5P_ATTRIBUTE_CREATE');
            try
                attr_id = H5A.open(group_id,'resolution-y');
            catch
                attr_id = H5A.create(group_id,'resolution-y',type_id,space_id,acpl_id);
            end
            H5A.write(attr_id,type_id,resolutionY);
            H5A.close(attr_id);
            H5P.close(acpl_id);
            H5S.close(space_id);
            H5T.close(type_id);
        end
        
        %% Get the resolution in y-direction
        function resolutionY = get.resolutionY (obj)
            group_id = obj.payloadHandle();
            try
                attr_id = H5A.open(group_id, 'resolution-y');
                resolutionY = transpose(H5A.read(attr_id));
            catch e
                warning(['The attribute ''resolution-y'' does not seem to exist: ' e.message]);
                resolutionY = '';
            end
        end
        
        %% Set the payload data
        function writePayloadData (obj, indx, indy, data, varargin)
            obj.writable;
            if isempty(obj.resolutionX) || isempty(obj.resolutionY)
                error('Please set the resolution in x- and y-direction first (h5bm.resolutionX and h5bm.resolutionY).');
            end
            p = inputParser;
            defaultDate = 'now';
            
            addRequired(p,'indx',@isnumeric);
            addRequired(p,'indy',@isnumeric);
            addRequired(p,'data',@isnumeric);
            addParameter(p,'datestring',defaultDate,@obj.checkDate)
            
            parse(p, indx, indy, data, varargin{:});

            if p.Results.indx > obj.resolutionX || p.Results.indy > obj.resolutionY
                error('Index exceeds matrix dimensions.');
            end
            if p.Results.indx < 0 || p.Results.indy < 0
                error('Subscript indices must either be real positive integers or logicals.');
            end
            
            index = (p.Results.indx-1)*obj.resolutionX + (p.Results.indy - 1);
            
            type_id = H5T.copy('H5T_NATIVE_DOUBLE');
            dims = size(p.Results.data);
            h5_dims = fliplr(dims);
            h5_maxdims = h5_dims;
            space_id = H5S.create_simple(ndims(p.Results.data),h5_dims,h5_maxdims);
            dcpl = 'H5P_DEFAULT';
            plist = 'H5P_DEFAULT';
            try
                dset_id = H5D.open(obj.payloadDataHandle,num2str(index));
            catch
                dset_id = H5D.create(obj.payloadDataHandle,num2str(index),type_id,space_id,dcpl);
            end
            H5D.write(dset_id,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',plist,p.Results.data);

            try
                datum = obj.parseDate(p.Results.datestring);
            catch e
                error(['''%s'' does not seem to be a valid dateformat: ' e.message], datestring);
            end
            
            %% Write date attribute
            type_id_date = H5T.copy('H5T_C_S1');
            H5T.set_size (type_id_date, numel(datum));
            space_id_date = H5S.create_simple(1,1,1);
            acpl_id_date = H5P.create('H5P_ATTRIBUTE_CREATE');
            try
                attr_id_date = H5A.open(dset_id,'date');
            catch
                attr_id_date = H5A.create(dset_id,'date',type_id_date,space_id_date,acpl_id_date);
            end
            H5A.write(attr_id_date,type_id_date,datum);
            H5A.close(attr_id_date);
            H5P.close(acpl_id_date);
            H5S.close(space_id_date);
            H5T.close(type_id_date);

            %% Close payload dataset
            H5D.close(dset_id);
            H5S.close(space_id);
            H5T.close(type_id);
        end
        
        %% Get the payload data
        function data = readPayloadData (obj, indx, indy, type)
            if indx > obj.resolutionX || indy > obj.resolutionY
                error('Index exceeds matrix dimensions.');
            end
            if indx < 0 || indy < 0
                error('Subscript indices must either be real positive integers or logicals.');
            end
            
            index = (indx-1)*obj.resolutionX + (indy - 1);
            
            if strcmp(type, 'data')
                try
                    dset_id = H5D.open(obj.payloadDataHandle,num2str(index));
                    data = H5D.read(dset_id);
                catch
                    error('The dataset ''%s'' cannot be found.', num2str(index));
                end
            elseif strcmp(type, 'date')
                try
                    dset_id = H5D.open(obj.payloadDataHandle,num2str(index));
                    attr_id = H5A.open(dset_id,'date');
                    data = H5A.read(attr_id);
                    data = transpose(data);
                catch
                    error('The attribute ''date'' of the dataset ''%s'' cannot be found.', num2str(index));
                end
            else
                error('The specified data type is not supported.');
            end
        end
        
        %% Set the background data
        function writeBackgroundData (obj, data, varargin)
            obj.writable;
            index = 1;
            p = inputParser;
            defaultDate = 'now';
            
            addRequired(p,'data',@isnumeric);
            addParameter(p,'datestring',defaultDate,@obj.checkDate)
            
            parse(p, data, varargin{:});
            
            type_id = H5T.copy('H5T_NATIVE_DOUBLE');
            dims = size(p.Results.data);
            h5_dims = fliplr(dims);
            h5_maxdims = h5_dims;
            space_id = H5S.create_simple(ndims(p.Results.data),h5_dims,h5_maxdims);
            dcpl = 'H5P_DEFAULT';
            plist = 'H5P_DEFAULT';
            try
                dset_id = H5D.open(obj.backgroundDataHandle,num2str(index));
            catch
                dset_id = H5D.create(obj.backgroundDataHandle,num2str(index),type_id,space_id,dcpl);
            end
            H5D.write(dset_id,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',plist,p.Results.data);

            try
                datum = obj.parseDate(p.Results.datestring);
            catch e
                error(['''%s'' does not seem to be a valid dateformat: ' e.message], datestring);
            end
            
            %% Write date attribute
            type_id_date = H5T.copy('H5T_C_S1');
            H5T.set_size (type_id_date, numel(datum));
            space_id_date = H5S.create_simple(1,1,1);
            acpl_id_date = H5P.create('H5P_ATTRIBUTE_CREATE');
            try
                attr_id_date = H5A.open(dset_id,'date');
            catch
                attr_id_date = H5A.create(dset_id,'date',type_id_date,space_id_date,acpl_id_date);
            end
            H5A.write(attr_id_date,type_id_date,datum);
            H5A.close(attr_id_date);
            H5P.close(acpl_id_date);
            H5S.close(space_id_date);
            H5T.close(type_id_date);

            %% Close payload dataset
            H5D.close(dset_id);
            H5S.close(space_id);
            H5T.close(type_id);
        end
        
        %% Read the background data
        function data = readBackgroundData (obj, type)
            index = 1;
            if strcmp(type, 'data')
                try
                    dset_id = H5D.open(obj.backgroundDataHandle, num2str(index));
                    data = H5D.read(dset_id);
                catch
                    error('The dataset ''%s'' cannot be found.', num2str(index));
                end
            elseif strcmp(type, 'date')
                try
                    dset_id = H5D.open(obj.backgroundDataHandle, num2str(index));
                    attr_id = H5A.open(dset_id,'date');
                    data = H5A.read(attr_id);
                    data = transpose(data);
                catch
                    error('The attribute ''date'' of the dataset ''%s'' cannot be found.', num2str(index));
                end
            else
                error('The specified data type is not supported.');
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
        
        %% Get handle for payload group
        function group_id = payloadHandle (obj)
            try
                group_id = H5G.open(obj.fileHandle,'payload');
            catch
                plist = 'H5P_DEFAULT';
                group_id = H5G.create(obj.fileHandle,'payload',plist,plist,plist);
            end
        end
        
        %% Get handle for payload data
        function data_id = payloadDataHandle (obj)
            group_id = obj.payloadHandle();
            try
                data_id = H5G.open(group_id,'data');
            catch
                plist = 'H5P_DEFAULT';
                data_id = H5G.create(group_id,'data',plist,plist,plist);
            end
        end
        
        %% Get handle for background data
        function data_id = backgroundDataHandle (obj)
            try
                data_id = H5G.open(obj.fileHandle,'background');
            catch
                plist = 'H5P_DEFAULT';
                data_id = H5G.create(obj.fileHandle,'background',plist,plist,plist);
            end
        end

    end
    methods (Static)
        %% Check datestring for validity
        function check = checkDate (date)
            try
                datetime(date);
                check = true;
            catch
                check = false;
            end
        end

        %% Parse datetime to ISO string
        function datum = parseDate (datestring)
            datum = datetime(datestring);
            datum.TimeZone = 'local';
            datum.Format = 'uuuu-MM-dd''T''HH:mm:ssXXX';
            datum = char(datum);
        end
    end
end