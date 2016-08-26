%% Example file on how to read data from a h5 file created with h5bmwrite

%% set resolution and positions
resX = 5;
x = linspace(0.2,0.3,resX);
resY = 5;
y = linspace(0.1,0.2,resY);
resZ = 1;
z = linspace(0.1,0.1,resZ);

[X, Y, Z] = meshgrid(x,y,z);

%% write the data
% get the handle to the file or create the file
file = h5bmwrite('H5BM_example.h5');

% set the date attribute
file.date = 'now';

% set the comment
file.comment = sprintf('This is a comment.\nThis is the second line of the comment.');

% set the resolution in x-direction
file.resolutionX = resX;

% set the resolution in y-direction
file.resolutionY = resY;

% set the resolution in z-direction
file.resolutionZ = resZ;

% set the positions in x-direction
file.positionsX = X;

% set the positions in x-direction
file.positionsY = Y;

% set the positions in x-direction
file.positionsZ = Z;

% set the payload data
img = randn(100,80,2);
img(10:30,10:30) = 4;
datestring = '2016-05-06';
for jj = 1:file.resolutionZ
    for kk = 1:file.resolutionY
        for ll = 1:file.resolutionX
            file.writePayloadData(ll,kk,jj,img,'datestring',datestring);
        end
    end
end

% set the background image data
bg = randn(100,80,1);
bg(15:45,15:45) = 4;
datestring = '2016-05-06T11:11:00+02:00';
file.writeBackgroundData(bg,'datestring',datestring);

% set the background image data
cal = randn(100,80,1);
cal(15:45,15:45) = 4;
datestring = 'now';
file.writeCalibrationData(cal,'datestring',datestring);

% close the handle
h5bmclose(file);