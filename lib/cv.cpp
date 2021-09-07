cv::Mat matSrc, matDst1, matDst2;

	matSrc = cv::imread("lena.jpg", 2 | 4);
	matDst1 = cv::Mat(cv::Size(800, 1000), matSrc.type(), cv::Scalar::all(0));
	matDst2 = cv::Mat(matDst1.size(), matSrc.type(), cv::Scalar::all(0));

	double scale_x = (double)matSrc.cols / matDst1.cols;
	double scale_y = (double)matSrc.rows / matDst1.rows;

    // 最邻近
	for (int i = 0; i < matDst1.cols; ++i)
	{
		int sx = cvFloor(i * scale_x);
		sx = std::min(sx, matSrc.cols - 1);
		for (int j = 0; j < matDst1.rows; ++j)
		{
			int sy = cvFloor(j * scale_y);
			sy = std::min(sy, matSrc.rows - 1);
			matDst1.at<cv::Vec3b>(j, i) = matSrc.at<cv::Vec3b>(sy, sx);
		}
	}
	cv::imwrite("nearest_1.jpg", matDst1);

	cv::resize(matSrc, matDst2, matDst1.size(), 0, 0, 0);
	cv::imwrite("nearest_2.jpg", matDst2);

	// lanczos
	#ifdef _MSC_VER
    	cv::resize(matSrc, matDst2, matDst1.size(), 0, 0, 3);
    	cv::imwrite("E:/GitCode/OpenCV_Test/test_images/area_2.jpg", matDst2);
    #else
    	cv::resize(matSrc, matDst2, matDst1.size(), 0, 0, 3);
    	cv::imwrite("area_2.jpg", matDst2);
    #endif

    	fprintf(stdout, "==== start area ====\n");
    	double inv_scale_x = 1. / scale_x;
    	double inv_scale_y = 1. / scale_y;
    	int iscale_x = cv::saturate_cast<int>(scale_x);
    	int iscale_y = cv::saturate_cast<int>(scale_y);
    	bool is_area_fast = std::abs(scale_x - iscale_x) < DBL_EPSILON && std::abs(scale_y - iscale_y) < DBL_EPSILON;

    	if (scale_x >= 1 && scale_y >= 1)  { // zoom out
    		if (is_area_fast)  { // integer multiples
    			for (int j = 0; j < matDst1.rows; ++j) {
    				int sy = std::min(cvFloor(j * scale_y), matSrc.rows - 1);

    				for (int i = 0; i < matDst1.cols; ++i) {
    					int sx = std::min(cvFloor(i * scale_x), matSrc.cols -1);

    					matDst1.at<cv::Vec3b>(j, i) = matSrc.at<cv::Vec3b>(sy, sx);
    				}
    			}
    #ifdef _MSC_VER
    			cv::imwrite("E:/GitCode/OpenCV_Test/test_images/area_1.jpg", matDst1);
    #else
    			cv::imwrite("area_1.jpg", matDst1);
    #endif
    			return 0;
    		}

    		for (int j = 0; j < matDst1.rows; ++j) {
    			double fsy1 = j * scale_y;
    			double fsy2 = fsy1 + scale_y;
    			double cellHeight = cv::min(scale_y, matSrc.rows - fsy1);

    			int sy1 = cvCeil(fsy1), sy2 = cvFloor(fsy2);

    			sy2 = std::min(sy2, matSrc.rows - 2);
    			sy1 = std::min(sy1, sy2);

    			float cbufy[2];
    			cbufy[0] = (float)((sy1 - fsy1) / cellHeight);
    			cbufy[1] = (float)(std::min(std::min(fsy2 - sy2, 1.), cellHeight) / cellHeight);

    			for (int i = 0; i < matDst1.cols; ++i) {
    				double fsx1 = i * scale_x;
    				double fsx2 = fsx1 + scale_x;
    				double cellWidth = std::min(scale_x, matSrc.cols - fsx1);

    				int sx1 = cvCeil(fsx1), sx2 = cvFloor(fsx2);

    				sx2 = std::min(sx2, matSrc.cols - 2);
    				sx1 = std::min(sx1, sx2);

    				float cbufx[2];
    				cbufx[0] = (float)((sx1 - fsx1) / cellWidth);
    				cbufx[1] = (float)(std::min(std::min(fsx2 - sx2, 1.), cellWidth) / cellWidth);

    				for (int k = 0; k < matSrc.channels(); ++k) {
    					matDst1.at<cv::Vec3b>(j, i)[k] = (uchar)(matSrc.at<cv::Vec3b>(sy1, sx1)[k] * cbufx[0] * cbufy[0] +
    						matSrc.at<cv::Vec3b>(sy1 + 1, sx1)[k] * cbufx[0] * cbufy[1] +
    						matSrc.at<cv::Vec3b>(sy1, sx1 + 1)[k] * cbufx[1] * cbufy[0] +
    						matSrc.at<cv::Vec3b>(sy1 + 1, sx1 + 1)[k] * cbufx[1] * cbufy[1]);
    				}
    			}
    		}
    #ifdef _MSC_VER
    		cv::imwrite("E:/GitCode/OpenCV_Test/test_images/area_1.jpg", matDst1);
    #else
    		cv::imwrite("area_1.jpg", matDst1);
    #endif

    		return 0;
    	}

    	//zoom in,it is emulated using some variant of bilinear interpolation
    	for (int j = 0; j < matDst1.rows; ++j) {
    		int  sy = cvFloor(j * scale_y);
    		float fy = (float)((j + 1) - (sy + 1) * inv_scale_y);
    		fy = fy <= 0 ? 0.f : fy - cvFloor(fy);
    		sy = std::min(sy, matSrc.rows - 2);

    		short cbufy[2];
    		cbufy[0] = cv::saturate_cast<short>((1.f - fy) * 2048);
    		cbufy[1] = 2048 - cbufy[0];

    		for (int i = 0; i < matDst1.cols; ++i) {
    			int sx = cvFloor(i * scale_x);
    			float fx = (float)((i + 1) - (sx + 1) * inv_scale_x);
    			fx = fx < 0 ? 0.f : fx - cvFloor(fx);

    			if (sx < 0) {
    				fx = 0, sx = 0;
    			}

    			if (sx >= matSrc.cols - 1) {
    				fx = 0, sx = matSrc.cols - 2;
    			}

    			short cbufx[2];
    			cbufx[0] = cv::saturate_cast<short>((1.f - fx) * 2048);
    			cbufx[1] = 2048 - cbufx[0];

    			for (int k = 0; k < matSrc.channels(); ++k) {
    				matDst1.at<cv::Vec3b>(j, i)[k] = (matSrc.at<cv::Vec3b>(sy, sx)[k] * cbufx[0] * cbufy[0] +
    					matSrc.at<cv::Vec3b>(sy + 1, sx)[k] * cbufx[0] * cbufy[1] +
    					matSrc.at<cv::Vec3b>(sy, sx + 1)[k] * cbufx[1] * cbufy[0] +
    					matSrc.at<cv::Vec3b>(sy + 1, sx + 1)[k] * cbufx[1] * cbufy[1]) >> 22;
    			}
    		}
    	}
    	fprintf(stdout, "==== end area ====\n");

    #ifdef _MSC_VER
    	cv::imwrite("E:/GitCode/OpenCV_Test/test_images/area_1.jpg", matDst1);
    #else
    	cv::imwrite("area_1.jpg", matDst1);
    #endif
