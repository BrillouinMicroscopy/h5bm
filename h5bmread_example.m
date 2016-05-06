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

img33 = file.readPayloadData(3,3,'data');
date33 = file.readPayloadData(3,3,'date');

% close the handle
h5bmclose(file);