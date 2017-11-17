#ifndef H5BM_H
#define H5BM_H

#include "hdf5.h"

class H5BM : public QObject {
	Q_OBJECT

public:
	H5BM(QObject *parent = 0);
	~H5BM();
	hid_t file;

};

#endif // H5BM_H
