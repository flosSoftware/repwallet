//
//  NSArray+ArrayUtils.h
//  repWallet
//
//  Created by Alberto Fiore on 20/02/13.
//  Copyright 2013 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (ArrayUtils)

-(NSArray *)filteredByPrefix:(NSString *)pref;

-(NSArray *)filteredBySubstring:(NSString *)sub caseInsensitive:(BOOL)caseInsensitive;

@end
