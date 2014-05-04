//
//  PhoneNrCell.m
//  repWallet
//
//  Created by Alberto Fiore on 11/23/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//

#import "PhoneNrCell.h"

@implementation PhoneNrCell

@synthesize detector;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier boundClassName:boundClassName dataKey:dataKey label:label]) {	
        
        self.textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        self.detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypePhoneNumber
                                                        error:nil];
        
    }
    
    return self;
}

- (void)textFieldDidEndEditing:(UITextField *)txtField
{
    BOOL passedValidation = NO;

    
    NSTextCheckingResult *match = [self.detector firstMatchInString:txtField.text
                                         options:0
                                           range:NSMakeRange(0, [txtField.text length])];
    
    if ([match resultType] == NSTextCheckingTypePhoneNumber 
        && NSEqualRanges(match.range, NSMakeRange(0, [txtField.text length]))) {
            passedValidation = YES;
    }
    
    if(passedValidation
       || 
       [[txtField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) { // string representing a phone number or an empty string
        
        if(![self hasValidControlValue])
            [super removeRedAlert];
        
        [self setControlValue:txtField.text];
        [self postEndEditingNotification];
        
    } else { // not empty string but not representing a phone number
        
        if([self hasValidControlValue])
            [super setRedAlert];
        
        [self setControlValue:txtField.text];
        [self postWrongEditingNotification];
        
    }

}


- (void)dealloc 
{
    [self.detector release];
    [super dealloc];
}

@end
