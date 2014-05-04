//
//  Statistic.h
//  repWallet
//
//  Created by Alberto Fiore on 1/31/13.
//  Copyright (c) 2013 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Firm, ItemCategory;

@interface Statistic : NSManagedObject

@property (nonatomic, retain) NSNumber * numSellsKO;
@property (nonatomic, retain) NSNumber * totMinContacts;
@property (nonatomic, retain) NSNumber * amtOpenUnpaidInv;
@property (nonatomic, retain) NSNumber * totMinSellsOK;
@property (nonatomic, retain) NSNumber * totDayUnresUnpaidInv;
@property (nonatomic, retain) NSNumber * amtClosedUnpaidInv;
@property (nonatomic, retain) NSNumber * refMonth;
@property (nonatomic, retain) NSNumber * numContacts;
@property (nonatomic, retain) NSNumber * refYear;
@property (nonatomic, retain) NSNumber * numSellsOK;
@property (nonatomic, retain) NSNumber * numOpenUnpaidInv;
@property (nonatomic, retain) NSNumber * amtSellsOK;
@property (nonatomic, retain) NSNumber * numClosedUnpaidInv;
@property (nonatomic, retain) NSNumber * totMinSellsKO;
@property (nonatomic, retain) Firm *firm;
@property (nonatomic, retain) ItemCategory *itemCategory;

- (BOOL) isEmpty;

@end
