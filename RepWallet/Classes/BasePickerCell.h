//
//  BasePickerCell.h
//  repWallet
//
//  Created by Alberto Fiore on 3/12/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseDataEntryCell.h"

#define CHOOSE_BTN_HEIGHT 40.0
#define CHOOSE_BTN_WIDTH 125.0
#define IPAD_CHOOSE_BTN_HEIGHT 80.0
#define IPAD_CHOOSE_BTN_WIDTH 250.0
#define CHOOSE_BTN_INTERNAL_HEIGHT 22.75
#define IPAD_CHOOSE_BTN_INTERNAL_HEIGHT 45.5

@interface BasePickerCell : BaseDataEntryCell <UIActionSheetDelegate, UIPickerViewDataSource, UIPickerViewDelegate> {
    
}

@property (nonatomic,retain) NSArray *dataSourceArray;
@property (nonatomic,retain) UIButton *btn;
@property (nonatomic,retain) UIPickerView *pickerView;
@property (nonatomic,retain) UIActionSheet *actionSheet;
@property (nonatomic,assign) BOOL addedUnderline;
@property (nonatomic,retain) UIView *underline;
@property (nonatomic,retain) UIPopoverController *popover;

- (id)initWithStyle:(UITableViewCellStyle)style andDataSource:(NSArray *)aDataSource reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label;
- (void)reloadPicker;

@end
