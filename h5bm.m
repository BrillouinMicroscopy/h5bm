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
            end
        end
        
        %% Destructor
        function delete (obj)
            H5F.close(obj.fileHandle);
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
        
        %% Get the resolution in x-direction
        function resolution = get.resolutionX (obj)
            resolution = getResolution (obj, 'x');
        end
        
        %% Get the resolution in y-direction
        function resolution = get.resolutionY (obj)
            resolution = getResolution (obj, 'y');
        end
        
        %% Get the resolution in z-direction
        function resolution = get.resolutionZ (obj)
            resolution = getResolution (obj, 'z');
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
        function positions = get.positionsX (obj)            
            positions = getPositions (obj, 'x');
        end
        
        %% Get the positions in y-direction
        function positions = get.positionsY (obj)
            positions = getPositions (obj, 'y');
        end
        
        %% Get the positions in z-direction
        function positions = get.positionsZ (obj)            
            positions = getPositions (obj, 'z');
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
            datum.Format = format;
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
            elseif regexp(datestring, '\d{4}-[01]\d-[0-3]\dT[0-2]\d:[0-5]\d:[0-5]\d\.\d{3}([+-][0-2]\d:[0-5]\d|Z)')
                format = 'uuuu-MM-dd''T''HH:mm:ss.SSSXXX';
            else
                format = '';
            end
        end
    end
end