//
//  NonNegativeIntegerCell.m
//  repWallet
//
//  Created by Alberto Fiore on 1/16/13.
//  Copyright (c) 2013 Alberto Fiore. All rights reserved.
//

#import "NonNegativeIntegerCell.h"

@implementation NonNegativeIntegerCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier boundClassName:boundClassName dataKey:dataKey label:label]) {	
        
        self.lowerLimitnumber = [NSNumber numberWithInt:0];
    }
    
    return self;
}

@end
