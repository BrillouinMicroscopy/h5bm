classdef h5bm < handle
    properties (Access = private)
        filePath;
        fileHandle;
        write = false;
    end
    properties (Constant)
        versionstring = 'H5BM-v0.0.3';
    end
    properties (Dependent)
        date;
        version;
        comment;
        resolutionX;
        resolutionY;
        resolutionZ;
        positionsX;
        positionsY;
        positionsZ;
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
                    obj.fileHandle = H5F.create(filePath, 'H5F_ACC_EXCL', 'H5P_DEFAULT', 'H5P_DEFAULT');
                    % set the version attribute
                    type_id = H5T.copy('H5T_C_S1');
                    H5T.set_size (type_id, numel(obj.versionstring));
                    space_id = H5S.create_simple(1, 1, 1);
                    acpl_id = H5P.create('H5P_ATTRIBUTE_CREATE');
                    attr_id = H5A.create(obj.fileHandle, 'version', type_id, space_id, acpl_id);
                    H5A.write(attr_id, type_id, obj.versionstring);
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
            space_id = H5S.create_simple(1, 1, 1);
            acpl_id = H5P.create('H5P_ATTRIBUTE_CREATE');
            try
                attr_id = H5A.open(obj.fileHandle, 'date');
            catch
                attr_id = H5A.create(obj.fileHandle, 'date', type_id, space_id, acpl_id);
            end
            H5A.write(attr_id, type_id, datum);
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
            space_id = H5S.create_simple(1, 1 ,1);
            acpl_id = H5P.create('H5P_ATTRIBUTE_CREATE');
            try
                attr_id = H5A.open(obj.fileHandle,'comment');
            catch
                attr_id = H5A.create(obj.fileHandle,'comment', type_id, space_id, acpl_id);
            end
            H5A.write(attr_id, type_id, comment);
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
        %% Set the resolution in specific direction
        function setResolution (obj, direction, resolution)
            direction = ['resolution-' direction];
            group_id = obj.payloadHandle();
            type_id = H5T.copy('H5T_NATIVE_DOUBLE');
            space_id = H5S.create_simple(1, 1, 1);
            acpl_id = H5P.create('H5P_ATTRIBUTE_CREATE');
            try
                attr_id = H5A.open(group_id, direction);
            catch
                attr_id = H5A.create(group_id, direction, type_id, space_id, acpl_id);
            end
            H5A.write(attr_id,type_id,resolution);
            H5A.close(attr_id);
            H5P.close(acpl_id);
            H5S.close(space_id);
            H5T.close(type_id);
        end
        
        %% Get the resolution in specific direction
        function resolution = getResolution (obj, direction)
            direction = ['resolution-' direction];
            group_id = obj.payloadHandle();
            try
                attr_id = H5A.open(group_id, direction);
                resolution = transpose(H5A.read(attr_id));
            catch e
                warning(['The attribute ' direction ' does not seem to exist: ' e.message]);
                resolution = '';
            end
        end
        
        %% Set the resolution in x-direction
        function set.resolutionX (obj, resolution)
            setResolution (obj, 'x', resolution);
        end
        
        %% Get the resolution in x-direction
        function resolution = get.resolutionX (obj)
            resolution = getResolution (obj, 'x');
        end
        
        %% Set the resolution in y-direction
        function set.resolutionY (obj, resolution)
            setResolution (obj, 'y', resolution);
        end
        
        %% Get the resolution in y-direction
        function resolution = get.resolutionY (obj)
            resolution = getResolution (obj, 'y');
        end
        
        %% Set the resolution in z-direction
        function set.resolutionZ (obj, resolution)
            setResolution (obj, 'z', resolution);
        end
        
        %% Get the resolution in z-direction
        function resolution = get.resolutionZ (obj)
            resolution = getResolution (obj, 'z');
        end
        
        %% Set the positions in specific direction
        function setPositions (obj, direction, positions)
            direction = ['positions-' direction];
            obj.writable;
            if isempty(obj.resolutionX) || isempty(obj.resolutionY)
                error('Please set the resolution in x- and y-direction first (h5bm.resolutionX and h5bm.resolutionY).');
            end
            
            type_id = H5T.copy('H5T_NATIVE_DOUBLE');
            dims = size(positions);
            h5_dims = fliplr(dims);
            h5_maxdims = h5_dims;
            space_id = H5S.create_simple(ndims(positions), h5_dims, h5_maxdims);
            dcpl = 'H5P_DEFAULT';
            plist = 'H5P_DEFAULT';
            try
                dset_id = H5D.open(obj.payloadHandle, direction);
            catch
                dset_id = H5D.create(obj.payloadHandle, direction, type_id, space_id, dcpl);
            end
            H5D.write(dset_id, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', plist, positions);
            
            %% Close payload dataset
            H5D.close(dset_id);
            H5S.close(space_id);
            H5T.close(type_id);
        end
        
        %% Get the positions in specific direction
        function positions = getPositions (obj, direction)
            direction = ['positions-' direction];
            try
                dset_id = H5D.open(obj.payloadHandle, direction);
                positions = H5D.read(dset_id);
            catch
                error('The dataset ''%s'' cannot be found.', direction);
            end
        end
        
        %% Set the positions in x-direction
        function set.positionsX (obj, positions)
            setPositions (obj, 'x', positions);
        end
        
        %% Set the positions in x-direction
        function positions = get.positionsX (obj)            
            positions = getPositions (obj, 'x');
        end
        
        %% Set the positions in y-direction
        function set.positionsY (obj, positions)
            setPositions (obj, 'y', positions);
        end
        
        %% Get the positions in y-direction
        function positions = get.positionsY (obj)
            positions = getPositions (obj, 'y');
        end
        
        %% Set the positions in z-direction
        function set.positionsZ (obj, positions)
            setPositions (obj, 'z', positions);
        end
        
        %% Get the positions in z-direction
        function positions = get.positionsZ (obj)            
            positions = getPositions (obj, 'z');
        end
        
        %% Set the payload data
        function writePayloadData (obj, indx, indy, indz, data, varargin)
            obj.writable;
            if isempty(obj.resolutionX) || isempty(obj.resolutionY) || isempty(obj.resolutionZ)
                error('Please set the resolution in x-, y- and z-direction first (h5bm.resolutionX, h5bm.resolutionY and h5bm.resolutionZ).');
            end
            p = inputParser;
            defaultDate = 'now';
            
            addRequired(p, 'indx', @isnumeric);
            addRequired(p, 'indy', @isnumeric);
            addRequired(p, 'indz', @isnumeric);
            addRequired(p, 'data', @isnumeric);
            addParameter(p, 'datestring', defaultDate, @obj.checkDate)
            
            parse(p, indx, indy, indz, data, varargin{:});
            
            if p.Results.indx > obj.resolutionX || p.Results.indy > obj.resolutionY || p.Results.indz > obj.resolutionZ
                error('Index exceeds matrix dimensions.');
            end
            if p.Results.indx < 0 || p.Results.indy < 0 || p.Results.indz < 0
                error('Subscript indices must either be real positive integers or logicals.');
            end
            
            index = ((p.Results.indz-1)*(obj.resolutionX*obj.resolutionY) + (p.Results.indy-1)*obj.resolutionX + (p.Results.indx-1));
            
            type_id = H5T.copy('H5T_NATIVE_DOUBLE');
            dims = size(p.Results.data);
            h5_dims = fliplr(dims);
            h5_maxdims = h5_dims;
            space_id = H5S.create_simple(ndims(p.Results.data), h5_dims, h5_maxdims);
            dcpl = 'H5P_DEFAULT';
            plist = 'H5P_DEFAULT';
            try
                dset_id = H5D.open(obj.payloadDataHandle, num2str(index));
            catch
                dset_id = H5D.create(obj.payloadDataHandle, num2str(index), type_id, space_id, dcpl);
            end
            H5D.write(dset_id, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', plist, p.Results.data);
            
            try
                datum = obj.parseDate(p.Results.datestring);
            catch e
                error(['''%s'' does not seem to be a valid dateformat: ' e.message], datestring);
            end
            
            %% Write date attribute
            type_id_date = H5T.copy('H5T_C_S1');
            H5T.set_size (type_id_date, numel(datum));
            space_id_date = H5S.create_simple(1, 1, 1);
            acpl_id_date = H5P.create('H5P_ATTRIBUTE_CREATE');
            try
                attr_id_date = H5A.open(dset_id, 'date');
            catch
                attr_id_date = H5A.create(dset_id, 'date', type_id_date, space_id_date, acpl_id_date);
            end
            H5A.write(attr_id_date, type_id_date, datum);
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
        function data = readPayloadData (obj, indx, indy, indz, type)
            if indx > obj.resolutionX || indy > obj.resolutionY
                error('Index exceeds matrix dimensions.');
            end
            if indx < 0 || indy < 0
                error('Subscript indices must either be real positive integers or logicals.');
            end
            
            index = ((indz-1)*(obj.resolutionX*obj.resolutionY) + (indy-1)*obj.resolutionX + (indx-1));
            
            if strcmp(type, 'data')
                try
                    dset_id = H5D.open(obj.payloadDataHandle, num2str(index));
                    data = double(H5D.read(dset_id));
                catch
                    error('The dataset ''%s'' cannot be found.', num2str(index));
                end
            elseif strcmp(type, 'date')
                try
                    dset_id = H5D.open(obj.payloadDataHandle, num2str(index));
                    attr_id = H5A.open(dset_id, 'date');
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
            
            addRequired(p, 'data', @isnumeric);
            addParameter(p, 'datestring', defaultDate, @obj.checkDate)
            
            parse(p, data, varargin{:});
            
            type_id = H5T.copy('H5T_NATIVE_DOUBLE');
            dims = size(p.Results.data);
            h5_dims = fliplr(dims);
            h5_maxdims = h5_dims;
            space_id = H5S.create_simple(ndims(p.Results.data), h5_dims, h5_maxdims);
            dcpl = 'H5P_DEFAULT';
            plist = 'H5P_DEFAULT';
            try
                dset_id = H5D.open(obj.backgroundDataHandle, num2str(index));
            catch
                dset_id = H5D.create(obj.backgroundDataHandle, num2str(index), type_id, space_id, dcpl);
            end
            H5D.write(dset_id, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', plist, p.Results.data);
            
            try
                datum = obj.parseDate(p.Results.datestring);
            catch e
                error(['''%s'' does not seem to be a valid dateformat: ' e.message], datestring);
            end
            
            %% Write date attribute
            type_id_date = H5T.copy('H5T_C_S1');
            H5T.set_size (type_id_date, numel(datum));
            space_id_date = H5S.create_simple(1, 1, 1);
            acpl_id_date = H5P.create('H5P_ATTRIBUTE_CREATE');
            try
                attr_id_date = H5A.open(dset_id, 'date');
            catch
                attr_id_date = H5A.create(dset_id, 'date', type_id_date, space_id_date, acpl_id_date);
            end
            H5A.write(attr_id_date, type_id_date, datum);
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
                    data = double(H5D.read(dset_id));
                catch
                    error('The dataset ''%s'' cannot be found.', num2str(index));
                end
            elseif strcmp(type, 'date')
                try
                    dset_id = H5D.open(obj.backgroundDataHandle, num2str(index));
                    attr_id = H5A.open(dset_id, 'date');
                    data = H5A.read(attr_id);
                    data = transpose(data);
                catch
                    error('The attribute ''date'' of the dataset ''%s'' cannot be found.', num2str(index));
                end
            else
                error('The specified data type is not supported.');
            end
        end
        
        %% Set the calibration data
        function writeCalibrationData (obj, index, data, shift, varargin)
            obj.writable;
            p = inputParser;
            defaultDate = 'now';
            
            addRequired(p, 'index', @isnumeric);
            addRequired(p, 'data', @isnumeric);
            addRequired(p, 'shift', @isnumeric);
            addParameter(p, 'sample', @ischar);
            addParameter(p, 'datestring', defaultDate, @obj.checkDate);
            
            parse(p, index, data, shift, varargin{:});
            
            type_id = H5T.copy('H5T_NATIVE_DOUBLE');
            dims = size(p.Results.data);
            h5_dims = fliplr(dims);
            h5_maxdims = h5_dims;
            space_id = H5S.create_simple(ndims(p.Results.data), h5_dims, h5_maxdims);
            dcpl = 'H5P_DEFAULT';
            plist = 'H5P_DEFAULT';
            try
                dset_id = H5D.open(obj.calibrationDataHandle, num2str(p.Results.index));
            catch
                dset_id = H5D.create(obj.calibrationDataHandle, num2str(p.Results.index), type_id, space_id, dcpl);
            end
            H5D.write(dset_id, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', plist, p.Results.data);
            
            try
                datum = obj.parseDate(p.Results.datestring);
            catch e
                error(['''%s'' does not seem to be a valid dateformat: ' e.message], datestring);
            end
            
            %% Write date attribute
            type_id_date = H5T.copy('H5T_C_S1');
            H5T.set_size (type_id_date, numel(datum));
            space_id_date = H5S.create_simple(1, 1, 1);
            acpl_id_date = H5P.create('H5P_ATTRIBUTE_CREATE');
            try
                attr_id_date = H5A.open(dset_id, 'date');
            catch
                attr_id_date = H5A.create(dset_id, 'date', type_id_date, space_id_date, acpl_id_date);
            end
            H5A.write(attr_id_date, type_id_date, datum);
            H5A.close(attr_id_date);
            H5P.close(acpl_id_date);
            H5S.close(space_id_date);
            H5T.close(type_id_date);
            
            %% Write sample attribute
            type_id_date = H5T.copy('H5T_C_S1');
            H5T.set_size (type_id_date, numel(p.Results.sample));
            space_id_date = H5S.create_simple(1, 1, 1);
            acpl_id_date = H5P.create('H5P_ATTRIBUTE_CREATE');
            try
                attr_id_date = H5A.open(dset_id, 'sample');
            catch
                attr_id_date = H5A.create(dset_id, 'sample', type_id_date, space_id_date, acpl_id_date);
            end
            H5A.write(attr_id_date, type_id_date, p.Results.sample);
            H5A.close(attr_id_date);
            H5P.close(acpl_id_date);
            H5S.close(space_id_date);
            H5T.close(type_id_date);
            
            %% Write shift attribute
            type_id_date = H5T.copy('H5T_NATIVE_DOUBLE');
            space_id_date = H5S.create_simple(1, 1, 1);
            acpl_id_date = H5P.create('H5P_ATTRIBUTE_CREATE');
            try
                attr_id_date = H5A.open(dset_id, 'shift');
            catch
                attr_id_date = H5A.create(dset_id, 'shift', type_id_date, space_id_date, acpl_id_date);
            end
            H5A.write(attr_id_date, type_id_date, p.Results.shift);
            H5A.close(attr_id_date);
            H5P.close(acpl_id_date);
            H5S.close(space_id_date);
            H5T.close(type_id_date);
            
            %% Close payload dataset
            H5D.close(dset_id);
            H5S.close(space_id);
            H5T.close(type_id);
        end
        
        %% Read the calibration data
        function data = readCalibrationData (obj, index, type)
            if strcmp(type, 'data')
                try
                    dset_id = H5D.open(obj.calibrationDataHandle, num2str(index));
                    data = double(H5D.read(dset_id));
                catch
                    error('The dataset ''%s'' cannot be found.', num2str(index));
                end
            elseif strcmp(type, 'date')
                try
                    dset_id = H5D.open(obj.calibrationDataHandle, num2str(index));
                    attr_id = H5A.open(dset_id, 'date');
                    data = H5A.read(attr_id);
                    data = transpose(data);
                catch
                    error('The attribute ''date'' of the dataset ''%s'' cannot be found.', num2str(index));
                end
            elseif strcmp(type, 'sample')
                try
                    dset_id = H5D.open(obj.calibrationDataHandle, num2str(index));
                    attr_id = H5A.open(dset_id, 'sample');
                    data = H5A.read(attr_id);
                    data = transpose(data);
                catch
                    error('The attribute ''sample'' of the dataset ''%s'' cannot be found.', num2str(index));
                end
            elseif strcmp(type, 'shift')
                try
                    dset_id = H5D.open(obj.calibrationDataHandle, num2str(index));
                    attr_id = H5A.open(dset_id, 'shift');
                    data = H5A.read(attr_id);
                    data = transpose(data);
                catch
                    error('The attribute ''shift'' of the dataset ''%s'' cannot be found.', num2str(index));
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
                group_id = H5G.open(obj.fileHandle, 'payload');
            catch
                plist = 'H5P_DEFAULT';
                group_id = H5G.create(obj.fileHandle, 'payload', plist, plist, plist);
            end
        end
        
        %% Get handle for payload data
        function data_id = payloadDataHandle (obj)
            group_id = obj.payloadHandle();
            try
                data_id = H5G.open(group_id, 'data');
            catch
                plist = 'H5P_DEFAULT';
                data_id = H5G.create(group_id, 'data', plist, plist, plist);
            end
        end
        
        %% Get handle for background data
        function data_id = backgroundDataHandle (obj)
            try
                data_id = H5G.open(obj.fileHandle, 'background');
            catch
                plist = 'H5P_DEFAULT';
                data_id = H5G.create(obj.fileHandle, 'background', plist, plist, plist);
            end
        end
        
        %% Get handle for calibration group
        function group_id = calibrationHandle (obj)
            try
                group_id = H5G.open(obj.fileHandle, 'calibration');
            catch
                plist = 'H5P_DEFAULT';
                group_id = H5G.create(obj.fileHandle, 'calibration', plist, plist, plist);
            end
        end
        
        %% Get handle for calibration data
        function data_id = calibrationDataHandle (obj)
            group_id = obj.calibrationHandle();
            try
                data_id = H5G.open(group_id, 'calibrationData');
            catch
                plist = 'H5P_DEFAULT';
                data_id = H5G.create(group_id, 'calibrationData', plist, plist, plist);
            end
        end
        
        %% Parse datetime to ISO string
        function datum = parseDate (obj, datestring)
            format = obj.dateFormat(datestring);
            if format
                datum = datetime(datestring, 'InputFormat', format, 'TimeZone', 'UTC');
            else
                datum = datetime(datestring);
            end
            datum.TimeZone = 'local';
            datum.Format = 'uuuu-MM-dd''T''HH:mm:ssXXX';
            datum = char(datum);
        end
        
        %% Check datestring for validity
        function check = checkDate (obj, datestring)
            try
                format = obj.dateFormat(datestring);
                if format
                    datetime(datestring, 'InputFormat', format, 'TimeZone', 'UTC');
                else
                    datetime(datestring);
                end
                check = true;
            catch
                check = false;
            end
        end
        
    end
    methods (Static)
        
        %% Get input date format
        function format = dateFormat (datestring)
            if regexp(datestring, '\d{4}-[01]\d-[0-3]\dT[0-2]\d:[0-5]\d:[0-5]\d([+-][0-2]\d:[0-5]\d|Z)')
                format = 'uuuu-MM-dd''T''HH:mm:ssXXX';
            else
                format = '';
            end
        end
    end
end