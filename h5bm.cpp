#include "stdafx.h"
#include "h5bm.h"

H5BM::H5BM(QObject *parent)
	: QObject(parent) {

	file = H5Fcreate("test.h5", H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT);
}

H5BM::~H5BM() {
}
