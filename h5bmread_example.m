%% Example file on how to read data from a h5 file created with h5bmwrite

% get the handle to the file
file = h5bmread('H5BM_example.h5');

% get the version attribute
version = file.version;

% get the date attribute
date = file.date;

% get the comment
comment = file.comment;

% get the resolution in x-direction
resolution.X = file.resolutionX;

% get the resolution in y-direction
resolution.Y = file.resolutionY;

% get the resolution in z-direction
resolution.Z = file.resolutionZ;

% get the positions in x-direction
positions.X = file.positionsX;

% get the positions in x-direction
positions.Y = file.positionsY;

% get the positions in x-direction
positions.Z = file.positionsZ;

% get the payload data at index (3,3,1)
payload = struct();
payload.data = file.readPayloadData(3,3,1,'data');
% get the payload data date at index (3,3)
payload.date = file.readPayloadData(3,3,1,'date');

% get the background image data
bg = struct();
bg.data = file.readBackgroundData('data');
% get the background image data date
bg.date = file.readBackgroundData('date');

% get the calibration image data
cal = struct();
cal(1).data = file.readCalibrationData(1,'data');
% get the calibration image data date
cal(1).date = file.readCalibrationData(1,'date');
% get the calibration image data sample type
cal(1).sample = file.readCalibrationData(1,'sample');
% get the calibration image data date
cal(1).shift = file.readCalibrationData(1,'shift');

% get the calibration image data
cal(2).data = file.readCalibrationData(2,'data');
% get the calibration image data date
cal(2).date = file.readCalibrationData(2,'date');
% get the calibration image data sample type
cal(2).sample = file.readCalibrationData(2,'sample');
% get the calibration image data date
cal(2).shift = file.readCalibrationData(2,'shift');

% close the handle
h5bmclose(file);