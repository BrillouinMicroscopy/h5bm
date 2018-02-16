#ifndef H5BM_H
#define H5BM_H

#include <string>
#include <vector>

#include "hdf5.h"

class H5BM : public QObject {
	Q_OBJECT

private:
	bool writable = FALSE;

	const std::string versionstring = "H5BM-v0.0.3";
	hid_t file;		// handle to the opened file

	hid_t payload;
	hid_t payloadData;

	hid_t calibration;
	hid_t calibrationData;

	hid_t background;
	hid_t backgroundData;

	void getGroupHandles(bool create = FALSE);

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

	hid_t setDataset(hid_t parent, std::vector<double> data, std::string name, const int rank, const hsize_t *dims);

public:
	H5BM(
		QObject *parent = 0,
		const std::string filename = "Brillouin.h5",
		int flags = H5F_ACC_RDONLY
	);
	~H5BM();

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
	void setPayloadData(int indX, int indY, int indZ, const std::vector<double> data, const int rank, const hsize_t *dims, std::string date = "now");
	std::vector<double> getPayloadData(int indX, int indY, int indZ);
	std::string getPayloadDate(int indX, int indY, int indZ);

	// background data
	void setBackgroundData();
	void getBackgroundData();

	// calibration data
	void setCalibrationData();
	void getCalibrationData();

};

#endif // H5BM_H
