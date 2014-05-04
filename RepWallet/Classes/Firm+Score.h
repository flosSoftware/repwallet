//
//  Firm+Score.h
//  repWallet
//
//  Created by Alberto Fiore on 6/4/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DAO.h"

@interface Firm (Firm_Score)

- (NSNumber *)calculateScore:(DAO *)dao;
- (NSComparisonResult)compareTo:(Firm *)anObject;

@end
