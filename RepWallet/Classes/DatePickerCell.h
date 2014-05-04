//
//  DatePickerCell.h
//  repWallet
//
//  Created by Alberto Fiore on 2/2/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseDataEntryCell.h"
#import "BasePickerCell.h"

#define SETDATE_BTN_HEIGHT 40.0
#define SETDATE_BTN_WIDTH 125.0
#define IPAD_SETDATE_BTN_HEIGHT 80.0
#define IPAD_SETDATE_BTN_WIDTH 250.0
#define SETDATE_BTN_INTERNAL_HEIGHT 22.75
#define IPAD_SETDATE_BTN_INTERNAL_HEIGHT 45.5

@interface DatePickerCell : BaseDataEntryCell <UIActionSheetDelegate> {
    
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier minDate:(NSDate *)minDate maxDate:(NSDate *)maxDate datePickerMode:(UIDatePickerMode)datePickerMode boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier datePickerMode:(UIDatePickerMode)datePickerMode boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label;

- (void) setMinDate:(NSDate *)minDate maxDate:(NSDate *)maxDate;

@property (nonatomic,retain) UIButton* btn;
@property (nonatomic,retain) UIDatePicker *datePicker;
@property (nonatomic,retain) NSDateFormatter *dateFormatter;
@property (nonatomic,retain) UIActionSheet *actionSheet;
@property (nonatomic,retain) NSDate *dateValue;
@property (nonatomic,retain) NSString *controlMode;
@property (nonatomic,assign) BOOL addedUnderline;
@property (nonatomic,retain) UIView * underline;
@property (nonatomic,retain) UIPopoverController *popover;

- (void) setConnectedDatePickerWithDK:(NSString *)datePickerDK controlMode:(NSString *)controlMode;

@end
