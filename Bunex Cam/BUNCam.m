//
//  BUNCam.m
//  multiCam
//
//  Created by JFR on 09/01/2014.
//  Copyright (c) 2014 JFR. All rights reserved.
//

#import "BUNCam.h"
#import <Accelerate/Accelerate.h>

@implementation BUNCam

@synthesize camIdentifier;
@synthesize captureDeviceInput;
@synthesize captureSession;
@synthesize locked;
@synthesize isRecording;
@synthesize customPreviewLayer;
@synthesize acc;

-(id)init
{
    self = [super init];
    W = 1920;
    H = 1080;
    
    self.captureSession= [[AVCaptureSession alloc] init];
    [self.captureSession beginConfiguration];
    
    NSError * err;
    self.locked = NO;
    self.isRecording = NO;
    
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    if (videoDevices.count == 0) {
        videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeClosedCaption];
    }
    if (videoDevices.count == 0)
    {
        return nil;
    }
    
    NSMutableArray * videoDevicesUids = [NSMutableArray array];
    for (AVCaptureDevice *device in videoDevices) {
        if ([[device manufacturer] isEqualToString:@"Unknown"] == YES) {
            [videoDevicesUids addObject:[device uniqueID]];
        }
    }
    if (videoDevicesUids.count > 0) {
        videoDevice = [AVCaptureDevice deviceWithUniqueID:[videoDevicesUids objectAtIndex:0]];
    } else {
        videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    if (videoDevice == nil)
    {
        return nil;
    }
    self.camIdentifier =  videoDevice.uniqueID;
    if (self.camIdentifier == nil)
    {
        return nil;
    }
    
    self.captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&err];
    if ([self.captureSession canAddInput:self.captureDeviceInput]) {
        [self.captureSession addInput:self.captureDeviceInput];
    }
    
    if (W == 1280 && H == 720)
    {
        if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
            self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
        }
    }
    else if (W == 1920 && H == 1080)
    {
        if ([self.captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
            self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
        }
    }
    
    
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [output setVideoSettings:@{(NSString *)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32ARGB],
                               (NSString*)kCVPixelBufferWidthKey:[NSNumber numberWithUnsignedInt:W],
                               (NSString*)kCVPixelBufferHeightKey:[NSNumber numberWithUnsignedInt:H]}];
    
    
    [output setAlwaysDiscardsLateVideoFrames:YES];
    if([self.captureSession canAddOutput:output])
    {
        [self.captureSession addOutput:output];
    }

    
    [self.captureSession commitConfiguration];
    
    [CIPlugIn loadAllPlugIns];
    acc = [CIFilter filterWithName:@"BUNEXFilter" withInputParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                       [NSNumber numberWithInt:W], @"width",
                                                                       [NSNumber numberWithInt:H], @"height", nil]];

    [acc setValue:[NSNumber numberWithDouble:0.01] forKey:@"noiseGateMin"];
    [acc setValue:[NSNumber numberWithDouble:0.05] forKey:@"noiseGateMax"];
    [acc setValue:[NSNumber numberWithDouble:1.0] forKey:@"redValue"];
    [acc setValue:[NSNumber numberWithDouble:1.0] forKey:@"greenValue"];
    [acc setValue:[NSNumber numberWithDouble:1.0] forKey:@"blueValue"];
    [acc setValue:[NSNumber numberWithDouble:0.001] forKey:@"speed"];
    [acc setValue:[NSNumber numberWithDouble:0.999] forKey:@"decay"];
    [acc setValue:[NSNumber numberWithDouble:1] forKey:@"saturation"];
    [acc setValue:[NSNumber numberWithInt:0] forKey:@"reset"];
    
    
    [self.captureSession startRunning];
    
    customPreviewLayer = [CALayer layer];
    customPreviewLayer.contentsGravity = kCAGravityResizeAspect;
    
    dispatch_queue_t outputQueue = dispatch_queue_create("outputQueue", DISPATCH_QUEUE_SERIAL);
    [output setSampleBufferDelegate:self queue:outputQueue];
    
    return self;
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection

{
    

    CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    
    Pixel_8888 *lumaBuffer = CVPixelBufferGetBaseAddress(imageBuffer);
    const vImage_Buffer inImage = { lumaBuffer, height, width, bytesPerRow };
    
    CIImage * img = [[CIImage alloc] initWithBitmapData:[NSData dataWithBytesNoCopy:inImage.data
                                                                             length:(inImage.rowBytes * inImage.height)
                                                                       freeWhenDone:NO]
                                            bytesPerRow:inImage.rowBytes
                                                   size:CGSizeMake(inImage.width, inImage.height)
                                                 format:kCIFormatARGB8
                                             colorSpace:CGColorSpaceCreateDeviceRGB()];
    
    [acc setValue:img forKey:@"inputImage"];
    CIImage * res = [acc valueForKey:@"outputImage"];
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(lumaBuffer, width, height, 8, bytesPerRow, colorSpace, (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    CIContext * ctx = [CIContext contextWithCGContext:context options:nil];

    CGImageRef dstImage = [ctx createCGImage:res fromRect:res.extent];

    if (isRecording==YES)
    {
        if (adaptor.assetWriterInput.readyForMoreMediaData) {
            CMTime frameTime = CMTimeMake(frameCount,25);
            CVPixelBufferRef rrrr = [self pixelBufferFromCGImage:dstImage andSize:NSMakeSize(W, H)];
            [adaptor appendPixelBuffer:rrrr
                  withPresentationTime:frameTime];
            
            CVPixelBufferRelease(rrrr);
            frameCount ++;
        }
        
    }
    
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        customPreviewLayer.contents = (__bridge id)dstImage;
    });
    CGImageRelease(dstImage);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
}


- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image andSize:(CGSize) size
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width,
                                          size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width,
                                                 size.height, 8, 4*size.width, rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}


- (void)maxFromImage:(const vImage_Buffer)src toImage:(const vImage_Buffer)dst
{
    int kernelSize = 7;
    vImageMin_ARGB8888(&src, &dst, NULL, 0, 0, kernelSize, kernelSize, kvImageDoNotTile);
}

-(void)startRecordingMovie
{
    NSError *error = nil;
    NSDate * date = [NSDate date];
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd 'at' HH-mm-ss"];
    NSString * dateString = [formatter stringFromDate:date];
    NSURL *fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/Desktop/%@.mov", NSHomeDirectory(), dateString]];
    
    videoWriter = [[AVAssetWriter alloc] initWithURL:fileURL
                                            fileType:AVFileTypeQuickTimeMovie
                                               error:&error];
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecAppleProRes422, AVVideoCodecKey,
                                   [NSNumber numberWithInt:W], AVVideoWidthKey,
                                   [NSNumber numberWithInt:H], AVVideoHeightKey,
                                   nil];
    
    videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                          outputSettings:videoSettings];
    
    adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                                                                               sourcePixelBufferAttributes:nil];
    
    NSParameterAssert(videoWriterInput);
    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
    videoWriterInput.expectsMediaDataInRealTime = YES;
    [videoWriter addInput:videoWriterInput];
    
    
    isRecording = YES;
    frameCount = 0;
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
}

-(void)stopRecording
{
    isRecording= NO;
    [videoWriterInput markAsFinished];
    [videoWriter finishWritingWithCompletionHandler:^{
        
    }];
}


@end
