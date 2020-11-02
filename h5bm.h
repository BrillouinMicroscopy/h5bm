#ifndef H5BM_H
#define H5BM_H

#include <string>
#include <vector>
#include <bitset>
#include <QtWidgets>

#include "hdf5.h"
#include "TypesafeBitmask.h"

struct IMAGE {
public:
	IMAGE(int indX, int indY, int indZ, int rank, hsize_t* dims, std::string date, std::vector<unsigned short> data,
		double exposure = 0, double gain = 1, std::string binning = "1x1") :
		indX(indX), indY(indY), indZ(indZ), rank(rank), dims(dims), date(date), data(data), exposure(exposure), gain(gain), binning(binning) {};

	const int indX;
	const int indY;
	const int indZ;
	const int rank;
	const hsize_t *dims;
	const std::string date;
	const std::vector<unsigned short> data;
	const double exposure;
	const double gain;
	const std::string binning;
};

struct CALIBRATION {
public:
	CALIBRATION(int index, std::vector<unsigned short> data, int rank, hsize_t *dims, std::string sample, double shift, std::string date,
		double exposure = 0, double gain = 1, std::string binning = "1x1") :
		index(index), data(data), rank(rank), dims(dims), sample(sample), shift(shift), date(date), exposure(exposure), gain(gain), binning(binning) {};

	const int index;
	const std::vector<unsigned short> data;
	const int rank;
	const hsize_t *dims;
	const std::string sample;
	const double shift;
	const std::string date;
	const double exposure;
	const double gain;
	const std::string binning;
};

struct ODTIMAGE {
public:
	ODTIMAGE(int ind, int rank, hsize_t *dims, std::string date, std::vector<unsigned char> data,
		double exposure = 0, double gain = 1, std::string binning = "1x1") :
		ind(ind), rank(rank), dims(dims), date(date), data(data), exposure(exposure), gain(gain), binning(binning) {};

	const int ind;
	const int rank;
	const hsize_t *dims;
	const std::string date;
	const std::vector<unsigned char> data;
	const double exposure;
	const double gain;
	const std::string binning;
};

struct FLUOIMAGE {
public:
	FLUOIMAGE(int ind, int rank, hsize_t *dims, std::string date, std::string channel, std::vector<unsigned char> data,
		double exposure = 0, double gain = 1, std::string binning = "1x1") :
		ind(ind), rank(rank), dims(dims), date(date), channel(channel), data(data), exposure(exposure), gain(gain), binning(binning) {};

	const int ind;
	const int rank;
	const hsize_t *dims;
	const std::string date;
	const std::string channel;
	const std::vector<unsigned char> data;
	const double exposure;
	const double gain;
	const std::string binning;
};

enum class ACQUISITION_MODE {
	NONE = 0x0,
	BRILLOUIN = 0x2,
	ODT = 0x4,
	FLUORESCENCE = 0x8,
	SPATIALCALIBRATION = 0x10,
	MODECOUNT
};
ENABLE_BITMASK_OPERATORS(ACQUISITION_MODE)

struct RepetitionHandles {
	hid_t payload{ -1 };
	hid_t payloadData{ -1 };

	hid_t calibration{ -1 };
	hid_t calibrationData{ -1 };

