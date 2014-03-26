#include <XnCppWrapper.h>
#include <XnOpenNI.h>
#include <XnLog.h>
#include <XnFPSCalculator.h>
#include <string.h>
#include "identifyLights.hpp"

//---------------------------------------------------------------------------
// Defines
//---------------------------------------------------------------------------
#define SAMPLE_XML_PATH "/home/prannoy/Downloads/OpenNI/Data/SamplesConfig.xml"
#define SAMPLE_XML_PATH_LOCAL "SamplesConfig.xml"

//---------------------------------------------------------------------------
// Globals
//---------------------------------------------------------------------------
xn::Context g_Context;
xn::ScriptNode g_scriptNode;
xn::UserGenerator g_UserGenerator;

XnBool g_bNeedPose = FALSE;
XnChar g_strPose[20] = "";

#define MAX_NUM_USERS 15
//---------------------------------------------------------------------------
// Code
//---------------------------------------------------------------------------
using namespace xn;

typedef struct{

   float real_x,real_y,real_z;

}light;

XnBool fileExists(const char *fn)
{
	XnBool exists;
	xnOSDoesFileExist(fn, &exists);
	return exists;
}

// Callback: New user was detected
void XN_CALLBACK_TYPE User_NewUser(xn::UserGenerator& /*generator*/, XnUserID nId, void* /*pCookie*/)
{
    XnUInt32 epochTime = 0;
    xnOSGetEpochTime(&epochTime);
    printf("%d New User %d\n", epochTime, nId);
    // New user found
    if (g_bNeedPose)
    {
        g_UserGenerator.GetPoseDetectionCap().StartPoseDetection(g_strPose, nId);
    }
    else
    {
        g_UserGenerator.GetSkeletonCap().RequestCalibration(nId, TRUE);
    }
}
// Callback: An existing user was lost
void XN_CALLBACK_TYPE User_LostUser(xn::UserGenerator& /*generator*/, XnUserID nId, void* /*pCookie*/)
{
    XnUInt32 epochTime = 0;
    xnOSGetEpochTime(&epochTime);
    printf("%d Lost user %d\n", epochTime, nId);	
}
// Callback: Detected a pose
void XN_CALLBACK_TYPE UserPose_PoseDetected(xn::PoseDetectionCapability& /*capability*/, const XnChar* strPose, XnUserID nId, void* /*pCookie*/)
{
    XnUInt32 epochTime = 0;
    xnOSGetEpochTime(&epochTime);
    printf("%d Pose %s detected for user %d\n", epochTime, strPose, nId);
    g_UserGenerator.GetPoseDetectionCap().StopPoseDetection(nId);
    g_UserGenerator.GetSkeletonCap().RequestCalibration(nId, TRUE);
}
// Callback: Started calibration
void XN_CALLBACK_TYPE UserCalibration_CalibrationStart(xn::SkeletonCapability& /*capability*/, XnUserID nId, void* /*pCookie*/)
{
    XnUInt32 epochTime = 0;
    xnOSGetEpochTime(&epochTime);
    printf("%d Calibration started for user %d\n", epochTime, nId);
}

void XN_CALLBACK_TYPE UserCalibration_CalibrationComplete(xn::SkeletonCapability& /*capability*/, XnUserID nId, XnCalibrationStatus eStatus, void* /*pCookie*/)
{
    XnUInt32 epochTime = 0;
    xnOSGetEpochTime(&epochTime);
    if (eStatus == XN_CALIBRATION_STATUS_OK)
    {
        // Calibration succeeded
        printf("%d Calibration complete, start tracking user %d\n", epochTime, nId);		
        g_UserGenerator.GetSkeletonCap().StartTracking(nId);
    }
    else
    {
        // Calibration failed
        printf("%d Calibration failed for user %d\n", epochTime, nId);
        if(eStatus==XN_CALIBRATION_STATUS_MANUAL_ABORT)
        {
            printf("Manual abort occured, stop attempting to calibrate!");
            return;
        }
        if (g_bNeedPose)
        {
            g_UserGenerator.GetPoseDetectionCap().StartPoseDetection(g_strPose, nId);
        }
        else
        {
            g_UserGenerator.GetSkeletonCap().RequestCalibration(nId, TRUE);
        }
    }
}


