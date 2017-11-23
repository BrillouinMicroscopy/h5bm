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
			getGroupHandles(FALSE);
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
		getGroupHandles(TRUE);
	}
}

H5BM::~H5BM() {
	H5Fclose(file);
}

void H5BM::getGroupHandles(bool create) {
	// payload handles
	payload = H5Gopen2(file, "payload", H5P_DEFAULT);
	if (payload < 0 && create) {
		payload = H5Gcreate2(file, "payload", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
	}
	payloadData = H5Gopen2(payload, "data", H5P_DEFAULT);
	if (payloadData < 0 && create) {
		payloadData = H5Gcreate2(payload, "data", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
	}
}

void H5BM::setAttribute(std::string attrName, std::string attr, hid_t parent) {
	if (!writable) {
		return;
	}
	hid_t type_id = H5Tcopy(H5T_C_S1);
	H5Tset_size(type_id, attr.length());
	hsize_t dims[1] = { 1 };
	hsize_t maxdims[1] = { 1 };
	hid_t space_id = H5Screate_simple(1, dims, maxdims);
	hid_t acpl_id = H5Pcreate(H5P_ATTRIBUTE_CREATE);
	hid_t attr_id;
	try {
		attr_id = H5Aopen(parent, attrName.c_str(), H5P_DEFAULT);
		if (attr_id < 0) {
			throw(-1);
		}
	}
	catch (int e) {
		attr_id = H5Acreate2(parent, attrName.c_str(), type_id, space_id, H5P_DEFAULT, H5P_DEFAULT);
	}
	H5Awrite(attr_id, type_id, attr.c_str());
	H5Aclose(attr_id);
	H5Pclose(acpl_id);
	H5Sclose(space_id);
	H5Tclose(type_id);
}

void H5BM::setAttribute(std::string attrName, int attr, hid_t parent) {
	if (!writable) {
		return;
	}
	hid_t type_id = H5Tcopy(H5T_NATIVE_INT);
	hsize_t dims[1] = { 1 };
	hsize_t maxdims[1] = { 1 };
	hid_t space_id = H5Screate_simple(1, dims, maxdims);
	hid_t acpl_id = H5Pcreate(H5P_ATTRIBUTE_CREATE);
	hid_t attr_id;
	try {
		attr_id = H5Aopen(parent, attrName.c_str(), H5P_DEFAULT);
		if (attr_id < 0) {
			throw(-1);
		}
	}
	catch (int e) {
		attr_id = H5Acreate2(parent, attrName.c_str(), type_id, space_id, H5P_DEFAULT, H5P_DEFAULT);
	}
	H5Awrite(attr_id, type_id, &attr);
	H5Aclose(attr_id);
	H5Pclose(acpl_id);
	H5Sclose(space_id);
	H5Tclose(type_id);
}

void H5BM::setAttribute(std::string attrName, double attr, hid_t parent) {
	if (!writable) {
		return;
	}
	hid_t type_id = H5Tcopy(H5T_NATIVE_DOUBLE);
	hsize_t dims[1] = { 1 };
	hsize_t maxdims[1] = { 1 };
	hid_t space_id = H5Screate_simple(1, dims, maxdims);
	hid_t acpl_id = H5Pcreate(H5P_ATTRIBUTE_CREATE);
	hid_t attr_id;
	try {
		attr_id = H5Aopen(parent, attrName.c_str(), H5P_DEFAULT);
		if (attr_id < 0) {
			throw(-1);
		}
	}
	catch (int e) {
		attr_id = H5Acreate2(parent, attrName.c_str(), type_id, space_id, H5P_DEFAULT, H5P_DEFAULT);
	}
	H5Awrite(attr_id, type_id, &attr);
	H5Aclose(attr_id);
	H5Pclose(acpl_id);
	H5Sclose(space_id);
	H5Tclose(type_id);
}

void H5BM::setAttribute(std::string attrName, std::string attr) {
	setAttribute(attrName, attr, file);
}

void H5BM::setAttribute(std::string attrName, int attr) {
	setAttribute(attrName, attr, file);
}

void H5BM::setAttribute(std::string attrName, double attr) {
	setAttribute(attrName, attr, file);
}

std::string H5BM::getAttributeString(std::string attrName, hid_t parent) {
	std::string string = "";
	try {
		hid_t attr_id = H5Aopen(parent, attrName.c_str(), H5P_DEFAULT);
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

std::string H5BM::getAttributeString(std::string attrName) {
	return getAttributeString(attrName, file);
}

int H5BM::getAttributeInt(std::string attrName, hid_t parent) {
	int buf;
	try {
		hid_t attr_id = H5Aopen(parent, attrName.c_str(), H5P_DEFAULT);
		hsize_t attr_size = H5Aget_storage_size(attr_id);
		hid_t attr_type = H5Aget_type(attr_id);
		H5Aread(attr_id, attr_type, &buf);
	}
	catch (int e) {
		// attribute was not found
	}
	return buf;
}

int H5BM::getAttributeInt(std::string attrName) {
	return getAttributeInt(attrName, file);
}

double H5BM::getAttributeDouble(std::string attrName, hid_t parent) {
	double buf;
	try {
		hid_t attr_id = H5Aopen(parent, attrName.c_str(), H5P_DEFAULT);
		hsize_t attr_size = H5Aget_storage_size(attr_id);
		hid_t attr_type = H5Aget_type(attr_id);
		H5Aread(attr_id, attr_type, &buf);
	}
	catch (int e) {
		// attribute was not found
	}
	return buf;
}

double H5BM::getAttributeDouble(std::string attrName) {
	return getAttributeDouble(attrName, file);
}

void H5BM::setDate(std::string date) {
	std::string attrName = "date";
	setAttribute(attrName, date);
}

std::string H5BM::getDate() {
	std::string attrName = "date";
	return getAttributeString(attrName);
}

std::string H5BM::getVersion() {
	std::string attrName = "version";
	return getAttributeString(attrName);
}

void H5BM::setComment(std::string comment) {
	std::string attrName = "comment";
	setAttribute(attrName, comment);
}

std::string H5BM::getComment() {
	std::string attrName = "comment";
	return getAttributeString(attrName);
}

void H5BM::setResolution(std::string direction, int resolution) {
	direction = "resolution-" + direction;
	setAttribute(direction, resolution, payload);
}

int H5BM::getResolution(std::string direction) {
	direction = "resolution-" + direction;
	return getAttributeInt(direction, payload);
}