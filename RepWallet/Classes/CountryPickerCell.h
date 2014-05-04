//
//  CountryPickerCell.h
//  repWallet
//
//  Created by Alberto Fiore on 11/16/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LabeledStringPickerCell.h"

@interface CountryPickerCell : LabeledStringPickerCell {
    
}

- (NSString *) getISOCodeForControlValue;

@end
