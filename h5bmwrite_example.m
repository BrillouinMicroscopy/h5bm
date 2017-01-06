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
payload.data = randn(100,80,2);
payload.data(10:30,10:30) = 4;
payload.date = '2016-05-06';
for jj = 1:file.resolutionZ
    for kk = 1:file.resolutionY
        for ll = 1:file.resolutionX
            file.writePayloadData(ll,kk,jj,payload.data,'datestring',payload.date);
        end
    end
end

% set the background image data
bg = struct();
bg.data = randn(100,80,2);
bg.data(15:45,15:45) = 4;
bg.date = '2016-05-06T11:11:00+02:00';
file.writeBackgroundData(bg.data,'datestring',bg.date);

cal = struct();
% set the calibration image data for the first calibration sample
cal(1).data = randn(100,80,3);
cal(1).data(15:45,15:45) = 4;
cal(1).date = 'now';
cal(1).sample = 'Methanol';
cal(1).shift = 3.799;
file.writeCalibrationData(1,cal(1).data,cal(1).shift,'datestring',cal(1).date,'sample',cal(1).sample);

% set the calibration image data for the second calibration sample
cal(2).data = randn(100,80,4);
cal(2).data(15:45,15:45) = 4;
cal(2).date = 'now';
cal(2).sample = 'Water';
cal(2).shift = 5.088;
file.writeCalibrationData(2,cal(2).data,cal(2).shift,'datestring',cal(2).date,'sample',cal(2).sample);

% close the handle
h5bmclose(file);