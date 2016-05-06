function [handle] = h5bmwrite (filePath)
    handle = h5bm(filePath, 'H5F_ACC_RDWR');
end