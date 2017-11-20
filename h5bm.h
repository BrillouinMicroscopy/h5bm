#ifndef H5BM_H
#define H5BM_H

#include <string>

#include "hdf5.h"

class H5BM : public QObject {
	Q_OBJECT

public:
	H5BM(
		QObject *parent = 0,
		const std::string filename = "Brillouin.h5",
		int flags = H5F_ACC_RDONLY
	);
	~H5BM();
	const std::string versionstring = "H5BM-v0.0.3";
	hid_t file;		// handle to the opened file

};

#endif // H5BM_H
