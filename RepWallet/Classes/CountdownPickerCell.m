//
//  CountdownPickerCell.m
//  repWallet
//
//  Created by Alberto Fiore on 1/27/13.
//  Copyright (c) 2013 Alberto Fiore. All rights reserved.
//

#import "CountdownPickerCell.h"

@implementation CountdownPickerCell

@synthesize timeLeft;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label
{
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier datePickerMode:UIDatePickerModeCountDownTimer boundClassName:boundClassName dataKey:dataKey label:label]){
        self.datePicker.countDownDuration = 0;
        self.datePicker.minuteInterval = 5;
    }
    
    return self;
}


-(void) setControlValue:(id)value
{ 
    if(value) {
        
        [self.datePicker setCountDownDuration:[value doubleValue]];
        [self.btn setBackgroundImage:nil forState:UIControlStateNormal];

        double timeInHours = self.datePicker.countDownDuration / 3600.0;
        double intPart, fractPart;
        fractPart = modf(timeInHours, &intPart);
        fractPart = 60.0 * fractPart;
        
        NSString *plForHrs = (int)intPart == 1 ? @"" : @"s";

        NSString *plForMins = (int)fractPart == 1 ? @"" : @"s";
        
        NSString *hoursStr = ((int)intPart == 0 ? @"" : [NSString stringWithFormat:@"%i hour%@", (int)intPart, plForHrs]);
        
        NSString *spaceStr = (hoursStr.length == 0 ? @"" : @" ");
        
        NSString *minsStr = [NSString stringWithFormat:@"%i min%@", (int)fractPart, plForMins];
        
        NSString *str = [NSString stringWithFormat:@"%@%@%@", hoursStr, spaceStr, minsStr];
        
        [self.btn setTitle:[NSString stringWithFormat:@"%@ early", str] forState:UIControlStateNormal];

    }  else {
        [self.btn setBackgroundImage:[UIImage imageNamed:@"setDate.png"] forState:UIControlStateNormal];
        [self.underline removeFromSuperview];
        self.underline = nil;
        self.addedUnderline = NO;
        [self.btn setTitle:nil forState:UIControlStateNormal];
        
    }
    
    self.dateValue = value;
    
    [self layoutSubviews];
}

-(id) getControlValue
{
	return [NSNumber numberWithDouble:self.datePicker.countDownDuration];
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) { // OK
        
        [self setControlValue:[NSNumber numberWithDouble:self.datePicker.countDownDuration]];
        
        //        NSLog(@"notified to %@", [NSString stringWithFormat:@"%@%@", self.boundClassName, self.dataKey]);
        
        [self postEndEditingNotification];
        
    } else if (buttonIndex == 1) { // CANCEL
        ;
    } 
}


@end
