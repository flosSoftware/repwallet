//
//  BusinessCategory.m
//  repWallet
//
//  Created by Alberto Fiore on 12/4/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//

#import "BusinessCategory.h"


@implementation BusinessCategory

@synthesize businessCategoryCode, parentBusinessCategoryCode, businessCategoryDescription;

-(id)initWithCode:(NSString *)code parentCode:(NSString *)parentCode description:(NSString *)description {
    
    if (self = [super init]) {
        self.businessCategoryCode = code;
        self.parentBusinessCategoryCode = parentCode;
        self.businessCategoryDescription = description;
    }
    
    return self;
}

- (NSComparisonResult)compareTo:(BusinessCategory *)anObject {
    return [self.businessCategoryDescription compare:[anObject businessCategoryDescription]];
}

-(void)dealloc{
    
    [self.businessCategoryCode release];
    [self.parentBusinessCategoryCode release];
    [self.businessCategoryDescription release];
    [super dealloc];
}

@end
