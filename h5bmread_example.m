%% Example file on how to read data from a h5 file created with h5bmwrite

% get the handle to the file
file = h5bmread('H5BM_example.h5');

% get the version attribute
version = file.version;

% get the date attribute
date = file.date;

% get the comment
comment = file.comment;

% close the handle
h5bmclose(file);