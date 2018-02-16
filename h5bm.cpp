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
	H5Gclose(payload);
	H5Gclose(payloadData);
	H5Gclose(background);
	H5Gclose(backgroundData);
	H5Gclose(calibration);
	H5Gclose(calibrationData);
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
	// background handles
	background = H5Gopen2(file, "background", H5P_DEFAULT);
	if (background < 0 && create) {
		background = H5Gcreate2(file, "background", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
	}
	backgroundData = H5Gopen2(background, "data", H5P_DEFAULT);
	if (backgroundData < 0 && create) {
		backgroundData = H5Gcreate2(background, "data", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
	}
	// calibration handles
	calibration = H5Gopen2(file, "calibration", H5P_DEFAULT);
	if (calibration < 0 && create) {
		calibration = H5Gcreate2(file, "calibration", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
	}
	calibrationData = H5Gopen2(calibration, "data", H5P_DEFAULT);
	if (calibrationData < 0 && create) {
		calibrationData = H5Gcreate2(calibration, "data", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
	}
}

template<typename T>
void H5BM::setAttribute(std::string attrName, T* attrValue, hid_t parent, hid_t type_id) {
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
	H5Awrite(attr_id, type_id, attrValue);
	H5Aclose(attr_id);
	H5Pclose(acpl_id);
	H5Sclose(space_id);
	H5Tclose(type_id);
}

void H5BM::setAttribute(std::string attrName, std::string attr, hid_t parent) {
	hid_t type_id = H5Tcopy(H5T_C_S1);
	H5Tset_size(type_id, attr.length());
	setAttribute(attrName, attr.c_str(), parent, type_id);
}

void H5BM::setAttribute(std::string attrName, int attr, hid_t parent) {
	hid_t type_id = H5Tcopy(H5T_NATIVE_INT);
	setAttribute(attrName, &attr, parent, type_id);
}

void H5BM::setAttribute(std::string attrName, double attr, hid_t parent) {
	hid_t type_id = H5Tcopy(H5T_NATIVE_DOUBLE);
	setAttribute(attrName, &attr, parent, type_id);
}

template<typename T>
void H5BM::setAttribute(std::string attrName, T attr) {
	setAttribute(attrName, attr, file);
}

template<typename T>
T H5BM::getAttribute(std::string attrName, hid_t parent) {
	T buf;
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

template<>
std::string H5BM::getAttribute(std::string attrName, hid_t parent) {
	std::string string = "";
	try {
		hid_t attr_id = H5Aopen(parent, attrName.c_str(), H5P_DEFAULT);
		hsize_t attr_size = H5Aget_storage_size(attr_id);
		hid_t attr_type = H5Aget_type(attr_id);
		char *buf = new char[attr_size + 1];
		H5Aread(attr_id, attr_type, buf);
		string.assign(buf, attr_size);
		delete[] buf;
		buf = 0;
	} catch (int e) {
		// attribute was not found
	}
	return string;
}

template<typename T>
T H5BM::getAttribute(std::string attrName) {
	return getAttribute<T>(attrName, file);
}

void H5BM::setDate(std::string date) {
	std::string attrName = "date";
	setAttribute(attrName, date);
}

std::string H5BM::getDate() {
	std::string attrName = "date";
	return getAttribute<std::string>(attrName);
}

std::string H5BM::getVersion() {
	std::string attrName = "version";
	return getAttribute<std::string>(attrName);
}

void H5BM::setComment(std::string comment) {
	std::string attrName = "comment";
	setAttribute(attrName, comment);
}

std::string H5BM::getComment() {
	std::string attrName = "comment";
	return getAttribute<std::string>(attrName);
}

void H5BM::setResolution(std::string direction, int resolution) {
	direction = "resolution-" + direction;
	setAttribute(direction, resolution, payload);
}

int H5BM::getResolution(std::string direction) {
	direction = "resolution-" + direction;
	return getAttribute<int>(direction, payload);
}

hid_t H5BM::setDataset(hid_t parent, std::vector<double> data, std::string name, const int rank, const hsize_t *dims) {
	hid_t type_id = H5Tcopy(H5T_NATIVE_DOUBLE);
	// For compatibility with MATLAB respect Fortran-style ordering: z, x, y
	hid_t space_id = H5Screate_simple(rank, dims, dims);

	hid_t dset_id;
	try {
		dset_id = H5Dopen2(parent, name.c_str(), H5P_DEFAULT);
		if (dset_id < 0) {
			throw(-1);
		}
	}
	catch (int e) {
		dset_id = H5Dcreate2(parent, name.c_str(), type_id, space_id, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
	}

	H5Dwrite(dset_id, H5T_NATIVE_DOUBLE, H5S_ALL, H5S_ALL, H5P_DEFAULT, data.data());

	H5Sclose(space_id);
	H5Tclose(type_id);

	return dset_id;
}

void H5BM::getDataset(std::vector<double>* data, hid_t parent, std::string name) {
	hid_t dset_id = H5Dopen2(parent, name.c_str(), H5P_DEFAULT);

	// get dataspace
	hid_t space_id = H5Dget_space(dset_id);

	// query dataspace length
	hsize_t nrPoints = H5Sget_simple_extent_npoints(space_id);

	// resize positions vector accordingly
	data->resize(nrPoints);

	H5Dread(dset_id, H5T_NATIVE_DOUBLE, H5S_ALL, H5S_ALL, H5P_DEFAULT, data->data());
}

void H5BM::setPositions(std::string direction, const std::vector<double> positions, const int rank, const hsize_t *dims) {
	if (!writable) {
		return;
	}
	direction = "positions-" + direction;

	hid_t dset_id = setDataset(payload, positions, direction, rank, dims);
	H5Dclose(dset_id);
}

std::vector<double> H5BM::getPositions(std::string direction) {
	direction = "positions-" + direction;

	std::vector<double> positions;
	try {
		getDataset(&positions, payload, direction);
	} catch (int e) {
		//
	}
	return positions;
}

void H5BM::setData(std::vector<double> data, std::string name, hid_t parent, const int rank, const hsize_t *dims, std::string date, std::string sample, double shift) {
	if (!writable) {
		return;
	}

	if (date.compare("now") == 0) {
		date = QDateTime::currentDateTime().toOffsetFromUtc(QDateTime::currentDateTime().offsetFromUtc())
			.toString(Qt::ISODate).toStdString();
	}

	// write data
	hid_t dset_id = setDataset(parent, data, name, rank, dims);

	// write date
	setAttribute("date", date.c_str(), dset_id);

	// write sample name
	if (sample != "") {
		setAttribute("sample", sample.c_str(), dset_id);
	}

	// write sample name
	if (shift != NULL) {
		setAttribute("shift", shift, dset_id);
	}

	H5Dclose(dset_id);
}

std::vector<double> H5BM::getData(std::string name, hid_t parent) {
	std::vector<double> data;
	try {
		getDataset(&data, parent, name);
	}
	catch (int e) {
		//
	}
	return data;
}

std::string H5BM::getDate(std::string name, hid_t parent) {
	std::string date;
	try {
		hid_t dset_id = H5Dopen2(parent, name.c_str(), H5P_DEFAULT);;
		date = getAttribute<std::string>("date", dset_id);
		H5Dclose(dset_id);
	}
	catch (int e) {
		//
	}
	return date;
}

void H5BM::setPayloadData(int indX, int indY, int indZ, const std::vector<double> data, const int rank, const hsize_t *dims, std::string date) {
	auto name = calculateIndex(indX, indY, indZ);

	setData(data, name, payloadData, rank, dims, date);
}

std::vector<double> H5BM::getPayloadData(int indX, int indY, int indZ) {
	auto name = calculateIndex(indX, indY, indZ);
	return getData(name, payloadData);
}

std::string H5BM::getPayloadDate(int indX, int indY, int indZ) {
	auto name = calculateIndex(indX, indY, indZ);
	return getDate(name, payloadData);
}

std::string H5BM::calculateIndex(int indX, int indY, int indZ) {
	int resolutionX = getResolution("x");
	int resolutionY = getResolution("y");
	int resolutionZ = getResolution("z");

	int index = (indZ*(resolutionX*resolutionY) + indY * resolutionX + indX);
	return std::to_string(index);
}

void H5BM::setBackgroundData(const std::vector<double> data, const int rank, const hsize_t *dims, std::string date) {
	setData(data, "1", backgroundData, rank, dims, date);
}

std::vector<double> H5BM::getBackgroundData() {
	return getData("1", backgroundData);
}

std::string H5BM::getBackgroundDate() {
	return getDate("1", backgroundData);
}

void H5BM::setCalibrationData(int index, const std::vector<double> data, const int rank, const hsize_t * dims, std::string sample, double shift, std::string date) {
	setData(data, std::to_string(index), calibrationData, rank, dims, date, sample, shift);
}

std::vector<double> H5BM::getCalibrationData(int index) {
	return std::vector<double>();
}

std::string H5BM::getCalibrationDate(int index) {
	return std::string();
}

std::string H5BM::getCalibrationSample(int index) {
	return std::string();
}

double H5BM::getCalibrationShift(int index) {
	return 0.0;
}
