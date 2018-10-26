%% Example file on how to read data from a h5 file created with h5bmwrite

% get the handle to the file
file = h5bmread('H5BM_example.h5');

% get the version attribute
version = file.version;

% get the date attribute
date = file.date;

% get the comment
comment = file.comment;

%% Brillouin

% get the repetition date
repDate = file.getDate('Brillouin', 0);

% get the resolution in x-direction
resolution.X = file.getResolutionX('Brillouin', 0);

% get the resolution in y-direction
resolution.Y = file.getResolutionY('Brillouin', 0);

% get the resolution in z-direction
resolution.Z = file.getResolutionZ('Brillouin', 0);

% get the positions in x-direction
positions.X = file.getPositionsX('Brillouin', 0);

% get the positions in x-direction
positions.Y = file.getPositionsY('Brillouin', 0);

% get the positions in x-direction
positions.Z = file.getPositionsZ('Brillouin', 0);

% get the payload data at index (3,3,1)
payload = struct();
payload.data = file.readPayloadData('Brillouin', 0, 'data', 3, 3, 1);
% get the payload data date at index (3,3)
payload.date = file.readPayloadData('Brillouin', 0, 'date', 3, 3, 1);

% get the background image data
bg = struct();
bg.data = file.readBackgroundData('Brillouin', 0, 'data');
% get the background image data date
bg.date = file.readBackgroundData('Brillouin', 0, 'date');

% get the calibration image data
cal = struct();
cal(1).data = file.readCalibrationData('Brillouin', 0, 'data', 1);
% get the calibration image data date
cal(1).date = file.readCalibrationData('Brillouin', 0, 'date', 1);
% get the calibration image data sample type
cal(1).sample = file.readCalibrationData('Brillouin', 0, 'sample', 1);
% get the calibration image data date
cal(1).shift = file.readCalibrationData('Brillouin', 0,'shift', 1);

% get the calibration image data
cal(2).data = file.readCalibrationData('Brillouin', 0, 'data', 2);
% get the calibration image data date
cal(2).date = file.readCalibrationData('Brillouin', 0, 'date', 2);
% get the calibration image data sample type
cal(2).sample = file.readCalibrationData('Brillouin', 0, 'sample', 2);
% get the calibration image data date
cal(2).shift = file.readCalibrationData('Brillouin', 0, 'shift', 2);

%% ODT

ODTpayload = struct();
ODTpayload.data = file.readPayloadData('ODT', 0, 'data', 1);

% close the handle
h5bmclose(file);