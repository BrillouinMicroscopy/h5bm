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
			setAttribute("version", versionstring);
		} else {
			file = H5Fopen(&filename[0], flags, H5P_DEFAULT);
		}
	}
}

H5BM::~H5BM() {
	H5Fclose(file);
}

void H5BM::setAttribute(std::string attrName, std::string datestring) {
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
		attr_id = H5Aopen(file, attrName.c_str(), H5P_DEFAULT);
		if (attr_id < 0) {
			throw(-1);
		}
	}
	catch (int e) {
		attr_id = H5Acreate2(file, attrName.c_str(), type_id, space_id, H5P_DEFAULT, H5P_DEFAULT);
	}
	H5Awrite(attr_id, type_id, datestring.c_str());
	H5Aclose(attr_id);
	H5Pclose(acpl_id);
	H5Sclose(space_id);
	H5Tclose(type_id);
}

std::string H5BM::getAttribute(std::string attrName) {
	std::string string = "";
	try {
		hid_t attr_id = H5Aopen(file, attrName.c_str(), H5P_DEFAULT);
		hsize_t attr_size = H5Aget_storage_size(attr_id);
		char *buf = new char[attr_size + 1];
		hid_t attr_type = H5Aget_type(attr_id);
		H5Aread(attr_id, attr_type, buf);
		string.assign(buf, attr_size);
		delete[] buf;
		buf = 0;
	}
	catch (int e) {
		// attribute was not found
	}
	return string;
}

void H5BM::setDate(std::string datestring) {
	std::string attrName = "date";
	setAttribute(attrName, datestring);
}

std::string H5BM::getDate() {
	std::string attrName = "date";
	return getAttribute(attrName);
}

std::string H5BM::getVersion() {
	std::string attrName = "version";
	return getAttribute(attrName);
}

void H5BM::setComment(std::string datestring) {
	std::string attrName = "comment";
	setAttribute(attrName, datestring);
}

std::string H5BM::getComment() {
	std::string attrName = "comment";
	return getAttribute(attrName);
}
