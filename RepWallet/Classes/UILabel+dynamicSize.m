//
//  UILabel+dynamicSize.m
//  repWallet
//
//  Created by Alberto Fiore on 7/23/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "UILabel+dynamicSize.h"


@implementation UILabel (UILabel_dynamicSize)

-(void)resizeToStretch {
    CGSize size = [self expectedSize];
    CGRect newFrame = [self frame];
    newFrame.size.width = size.width;
    newFrame.size.height = size.height;
    [self setFrame:newFrame];
}

- (CGSize) expectedSize {
    
    [self setNumberOfLines:1];
    
//    CGSize maximumLabelSize = CGSizeMake(9999,9999);
    
    CGSize expectedLabelSize = [[self text] sizeWithFont:[self font] 
                                            forWidth:9999
                                            lineBreakMode:[self lineBreakMode]
                                ]; 
    return expectedLabelSize;
}

@end
