//
//  BusinessCategory.h
//  repWallet
//
//  Created by Alberto Fiore on 12/4/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BusinessCategory : NSObject

@property (nonatomic, retain) NSString *businessCategoryCode;
@property (nonatomic, retain) NSString *parentBusinessCategoryCode;
@property (nonatomic, retain) NSString *businessCategoryDescription;

- (id) initWithCode:(NSString *)code parentCode:(NSString *)parentCode description:(NSString *)description;
- (NSComparisonResult)compareTo:(BusinessCategory *)anObject;

@end
