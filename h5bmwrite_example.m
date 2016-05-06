%% Example file on how to read data from a h5 file created with h5bmwrite

% get the handle to the file or create the file
file = h5bmwrite('H5BM_example.h5');

% set the date attribute
file.date = 'now';

% set the comment
file.comment = sprintf('This is a comment.\nThis is the second line of the comment.');

% set the resolution in x-direction
file.resolutionX = 5;

% set the resolution in y-direction
file.resolutionY = 5;

% set the payload data
img = randn(100,80,2);
img(10:30,10:30) = 4;
datestring = '2016-05-06';
for jj = 1:file.resolutionX
    disp(jj);
    for kk = 1:file.resolutionY
        file.writePayloadData(jj,kk,img,'datestring',datestring);
    end
end

% close the handle
h5bmclose(file);