//
//  AppDelegate.h
//  TheGreatAndNastyWolf
//
//  Created by JFR on 25/03/2015.
//  Copyright (c) 2015 JFR. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BUNCam.h"
#import <VVUVCKit/VVUVCKit.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>
{
    BUNCam * cam;
    VVUVCController * ctrl;
    
    IBOutlet NSSlider * speed;
    IBOutlet NSSlider * decay;
    IBOutlet NSSlider * r;
    IBOutlet NSSlider * v;
    IBOutlet NSSlider * b;
    IBOutlet NSSlider * saturation;
    
    IBOutlet NSTextField * noiseGateMin;
    IBOutlet NSTextField * noiseGateMax;
    
    IBOutlet NSSlider * noiseGateMinSlider;
    IBOutlet NSSlider * noiseGateMaxSlider;
    
    
    IBOutlet NSButton *reset;
    IBOutlet NSWindow * filterSettingsWindow;
    IBOutlet NSMenuItem * startStopMenuItem;
}

-(IBAction)startRecording:(id)sender;
-(IBAction)toggleFullScreen:(id)sender;
-(IBAction)toggleSettings:(id)sender;

@end
