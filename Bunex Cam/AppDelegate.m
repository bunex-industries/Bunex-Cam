//
//  AppDelegate.m
//  TheGreatAndNastyWolf
//
//  Created by JFR on 25/03/2015.
//  Copyright (c) 2015 JFR. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate



- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    //NEEDED CAUSE NEW FULL-SCREEN BEHAVIOUR
    self.window.styleMask = NSTitledWindowMask  | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask;
    [self.window setDelegate:self];
    
    NSView * cntv = self.window.contentView;
    [cntv setWantsLayer:YES];
    CALayer * layer = [CALayer layer];
    [cntv setLayer:layer];
    
    [layer setFrame:CGRectMake([cntv bounds].origin.x, [cntv bounds].origin.y, [cntv bounds].size.width, [cntv bounds].size.width)];
    [layer setBackgroundColor:[NSColor blackColor].CGColor];
    [layer setDelegate:self];
    [layer setNeedsDisplay];
    
    cam = [[BUNCam alloc] init];
    if (cam == nil)
    {
        cam = nil;
        [self startCamRecoveryMode];
    }
    else
    {
        ctrl = [[VVUVCController alloc] initWithDeviceIDString:cam.camIdentifier];
        
        [layer addSublayer:cam.customPreviewLayer];
        [cam.customPreviewLayer setFrame:[self.window.contentView bounds]];
        [ctrl openSettingsWindow];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(camError:) name:AVCaptureSessionRuntimeErrorNotification object:nil];
    }
}


-(IBAction)change:(id)sender
{
    if (sender == noiseGateMin)
    {
        [noiseGateMinSlider setDoubleValue:[noiseGateMin doubleValue]];
        if ([noiseGateMin doubleValue] > [noiseGateMax doubleValue])
        {
            [noiseGateMaxSlider setDoubleValue:[noiseGateMin doubleValue]];
            [noiseGateMax setDoubleValue:[noiseGateMin doubleValue]];
        }
    }
    else if (sender == noiseGateMax)
    {
        [noiseGateMaxSlider setDoubleValue:[noiseGateMax doubleValue]];
        if ([noiseGateMax doubleValue] < [noiseGateMin doubleValue])
        {
            [noiseGateMinSlider setDoubleValue:[noiseGateMax doubleValue]];
            [noiseGateMin setDoubleValue:[noiseGateMax doubleValue]];
        }
    }
    else if (sender == noiseGateMinSlider)
    {
        [noiseGateMin setDoubleValue:[noiseGateMinSlider doubleValue]];
        if ([noiseGateMinSlider doubleValue] > [noiseGateMaxSlider doubleValue])
        {
            [noiseGateMaxSlider setDoubleValue:[noiseGateMinSlider doubleValue]];
            [noiseGateMax setDoubleValue:[noiseGateMinSlider doubleValue]];
        }
    }
    else if (sender == noiseGateMaxSlider)
    {
        [noiseGateMax setDoubleValue:[noiseGateMaxSlider doubleValue]];
        if ([noiseGateMaxSlider doubleValue] < [noiseGateMinSlider doubleValue])
        {
            [noiseGateMinSlider setDoubleValue:[noiseGateMaxSlider doubleValue]];
            [noiseGateMin setDoubleValue:[noiseGateMaxSlider doubleValue]];
        }
    }
    
    [cam.acc setValue:[NSNumber numberWithDouble:[noiseGateMin doubleValue]] forKey:@"noiseGateMin"];
    [cam.acc setValue:[NSNumber numberWithDouble:[noiseGateMax doubleValue]] forKey:@"noiseGateMax"];
    [cam.acc setValue:[NSNumber numberWithDouble:[r doubleValue]] forKey:@"redValue"];
    [cam.acc setValue:[NSNumber numberWithDouble:[v doubleValue]] forKey:@"greenValue"];
    [cam.acc setValue:[NSNumber numberWithDouble:[b doubleValue]] forKey:@"blueValue"];
    [cam.acc setValue:[NSNumber numberWithDouble:[speed doubleValue]] forKey:@"speed"];
    [cam.acc setValue:[NSNumber numberWithDouble:[decay doubleValue]] forKey:@"decay"];
    [cam.acc setValue:[NSNumber numberWithInteger:[reset state]] forKey:@"reset"];
    [cam.acc setValue:[NSNumber numberWithDouble:[saturation doubleValue]] forKey:@"saturation"];
    
    [self.window makeKeyAndOrderFront:nil];
}

