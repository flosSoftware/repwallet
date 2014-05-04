//
//  DatePickerViewController.h
//  repWallet
//
//  Created by Alberto Fiore on 11/13/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DatePickerCell.h"


@interface DatePickerViewController : UIViewController {
    
}

@property (nonatomic, retain) DatePickerCell* datePickerCell;
-(id)initWithDatePickerCell:(DatePickerCell *)dp;
@end
