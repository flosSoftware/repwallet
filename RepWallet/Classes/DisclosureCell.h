//
//  DisclosureCell.h
//  repWallet
//
//  Created by Alberto Fiore on 6/7/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseDataEntryCell.h"

#define SEE_BUTTON_HEIGHT 40.0
#define SEE_BUTTON_WIDTH 125.0
#define IPAD_SEE_BUTTON_HEIGHT 80.0
#define IPAD_SEE_BUTTON_WIDTH 250.0
#define SEE_BTN_INTERNAL_HEIGHT 22.75
#define IPAD_SEE_BTN_INTERNAL_HEIGHT 45.5

@interface DisclosureCell : BaseDataEntryCell {
    NSString * notificationName;
    UIButton * btn;
}

@property(nonatomic, retain) NSString * notificationName;
@property(nonatomic, retain) UIButton * btn;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier notificationName:(NSString *)notificationName boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label;

@end
