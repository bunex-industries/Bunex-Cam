//
//  BUNCam.h
//  multiCam
//
//  Created by JFR on 09/01/2014.
//  Copyright (c) 2014 JFR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CMTime.h>
#import "BUNEXFilter.h"


@interface BUNCam : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureDevice * videoDevice;
    
    AVAssetWriter *videoWriter;
    AVAssetWriterInput* videoWriterInput;
    AVAssetWriterInputPixelBufferAdaptor *adaptor;
    int frameCount;
    
    int W;
    int H;
    
}



@property (strong) NSString                  * camIdentifier;
@property (strong) AVCaptureDeviceInput      * captureDeviceInput;
@property (strong) AVCaptureDeviceInput      * audioCaptureDeviceInput;
@property (strong) AVCaptureSession          * captureSession;

@property (strong) CALayer                   * customPreviewLayer;
@property (strong) CIFilter                  * acc;


@property BOOL locked;
@property BOOL isRecording;


-(id)init;


//
-(void)stopRecording;
-(void)startRecordingMovie;

@end

