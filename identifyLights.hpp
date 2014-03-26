#ifndef INCLUDES_OPENCV
#define INCLUDES_OPENCV
#include</usr/local/include/opencv2/core/core.hpp>
#include</usr/local/include/opencv2/highgui/highgui.hpp>
#include</usr/local/include/opencv2/imgproc/imgproc.hpp>
#include</usr/local/include/opencv2/video/video.hpp>

using namespace cv;

typedef struct{
    int code;
    int x,y;
    float real_x,real_y,real_z;
    
}Light;

int getLightCoordinates(Light** ptr);
#endif
