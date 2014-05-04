//
//  OneCharTextCell.m
//  repWallet
//
//  Created by Alberto Fiore on 10/19/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "OneCharTextCell.h"


@implementation OneCharTextCell

-(void) setControlValue:(id)value
{ 
    if(value) {
        
        if ([value length] == 0) {
            
            self.textField.text = @"<empty>";
            self.textValue = nil;
            
        } else if ([value length] > 1) {
            
            self.textField.text = value;
            self.textValue = value;
            
        } else { //OK
            
            self.textField.text = value;
            self.textValue = value;
        }
        
    } else {
        self.textField.text = @"<empty>";
        self.textValue = nil;
        
    }
}

- (id) getControlValue
{
	return self.textValue;
}

#pragma mark UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)txtField
{
    if(!self.textField.text
       || (self.textField.text && [self.textField.text length] == 0)
       || (self.textField.text && [self.textField.text length] == 1)) {
        
        if(![self hasValidControlValue])
            [super removeRedAlert];
        
        [self setControlValue:self.textField.text];
        [self postEndEditingNotification];
        
    } else if(self.textField.text || [self.textField.text length] > 1) {
        
        if([self hasValidControlValue])
            [super setRedAlert];
        
        [self setControlValue:self.textField.text];
        [self postWrongEditingNotification];
        
    } else {
        ;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string 
{
    NSUInteger oldLength = [textField.text length];
    NSUInteger replacementLength = [string length];
    NSUInteger rangeLength = range.length;
    
    NSUInteger newLength = oldLength - rangeLength + replacementLength;
    
    BOOL returnKey = [string rangeOfString: @"\n"].location != NSNotFound;
    
    return newLength <= 1 || returnKey;
}

@end
