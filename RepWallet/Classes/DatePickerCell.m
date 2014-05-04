//
//  DatePickerCell.m
//  repWallet
//
//  Created by Alberto Fiore on 2/2/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "DatePickerCell.h"
#import "DatePickerViewController.h"
#import "UIViewController+Utils.h"

@implementation DatePickerCell

@synthesize btn;
@synthesize datePicker;
@synthesize dateFormatter;
@synthesize actionSheet;
@synthesize dateValue;
@synthesize controlMode;
@synthesize addedUnderline;
@synthesize underline;
@synthesize popover;

- (void) doneAction {
    [self.actionSheet dismissWithClickedButtonIndex:0 animated:YES];
}

- (void) dismissActionSheet {
    [self.actionSheet dismissWithClickedButtonIndex:1 animated:YES];
}

- (UIToolbar *) createToolbar {
    
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    
    [toolbar setBarStyle:UIBarStyleBlackTranslucent];
    
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    
    UIBarButtonItem *doneButton =[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneAction)];
    
    UIBarButtonItem *cancelButton =[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(dismissActionSheet)];
    
    UIBarButtonItem *flexButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    NSArray *itemsArray = [NSArray arrayWithObjects:cancelButton, flexButton, doneButton, nil];
    
    [toolbar setItems:itemsArray];
    
    [cancelButton release];
    [flexButton release];
    [doneButton release];
    
    return [toolbar autorelease];
}

