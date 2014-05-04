//
//  BaseDataEntryCell.m
//  repWallet
//
//  Created by Alberto Fiore on 3/13/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "BaseDataEntryCell.h"
#import "UILabel+dynamicSize.h"


@implementation BaseDataEntryCell

@synthesize boundClassName;
@synthesize dataKey;
@synthesize mandatory;
@synthesize disablingDK;
@synthesize disablingValue;
@synthesize validControlValue;
@synthesize enabledCell;
@synthesize color;

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label color:(UIColor *)color 
{
    self = [self initWithStyle:style reuseIdentifier:reuseIdentifier boundClassName:boundClassName dataKey:dataKey label:label];
    if (self) {
        self.color = color;
        self.textLabel.textColor = self.color;
    }
    return self;
}

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        
        _isAddEditCell = YES; // DEFAULT
        self.mandatory = NO;
        self.enabledCell = YES;
        self.validControlValue = YES;
        self.boundClassName = boundClassName;
        self.dataKey = dataKey;
        self.textLabel.text = [NSString stringWithFormat:@"%@:", label];
        self.color = [UIColor colorWithRed:0.0 green:0.27 blue:0.67 alpha:1.0];
        self.textLabel.textColor = self.color;
    }
    
    return self;
}

- (UIViewController*)viewController
{
    for (UIView* next = [self superview]; next; next = next.superview)
    {
        UIResponder* nextResponder = [next nextResponder];
        
        if ([nextResponder isKindOfClass:[UIViewController class]])
        {
            return (UIViewController*)nextResponder;
        }
    }
    
    return nil;
}

- (void) setControlValue:(id)value
{
    NSException *exception = [NSException exceptionWithName: @"AbstractMethodCalledException"
                                                     reason: [NSString stringWithFormat:@"You must override method %@ in a subclass!", NSStringFromSelector(_cmd)]
                                                   userInfo: nil];
    @throw exception;
}

- (id) getControlValue
{
    NSException *exception = [NSException exceptionWithName: @"AbstractMethodCalledException"
                                                     reason: [NSString stringWithFormat:@"You must override method %@ in a subclass!", NSStringFromSelector(_cmd)]
                                                   userInfo: nil];
    @throw exception;
}

- (void) postEndEditingNotification
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary]; 
    [dict setObject:self forKey:@"value"];

    [[NSNotificationCenter defaultCenter] 
     postNotificationName:CELL_ENDEDIT_NOTIFICATION_NAME
     object:nil userInfo:dict];
}

- (void) postWrongEditingNotification
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary]; 
    [dict setObject:self forKey:@"value"];

    [[NSNotificationCenter defaultCenter] 
     postNotificationName:CELL_WRONGEDIT_NOTIFICATION_NAME
     object:nil userInfo:dict];
}

- (void) setRedAlert
{
    self.validControlValue = NO;
    self.textLabel.textColor = [UIColor redColor];
}

- (void) removeRedAlert
{
	self.validControlValue = YES;
    self.textLabel.textColor = self.color;
}

- (void) setEnabled:(BOOL)enabled
{
    self.textLabel.enabled = enabled;
    self.userInteractionEnabled = enabled;    
    self.enabledCell = enabled;
}

- (void) setDisablingDK:(NSString *)disablingDK forValue:(NSString *)disablingValue 
{
    self.disablingDK = [NSString stringWithFormat:@"%@%@", self.boundClassName, disablingDK];
    
    self.disablingValue = disablingValue;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveDisablingNotification:) name:self.disablingDK object:nil];
    
//    NSLog(@"cell with data key %@: setting disabling data key to %@", self.dataKey, self.disablingDK);
}

- (void) receiveDisablingNotification:(NSNotification *)notification 
{
//    NSLog(@"cell with data key %@: receiving value %@", self.dataKey, [[notification userInfo] objectForKey:@"value"]);
    
    if([[[notification userInfo] objectForKey:@"value"] isEqualToString:self.disablingValue]) {

        [self setEnabled: NO];
        
    } else {
        
        [self setEnabled: YES];
    }
}

- (void) changeMandatoryStatusTo:(BOOL)mandatory 
{
    if(self.textLabel.text == nil) {
        
        return;  
        
    } else if ((self.mandatory && mandatory)
        || (!self.mandatory && !mandatory)) {
        
        ; // do nothing
        
    } else if (!self.mandatory && mandatory) {
        self.textLabel.text = [self.textLabel.text stringByAppendingString:@"*"];
        
        [self.textLabel resizeToStretch];
        [self layoutSubviews];
        
    } else if (self.mandatory && !mandatory) {
        NSRange range = NSMakeRange(0, [self.textLabel.text length] - 1);
        self.textLabel.text = [self.textLabel.text substringWithRange:range];
        
        [self.textLabel resizeToStretch];
        [self layoutSubviews];
        
    } else {
        ;
    }
    
    self.mandatory = mandatory;
}

- (BOOL) isMandatory
{
    return self.mandatory && self.enabledCell;
}

- (void)layoutSubviews 
{
	[super layoutSubviews];
    
    [self.textLabel resizeToStretch];
    
    float sepRowHeight;
    
    if ([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad]) {
        sepRowHeight = IPAD_SEPARATOR_ROW_HEIGHT;
    } else {
        sepRowHeight = SEPARATOR_ROW_HEIGHT;
    }
    
    CGRect labelRect;
    
    if (_isAddEditCell) {
        labelRect = CGRectMake(self.textLabel.frame.origin.x
                               + 4.0 * self.indentationWidth,
                               self.contentView.center.y
                               - roundf(self.textLabel.frame.size.height - 0.5 * sepRowHeight), 
                               self.textLabel.frame.size.width, 
                               self.textLabel.frame.size.height);
    } else {
        labelRect = CGRectMake(self.textLabel.frame.origin.x
                               + 4.0 * self.indentationWidth,
                               self.contentView.center.y
                               - roundf(0.5 * self.textLabel.frame.size.height), 
                               self.textLabel.frame.size.width, 
                               self.textLabel.frame.size.height);
    }
    
    [self.textLabel setFrame:labelRect];
}

- (void)setIsAddEditCell:(BOOL)isAddEditCell 
{
    _isAddEditCell = isAddEditCell;
}

- (void) dealloc 
{
//    NSLog(@"dealloc'd %@", self.dataKey);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.color release];
    [self.boundClassName release];
    [self.dataKey release];
    [self.disablingDK release];
    [self.disablingValue release];
    [super dealloc];
}


@end
