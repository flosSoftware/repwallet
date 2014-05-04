//
//  NSArray+ArrayUtils.m
//  repWallet
//
//  Created by Alberto Fiore on 20/02/13.
//  Copyright 2013 Alberto Fiore. All rights reserved.
//

#import "NSArray+ArrayUtils.h"

@implementation NSArray (ArrayUtils)

-(NSArray *)filteredByPrefix:(NSString *)pref
{
    return [self objectsAtIndexes:
            
            [self indexesOfObjectsPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if ([obj hasPrefix:pref]) {
            
            return YES;
            
        } else
            
            return NO;
    }]];
    
}

-(NSArray *)filteredBySubstring:(NSString *)sub caseInsensitive:(BOOL)caseInsensitive
{
    return [self objectsAtIndexes:
            
            [self indexesOfObjectsPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if (!caseInsensitive && [obj rangeOfString:sub].location != NSNotFound) {
            
            return YES;
            
        } else if (caseInsensitive && [obj rangeOfString:sub options:NSCaseInsensitiveSearch].location != NSNotFound) {
            
            return YES;
            
        } else
            
            return NO;
    }]];
}

@end
