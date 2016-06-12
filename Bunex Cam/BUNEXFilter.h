//
//  BUNOpacityFilter.h
//  videoAccumulator
//
//  Created by Jean-François Roversi on 13/05/13.
//  Copyright (c) 2013 Bunex-Industries. All rights reserved.
//


#import <Quartz/Quartz.h>

@interface BUNEXFilter : CIFilter
{
    CIImage *   inputImage;
    
    NSNumber *  noiseGateMin;
    NSNumber *  noiseGateMax;
    
    NSNumber *  redValue;
    NSNumber *  greenValue;
    NSNumber *  blueValue;
    
    NSNumber *  height;
    NSNumber *  width;
    
    NSNumber * speed;
    NSNumber * decay;
    NSNumber * reset;
    NSNumber * saturation;


    CIFilter *multiply;
    CIFilter *addition;
    CIFilter *colorControls;
}



@end
