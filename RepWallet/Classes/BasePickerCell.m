//
//  BasePickerCell.m
//  repWallet
//
//  Created by Alberto Fiore on 3/12/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "BasePickerCell.h"
#import <QuartzCore/QuartzCore.h>
#import "PickerViewController.h"
#import "UILabel+dynamicSize.h"

@implementation BasePickerCell

@synthesize btn;
@synthesize pickerView;
@synthesize dataSourceArray;
@synthesize actionSheet;
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

-(void)openPopover{
    
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

# pragma mark -
# pragma mark <UIPickerViewDelegate>

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView 
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)thePickerView numberOfRowsInComponent:(NSInteger)component 
{
    return [self.dataSourceArray count];
}

- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component 
{
    NSException *exception = [NSException exceptionWithName: @"AbstractMethodCalledException"
                                                     reason: [NSString stringWithFormat:@"You must override method %@ in a subclass!", NSStringFromSelector(_cmd)]
                                                   userInfo: nil];
    @throw exception;
}

- (void)pickerView:(UIPickerView *)thePickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component 
{
    //NSLog(@"Selected index: %i", row);
}

- (id)initWithStyle:(UITableViewCellStyle)style andDataSource:(NSArray *)aDataSource reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier boundClassName:boundClassName dataKey:dataKey label:label]) {
        
        RepWalletAppDelegate *appDelegate = (RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        self.underline = nil;
        
        self.addedUnderline = NO;
        
        self.dataSourceArray = aDataSource;
        
        // Configuro il btn secondo la necessità
        
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
        [b setBackgroundImage:[UIImage imageNamed:@"chooseElement.png"] forState:UIControlStateNormal];
        [b setBackgroundImage:[UIImage imageNamed:@"chooseElementDisabled.png"] forState:UIControlStateDisabled];
        [b setTitle:nil forState:UIControlStateDisabled];
        [b addTarget:self action:@selector(showPicker)
           forControlEvents:UIControlEventTouchUpInside];
        self.btn = b;
        [b release];
        
        if([aDataSource count] == 0)
            [self.btn setEnabled:NO];
        else
            [self.btn setEnabled:YES];
        
        [self.contentView addSubview:self.btn];
        
        if ([appDelegate isIpad]) {
            
            UIPickerView *p = [[UIPickerView alloc] initWithFrame: CGRectMake(0, 0, 320, 216)];
            p.autoresizingMask = UIViewAutoresizingNone;
            [p setDelegate:self];
            [p setDataSource:self];
            [p selectRow:0 inComponent:0 animated:NO];
            [p setShowsSelectionIndicator:YES];
            self.pickerView = p;
            [p release];
            
            self.actionSheet = nil;
            PickerViewController *pv = [[PickerViewController alloc] initWithPickerCell:self];
            UINavigationController *navbar = [[UINavigationController alloc] initWithRootViewController:pv];
            UIPopoverController * pop = [[UIPopoverController alloc] initWithContentViewController:navbar];
            self.popover = pop;
            [pop release];
            [navbar release];
            [pv release];
            
        } else {
            
            UIPickerView *p = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 45, 320, 216)];
            [p setDelegate:self];
            [p setDataSource:self];
            [p selectRow:0 inComponent:0 animated:NO];
            [p setShowsSelectionIndicator:YES];
            self.pickerView = p;
            [p release];
            
            self.popover = nil;
            UIActionSheet *a = [[UIActionSheet alloc] initWithTitle:@"Choose" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
            [a setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
            [a addSubview:self.pickerView];
            self.actionSheet = a;
            [a release];
            
            [self.actionSheet addSubview:[self createToolbar]];
        }

    }
    
    return self;
}


-(void)showPicker 
{
    //Mostriamo nella view principale
    RepWalletAppDelegate *appDelegate = (RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate];

    float actSheetWidth, actSheetHeight;
    if ([appDelegate isIpad]) {
       
        [self openPopover];
        
    } else {
        
        actSheetHeight = 485;
        actSheetWidth = [[self viewController] view].bounds.size.width;
        [self.actionSheet showFromTabBar:appDelegate.tabBarController.tabBar];
        [self.actionSheet setBounds:CGRectMake(0, 0, actSheetWidth, actSheetHeight)];
        [self.pickerView setFrame:CGRectMake(
                                             floorf((self.actionSheet.frame.size.width - self.pickerView.frame.size.width) / 2.0),
                                             self.pickerView.frame.origin.y,
                                             self.pickerView.frame.size.width,
                                             self.pickerView.frame.size.height)];
    }
    
}

