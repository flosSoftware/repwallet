//
//  NumberCell.m
//  repWallet
//
//  Created by Alberto Fiore on 2/2/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "NumberCell.h"

@implementation NumberCell

@synthesize number, upperLimitnumber, lowerLimitnumber, controlMode;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier boundClassName:boundClassName dataKey:dataKey label:label]) {	

        self.textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        
        self.number = nil;
        
        self.lowerLimitnumber = nil;
        self.upperLimitnumber = nil;
    }
    
    return self;
}

-(void) setControlValue:(id)value
{ 
    NSNumberFormatter * numF = [[NSNumberFormatter alloc] init]; 
    [numF setNumberStyle:NSNumberFormatterDecimalStyle]; 
    [numF setMaximumFractionDigits:3];
    
    if(value && [value isKindOfClass:[NSNumber class]]) {
        
        [super setControlValue:[numF stringFromNumber:value]];  
        
        self.number = value;

    } else {
        
        [super setControlValue:value]; 
        
        self.number = nil;
        
    } 

    [numF release];
}

- (id) getControlValue
{
	return self.number;
}

- (void)setEnabled:(BOOL)enabled {
    
    [super setEnabled:enabled];
    
}

#pragma mark UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)txtField
{
    NSNumberFormatter * numF = [[NSNumberFormatter alloc] init]; 
    [numF setNumberStyle:NSNumberFormatterDecimalStyle]; 
    [numF setMaximumFractionDigits:3];

    NSNumber *n = nil;
    
    if(self.textField.text) {
        NSMutableString * string = [self.textField.text mutableCopy];
        [string replaceOccurrencesOfString:@"," withString:@"" options:0 range:NSMakeRange(0, string.length)];
        self.textField.text = string;
        [string release];
        n = [numF numberFromString:self.textField.text];
    }
    
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
    
    if(n) { // string representing a number
        
        if(![self hasValidControlValue])
            [super removeRedAlert];
        
        [self setControlValue:n];
        
        // notify connected cells
        
        NSMutableDictionary * dictio = [NSMutableDictionary dictionary];
        [dictio setValue:[self getControlValue] forKey:@"value"];
        [[NSNotificationCenter defaultCenter] postNotificationName:[NSString stringWithFormat:@"%@%@", self.boundClassName, self.dataKey] object:nil userInfo:dictio];
        
        [self postEndEditingNotification];
        
    } else if([[self.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) { // an empty string
        
        if(![self hasValidControlValue])
            [super removeRedAlert];
        
        [self setControlValue:nil];

        [self postEndEditingNotification];
                
    } else { // not empty string but not representing a number
        
        if([self hasValidControlValue])
            [super setRedAlert];
        
        [self setControlValue:self.textField.text];
        [self postWrongEditingNotification];
        
    }
    
    [numF release];
}


#pragma mark -
#pragma mark Notifications from other number cells

- (void) setConnectedNumberCellWithDK:(NSString *)numberCellDK controlMode:(NSString *)controlMode 
{
    self.controlMode = controlMode;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNumberCellNotification:) name:[NSString stringWithFormat:@"%@%@", self.boundClassName, numberCellDK] object:nil];
}

- (void) receiveNumberCellNotification:(NSNotification *)notification 
{
    if([self getControlValue] 
       && [[notification userInfo] objectForKey:@"value"] 
       && [self.controlMode isEqualToString:@"HigherThanOrEqual"]) {
        
        NSNumber * num = (NSNumber *)[[notification userInfo] objectForKey:@"value"];
        
        if ([[self getControlValue] doubleValue] < [num doubleValue]) {
            
            if(![self hasValidControlValue])
                [super removeRedAlert];
            
            [self setControlValue:num];
            
            [self postEndEditingNotification];
            
        } 
        
    } else if([self getControlValue] 
              && [[notification userInfo] objectForKey:@"value"] 
              && [self.controlMode isEqualToString:@"LowerThanOrEqual"]) {
        
        NSNumber * num = (NSNumber *)[[notification userInfo] objectForKey:@"value"];
        
        if ([[self getControlValue] doubleValue] > [num doubleValue]) {
            
            if(![self hasValidControlValue])
                [super removeRedAlert];
            
            [self setControlValue:num];
            
            [self postEndEditingNotification];
            
        } 
        
    } else
        ;
}


- (void)dealloc 
{
    [self.controlMode release];
    [self.lowerLimitnumber release];
    [self.upperLimitnumber release];
    [self.number release];
    [super dealloc];
}

@end
