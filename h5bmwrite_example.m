%% Example file on how to read data from a h5 file created with h5bmwrite

% get the handle to the file or create the file
file = h5bmwrite('H5BM_example.h5');

% set the date attribute
file.date = 'now';

% get the comment
file.comment = sprintf('This is a comment.\nThis is the second line of the comment.');

h5bmclose(file);