-(void)openPopover
{
    CGRect popoverRect = [[[self viewController] view] convertRect:[self.btn frame]
                                       fromView:[self.btn superview]];
    
    [self.popover presentPopoverFromRect:CGRectMake(popoverRect.origin.x, 
                                                    popoverRect.origin.y,
                                                    popoverRect.size.width, 
                                                    popoverRect.size.height) 
                                inView:[[self viewController] view] 
                                permittedArrowDirections:UIPopoverArrowDirectionAny 
                                animated:YES];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier minDate:(NSDate *)minDate maxDate:(NSDate *)maxDate datePickerMode:(UIDatePickerMode)datePickerMode boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label
{
    if(self = [self initWithStyle:style reuseIdentifier:reuseIdentifier datePickerMode:datePickerMode boundClassName:boundClassName dataKey:dataKey label:label]){

        self.datePicker.minimumDate = minDate;
        self.datePicker.maximumDate = maxDate;
    }
    return self;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier datePickerMode:(UIDatePickerMode)datePickerMode boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier boundClassName:boundClassName dataKey:dataKey label:label]) {
        
        RepWalletAppDelegate *appDelegate = (RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        self.addedUnderline = NO;
        
        self.underline = nil;
        
        // Configuro il btn
        
        float fontSize;
        if([appDelegate isIpad]){
            fontSize = [UIFont labelFontSize] + 14;
        } else {
            fontSize = [UIFont labelFontSize];
        }
        
        UIButton *b = [[UIButton alloc] initWithFrame:CGRectZero];
        b.backgroundColor = [UIColor clearColor];
        b.titleLabel.font = [UIFont systemFontOfSize:fontSize];
        b.titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
        b.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [b setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [b setBackgroundImage:[UIImage imageNamed:@"setDate.png"] forState:UIControlStateNormal];
        [b setBackgroundImage:[UIImage imageNamed:@"setDateDisabled.png"] forState:UIControlStateDisabled];
        [b addTarget:self action:@selector(showPicker) forControlEvents:UIControlEventTouchUpInside];
        self.btn = b;
        [b release];
        [self.contentView addSubview:self.btn];

        if ([appDelegate isIpad]) {
            
            UIDatePicker *d=[[UIDatePicker alloc] init];
            d.frame = CGRectMake(0, 0, 320, 216);
            d.datePickerMode = datePickerMode;
            d.maximumDate = nil; // default
            d.minimumDate = nil; // default
            self.datePicker = d;
            [d release];
            
            self.actionSheet = nil;
            DatePickerViewController *dpv = [[DatePickerViewController alloc] initWithDatePickerCell:self];
            UINavigationController *navbar = [[UINavigationController alloc] initWithRootViewController:dpv];
            UIPopoverController * pop = [[UIPopoverController alloc] initWithContentViewController:navbar];
            self.popover = pop;
            [pop release];
            [navbar release];
            [dpv release];
            
        } else {
            
            UIDatePicker *d = [[UIDatePicker alloc] init];
            d.frame = CGRectMake(0, 45, 320, 216);
            d.datePickerMode = datePickerMode;
            d.maximumDate = nil; // default
            d.minimumDate = nil; // default
            self.datePicker = d;
            [d release];
            
            self.popover = nil;
            UIActionSheet *a = [[UIActionSheet alloc] initWithTitle:@"Choose" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
            [a setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
            self.actionSheet = a;
            [a release];
            [self.actionSheet addSubview:self.datePicker];
            [self.actionSheet addSubview:[self createToolbar]];
        }
        
        NSDateFormatter *df = [[NSDateFormatter alloc] init]; 
        
        if (self.datePicker.datePickerMode == UIDatePickerModeDateAndTime) {
            [df setTimeStyle:NSDateFormatterShortStyle];
        } else {
            [df setTimeStyle:NSDateFormatterNoStyle];
        }
         
        [df setDateStyle:NSDateFormatterMediumStyle];
        self.dateFormatter = df;
        [df release];

        self.dateValue = nil;
    }

    return self;
}


-(void)showPicker {

    //Mostriamo nella view principale
    RepWalletAppDelegate *appDelegate = (RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    float actSheetWidth, actSheetHeight;
    if ([appDelegate isIpad]) {

        [self openPopover];
        
    } else {
        
        UIViewController *vc = [self viewController];
        
        // magic number...
        actSheetHeight = 485;
        
        actSheetWidth = [[self viewController] view].bounds.size.width;
        
        if ([vc isModal]) {
            [self.actionSheet showInView:[vc view]];
        } else {
            [self.actionSheet showFromTabBar:appDelegate.tabBarController.tabBar];
        }
        
        [self.actionSheet setBounds:CGRectMake(0, 0, actSheetWidth, actSheetHeight)];
        
        [self.datePicker setFrame:CGRectMake(
                                        floorf((self.actionSheet.frame.size.width - self.datePicker.frame.size.width) / 2.0),
                                        self.datePicker.frame.origin.y,
                                        self.datePicker.frame.size.width,
                                        self.datePicker.frame.size.height)];
    }
}

- (void)layoutSubviews {
    
	[super layoutSubviews];
	CGRect rect =  CGRectZero;
    
    float btnWidth;
    float btnHeight, internalBtnHeight;
    float rightPadding, underlinePadding, sepRowHeight, btnPadding, trickOrTreat;

    if ([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad]) {
        underlinePadding = IPAD_UNDERLINE_PADDING;
        rightPadding = IPAD_RIGHT_PADDING;
        btnHeight = IPAD_SETDATE_BTN_HEIGHT;
        btnWidth = IPAD_SETDATE_BTN_WIDTH;
        internalBtnHeight = IPAD_CHOOSE_BTN_INTERNAL_HEIGHT;
        sepRowHeight = IPAD_SEPARATOR_ROW_HEIGHT;
        btnPadding = IPAD_BTN_BOTTOM_PADDING;
        trickOrTreat = 0;
    } else {
        underlinePadding = UNDERLINE_PADDING;
        rightPadding = RIGHT_PADDING;
        btnHeight = SETDATE_BTN_HEIGHT;
        btnWidth = SETDATE_BTN_WIDTH;
        internalBtnHeight = CHOOSE_BTN_INTERNAL_HEIGHT;
        sepRowHeight = SEPARATOR_ROW_HEIGHT;
        btnPadding = BTN_BOTTOM_PADDING;
        trickOrTreat = 0;
    }
    
	// Rect area del btnbox
    if ([self.btn backgroundImageForState:UIControlStateNormal] == nil) {
        
        if (!_isAddEditCell) {
            rect = CGRectMake(self.textLabel.frame.origin.x 
                              + self.textLabel.frame.size.width  
                              + 1.0 * self.indentationWidth, 
                              self.contentView.frame.origin.y 
                              + roundf(0.5 * (self.contentView.frame.size.height - btnHeight)), 
                              self.contentView.frame.size.width 
                              - (self.textLabel.frame.size.width 
                                 + 3.0 * self.indentationWidth 
                                 + self.textLabel.frame.origin.x) 
                              - rightPadding, 
                              btnHeight);

        } else {
            rect = CGRectMake(self.textLabel.frame.origin.x 
                              + self.textLabel.frame.size.width 
                              + 1.0 * self.indentationWidth,
                              self.textLabel.frame.origin.y,
                              self.contentView.frame.size.width 
                              - (self.textLabel.frame.size.width 
                                 + 3.0 * self.indentationWidth 
                                 + self.textLabel.frame.origin.x) 
                              - rightPadding, 
                              self.textLabel.frame.size.height);
        }
        
    } else {
        
        if (!_isAddEditCell) {
            rect = CGRectMake(self.textLabel.frame.origin.x 
                              + self.textLabel.frame.size.width  
                              + 1.0 * self.indentationWidth, 
                              self.textLabel.frame.origin.y
                              + self.textLabel.frame.size.height
                              - roundf((0.5 * (btnHeight - internalBtnHeight)) + internalBtnHeight)
                              - btnPadding - trickOrTreat, 
                              btnWidth, 
                              btnHeight);

            
        } else {
            rect = CGRectMake(self.textLabel.frame.origin.x 
                              + self.textLabel.frame.size.width  
                              + 1.0 * self.indentationWidth, 
                              + self.contentView.center.y 
                              - roundf(btnHeight * 0.5
                                     + 0.5 * internalBtnHeight
                                     + 0.5 * sepRowHeight)
                              - btnPadding
                              , 
                              btnWidth, 
                              btnHeight);
        }
    }
    
	[self.btn setFrame:rect];
    
    if (!_isAddEditCell && [self getControlValue] != nil && !self.addedUnderline) {
        
        self.addedUnderline = YES;
        
        // aggiungo la riga sotto
        
        UIView * v = [[UIView alloc] initWithFrame:CGRectMake(self.btn.frame.origin.x, 
                                                              self.contentView.frame.origin.y
                                                              + self.contentView.frame.size.height
                                                              - underlinePadding, 
                                                              self.btn.frame.size.width, 
                                                              1
                                                              )];
        [v setBackgroundColor:[UIColor blackColor]];
        
        self.underline = v;
        
        [self.contentView addSubview:self.underline];
        
        [v release];
        
    } else if (!_isAddEditCell && self.addedUnderline) {
        
        
        [self.underline setFrame:CGRectMake(self.btn.frame.origin.x, 
                                            self.contentView.frame.origin.y
                                            + self.contentView.frame.size.height
                                            - underlinePadding, 
                                            self.btn.frame.size.width, 
                                            1
                                            )];
    } else
        ;
}

-(void) setControlValue:(id)value
{ 
    if(value) {
        [self.datePicker setDate:value];
        [self.btn setBackgroundImage:nil forState:UIControlStateNormal];
        [self.btn setTitle:[self.dateFormatter stringFromDate:value] forState:UIControlStateNormal];
    }  else {
        [self.btn setBackgroundImage:[UIImage imageNamed:@"setDate.png"] forState:UIControlStateNormal];
        [self.underline removeFromSuperview];
        self.underline = nil;
        self.addedUnderline = NO;
        [self.btn setTitle:nil forState:UIControlStateNormal];

    }
    
    self.dateValue = value;
    
    [self layoutSubviews];
}

-(id) getControlValue
{
	return self.dateValue;
}

-(void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    [self.btn setEnabled:enabled];
}

- (void)dealloc 
{
    [self.popover release];
    [self.underline release];
    [self.actionSheet release];
    [self.btn release];
    [self.dateFormatter release];
    [self.datePicker release];
    [self.dateValue release];
    [self.controlMode release];
    [super dealloc];
}

-(void) setMinDate:(NSDate *)minDate maxDate:(NSDate *)maxDate
{
    self.datePicker.minimumDate = minDate;
    self.datePicker.maximumDate = maxDate;
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) { // OK
        
        [self setControlValue:[self.datePicker date]];
        
        // notify other connected date pickers
        NSMutableDictionary * dictio = [NSMutableDictionary dictionary];
        [dictio setValue:[self getControlValue] forKey:@"value"];
        [[NSNotificationCenter defaultCenter] postNotificationName:[NSString stringWithFormat:@"%@%@", self.boundClassName, self.dataKey] object:nil userInfo:dictio];
        
//        NSLog(@"notified to %@", [NSString stringWithFormat:@"%@%@", self.boundClassName, self.dataKey]);
        
        [self postEndEditingNotification];
        
    } else if (buttonIndex == 1) { // CANCEL
        ;
    } 
}

#pragma mark -
#pragma mark Notifications from other date pickers

- (void) setConnectedDatePickerWithDK:(NSString *)datePickerDK controlMode:(NSString *)controlMode 
{
    self.controlMode = controlMode;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveDatePickerNotification:) name:[NSString stringWithFormat:@"%@%@", self.boundClassName, datePickerDK] object:nil];
    
//    NSLog(@"connected to %@", [NSString stringWithFormat:@"%@%@", self.boundClassName, datePickerDK]);
}

- (void) receiveDatePickerNotification:(NSNotification *)notification 
{
    if(self.dateValue 
       && [[notification userInfo] objectForKey:@"value"] 
       && [self.controlMode isEqualToString:@"After"]) {
      
        NSDate * date = (NSDate *)[[notification userInfo] objectForKey:@"value"];
        
        if ([self.dateValue compare:date] == NSOrderedAscending) {
            
            [self setControlValue:date];
            
            [self postEndEditingNotification];
            
        } 
        
        self.datePicker.minimumDate = date;
        
    } else if(self.dateValue 
              && [[notification userInfo] objectForKey:@"value"] 
              && [self.controlMode isEqualToString:@"Before"]) {
        
        NSDate * date = (NSDate *)[[notification userInfo] objectForKey:@"value"];
        
        if ([self.dateValue compare:date] == NSOrderedDescending) {
            
            [self setControlValue:date];
            
            [self postEndEditingNotification];
            
        } 
    
        self.datePicker.maximumDate = date;
        
    } else
        ;
}

@end
