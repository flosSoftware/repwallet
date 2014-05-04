//
//  IntegerCell.m
//  repWallet
//
//  Created by Alberto Fiore on 12/14/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//

#import "IntegerCell.h"


@implementation IntegerCell

- (void)textFieldDidEndEditing:(UITextField *)txtField
{
    NSNumberFormatter * numF = [[NSNumberFormatter alloc] init]; 
    [numF setNumberStyle:NSNumberFormatterDecimalStyle]; 
    [numF setMaximumFractionDigits:3];
    
    NSNumber *n = nil;
    
    if(self.textField.text)
        n = [numF numberFromString:self.textField.text];
    
    if (self.lowerLimitnumber) {
        if (n && [n doubleValue] < [self.lowerLimitnumber doubleValue]) {
            n = self.lowerLimitnumber;
        }
    }
    
    if (self.upperLimitnumber) {
        if (n && [n doubleValue] > [self.upperLimitnumber doubleValue]) {
            n = self.upperLimitnumber;
        }
    }
    
    if(n) { // string representing number
        
        if(![super hasValidControlValue])
            [super removeRedAlert];
        int i = round([n doubleValue]);
        [super setControlValue:[NSNumber numberWithInt:i]];
        [super postEndEditingNotification];
        
    } else if([[self.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) { // an empty string
        
        if(![super hasValidControlValue])
            [super removeRedAlert];
        
        [super setControlValue:nil];
        
        [self postEndEditingNotification];
        
    } else { // not empty string but not representing a correct number
        
        if([super hasValidControlValue])
            [super setRedAlert];
        
        [super setControlValue:self.textField.text];
        [super postWrongEditingNotification];
        
    }
    
    [numF release];
}

@end
