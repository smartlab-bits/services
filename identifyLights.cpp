#include "identifyLights.hpp"
#include<iostream>
#include<vector>
#include<stdio.h>
using namespace std;
using namespace cv;

struct storeRectangle{
    Point pt;
    int l;
    int b;
};

void initializeCamera(VideoCapture camera, int initTime)
{
  Mat waste;
  
  for( int i=0; i<initTime ;i++ )
  {
    camera.grab();
    camera.retrieve(waste,CV_CAP_OPENNI_BGR_IMAGE);
  }
}

void findLenBrd(int* x, int* y, int a, int b, Mat reduced_with_border)
{
    int l, br;
    uchar* rowp = reduced_with_border.ptr<uchar>(a);
    for(int j=b;j<reduced_with_border.cols;j++)
    {
        if(rowp[j]==0)
        {
            l = j-b;
            break;
        }
    }
    *x = l;
    
    for(int i=a;i<reduced_with_border.rows;i++)
    {
        if(reduced_with_border.at<uchar>(i,b)==0)
        {
            br = i-a;
            break;
        }
    }
    *y = br;
}

long countWhites(Mat image)
{
  long count = 0;
  uchar* pix_row;
  
  for(int i=0;i<image.rows;i++)
  {
    pix_row = image.ptr<uchar>(i);
    for(int j=0;j<image.cols;j++)
    {
      if(pix_row[j]==255)
	count+=1;      
    }
  }  
  return count;
}

void enchanceImage(Mat reduced)
{
    int rows = reduced.rows;
    int cols = reduced.cols;
        
    for(int i = 0;i<rows;i++)
    {
        for(int j = 0;j<cols;j++)
        {
            if(reduced.at<uchar>(i,j)==0)
            {
                if(((i-1)>=0) && reduced.at<uchar>(i-1,j)==255)
                {
                    if(((j+1)<=cols) && reduced.at<uchar>(i,j+1)==255)
                    {
                        reduced.at<uchar>(i,j)=255;    
                        i = 0;
                        j = 0;
                    }
                    else if(((j-1)>=0) && reduced.at<uchar>(i,j-1)==255)
                    {
                        reduced.at<uchar>(i,j) = 255;
                        i = 0;
                        j = 0;
                    }
                }
                else if(((i+1)<=rows) && reduced.at<uchar>(i+1,j)==255)
                {
                    if(((j+1)<=cols) && reduced.at<uchar>(i,j+1)==255)
                    {
                        reduced.at<uchar>(i,j)=255;    
                        i = 0;
                        j = 0;
                    }
                    else if(((j-1)>=0) && reduced.at<uchar>(i,j-1)==255)
                    {
                        reduced.at<uchar>(i,j) = 255;
                        i = 0;
                        j = 0;
                     }
                }
            }
        }
    }        
}

//Follow border to obtain co-ordinates of rectangular patches
int followBorder(Mat reduced, Light*** ptrL)
{          
  Mat reduced_with_border;
  copyMakeBorder(reduced,reduced_with_border,1,1,1,1,BORDER_CONSTANT,0);  
  vector<storeRectangle> corners;  
  for(int i=1;i<reduced_with_border.rows;i++)
  {      
      for(int j=1;j<reduced_with_border.cols;j++)
      {
          if(reduced_with_border.at<uchar>(i,j)==255)
          {
              if(reduced_with_border.at<uchar>(i-1,j)==0 && reduced_with_border.at<uchar>(i,j-1)==0)
              {
                  storeRectangle cor;
                  cor.pt = Point(i,j);
                  int length=0;
                  int breadth=0;
                  findLenBrd(&length,&breadth,i,j, reduced_with_border);
                  cor.l = length;
                  cor.b = breadth;
                  corners.push_back(cor);
              }
          }
      }
  }
  const int kernel_size = 16;
  //printf("I am here before memory");
  **ptrL = (Light*)calloc(sizeof(Light),corners.size());
  for(int k=0;k<corners.size();k++)
  {
      Light lt;
      lt.code = k;
      storeRectangle cor = corners.at(k);
      lt.x = ((cor.pt.x + (cor.l/2))*kernel_size)+(kernel_size/2);
      lt.y = ((cor.pt.y + (cor.b/2))*kernel_size)+(kernel_size/2);
      //lt.x = cor.pt.x + (cor.l/2);
      //lt.y = cor.pt.y + (cor.b/2);     
      (**ptrL)[k] = lt;
       //ptrL++;
  }
  
for(int i=0;i<corners.size();i++)
     // printf("%d %d \n",(**ptrL)[i].x,(**ptrL)[i].y);
for(int j=1;j<=corners.size();j++)
    (**ptrL)[j].code=j; 

  return corners.size();
}
   

int getLightCoordinates(Light** ptr)
{
  int const threshold_value = 220;	//value of threshold_value obatined by experimentation
  int const max_binary_value = 255;
  VideoCapture camera(CV_CAP_OPENNI);  
  initializeCamera(camera,25);
  Mat image_color;
  camera.grab();
  camera.retrieve(image_color,CV_CAP_OPENNI_BGR_IMAGE);
  
  Mat image_bw;
  cvtColor(image_color,image_bw,CV_BGR2GRAY);
    
  Mat image_threshold;
  threshold(image_bw,image_threshold,threshold_value,max_binary_value,THRESH_BINARY); // last parameter to indicate BINARY THRESHOLD operation
  
  Mat img;
  img = image_threshold.clone();
  
  const int kernel_size = 16;
  
  Mat ROI;
  Mat image_new = Mat(img.rows,img.cols,CV_8UC(1),Scalar::all(0));
  Mat image_reduced = Mat(img.rows/kernel_size,img.cols/kernel_size,CV_8UC(1),Scalar::all(0));
  
  
  for(int i=0;i<img.rows-kernel_size;i+=kernel_size)
  {
    for(int j=0;j<img.cols-kernel_size;j+=kernel_size)
    {
	ROI = Mat(img,Rect(j,i,kernel_size,kernel_size));	
	if(countWhites(ROI)>=(8*16))
	{
          image_reduced.at<uchar>(i/kernel_size,j/kernel_size) = 255;
	  rectangle(image_color,Rect(j,i,kernel_size,kernel_size),Scalar(255,0,0),2,8,0);
	}
    }
  }
  enchanceImage(image_reduced);
  
  namedWindow("work please!!!",CV_WINDOW_AUTOSIZE);
  imshow("work please!!!",image_color);  
  waitKey(0);
  int noLights = followBorder(image_reduced,&ptr);
  //printf("number of lights: %d \n",noLights);
  for(int i=0;i<noLights;i++)
     // printf("%d %d \n",(*ptr)[i].x,(*ptr)[i].y);     
  return noLights;
}
