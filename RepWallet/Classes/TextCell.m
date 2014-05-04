//
//  TextCell.m
//  repWallet
//
//  Created by Alberto Fiore on 10/09/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "TextCell.h"
#import <QuartzCore/QuartzCore.h>
#import "AddEditViewController.h"

@implementation TextCell

@synthesize textField;
@synthesize textValue;
@synthesize underline;

- (void) focus {
    
    [self.textField becomeFirstResponder];
}

- (void) defocus {
    
    if([self.textField isFirstResponder])
        [self.textField resignFirstResponder];
    
}

- (void)setIsAddEditCell:(BOOL)isAddEditCell 
{
    [super setIsAddEditCell:isAddEditCell];
    if (!_isAddEditCell) {
        UIView * v = [[UIView alloc] initWithFrame:CGRectZero];
        self.underline = v;
        [self.underline setBackgroundColor:[UIColor blackColor]];
        [self.contentView addSubview:self.underline];
        [v release];
    }
}

- (void) nextTextField {

    TextCell* nextCell = [[self viewController] nextTextCellForIndexpath:[(UITableView *)self.superview indexPathForCell:self]];   

    if (nextCell) {
        [nextCell focus];
    } else {
        [self defocus];
    }   
}

- (void) prevTextField {
    
    NSIndexPath * ip = [(UITableView *)self.superview indexPathForCell:self];

    TextCell* nextCell = [[self viewController] prevTextCellForIndexpath:ip];    
    
    if (nextCell) {
        [nextCell focus];   
    } else {
        [self defocus];
    }   
}

- (void) clearField {
    
    [self setControlValue:@""];
    
    self.textField.text = @"";
    
}

-(void) segmentAction:(UISegmentedControl *)segmentedControl
{
    if (segmentedControl.selectedSegmentIndex == 0) {
        [self prevTextField];
    } else
        [self nextTextField];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier boundClassName:boundClassName dataKey:dataKey label:label]) {	
        
        [[NSNotificationCenter defaultCenter] 
         addObserver:self 
         selector:@selector(defocus) 
         name:DRAGGING_STARTED_NOTIFICATION 
         object:nil];
        
		// Configuro il textfield
        float fontSize;
        if([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad]){
            fontSize = [UIFont labelFontSize] + 14;
        } else {
            fontSize = [UIFont labelFontSize];
        }
        
		UITextField * t = [[UITextField alloc] initWithFrame:CGRectZero];
		t.clearsOnBeginEditing = NO;
		t.textAlignment = UITextAlignmentLeft;
		t.returnKeyType = UIReturnKeyDone;
		t.font = [UIFont systemFontOfSize:fontSize];	
		t.autocorrectionType = UITextAutocorrectionTypeNo;
		t.autocapitalizationType = UITextAutocapitalizationTypeNone;
        
        t.borderStyle = UITextBorderStyleNone;
        
        t.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        
		t.delegate = self;
        
        UIToolbar *toolbar = [[[UIToolbar alloc] init] autorelease];
        [toolbar setBarStyle:UIBarStyleBlackTranslucent];
        [toolbar sizeToFit];
        
        // Create the segmented control
        NSArray *buttonNames = [NSArray arrayWithObjects:
                                @"Previous", @"Next", nil];
        UISegmentedControl* segmentedControl = [[UISegmentedControl alloc] initWithItems:buttonNames];
        segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        segmentedControl.momentary = YES;
        [segmentedControl addTarget:self action:@selector(segmentAction:)
                   forControlEvents:UIControlEventValueChanged];
        
        UIBarButtonItem *clearButton =[[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStyleBordered target:self action:@selector(clearField)];

        UIBarButtonItem *flexButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
        
        UIBarButtonItem *segmentedItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
        
        NSArray *itemsArray = [NSArray arrayWithObjects:clearButton, flexButton, segmentedItem, nil];
        
        [toolbar setItems:itemsArray];
        
        [clearButton release];
        [flexButton release];
        [segmentedControl release];
        [segmentedItem release];

        [t setInputAccessoryView:toolbar];
        
        self.textField = t;
        
		[self.contentView addSubview:self.textField];
        
        [t release];
        
        self.textField.text = @"<empty>";
        
        self.textValue = nil;
    }
    
    return self;
}

- (void)layoutSubviews 
{
	[super layoutSubviews];
    
    float rightPadding, underlinePadding;
    if([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad]){
        rightPadding = IPAD_RIGHT_PADDING;
        underlinePadding = IPAD_UNDERLINE_PADDING;
    } else {
        rightPadding = RIGHT_PADDING;
        underlinePadding = UNDERLINE_PADDING;
    }
	
	// Rect area del textbox
	CGRect rect = CGRectMake(self.textLabel.frame.origin.x 
                             + self.textLabel.frame.size.width 
                             + 1.0 * self.indentationWidth,
                             self.textLabel.frame.origin.y,
							 self.contentView.frame.size.width 
                             - (self.textLabel.frame.size.width 
                                + 3.0 * self.indentationWidth 
                                + self.textLabel.frame.origin.x) 
                             - rightPadding, 
                             self.textLabel.frame.size.height);
	
	[self.textField setFrame:rect];
    
    if (!_isAddEditCell) {
        [self.underline setFrame:CGRectMake(self.textField.frame.origin.x, 
                                            self.contentView.frame.origin.y
                                            + self.contentView.frame.size.height
                                            - underlinePadding, 
                                            self.textField.frame.size.width, 
                                            1
                                            )];
    }
    
}

-(void) setControlValue:(id)value
{ 
    if(value) {
        
        NSString * trimmedValue = [(NSString *) value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if ([trimmedValue length] == 0) {
            
            self.textField.text = @"<empty>";
            self.textValue = nil;
            
        } else {
         
            self.textField.text = value;
            self.textValue = value;
            
        }
        
    } else {
        
        self.textField.text = @"<empty>";
        self.textValue = nil;
        
    }
    
//    NSLog(@"textfield text '%@' control value '%@'", self.textField.text, self.textValue);
}

- (id) getControlValue
{
	return self.textValue;
}

- (void) setEnabled:(BOOL)enabled 
{
    if (!enabled) {
        
        [self.textField setTextColor:[UIColor grayColor]];
        self.textField.text = @"";
        [self.underline setBackgroundColor:[UIColor grayColor]];
        
    } else {
        
        [self.textField setTextColor:[UIColor blackColor]];
        
        if (self.textValue && [[self.textValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0) {
            
            self.textField.text = self.textValue;
            
        } else {
            
            self.textField.text = @"<empty>";
            
        }
        
        [self.underline setBackgroundColor:[UIColor blackColor]];
    }
    
    [super setEnabled:enabled];
}

#pragma mark UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if([self.textField.text isEqualToString:@"<empty>"])
       self.textField.text = @"" ;
}

- (void)textFieldDidEndEditing:(UITextField *)txtField
{
    [self setControlValue:txtField.text];
	[self postEndEditingNotification];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField 
{ 
    if (theTextField == self.textField) {
        [theTextField resignFirstResponder];
    } 
    return YES;
}

- (void)dealloc 
{
    [self.underline release];
    [self.textValue release];
    [self.textField release];
    [super dealloc];
}

@end
