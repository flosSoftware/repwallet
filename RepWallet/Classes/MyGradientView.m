//
//  MyGradientView.m
//  repWallet
//
//  Created by Alberto Fiore on 16/02/13.
//  Copyright 2013 Alberto Fiore. All rights reserved.
//

#import "MyGradientView.h"
#import <QuartzCore/QuartzCore.h>


@implementation MyGradientView

+(Class) layerClass {
    return [CAGradientLayer class];
}

- (void) greyGradient {
    
    UIColor *colorOne = [UIColor colorWithHue:0.0 saturation:0.0 brightness:0.5 alpha:1.0];
    UIColor *colorTwo = [UIColor colorWithHue:0.0 saturation:0.0 brightness:0.82 alpha:1.0];
    
    NSArray *colors =  [NSArray arrayWithObjects:(id)colorOne.CGColor, colorTwo.CGColor,  nil];
    
    NSNumber *stopOne = [NSNumber numberWithFloat:0.0];
    NSNumber *stopFour = [NSNumber numberWithFloat:1.0];
    
    NSArray *locations = [NSArray arrayWithObjects:stopOne, stopFour, nil];

    [(CAGradientLayer*)[self layer] setColors:colors];
    [(CAGradientLayer*)[self layer] setLocations:locations];
    
}

- (void) blueGradient {
    
    UIColor *colorOne = [UIColor colorWithRed:(120/255.0) green:(135/255.0) blue:(150/255.0) alpha:1.0];
    UIColor *colorTwo = [UIColor colorWithRed:(57/255.0)  green:(79/255.0)  blue:(96/255.0)  alpha:1.0];
    
    NSArray *colors = [NSArray arrayWithObjects:(id)colorOne.CGColor, colorTwo.CGColor, nil];
    NSNumber *stopOne = [NSNumber numberWithFloat:0.0];
    NSNumber *stopTwo = [NSNumber numberWithFloat:1.0];
    
    NSArray *locations = [NSArray arrayWithObjects:stopOne, stopTwo, nil];
    
    [(CAGradientLayer*)[self layer] setColors:colors];
    [(CAGradientLayer*)[self layer] setLocations:locations];
    
}

@end
