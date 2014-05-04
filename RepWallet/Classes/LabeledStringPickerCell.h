//
//  LabeledStringPickerCell.h
//  repWallet
//
//  Created by Alberto Fiore on 5/4/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BasePickerCell.h"


@interface LabeledStringPickerCell : BasePickerCell {
    
}

@property (nonatomic,retain) NSString *pickerValue;

- (NSString *)getLabelValue;

@end
