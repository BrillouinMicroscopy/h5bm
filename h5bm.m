classdef h5bm < handle
    properties (Access = private)
        filePath;
        fileHandle;
        write = false;
        major;
        minor;
        patch;
    end
    properties (Constant)
        versionstring = 'H5BM-v0.0.4';
        versionmajor = 0;
        versionminor = 0;
        versionpatch = 4;
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
                    [~, tok] = regexp(obj.version, 'H5BM-v(\d).(\d).(\d)', 'match', 'tokens');
                    obj.major = str2double(tok{1}{1});
                    obj.minor = str2double(tok{1}{2});
                    obj.patch = str2double(tok{1}{3});
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
                 error(['The attribute ''date'' does not seem to exist: ' e.message]);
            end
        end
        
        %% Get the date of the repetition
        function date = getDate (obj, mode, repetition)
            try
                attr_id = H5A.open(obj.repetitionHandle(mode, repetition), 'date');
                date = transpose(H5A.read(attr_id));
            catch e
                error(['The attribute ''date'' does not seem to exist: ' e.message]);
            end
        end
        
        %% Get the version
        function version = get.version (obj)
            try
                attr_id = H5A.open(obj.fileHandle, 'version');
                version = transpose(H5A.read(attr_id));
            catch e
                error(['The attribute ''version'' does not seem to exist: ' e.message]);
            end
        end
        
        %% Get the comment
        function comment = get.comment (obj)
            try
                attr_id = H5A.open(obj.fileHandle, 'comment');
                comment = transpose(H5A.read(attr_id));
            catch e
                error(['The attribute ''comment'' does not seem to exist: ' e.message]);
            end
        end
        
        %% Get the resolution in specific direction
        function resolution = getResolution (obj, mode, repetition, direction)
            direction = ['resolution-' direction];
            group_id = obj.payloadHandle(mode, repetition);
            try
                attr_id = H5A.open(group_id, direction);
                resolution = transpose(H5A.read(attr_id));
            catch e
                error(['The attribute ' direction ' does not seem to exist: ' e.message]);
            end
        end
        
        %% Get the resolution in x-direction
        function resolution = getResolutionX (obj, mode, repetition)
            resolution = getResolution(obj, mode, repetition, 'x');
        end
        
        %% Get the resolution in y-direction
        function resolution = getResolutionY (obj, mode, repetition)
            resolution = getResolution(obj, mode, repetition, 'y');
        end
        
        %% Get the resolution in z-direction
        function resolution = getResolutionZ (obj, mode, repetition)
            resolution = getResolution(obj, mode, repetition, 'z');
        end
        
        %% Get the positions in specific direction
        function positions = getPositions (obj, mode, repetition, direction)
            direction = ['positions-' direction];
            try
                dset_id = H5D.open(obj.payloadHandle(mode, repetition), direction);
                positions = H5D.read(dset_id);
            catch
                error('The dataset ''%s'' cannot be found.', direction);
            end
        end
        
        %% Get the positions in x-direction
        function positions = getPositionsX (obj, mode, repetition)
            positions = getPositions (obj, mode, repetition, 'x');
        end
        
        %% Get the positions in y-direction
        function positions = getPositionsY (obj, mode, repetition)
            positions = getPositions (obj, mode, repetition, 'y');
        end
        
        %% Get the positions in z-direction
        function positions = getPositionsZ (obj, mode, repetition)            
            positions = getPositions (obj, mode, repetition, 'z');
        end
        
        %% Get the repetition names for the specified mode
        
        function repetitions = getRepetitions (obj, mode)
            % Storing multiple repetitions is only supported since H5BM-v0.0.4
            if (obj.fileVersionMatches(struct('major', 0, 'minor', 0, 'patch', 4)))
                [~, ~, repetitions] = H5L.iterate(obj.modeHandle(mode), 'H5_INDEX_NAME' , 'H5_ITER_INC', 0, @addMemberName, {});
            else
            % Otherwise we return '0'
                repetitions = {'0'};
            end
            
            %%
            function [status, memberNames] = addMemberName(~, memberName, memberNames)
                %% Add group to array of repetitions
                memberNames{length(memberNames)+1} = memberName;
                status = 0;
            end
        end
        
        %% Get the scale calibration data for a specific repetition
        function scaleCalibration = getScaleCalibration(obj, mode, repetition)
            payload_group = obj.payloadHandle(mode, repetition);
            try
                scaleCalibration_group = H5G.open(payload_group, 'scaleCalibration');
                points = {'micrometerToPixX', 'micrometerToPixY', 'origin', ...
                    'pixToMicrometerX', 'pixToMicrometerY', 'positionScanner', 'positionStage'};
                scaleCalibration = struct();
                for jj = 1:length(points)
                    group = H5G.open(scaleCalibration_group, points{jj});
                    attr_x = H5A.open(group, 'x');
                    x = H5A.read(attr_x);
                    H5A.close(attr_x);
                    attr_y = H5A.open(group, 'y');
                    y = H5A.read(attr_y);
                    H5A.close(attr_y);
                    scaleCalibration.(points{jj}) = [x y];
                end
            catch e
                error(['The scale calibration is invalid: ' e.message]);
            end
        end
        
        %% Get the payload data for the specified mode
        function data = readPayloadData (varargin)
            obj = varargin{1};
            mode = varargin{2};
            repetition = varargin{3};
            type = varargin{4};
            
            if nargin == 7      % Brillouin mode
                indx = varargin{5};
                indy = varargin{6};
                indz = varargin{7};
                if indx > obj.getResolutionX(mode, repetition) || indy > obj.getResolutionY(mode, repetition)
                    error('Index exceeds matrix dimensions.');
                end
                if indx < 0 || indy < 0
                    error('Subscript indices must either be real positive integers or logicals.');
                end
                imageNr = ((indz-1)*(obj.getResolutionX(mode, repetition)*obj.getResolutionY(mode, repetition)) + ...
                    (indy-1)*obj.getResolutionX(mode, repetition) + (indx-1));
            elseif nargin == 5  % ODT mode
                imageNr = varargin{5};
                if imageNr < 0
                    error('Subscript indices must either be real positive integers or logicals.');
                end
            elseif nargin == 4
            else
                return;
            end
            
            if strcmp(type, 'data')
                try
                    dset_id = H5D.open(obj.payloadDataHandle(mode, repetition), num2str(imageNr));
                    data = double(H5D.read(dset_id));
                    % Images need to be rotated for correct orientation
                    data = rot90(data);
                catch
                    error('The dataset ''%s'' cannot be found.', num2str(imageNr));
                end
            elseif strcmp(type, 'date')
                try
                    dset_id = H5D.open(obj.payloadDataHandle(mode, repetition), num2str(imageNr));
                    attr_id = H5A.open(dset_id, 'date');
                    data = H5A.read(attr_id);
                    data = transpose(data);
                catch
                    error('The attribute ''date'' of the dataset ''%s'' cannot be found.', num2str(imageNr));
                end
            elseif strcmp(type, 'channel')
                try
                    dset_id = H5D.open(obj.payloadDataHandle(mode, repetition), num2str(imageNr));
                    attr_id = H5A.open(dset_id, 'channel');
                    data = H5A.read(attr_id);
                    data = transpose(data);
                catch
                    error('The attribute ''channel'' of the dataset ''%s'' cannot be found.', num2str(imageNr));
                end
            elseif strcmp(type, 'memberNames')
                try
                    [~, ~, data] = H5L.iterate(obj.payloadDataHandle(mode, repetition), ...
                        'H5_INDEX_NAME' , 'H5_ITER_INC', 0, @addMemberName, {});
                catch
                    error('Could not determine the members of this group.');
                end
            elseif strcmp(type, 'exposure')
                try
                    dset_id = H5D.open(obj.payloadDataHandle(mode, repetition), num2str(imageNr));
                    attr_id = H5A.open(dset_id, 'exposure');
                    data = H5A.read(attr_id);
                    data = transpose(data);
                catch
                    % The exposure time is only saved for newer files, so
                    % we fall back to an error value.
                    data = NaN;
                end
            elseif strcmp(type, 'ROI')
                try
                    data = struct();
                    attributes = {'left', 'bottom', 'width_physical', 'height_physical', ...
                        'right', 'top', 'width_binned', 'height_binned'};
                    found = false;
                    for jj = 1:length(attributes)
                        try
                            dset_id = H5D.open(obj.payloadDataHandle(mode, repetition), num2str(imageNr));
                            attr_id = H5A.open(dset_id, ['ROI_' attributes{jj}]);
                            data.(attributes{jj}) = double(H5A.read(attr_id));
                            H5A.close(attr_id);
                            H5D.close(dset_id);
                            found = true;
                        catch
                            data.(attributes{jj}) = NaN;
                        end
                    end
                    if ~found
                        throw('ROI data is not available.');
                    end
                catch
                    error(['The attribute ' type ' of the dataset ''%s'' cannot be found.'], num2str(imageNr));
                end
            else
                error('The specified data type is not supported.');
            end
            
            %%
            function [status, memberNames] = addMemberName(~, memberName, memberNames)
                %% Add group to array of repetitions
                memberNames{length(memberNames)+1} = memberName;
                status = 0;
            end
        end
        
        %% Read the background data
        function data = readBackgroundData (obj, mode, repetition, type)
            index = 1;
            if strcmp(type, 'data')
                try
                    dset_id = H5D.open(obj.backgroundDataHandle(mode, repetition), num2str(index));
                    data = double(H5D.read(dset_id));
                    % Images need to be rotated for correct orientation
                    data = rot90(data);
                catch
                    error('The dataset ''%s'' cannot be found.', num2str(index));
                end
            elseif strcmp(type, 'date')
                try
                    dset_id = H5D.open(obj.backgroundDataHandle(mode, repetition), num2str(index));
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
        function data = readCalibrationData (obj, mode, repetition, type, index)
            if strcmp(type, 'data')
                try
                    dset_id = H5D.open(obj.calibrationDataHandle(mode, repetition), num2str(index));
                    data = double(H5D.read(dset_id));
                    % Images need to be rotated for correct orientation
                    data = rot90(data);
                catch
                    error('The dataset ''%s'' cannot be found.', num2str(index));
                end
            elseif strcmp(type, 'date')
                try
                    dset_id = H5D.open(obj.calibrationDataHandle(mode, repetition), num2str(index));
                    attr_id = H5A.open(dset_id, 'date');
                    data = H5A.read(attr_id);
                    data = transpose(data);
                catch
                    error('The attribute ''date'' of the dataset ''%s'' cannot be found.', num2str(index));
                end
            elseif strcmp(type, 'sample')
                try
                    dset_id = H5D.open(obj.calibrationDataHandle(mode, repetition), num2str(index));
                    attr_id = H5A.open(dset_id, 'sample');
                    data = H5A.read(attr_id);
                    data = transpose(data);
                catch
                    error('The attribute ''sample'' of the dataset ''%s'' cannot be found.', num2str(index));
                end
            elseif strcmp(type, 'shift')
                try
                    dset_id = H5D.open(obj.calibrationDataHandle(mode, repetition), num2str(index));
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
        %% Get handle for mode group (Brillouin, ODT or Fluorescence)
        function group_id = modeHandle (obj, mode)
            if (obj.fileVersionMatches(struct('major', 0, 'minor', 0, 'patch', 4)))
                group_id = H5G.open(obj.fileHandle, mode);
            elseif strcmp(mode, 'Brillouin')
                group_id = obj.fileHandle;
            else
                ME = MException('H5BM:modeNotSupported', ...
                    'This file version does not support to store %s data.', mode);
                throw(ME);
            end
        end
        
        %% Get handle for repetition group
        function group_id = repetitionHandle (obj, mode, repetition)
            if (obj.fileVersionMatches(struct('major', 0, 'minor', 0, 'patch', 4)))
                try
                    group_id = H5G.open(obj.modeHandle(mode), num2str(repetition));
                catch
                    ME = MException('H5BM:repetitionNotFound', ...
                        'The requested repetition %s was not found.', num2str(repetition));
                    throw(ME);
                end
            elseif (repetition == 0)
                group_id = obj.fileHandle;
            else
                ME = MException('H5BM:noRepetitions', ...
                    'This file version does not support to store more than one repetition.');
                throw(ME);
            end
        end
        
        %% Get handle for payload group of specified mode
        function group_id = payloadHandle(obj, mode, repetition)
            try
                group_id = H5G.open(obj.repetitionHandle(mode, repetition), 'payload');
            catch
                ME = MException('H5BM:couldNotOpenPayload', ...
                    'Could not open the payload handle for mode %s, repetition %s.', mode, num2str(repetition));
                throw(ME);
            end
        end
        
        %% Get handle for payload data
        function data_id = payloadDataHandle (obj, mode, repetition)
            group_id = obj.payloadHandle(mode, repetition);
            try
                data_id = H5G.open(group_id, 'data');
            catch
            end
        end
        
        %% Get handle for background data
        function data_id = backgroundDataHandle (obj, mode, repetition)
            try
                data_id = H5G.open(obj.repetitionHandle(mode, repetition), 'background');
            catch
            end
        end
        
        %% Get handle for calibration group
        function group_id = calibrationHandle (obj, mode, repetition)
            try
                group_id = H5G.open(obj.repetitionHandle(mode, repetition), 'calibration');
            catch
            end
        end
        
        %% Get handle for calibration data
        function data_id = calibrationDataHandle (obj, mode, repetition)
            group_id = obj.calibrationHandle(mode, repetition);
            try
                % starting with H5BM-v0.0.4 the group is called 'data'
                data_id = H5G.open(group_id, 'data');
            catch
                
                data_id = H5G.open(group_id, 'calibrationData');
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
        
        %% Check if file version fullfils requested version number
        function is = fileVersionMatches(obj, requestedVersion)
           if (obj.major < requestedVersion.major) 
               is = false;
           elseif (obj.minor < requestedVersion.minor)
               is = false;
           elseif (obj.patch < requestedVersion.patch)
               is = false;
           else
               is = true;
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