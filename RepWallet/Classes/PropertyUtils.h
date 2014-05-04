//
//  PropertyUtils.h
//  repWallet
//
//  Created by Alberto Fiore on 3/30/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PropertyUtils : NSObject

+ (NSDictionary *)classPropsFor:(Class)klass;

@end