-(void)reloadPicker 
{
    [self.pickerView reloadAllComponents];
    
    if([self.dataSourceArray count] == 0)
        [self.btn setEnabled:NO];
    else
        [self.btn setEnabled:YES];
}

- (void)layoutSubviews 
{
	[super layoutSubviews];
    
    CGRect rect =  CGRectZero;
    
    float btnWidth;
    float btnHeight, internalBtnHeight;
    float rightPadding, underlinePadding;
    float sepRowHeight, btnPadding, trickOrTreat;
    
    if ([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad]) {
        underlinePadding = IPAD_UNDERLINE_PADDING;
        rightPadding = IPAD_RIGHT_PADDING;
        btnHeight = IPAD_CHOOSE_BTN_HEIGHT;
        btnWidth = IPAD_CHOOSE_BTN_WIDTH;
        internalBtnHeight = IPAD_CHOOSE_BTN_INTERNAL_HEIGHT;
        sepRowHeight = IPAD_SEPARATOR_ROW_HEIGHT;
        btnPadding = IPAD_BTN_BOTTOM_PADDING;
        trickOrTreat = 0;
    } else {
        underlinePadding = UNDERLINE_PADDING;
        rightPadding = RIGHT_PADDING;
        btnHeight = CHOOSE_BTN_HEIGHT;
        btnWidth = CHOOSE_BTN_WIDTH;
        internalBtnHeight = CHOOSE_BTN_INTERNAL_HEIGHT;
        sepRowHeight = SEPARATOR_ROW_HEIGHT;
        btnPadding = BTN_BOTTOM_PADDING;
        trickOrTreat = 0;
    }
	// Rect area del btnbox
    if (self.enabledCell && [self.btn backgroundImageForState:UIControlStateNormal] == nil) {
        
        if (!_isAddEditCell) {
            
            rect = CGRectMake(self.textLabel.frame.origin.x 
                              + self.textLabel.frame.size.width  
                              + 1.0 * self.indentationWidth, 
                              self.contentView.frame.origin.y 
                              + roundf(0.5 * (self.contentView.frame.size.height 
                                              - btnHeight))
                              , 
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
                              + roundf(- 0.5 * btnHeight - 0.5 * internalBtnHeight)
                              - btnPadding - trickOrTreat
                              ,
                              btnWidth, 
                              btnHeight);
            
        } else {
            
            rect = CGRectMake(self.textLabel.frame.origin.x 
                              + self.textLabel.frame.size.width  
                              + 1.0 * self.indentationWidth, 
                              self.contentView.center.y 
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
    
    if (!_isAddEditCell && self.addedUnderline) {
        
        [self.underline setFrame:CGRectMake(self.btn.frame.origin.x, 
                                            self.contentView.frame.origin.y
                                            + self.contentView.frame.size.height
                                            - underlinePadding, 
                                            self.btn.frame.size.width, 
                                            1
                                            )];
    }
}

-(void)setEnabled:(BOOL)enabled 
{    
    if (!enabled) {
        
        [self.btn setTitle:nil forState:UIControlStateNormal];
        [self.underline setBackgroundColor:[UIColor grayColor]];
        
    } else {
        
        [self.underline setBackgroundColor:[UIColor blackColor]];
    }
    
    [self.btn setEnabled:enabled];
    
    [super setEnabled:enabled];
}

- (void)dealloc 
{
    [self.popover release];
    [self.underline release];
    [self.dataSourceArray release];
    [self.btn release];
    [self.pickerView release];
    [self.actionSheet release];
    [super dealloc];
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) { // OK
        [self setControlValue:[self.dataSourceArray objectAtIndex:[self.pickerView selectedRowInComponent:0]]];
        [self postEndEditingNotification];
    } else if (buttonIndex == 1) { // CANCEL
        ;
    } 
}


@end
