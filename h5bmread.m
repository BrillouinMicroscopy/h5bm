function [handle] = h5bmread (filePath)
    handle = h5bm(filePath, 'H5F_ACC_RDONLY');
end