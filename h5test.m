%% Write data
testdata = [1 3 5; 2 4 6];
ccc;

filename = 'BM-Test_01';

version = 'H5BM-v0.0.1';
date = datetime('now');
date.TimeZone = 'local';
date.Format = 'uuuu-MM-dd''T''HH:mm:ssXXX';
date = char(date);
comments = sprintf('First Test of datastorage for BM using the HDF5 standard.\nSeems to work.');

resolution_x = 256;
resolution_y = 512;

%% create the HDF5 file
filepath = fullfile('',[filename,'.h5']);      %filename
fileID = H5F.create(filepath,'H5F_ACC_TRUNC','H5P_DEFAULT','H5P_DEFAULT');

%% create the version attribute
type_id = H5T.copy('H5T_C_S1');
H5T.set_size (type_id, numel(version));
space_id = H5S.create_simple(1,1,1);
acpl_id = H5P.create('H5P_ATTRIBUTE_CREATE');
attr_id = H5A.create(fileID,'version',type_id,space_id,acpl_id);
H5A.write(attr_id,type_id,version);
H5A.close(attr_id);
H5P.close(acpl_id);
H5S.close(space_id);
H5T.close(type_id);

%% create the datetime attribute
type_id = H5T.copy('H5T_C_S1');
H5T.set_size (type_id, numel(date));
space_id = H5S.create_simple(1,1,1);
acpl_id = H5P.create('H5P_ATTRIBUTE_CREATE');
attr_id = H5A.create(fileID,'date',type_id,space_id,acpl_id);
H5A.write(attr_id,type_id,date);
H5A.close(attr_id);
H5P.close(acpl_id);
H5S.close(space_id);
H5T.close(type_id);

%% create the comments attribute
type_id = H5T.copy('H5T_C_S1');
H5T.set_size (type_id, numel(comments));
space_id = H5S.create_simple(1,1,1);
acpl_id = H5P.create('H5P_ATTRIBUTE_CREATE');
attr_id = H5A.create(fileID,'comments',type_id,space_id,acpl_id);
H5A.write(attr_id,type_id,comments);
H5A.close(attr_id);
H5P.close(acpl_id);
H5S.close(space_id);
H5T.close(type_id);

%% create group for payload data
plist = 'H5P_DEFAULT';
group_id = H5G.create(fileID,'payload',plist,plist,plist);

    % create attributes for resolutions
    type_id = H5T.copy('H5T_NATIVE_DOUBLE');
    space_id = H5S.create_simple(1,1,1);
    acpl_id = H5P.create('H5P_ATTRIBUTE_CREATE');
    attr_id = H5A.create(group_id,'resolution-x',type_id,space_id,acpl_id);
    H5A.write(attr_id,type_id,resolution_x);
    H5A.close(attr_id);
    H5P.close(acpl_id);
    H5S.close(space_id);
    H5T.close(type_id);
    
    type_id = H5T.copy('H5T_NATIVE_DOUBLE');
    space_id = H5S.create_simple(1,1,1);
    acpl_id = H5P.create('H5P_ATTRIBUTE_CREATE');
    attr_id = H5A.create(group_id,'resolution-y',type_id,space_id,acpl_id);
    H5A.write(attr_id,type_id,resolution_y);
    H5A.close(attr_id);
    H5P.close(acpl_id);
    H5S.close(space_id);
    H5T.close(type_id);
    

    plist = 'H5P_DEFAULT';
    data_id = H5G.create(group_id,'data',plist,plist,plist);
    
    H5G.close(data_id);

H5G.close(group_id);

% datatypeID = H5T.copy('H5T_NATIVE_DOUBLE');
% dims = size(testdata);
% dataspaceID = H5S.create_simple(2, fliplr(dims), []);
% dsetname = 'my_dataset';
% datasetID = H5D.create(fileID,dsetname,datatypeID,dataspaceID,'H5P_DEFAULT');
% H5D.write(datasetID,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',...
%     'H5P_DEFAULT',testdata);
% H5D.close(datasetID);
% H5S.close(dataspaceID);
% H5T.close(datatypeID);
H5F.close(fileID);

fileinfo = hdf5info(filepath);

% %% Read data
% fileID = H5F.open(filename,'H5F_ACC_RDONLY','H5P_DEFAULT');
% datasetID = H5D.open(fileID,dsetname);
% returned_data = H5D.read(datasetID,'H5ML_DEFAULT',...
%     'H5S_ALL','H5S_ALL','H5P_DEFAULT');
% H5D.close(datasetID);
% H5F.close(fileID);
% 
% %% Compare data
% isequal(testdata,returned_data);
