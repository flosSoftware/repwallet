//
//  UILabel+dynamicSize.h
//  repWallet
//
//  Created by Alberto Fiore on 7/23/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UILabel (UILabel_dynamicSize)
-(void)resizeToStretch;
-(CGSize)expectedSize;
@end
