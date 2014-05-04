//
//  SwitchCell.h
//  repWallet
//
//  Created by Alberto Fiore on 4/13/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "BaseDataEntryCell.h"
#import "UICustomSwitch.h"



@interface SwitchCell : BaseDataEntryCell {
    
}

@property (nonatomic, retain) UICustomSwitch *switchField;
@property (nonatomic, retain) NSString *rightText;
@property (nonatomic, retain) NSString *leftText;

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier leftText:(NSString *)leftTxt rightText:(NSString *)rightTxt boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label;

- (void) switchTouched:(id)sender;

@end
