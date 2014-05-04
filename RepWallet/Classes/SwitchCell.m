//
//  SwitchCell.m
//  repWallet
//
//  Created by Alberto Fiore on 4/13/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "SwitchCell.h"


@implementation SwitchCell

@synthesize switchField;
@synthesize rightText;
@synthesize leftText;

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier leftText:(NSString *)leftTxt rightText:(NSString *)rightTxt boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier boundClassName:boundClassName dataKey:dataKey label:label]) {	
        
        self.rightText = rightTxt;
        self.leftText = leftTxt;
		self.switchField = [UICustomSwitch switchWithLeftText:self.leftText andRight:self.rightText]; 
        
        // DEFAULT is left value
        
        // listen to the switchField
        
        [self.switchField addTarget:self action:@selector(switchTouched:) forControlEvents:UIControlEventValueChanged];
        
		[self.contentView addSubview:self.switchField];
        
    }
    
    return self;
}

- (void) postSwitchStateChangeNotification 
{    
    if ([self.switchField isOn]
        && self.boundClassName
        && self.dataKey) { // LEFT
        
        //        NSLog(@"Changed to %@", self.leftText);
        
        NSDictionary* dict = [NSDictionary dictionaryWithObject:self.leftText forKey:@"value"];
        [[NSNotificationCenter defaultCenter] postNotificationName:[NSString stringWithFormat:@"%@%@", self.boundClassName, self.dataKey] object:nil userInfo:dict];
        
        //        NSLog(@"posted notification: %@", [NSString stringWithFormat:@"%@%@", self.boundClassName, self.dataKey]);
        
    } else if (![self.switchField isOn]
               && self.boundClassName
               && self.dataKey) { // RIGHT
        
        //        NSLog(@"Changed to %@", self.rightText);
        
        NSDictionary* dict = [NSDictionary dictionaryWithObject:self.rightText forKey:@"value"];
        [[NSNotificationCenter defaultCenter] postNotificationName:[NSString stringWithFormat:@"%@%@", self.boundClassName, self.dataKey] object:nil userInfo:dict];
        
        //        NSLog(@"posted notification: %@", [NSString stringWithFormat:@"%@%@", self.boundClassName, self.dataKey]);
        
    } else
        ;
    
}

- (void) switchTouched:(id)sender 
{
    [self postSwitchStateChangeNotification];
    
    [self postEndEditingNotification];
}

- (void) layoutSubviews 
{
	[super layoutSubviews];
    
    float sepRowHeight, btnPadding;
    
    if ([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad]) {
        sepRowHeight = IPAD_SEPARATOR_ROW_HEIGHT;
        btnPadding = IPAD_BTN_BOTTOM_PADDING;
    } else {
        sepRowHeight = SEPARATOR_ROW_HEIGHT;
        btnPadding = 0;
    }
    
    // Rect area del textbox
    
    CGRect rect;
    
    if (!_isAddEditCell) {
        rect = CGRectMake(self.textLabel.frame.origin.x + 
                                 self.textLabel.frame.size.width + 
                                 1.0 * self.indentationWidth, 
                                 self.contentView.center.y
                                 - roundf(0.5 * self.switchField.frame.size.height)
                                 , 
                                 self.switchField.frame.size.width, 
                                 self.switchField.frame.size.height);

    } else {
        rect = CGRectMake(self.textLabel.frame.origin.x 
                                 + self.textLabel.frame.size.width  
                                 + 1.0 * self.indentationWidth, 
                                 self.contentView.center.y 
                                 - self.switchField.frame.size.height
                                 - roundf(0.5 * sepRowHeight)
                                 - btnPadding
                                 , 
                                 self.switchField.frame.size.width, 
                                 self.switchField.frame.size.height);
    }
    
    [self.switchField setFrame:rect];
    
}

- (void) setControlValue:(id)value
{  
    if([(NSString *) value isEqualToString:self.leftText]) {
        
        [self.switchField setOn:YES];
        
    } else {
        
        [self.switchField setOn:NO];
    }
    
    [self postSwitchStateChangeNotification];
}

- (id) getControlValue
{
    if(![self.switchField isEnabled]) {
        return nil;  
        
    } else if([self.switchField isOn]) {
        return self.leftText;
        
    } else {
        return self.rightText;
        
    }
}

- (void) setEnabled:(BOOL)enabled 
{    
    [super setEnabled:enabled];
}

- (void) dealloc 
{
    [self.switchField release];
    [self.rightText release];
    [self.leftText release];
    [super dealloc];
}


@end
