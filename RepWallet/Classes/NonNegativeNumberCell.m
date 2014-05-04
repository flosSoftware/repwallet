//
//  NonNegativeNumberCell.m
//  repWallet
//
//  Created by Alberto Fiore on 11/7/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "NonNegativeNumberCell.h"


@implementation NonNegativeNumberCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier boundClassName:boundClassName dataKey:dataKey label:label]) {	
        
        self.lowerLimitnumber = [NSNumber numberWithInt:0];
    }
    
    return self;
}

@end
