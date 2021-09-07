//
// Created by zheng on 2021/9/3.
//

#include "area_solution.h"
#include <opencv2/opencv.hpp>
#include <iostream>
using namespace cv;      //使用cv命名空间

///[src]为

int main(int argc, char** argv) {
    //argc 表示命令行输入参数的个数（以空白符分隔），argv中存储了所有的命令行参数
    Mat src, dst, gray_src;
    src = imread("E:/OpenCV/testimage/test7.jpg");
    if (src.empty()) {
        printf("could not load image...\n");
        return -1;
    }
    namedWindow("input image", CV_WINDOW_AUTOSIZE);
    imshow("input image", src);

    Mat xgrad, ygrad, xygrad, sharpen;
    GaussianBlur(src, dst, Size(3, 3), 0, 0); //高斯模糊平滑
    cvtColor(src, gray_src, CV_BGR2GRAY); //转灰度
    // Sobel算子求X方向的梯度（CV_16S改写成-1与输入一样8U类型的话会漏掉很多信息，效果精准度会变差）
    Sobel(gray_src, xgrad, CV_16S, 1, 0, 3);
    // Sobel算子求Y方向的梯度
    Sobel(gray_src, ygrad, CV_16S, 0, 1, 3);
    // Scharr(gray_src, xgrad, CV_16S, 1, 0); //Scharr算子求X方向的梯度，边缘更得到加强，几乎所有边缘都显出来了
    // Scharr(gray_src, ygrad, CV_16S, 0, 1); //Scharr算子求Y方向的梯度
    convertScaleAbs(xgrad, xgrad); // 计算图像像素绝对值
    convertScaleAbs(ygrad, ygrad); // 计算图像像素绝对值
    imshow("xgrad image", xgrad);
    imshow("ygrad image", ygrad);

 /*法一：混合权重相加，效果较差*/
    addWeighted(xgrad, 0.5, ygrad, 0.5, 0, xygrad); //混合权重相加，效果较差
    imshow("hunhe_xygrad image", xygrad);
    //灰度图像锐化处理，图像和sobel图像叠加，增强图像的边缘
    addWeighted(xygrad, 0.5, gray_src, 0.5, 0, sharpen);
    imshow("sharpen image", sharpen);

 /*法二：循环获取像素，每个点直接相加，效果更好*/
    Mat addxygrad = Mat(xgrad.size(), xgrad.type()); //type是个函数要加()，变量不用加
    printf("type: %d", xgrad.type()); // 0 就是CV_8U
    int width = xgrad.cols;
    int height = ygrad.rows;
    for (int row = 0; row < height; row++) {
        for (int col = 0; col < width; col++) {
            int xg = xgrad.at<uchar>(row, col);
            int yg = ygrad.at<uchar>(row, col);
            int xy = xg + yg;  //各直接相加，效果比混合相加好
            addxygrad.at<uchar>(row, col) = saturate_cast<uchar>(xy); //保证值在0-255之间
        }
    }
    imshow("add_xygrad image", addxygrad);//最亮的地方如果点点，是因为有被截断，类型不一致造成，还有可能值超出了0-255之间
    aitKey(0);
 return 0;
}