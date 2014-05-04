//
//  EMailCell.m
//  repWallet
//
//  Created by Alberto Fiore on 12/26/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//

#import "EMailCell.h"

@implementation EMailCell

- (BOOL) validateEmail: (NSString *) candidate {
    
    NSString *emailRegex =
    @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
    @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
    @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
    @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
    @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
    @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
    @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"; 
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex]; 
    
    return [emailTest evaluateWithObject:candidate];
}

- (void)textFieldDidEndEditing:(UITextField *)txtField
{
    BOOL passedValidation = NO;
    
    if ([self validateEmail:txtField.text]) {
        passedValidation = YES;
    }
    
    if(passedValidation
       || 
       [[txtField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) { // string representing an e-mail address or an empty string
        
        if(![self hasValidControlValue])
            [super removeRedAlert];
        
        [self setControlValue:txtField.text];
        [self postEndEditingNotification];
        
    } else { // not empty string but not representing an e-mail address
        
        if([self hasValidControlValue])
            [super setRedAlert];
        
        [self setControlValue:txtField.text];
        [self postWrongEditingNotification];
        
    }
    
}


@end
