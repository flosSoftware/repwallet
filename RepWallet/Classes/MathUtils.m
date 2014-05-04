//
//  MathUtils.m
//  repWallet
//
//  Created by Alberto Fiore on 10/19/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "MathUtils.h"

#define kVerySmallValue (0.0000001)

@implementation MathUtils

-(double) getRandomValuewithMin: (double) lowerBound Max:(double) upperBound 
{
    if(lowerBound < 0 || upperBound <= lowerBound){
        NSLog(@"Error in random number generation");
    }
    
    double r = (double)rand()/RAND_MAX;
    double dbl =  r * (upperBound - lowerBound) + lowerBound;
    return dbl;
}

- (BOOL)firstDouble:(double)first isEqualTo:(double)second {
    
    if(fabsf(first - second) < kVerySmallValue)
        return YES;
    else
        return NO;
}

@end
