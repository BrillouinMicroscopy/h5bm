#include "stdafx.h"
#include "h5bm.h"
#include "filesystem"

using namespace std::experimental::filesystem::v1;

H5BM::H5BM(QObject *parent, const std::string filename, int flags)
	: QObject(parent) {
	if (flags == H5F_ACC_RDONLY) {
		if (exists(filename)) {
			file = H5Fopen(&filename[0], flags, H5P_DEFAULT);
		}
	} else if (flags == H5F_ACC_RDWR) {
		if (!exists(filename)) {
			// create the file
			file = H5Fcreate(&filename[0], H5F_ACC_EXCL, H5P_DEFAULT, H5P_DEFAULT);
			// set the version attribute
			hid_t type_id = H5Tcopy(H5T_C_S1);
			H5Tset_size(type_id, versionstring.length());
			hsize_t dims[1] = { 1 };
			hsize_t maxdims[1] = { 1 };
			hid_t space_id = H5Screate_simple(1, dims, maxdims);
			hid_t attr_id = H5Acreate2(file, "version", type_id, space_id, H5P_DEFAULT, H5P_DEFAULT);
			H5Awrite(attr_id, type_id, versionstring.c_str());
			H5Aclose(attr_id);
			H5Sclose(space_id);
			H5Tclose(type_id);
		} else {
			file = H5Fopen(&filename[0], flags, H5P_DEFAULT);
		}
	}
}

H5BM::~H5BM() {
	H5Fclose(file);
}