-(void)windowDidBecomeKey:(NSNotification *)notification
{
    [cam.customPreviewLayer setFrame:[self.window.contentView bounds]];
}

-(void)windowDidEndLiveResize:(NSNotification *)notification
{
    [cam.customPreviewLayer setFrame:[self.window.contentView bounds]];
}


-(IBAction)startRecording:(id)sender
{
    if (cam.isRecording == NO)
    {
        cam.isRecording = YES;
        [cam startRecordingMovie];
        [startStopMenuItem setTitle:@"Stop recording"];
    }
    else
    {
        cam.isRecording = NO;
        [cam stopRecording];
        [startStopMenuItem setTitle:@"Start recording"];
    }
}

-(IBAction)toggleSettings:(id)sender
{
    
}

-(IBAction)toggleFullScreen:(id)sender
{
    NSLog(@"toggleFullScreen");
    NSDictionary *opts = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithBool:NO], NSFullScreenModeAllScreens,
                          [NSNumber numberWithInt:0], NSFullScreenModeWindowLevel,
                          [NSNumber numberWithInt:NSApplicationPresentationHideDock | NSApplicationPresentationHideMenuBar], NSFullScreenModeApplicationPresentationOptions,nil];
    
    if ([self.window.contentView isInFullScreenMode])
    {
        [self.window.contentView exitFullScreenModeWithOptions:opts];
        [self.window setStyleMask:NSTitledWindowMask  | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask];
        [self.window setFrame:NSInsetRect(self.window.frame, -2, -2)  display:YES];
        //[ctrl openSettingsWindow];
        [filterSettingsWindow makeKeyAndOrderFront:nil];
        [NSCursor unhide];
        [self.window makeKeyAndOrderFront:nil];
    }
    else
    {
        self.window.styleMask = NSBorderlessWindowMask;
        [self.window.contentView enterFullScreenMode:[NSScreen mainScreen] withOptions:opts];
        //[ctrl closeSettingsWindow];
        [filterSettingsWindow close];
        //[NSCursor hide];
    }
    [cam.customPreviewLayer setFrame:[self.window.contentView bounds]];//];
}



-(void)startCamRecoveryMode
{
    cam = nil;
    NSLog(@"Try to connect");
    if (cam == nil && ctrl == nil)
    {
        cam = [[BUNCam alloc] init];
        if (cam == nil)
        {
            cam = nil;
            NSLog(@"no cam yet, retry in 3 sec...");
            [self performSelector:@selector(startCamRecoveryMode) withObject:nil afterDelay:3];
        }
        else
        {
            [self.window.contentView.layer addSublayer:cam.customPreviewLayer];
            [cam.customPreviewLayer setFrame:[self.window.contentView bounds]];
            
            ctrl = [[VVUVCController alloc] initWithDeviceIDString:cam.camIdentifier];
            [ctrl openSettingsWindow];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(camError:) name:AVCaptureSessionRuntimeErrorNotification object:nil];
            [self change:nil];
        }
    }
}



-(void)camError:(NSNotification*)notif
{
    NSLog(@"Manage the error if possible");
    if (cam.isRecording == YES)
    {
        [cam stopRecording];
    }
    [cam.captureSession stopRunning];
    [cam.customPreviewLayer removeFromSuperlayer];
    cam.acc = nil;
    [ctrl closeSettingsWindow];
    
    cam = nil;
    ctrl = nil;
    [self startCamRecoveryMode];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionRuntimeErrorNotification object:nil];
}



- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    
}

@end
