//
//  BUNOpacityFilter.m
//  videoAccumulator
//
//  Created by Jean-François Roversi on 13/05/13.
//  Copyright (c) 2013 Bunex-Industries. All rights reserved.
//

#import "BUNEXFilter.h"

@implementation BUNEXFilter

static CIKernel *_opacityMultiplierKernel = nil;
static CIKernel *_inputProcessorKernel = nil;
static CIImageAccumulator * imageAccumulator;
static CIImage * black;


- (id)init
{
    self = [super init];
    
    [CIPlugIn loadAllPlugIns];
    reset = [NSNumber numberWithBool:NO];
    
    NSError * err;
    NSBundle    *bundle = [NSBundle mainBundle];
    NSString    *code = [NSString stringWithContentsOfFile:[bundle pathForResource:@"kernels" ofType: @"cikernel"] 
                                                  encoding:NSUTF8StringEncoding 
                                                     error:&err];
    
    NSArray     *kernels = [CIKernel kernelsWithString: code];
    
    if(_opacityMultiplierKernel == nil)
    {
        _opacityMultiplierKernel = [kernels objectAtIndex:0];
    }
    if(_inputProcessorKernel == nil)
    {
        _inputProcessorKernel = [kernels objectAtIndex:1];
    }
    
    multiply = [CIFilter filterWithName:@"CIMultiplyBlendMode"];
    addition = [CIFilter filterWithName:@"CIAdditionCompositing"];
    colorControls = [CIFilter filterWithName:@"CIColorControls"];
    [colorControls setValue:[NSNumber numberWithFloat:1] forKey:@"inputContrast"];
    [colorControls setValue:saturation forKey:@"inputSaturation"];
    [colorControls setValue:[NSNumber numberWithFloat:0] forKey:@"inputBrightness"];
    
    [self addObserver:self forKeyPath:@"width" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"height" options:NSKeyValueObservingOptionNew context:nil];
    
    return self;
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{    
    CIFilter * constantColor = [CIFilter filterWithName:@"CIConstantColorGenerator" keysAndValues:@"inputColor",[CIColor colorWithRed:0 green:0 blue:0 alpha:1], nil];
    CGRect rrr = CGRectMake(0, 0, [width floatValue], [height floatValue]);
    if (!(rrr.size.width == 0 || rrr.size.height == 0))
    {
        NSLog(@"width or height change");
        black = [constantColor valueForKey:@"outputImage"];
        black = [black imageByCroppingToRect:rrr];
        if (imageAccumulator != nil)
        {
            imageAccumulator = nil;
        }
        imageAccumulator = [[CIImageAccumulator alloc] initWithExtent:rrr format:kCIFormatRGBAf];
        [imageAccumulator setImage:black dirtyRect:rrr];
        NSLog(@"new size = %@", NSStringFromRect(imageAccumulator.extent));
    }
}

- (CIImage *)outputImage
{
    if (inputImage && imageAccumulator)
    {
        if ([reset intValue] == 1)
        {   
            [multiply setValue:inputImage forKey:@"inputImage"];
            [multiply setValue:black forKey:@"inputBackgroundImage"];
            [imageAccumulator setImage:[multiply valueForKey:@"outputImage"]];
        }
        else
        {
            CISampler *src = [CISampler samplerWithImage:inputImage];
            
            NSArray * extentArray = [NSArray arrayWithObjects:
                                     [NSNumber numberWithFloat:0], 
                                     [NSNumber numberWithFloat:0], 
                                     width,
                                     height, nil];
            
            NSDictionary * opts = [NSDictionary dictionaryWithObjectsAndKeys:extentArray, kCIApplyOptionExtent, nil];
            
            CIImage * img = [self apply:_inputProcessorKernel arguments:[NSArray arrayWithObjects:src,redValue,greenValue,blueValue,speed,noiseGateMin, noiseGateMax, nil] options:opts];
            [colorControls setValue:saturation forKey:@"inputSaturation"];
            [colorControls setValue:img forKey:@"inputImage"];
            img = [colorControls valueForKey:@"outputImage"];
            
            CISampler * accSrc = [CISampler samplerWithImage:[imageAccumulator image]];
            CIImage * accImg = [self apply:_opacityMultiplierKernel arguments:[NSArray arrayWithObjects:accSrc, decay, nil] options:opts];

            [addition setValue:img forKey:@"inputImage"];
            [addition setValue:accImg forKey:@"inputBackgroundImage"];
            [imageAccumulator setImage:[addition valueForKey:@"outputImage"]];
        }
        return [imageAccumulator image];
    }
    return nil;
}




@end
