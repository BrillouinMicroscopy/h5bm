#include "stdafx.h"
#include "h5bm.h"
#include "filesystem"

using namespace std::experimental::filesystem::v1;

H5BM::H5BM(QObject *parent, const std::string filename, int flags)
	: QObject(parent) {
	if (flags == H5F_ACC_RDONLY) {
		writable = FALSE;
		if (exists(filename)) {
			file = H5Fopen(&filename[0], flags, H5P_DEFAULT);
		}
	} else if (flags == H5F_ACC_RDWR) {
		writable = TRUE;
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

void H5BM::setDate(std::string datestring) {
	if (!writable) {
		return;
	}
	hid_t type_id = H5Tcopy(H5T_C_S1);
	H5Tset_size(type_id, datestring.length());
	hsize_t dims[1] = { 1 };
	hsize_t maxdims[1] = { 1 };
	hid_t space_id = H5Screate_simple(1, dims, maxdims);
	hid_t acpl_id = H5Pcreate(H5P_ATTRIBUTE_CREATE);
	hid_t attr_id;
	try {
		attr_id = H5Aopen(file, "date", H5P_DEFAULT);
		if (attr_id < 0) {
			throw(-1);
		}
	} catch (int e) {
		attr_id = H5Acreate2(file, "date", type_id, space_id, H5P_DEFAULT, H5P_DEFAULT);
	}
	H5Awrite(attr_id, type_id, datestring.c_str());
	H5Aclose(attr_id);
	H5Pclose(acpl_id);
	H5Sclose(space_id);
	H5Tclose(type_id);
}

std::string H5BM::getDate() {
	std::string datestring = "";
	try {
		hid_t attr_id = H5Aopen(file, "date", H5P_DEFAULT);
		hsize_t attr_size = H5Aget_storage_size(attr_id);
		char *buf = new char[attr_size+1];
		hid_t attr_type = H5Aget_type(attr_id);
		H5Aread(attr_id, attr_type, buf);
		datestring.assign(buf, attr_size);
		delete[] buf;
		buf = 0;
	} catch (int e) {
		// attribute was not found
	}
	return datestring;
}