	hid_t background{ -1 };
	hid_t backgroundData{ -1 };

public:
	RepetitionHandles(ACQUISITION_MODE mode, hid_t handle, bool create) { initialize(mode, handle, create); };
	~RepetitionHandles() {
		H5Gclose(payload);
		H5Gclose(payloadData);
		H5Gclose(background);
		H5Gclose(backgroundData);
		H5Gclose(calibration);
		H5Gclose(calibrationData);
	}

private:
	void initialize(ACQUISITION_MODE mode, hid_t handle, bool create) {
		// payload handles
		payload = H5Gopen2(handle, "payload", H5P_DEFAULT);
		if (payload < 0 && create) {
			payload = H5Gcreate2(handle, "payload", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
		}
		payloadData = H5Gopen2(payload, "data", H5P_DEFAULT);
		if (payloadData < 0 && create) {
			payloadData = H5Gcreate2(payload, "data", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
		}
		/*
		* Only Brillouin mode writes calibration and background data
		*/
		if ((bool)(mode & ACQUISITION_MODE::BRILLOUIN)) {
			// background handles
			background = H5Gopen2(handle, "background", H5P_DEFAULT);
			if (background < 0 && create) {
				background = H5Gcreate2(handle, "background", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
			}
			backgroundData = H5Gopen2(background, "data", H5P_DEFAULT);
			if (backgroundData < 0 && create) {
				backgroundData = H5Gcreate2(background, "data", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
			}
			// calibration handles
			calibration = H5Gopen2(handle, "calibration", H5P_DEFAULT);
			if (calibration < 0 && create) {
				calibration = H5Gcreate2(handle, "calibration", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
			}
			// legacy: this should actually be named "data" only
			calibrationData = H5Gopen2(calibration, "data", H5P_DEFAULT);
			if (calibrationData < 0 && create) {
				calibrationData = H5Gcreate2(calibration, "data", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
			}
		}
	}
};

struct ModeHandles {
	ACQUISITION_MODE mode{ ACQUISITION_MODE::NONE };
	std::string modename{};
	hid_t rootHandle{ -1 };
	hid_t currentRepetitionHandle{ -1 };

	std::unique_ptr<RepetitionHandles> groups = nullptr;

	int repetitionCount{ 0 };

public:
	ModeHandles(ACQUISITION_MODE mode, std::string modename) : mode(mode), modename(modename) {};
	~ModeHandles() {
		H5Gclose(rootHandle);
		H5Gclose(currentRepetitionHandle);
	};
};

class H5BM : public QObject {
	Q_OBJECT

public:
	H5BM(
		QObject *parent = 0,
		const std::string filename = "Brillouin.h5",
		int flags = H5F_ACC_RDONLY
	) noexcept;
	~H5BM();

	void newRepetition(ACQUISITION_MODE mode);

	// date
	void setDate(std::string datestring);
	std::string getDate();

	// version
	// setVersion() is not implemented because the version attribute is set on file creation
	std::string getVersion();

	// comment
	void setComment(std::string comment);
	std::string getComment();

	// resolution
	void setResolution(std::string direction, int resolution);
	int getResolution(std::string direction);

	// positions
	void setPositions(std::string direction, const std::vector<double> positions, const int rank, const hsize_t *dims);
	std::vector<double> getPositions(std::string direction);

	// payload data
	template <typename T>
	void setPayloadData(int indX, int indY, int indZ, const std::vector<T> data, const int rank, const hsize_t *dims, std::string date = "now",
			double exposure = 0, double gain = 1, std::string binning = "1x1");
	void setPayloadData(IMAGE *);
	void setPayloadData(ODTIMAGE *);
	void setPayloadData(FLUOIMAGE *);
	std::vector<double> getPayloadData(int indX, int indY, int indZ);
	std::string getPayloadDate(int indX, int indY, int indZ);

	// background data
	template <typename T>
	void setBackgroundData(const std::vector<T> data, const int rank, const hsize_t *dims, std::string date = "now",
		double exposure = 0, double gain = 1, std::string binning = "1x1");
	std::vector<double> getBackgroundData();
	std::string getBackgroundDate();

	// calibration data
	template <typename T>
	void setCalibrationData(int index, const std::vector<T> data, const int rank, const hsize_t *dims, std::string sample, double shift, std::string date = "now",
		double exposure = 0, double gain = 1, std::string binning = "1x1");
	std::vector<double> getCalibrationData(int index);
	std::string getCalibrationDate(int index);
	std::string getCalibrationSample(int index);
	double getCalibrationShift(int index);

private:
	bool m_fileWritable = false;
	bool m_fileValid = false;

	const std::string m_versionstring = "H5BM-v0.0.4";
	hid_t m_file{ -1 };		// handle to the opened file, default initialize to indicate no open file

	/*
	 *	Brillouin handles
	 */
	ModeHandles m_Brillouin{ ACQUISITION_MODE::BRILLOUIN, "Brillouin" };

	/*
	 *	ODT handles
	 */
	ModeHandles m_ODT{ ACQUISITION_MODE::ODT, "ODT" };

	/*
	 *	Fluorescence handles
	 */
	ModeHandles m_Fluorescence{ ACQUISITION_MODE::FLUORESCENCE, "Fluorescence" };

	template<class T>
	inline hid_t get_memtype();

#define HDF5_WRAPPER_SPECIALIZE_TYPE(T, tid) \
	template<> inline hid_t get_memtype<T>() { \
		return H5Tcopy(tid); \
	} \

	HDF5_WRAPPER_SPECIALIZE_TYPE(int, H5T_NATIVE_INT)
		HDF5_WRAPPER_SPECIALIZE_TYPE(unsigned int, H5T_NATIVE_UINT)
		HDF5_WRAPPER_SPECIALIZE_TYPE(unsigned short, H5T_NATIVE_USHORT)
		HDF5_WRAPPER_SPECIALIZE_TYPE(unsigned long long, H5T_NATIVE_ULLONG)
		HDF5_WRAPPER_SPECIALIZE_TYPE(long long, H5T_NATIVE_LLONG)
		HDF5_WRAPPER_SPECIALIZE_TYPE(char, H5T_NATIVE_CHAR)
		HDF5_WRAPPER_SPECIALIZE_TYPE(unsigned char, H5T_NATIVE_UCHAR)
		HDF5_WRAPPER_SPECIALIZE_TYPE(float, H5T_NATIVE_FLOAT)
		HDF5_WRAPPER_SPECIALIZE_TYPE(double, H5T_NATIVE_DOUBLE)
		HDF5_WRAPPER_SPECIALIZE_TYPE(bool, H5T_NATIVE_CHAR)
		HDF5_WRAPPER_SPECIALIZE_TYPE(unsigned long, H5T_NATIVE_ULONG)
		HDF5_WRAPPER_SPECIALIZE_TYPE(long, H5T_NATIVE_LONG)

		void getRootHandle(ModeHandles& handle, bool create);

	void getRepetitionHandle(ModeHandles& handle, bool create);
	void getGroupHandles(ModeHandles& handle, bool create = false);

	// set/get attribute

	template<typename T>
	void setAttribute(std::string attrName, T* attrValue, hid_t parent, hid_t type_id);
	void setAttribute(std::string attrName, std::string attr, hid_t parent);
	void setAttribute(std::string attrName, int attr, hid_t parent);
	void setAttribute(std::string attrName, double attr, hid_t parent);
	template<typename T>
	void setAttribute(std::string attrName, T attr);

	template<typename T>
	T getAttribute(std::string attrName, hid_t parent);
	template<>
	std::string getAttribute(std::string attrName, hid_t parent);
	template<typename T>
	T getAttribute(std::string attrName);

	template <typename T>
	hid_t setDataset(hid_t parent, std::vector<T> data, std::string name, const int rank, const hsize_t* dims);
	void getDataset(std::vector<double>* data, hid_t parent, std::string name);

	template <typename T>
	void setData(std::vector<T> data, std::string name, hid_t parent, const int rank, const hsize_t* dims,
		std::string date, std::string sample = "", double shift = NULL, std::string channel = "",
			double exposure = 0, double gain = 1, std::string binning = "1x1");

	std::vector<double> getData(std::string name, hid_t parent);
	std::string getDate(std::string name, hid_t parent);

	std::string calculateIndex(int indX, int indY, int indZ);

	std::string getNow();
};

template <typename T>
hid_t H5BM::setDataset(hid_t parent, std::vector<T> data, std::string name, const int rank, const hsize_t *dims) {
	hid_t type_id = get_memtype<T>();
	// For compatibility with MATLAB respect Fortran-style ordering: z, x, y
	hid_t space_id = H5Screate_simple(rank, dims, dims);

	hid_t dset_id;
	dset_id = H5Dopen2(parent, name.c_str(), H5P_DEFAULT);
	if (dset_id < 0) {
		dset_id = H5Dcreate2(parent, name.c_str(), type_id, space_id, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
	}

	H5Dwrite(dset_id, get_memtype<T>(), H5S_ALL, H5S_ALL, H5P_DEFAULT, data.data());

	H5Sclose(space_id);
	H5Tclose(type_id);

	return dset_id;
}

template <typename T>
void H5BM::setData(std::vector<T> data, std::string name, hid_t parent, const int rank, const hsize_t *dims,
	std::string date, std::string sample, double shift, std::string channel, double exposure, double gain, std::string binning) {
	if (!m_fileWritable) {
		return;
	}

	if (date.compare("now") == 0) {
		date = getNow();
	}

	// write data
	hid_t dset_id = setDataset(parent, data, name, rank, dims);

	// write date
	setAttribute("date", date.c_str(), dset_id);

	// write image attributes
	setAttribute("CLASS", "IMAGE", dset_id);
	setAttribute("IMAGE_VERSION", "1.2", dset_id);
	setAttribute("IMAGE_SUBCLASS", "IMAGE_GRAYSCALE", dset_id);

	// write sample name
	if (sample != "") {
		setAttribute("sample", sample.c_str(), dset_id);
	}

	// write sample name
	if (shift != NULL) {
		setAttribute("shift", shift, dset_id);
	}

	// write channel name
	if (channel != "") {
		setAttribute("channel", channel, dset_id);
	}

	// set camera meta data
	setAttribute("exposure", exposure, dset_id);
	setAttribute("gain", gain, dset_id);
	setAttribute("binning", binning.c_str(), dset_id);

	H5Dclose(dset_id);

	// write last-modified date to file
	setAttribute("last-modified", getNow());
}

template <typename T>
void H5BM::setPayloadData(int indX, int indY, int indZ, const std::vector<T> data, const int rank, const hsize_t *dims, std::string date,
		double exposure, double gain, std::string binning) {
	auto name = calculateIndex(indX, indY, indZ);

	setData(data, name, m_Brillouin.groups->payloadData, rank, dims, date, "", NULL, "", exposure, gain, binning);
}

template <typename T>
void H5BM::setCalibrationData(int index, const std::vector<T> data, const int rank, const hsize_t * dims, std::string sample, double shift, std::string date,
	double exposure, double gain, std::string binning) {
	setData(data, std::to_string(index), m_Brillouin.groups->calibrationData, rank, dims, date, sample, shift, "", exposure, gain, binning);
}

template <typename T>
void H5BM::setBackgroundData(const std::vector<T> data, const int rank, const hsize_t *dims, std::string date,
	double exposure, double gain, std::string binning) {
	// legacy: this should actually be stored under "backgroundData"
	setData(data, "1", m_Brillouin.groups->background, rank, dims, date, "", NULL, "", exposure, gain, binning);
}

#endif // H5BM_H
