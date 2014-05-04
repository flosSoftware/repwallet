//
//  Statistic.m
//  repWallet
//
//  Created by Alberto Fiore on 1/31/13.
//  Copyright (c) 2013 Alberto Fiore. All rights reserved.
//

#import "Statistic.h"
#import "Firm.h"
#import "ItemCategory.h"


@implementation Statistic

@dynamic numSellsKO;
@dynamic totMinContacts;
@dynamic amtOpenUnpaidInv;
@dynamic totMinSellsOK;
@dynamic totDayUnresUnpaidInv;
@dynamic amtClosedUnpaidInv;
@dynamic refMonth;
@dynamic numContacts;
@dynamic refYear;
@dynamic numSellsOK;
@dynamic numOpenUnpaidInv;
@dynamic amtSellsOK;
@dynamic numClosedUnpaidInv;
@dynamic totMinSellsKO;
@dynamic firm;
@dynamic itemCategory;

- (BOOL) isEmpty
{
    if(
       [self.numSellsOK intValue] == 0
       &&
       [self.numSellsKO intValue] == 0
       &&
       [self.numContacts intValue] == 0
       &&
       [self.numClosedUnpaidInv intValue] == 0
       &&
       [self.numOpenUnpaidInv intValue] == 0
       &&
       [self.totMinContacts integerValue] == 0
       &&
       [self.totMinSellsOK integerValue] == 0
       &&
       [self.totMinSellsKO integerValue] == 0
       &&
       [self.totDayUnresUnpaidInv integerValue] == 0
       &&
       [self.amtOpenUnpaidInv doubleValue] == 0.0
       &&
       [self.amtClosedUnpaidInv doubleValue] == 0.0
       &&
       [self.amtSellsOK doubleValue] == 0.0
       )
        return YES;
    
    return NO;
}

@end
