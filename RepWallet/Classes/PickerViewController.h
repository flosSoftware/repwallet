//
//  PickerViewController.h
//  repWallet
//
//  Created by Alberto Fiore on 11/13/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BasePickerCell.h"

@interface PickerViewController : UIViewController {
    
}
@property (nonatomic, retain) BasePickerCell* pickerCell;
-(id)initWithPickerCell:(BasePickerCell *)pv;
@end
