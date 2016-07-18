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

% get the payload data at index (3,3)
img33_data = file.readPayloadData(3,3,'data');
% get the payload data date at index (3,3)
img33_date = file.readPayloadData(3,3,'date');

% get the background image data
bg_data = file.readBackgroundData('data');
% get the background image data date
bg_date = file.readBackgroundData('date');

% close the handle
h5bmclose(file);