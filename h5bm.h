#ifndef H5BM_H
#define H5BM_H

#include <string>
#include <vector>

#include "hdf5.h"

class H5BM : public QObject {
	Q_OBJECT

private:
	bool writable = FALSE;

	// set/get attribute
	void setAttribute(std::string attrName, hid_t attrType, std::string attr);
	void setStringAttribute(std::string attrName, std::string attr);
	void setDoubleAttribute(std::string attrName, std::string attr);
	std::string getAttribute(std::string attrName);

public:
	H5BM(
		QObject *parent = 0,
		const std::string filename = "Brillouin.h5",
		int flags = H5F_ACC_RDONLY
	);
	~H5BM();
	const std::string versionstring = "H5BM-v0.0.3";
	hid_t file;		// handle to the opened file

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
	int getResolution(int direction);

	// positions
	void setPositions(std::string direction, std::vector<int>& positions);
	std::vector<int> getPositions(char direction);

	// payload data
	void setPayloadData();
	void getPayloadData();

	// background data
	void setBackgroundData();
	void getBackgroundData();

	// calibration data
	void setCalibrationData();
	void getCalibrationData();

};

#endif // H5BM_H
