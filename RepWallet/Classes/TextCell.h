//
//  TextCell.h
//  repWallet
//
//  Created by Alberto Fiore on 10/09/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseDataEntryCell.h"

#define TEXTFIELD_HEIGHT 25.0
#define TEXTFIELD_PADDING_TOP 16.0

@interface TextCell : BaseDataEntryCell <UITextFieldDelegate> {

}

@property (nonatomic, retain) UITextField *textField;
@property (nonatomic, retain) NSString *textValue;
@property (nonatomic, retain) UIView *underline;

- (void) focus;
- (void) defocus;
- (void) nextTextField;
- (void) prevTextField;
- (void) clearField;

@end