#define CHECK_RC(nRetVal, what)					    \
    if (nRetVal != XN_STATUS_OK)				    \
{								    \
    printf("%s failed: %s\n", what, xnGetStatusString(nRetVal));    \
    return nRetVal;						    \
}

int main(int argc, char *argv[])
{
    XnStatus nRetVal = XN_STATUS_OK;
    xn::EnumerationErrors errors;
    //DepthGenerator depth;
    //DepthMetaData depthMD;
    int number_lights,config=0,gesture=0;
    Light *croom;
    
    if( strcmp("config",argv[1]) == 0 ){
         number_lights=getLightCoordinates(&croom);
         config=1;
     }
    else{
        gesture=1;
   }
    
    const char *fn = NULL;
    if    (fileExists(SAMPLE_XML_PATH)) fn = SAMPLE_XML_PATH;
    else if (fileExists(SAMPLE_XML_PATH_LOCAL)) fn = SAMPLE_XML_PATH_LOCAL;
    else {
       // printf("Could not find '%s' nor '%s'. Aborting.\n" , SAMPLE_XML_PATH, SAMPLE_XML_PATH_LOCAL);
        return XN_STATUS_ERROR;
    }
    printf("Reading config from: '%s'\n", fn);

    nRetVal = g_Context.InitFromXmlFile(fn, g_scriptNode, &errors);
    if (nRetVal == XN_STATUS_NO_NODE_PRESENT)
    {
        XnChar strError[1024];
        errors.ToString(strError, 1024);
      //  printf("%s\n", strError);
        return (nRetVal);
    }
    else if (nRetVal != XN_STATUS_OK)
    {
        //printf("Open failed: %s\n", xnGetStatusString(nRetVal));
        return (nRetVal);
    }

    nRetVal = g_Context.FindExistingNode(XN_NODE_TYPE_USER, g_UserGenerator);
    if (nRetVal != XN_STATUS_OK)
    {
        nRetVal = g_UserGenerator.Create(g_Context);
        CHECK_RC(nRetVal, "Find user generator");
    }

    XnCallbackHandle hUserCallbacks, hCalibrationStart, hCalibrationComplete, hPoseDetected;
    if (!g_UserGenerator.IsCapabilitySupported(XN_CAPABILITY_SKELETON))
    {
        //printf("Supplied user generator doesn't support skeleton\n");
        return 1;
    }
    nRetVal = g_UserGenerator.RegisterUserCallbacks(User_NewUser, User_LostUser, NULL, hUserCallbacks);
    CHECK_RC(nRetVal, "Register to user callbacks");
    nRetVal = g_UserGenerator.GetSkeletonCap().RegisterToCalibrationStart(UserCalibration_CalibrationStart, NULL, hCalibrationStart);
    CHECK_RC(nRetVal, "Register to calibration start");
    nRetVal = g_UserGenerator.GetSkeletonCap().RegisterToCalibrationComplete(UserCalibration_CalibrationComplete, NULL, hCalibrationComplete);
    CHECK_RC(nRetVal, "Register to calibration complete");

if(config==1){
 DepthGenerator depth;
	nRetVal = g_Context.FindExistingNode(XN_NODE_TYPE_DEPTH, depth);
	CHECK_RC(nRetVal, "Find depth generator");

	XnFPSData xnFPS;
	nRetVal = xnFPSInit(&xnFPS, 180);
	CHECK_RC(nRetVal, "FPS Init");

	DepthMetaData depthMD;
xnFPSMarkFrame(&xnFPS);

		depth.GetMetaData(depthMD);
             

printf("--2");//Print Number of Lights
for(int i=0;i<2;i++){
		//printf("Frame %d Middle point is: %u  FPS: %f\n", depthMD.FrameID(), depthMD(room[i].y,room[i].x), xnFPSCalc(&xnFPS));
                XnPoint3D my_projective_point = {croom[i].y,croom[i].x,depthMD(croom[i].y,croom[i].x)};
                XnPoint3D my_real_point;  //the converted coordinates will be stored here
                depth.ConvertProjectiveToRealWorld(
                             1,  //convert one point
                           &my_projective_point,
                           &my_real_point
                            );
               printf("!%6.2f %6.2f %6.2f",my_real_point.X,my_real_point.Y,my_real_point.Z);
               
}
 depth.Release();
}
if(gesture==1){
   
   light room[2];
   for(int i=0;i<2;i++){
   room[i].real_x=atof(argv[(3*i)+2]);
   room[i].real_y=atof(argv[(3*i)+3]);
   if(room[i].real_x<0)
      room[i].real_z=atof(argv[(3*i)+4])-2200;
   else
      room[i].real_z=atof(argv[(3*i)+4]);
  }

    if (g_UserGenerator.GetSkeletonCap().NeedPoseForCalibration())
    {
        g_bNeedPose = TRUE;
        if (!g_UserGenerator.IsCapabilitySupported(XN_CAPABILITY_POSE_DETECTION))
        {
          //  printf("Pose required, but not supported\n");
            return 1;
        }
        nRetVal = g_UserGenerator.GetPoseDetectionCap().RegisterToPoseDetected(UserPose_PoseDetected, NULL, hPoseDetected);
        CHECK_RC(nRetVal, "Register to Pose Detected");
        g_UserGenerator.GetSkeletonCap().GetCalibrationPose(g_strPose);
    }

    g_UserGenerator.GetSkeletonCap().SetSkeletonProfile(XN_SKEL_PROFILE_ALL);

    nRetVal = g_Context.StartGeneratingAll();
    CHECK_RC(nRetVal, "StartGenerating");

    XnUserID aUsers[MAX_NUM_USERS];
    XnUInt16 nUsers;
    XnSkeletonJointTransformation lelbowJoint;
    XnSkeletonJointTransformation headJoint;
    XnSkeletonJointTransformation lwristJoint;
    XnSkeletonJointTransformation relbowJoint;
    XnSkeletonJointTransformation rwristJoint;
    XnSkeletonJointTransformation head;
    XnSkeletonJointTransformation elbow;
    XnSkeletonJointTransformation wrist;

    printf("Starting to run\n");
    if(g_bNeedPose)
    {
       // printf("Assume calibration pose\n");
    }

   int gestureflag=1;
	while (!xnOSWasKeyboardHit() || gestureflag)
    {
        g_Context.WaitOneUpdateAll(g_UserGenerator);
        // print the torso information for the first user already tracking
        nUsers=MAX_NUM_USERS;
        g_UserGenerator.GetUsers(aUsers, nUsers);
       
      
        
        for(XnUInt16 i=0; i<nUsers; i++)
        {
            if(g_UserGenerator.GetSkeletonCap().IsTracking(aUsers[i])==FALSE)
                continue;
            //Doing everything for left hand

            g_UserGenerator.GetSkeletonCap().GetSkeletonJoint(aUsers[i],XN_SKEL_LEFT_ELBOW,lelbowJoint);
            g_UserGenerator.GetSkeletonCap().GetSkeletonJoint(aUsers[i],XN_SKEL_RIGHT_ELBOW,relbowJoint);
              //  printf("user %d: left elbow at (%6.2f,%6.2f,%6.2f)\n",aUsers[i],
                //                                                lelbowJoint.position.position.X,
                  //                                              lelbowJoint.position.position.Y,
                    //                                            lelbowJoint.position.position.Z);

            g_UserGenerator.GetSkeletonCap().GetSkeletonJoint(aUsers[i],XN_SKEL_HEAD,headJoint);
              //  printf("user %d:  head at (%6.2f,%6.2f,%6.2f)\n",aUsers[i],
                //                                                headJoint.position.position.X,
                  //                                              headJoint.position.position.Y,
                    //                                           headJoint.position.position.Z);
            g_UserGenerator.GetSkeletonCap().GetSkeletonJoint(aUsers[i],XN_SKEL_LEFT_HAND,lwristJoint);
            g_UserGenerator.GetSkeletonCap().GetSkeletonJoint(aUsers[i],XN_SKEL_RIGHT_HAND,rwristJoint);
                //printf("user %d:  left wrist at (%6.2f,%6.2f,%6.2f)\n",aUsers[i],
                  //                                              lwristJoint.position.position.X,
                    //                                            lwristJoint.position.position.Y,
                      //                                          lwristJoint.position.position.Z);
           int pointing=0; //-1 if pointing backwards or 1 if pointing forwards,0 if not pointing
          /* Direction Not necessary,eqn takes care of everything
          // int direction=0;//1 if right and 0 if left 

           if((lwristJoint.position.position.Y-lelbowJoint.position.position.Y)>0){
            
                pointing=((headJoint.position.position.Z-lwristJoint.position.position.Z)>0)?1:-1;
                if(lwristJoint.position.position.X>0 && lelbowJoint.position.position.X>0)
                    direction=((lwristJoint.position.position.X-lelbowJoint.position.position.X)>0)?0:1;
                else if(lwristJoint.position.position.X<0 && lelbowJoint.position.position.X<0) 
                    direction=((lwristJoint.position.position.X-lelbowJoint.position.position.X)<0)?0:1;
                else if(lwristJoint.position.position.X>lelbowJoint.position.position.X)
                     direction=1;            
                      
           } */
           head=headJoint;
           if((lwristJoint.position.position.Y-lelbowJoint.position.position.Y)>0){
                 pointing=((headJoint.position.position.Z-lwristJoint.position.position.Z)>0)?1:-1;                 
                 wrist=lwristJoint;
                 elbow=lelbowJoint;
                // printf("left hand %d \n",pointing);
           }
           if((rwristJoint.position.position.Y-relbowJoint.position.position.Y)>0){
                 pointing=((headJoint.position.position.Z-rwristJoint.position.position.Z)>0)?1:-1;
                 wrist=rwristJoint;
                 elbow=relbowJoint;
                 //printf("right hand %d \n",pointing);
           }    
            
           float slope,intercept,depth;
           float threshold=1000;//Error accepted for each light,usually dependent on number of lights
           slope=((wrist.position.position.Z-elbow.position.position.Z)/(wrist.position.position.X-elbow.position.position.X));
           intercept=(wrist.position.position.Z-(slope*wrist.position.position.X));
            
          if(pointing==1 || pointing==-1){ 
           for(int j=0;j<2;j++){
           
              depth=((slope*room[j].real_x)+intercept);
              //printf("i am a light at %6.2f \n",room[i].real_x);
             // printf("i am pointing to a depth of %6.2f for light %6.2f \n",(depth-room[j].real_z),room[j].real_x);
              if((depth-room[j].real_z)>(-1000) && (depth-room[j].real_z)<(1000)){

                    if(pointing==1 && (head.position.position.Z-room[j].real_z)>0){
                     //Switch on this particular light
                     printf("--%d\n",j);
                     return 0;
     
                     }
                    else if(pointing==-1 && (head.position.position.Z-room[j].real_z)<0){
                      //Switch on this light
                     printf("--%d\n",j);
                      return 0;
                     }
                     
              }}
             
           }

          
            
        } 
        
    }
}//if gesture==1
    
    g_scriptNode.Release();
    g_UserGenerator.Release();
    g_Context.Release();

}
