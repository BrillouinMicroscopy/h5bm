%% this script merges different H5BM files into a single one
% this might be necessary if different samples were measured and should be
% evaluated using the standard scripts

load_path = 'RawData';
targetFile = h5bmwrite([load_path filesep 'Target.h5']);
targetFile.date = 'now';

% set the comment
targetFile.comment = sprintf('This file was merged from the "Source_XX" files.');

nrMeas = 5;
nrPics = 60;

targetFile.resolutionX = nrMeas;
targetFile.resolutionY = 1;
targetFile.resolutionZ = 1;

%% write measurement data
for jj = 1:nrMeas
    %% load the measurement data
    filename = sprintf('Source_%02d',jj);
    loadFile = [load_path filesep filename '.h5'];
    file = h5bmread(loadFile);
    
    tmp = file.readPayloadData(1,1,1,'data');
    img = NaN(size(tmp,1),size(tmp,2),nrPics);
    for ii = 1:nrPics
        img(:,:,ii) = file.readPayloadData(1,1,ii,'data');
    end
    datestring = file.readPayloadData(1,1,1,'date');
    h5bmclose(file);
    targetFile.writePayloadData(jj,1,1,img,'datestring',datestring);
end

%% write calibration data
filename = sprintf('Calibration');
loadFile = [load_path filesep filename '.h5'];
file = h5bmread(loadFile);

img = NaN(size(tmp,1),size(tmp,2),nrPics);
for ii = 1:nrPics
    img(:,:,ii) = file.readPayloadData(1,1,ii,'data');
end
datestring = file.readPayloadData(1,1,1,'date');
h5bmclose(file);
targetFile.writeCalibrationData(img,'datestring',datestring);

h5bmclose(targetFile);
