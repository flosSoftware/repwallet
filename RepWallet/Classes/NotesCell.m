//
//  NotesCell.m
//  repWallet
//
//  Created by Alberto Fiore on 11/15/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "NotesCell.h"
#import <QuartzCore/QuartzCore.h>
#import "DatePickerCell.h"
#import "AddEditViewController.h"

@implementation NotesCell

@synthesize textValue;
@synthesize btn;
@synthesize notes;


-(void)showNotes {
    
    // Add create and configure the navigation controller.
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.notes];
    UIColor * c = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    navigationController.navigationBar.tintColor = c;
    UIViewController *vc = [self viewController];
    
    if ([vc respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        
        [vc presentViewController:navigationController animated:YES completion:NULL];
        
    } else if([vc respondsToSelector:@selector(presentModalViewController:animated:)]) {
        
        [vc presentModalViewController:navigationController animated:YES];
        
    }
    
    [navigationController release];
    
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier boundClassName:boundClassName dataKey:dataKey label:label]) {
        
        // Configuro il btn
        
        UIButton *b = [[UIButton alloc] initWithFrame:CGRectZero];
        b.backgroundColor = [UIColor clearColor];
        b.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [b setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [b setBackgroundImage:[UIImage imageNamed:@"write.png"] forState:UIControlStateNormal];
        [b setBackgroundImage:[UIImage imageNamed:@"writeDisabled.png"] forState:UIControlStateDisabled];
        [b addTarget:self action:@selector(showNotes) forControlEvents:UIControlEventTouchUpInside];
        self.btn = b;
        [b release];
        [self.contentView addSubview:self.btn];
        self.textValue = nil;
        
        NotesViewController * n = [[NotesViewController alloc] initWithNotesCell:self];
        n.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        n.modalPresentationStyle = UIModalPresentationFormSheet;
        self.notes = n;
        [n release];
    }
    
    return self;
}

- (void)layoutSubviews {
    
	[super layoutSubviews];
	CGRect rect =  CGRectZero;
    
    float btnWidth;
    float btnHeight, internalBtnHeight;
    float sepRowHeight, btnPadding;

    if ([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate]  isIpad]) {

        btnHeight = IPAD_WRITE_BTN_HEIGHT;
        btnWidth = IPAD_WRITE_BTN_WIDTH;
        internalBtnHeight = IPAD_WRITE_BTN_INTERNAL_HEIGHT;
        sepRowHeight = IPAD_SEPARATOR_ROW_HEIGHT;
        btnPadding = IPAD_BTN_BOTTOM_PADDING;
    } else {

        btnHeight = WRITE_BTN_HEIGHT;
        btnWidth = WRITE_BTN_WIDTH;
        internalBtnHeight = WRITE_BTN_INTERNAL_HEIGHT;
        sepRowHeight = SEPARATOR_ROW_HEIGHT;
        btnPadding = BTN_BOTTOM_PADDING;
    }
    
	// Rect area del btnbox
    if ([self.btn backgroundImageForState:UIControlStateNormal] == nil) {
        ;
    } else {
        
        if (!_isAddEditCell) {
            rect = CGRectMake(self.textLabel.frame.origin.x 
                              + self.textLabel.frame.size.width  
                              + 1.0 * self.indentationWidth, 
                              self.textLabel.frame.origin.y
                              + self.textLabel.frame.size.height
                              - roundf((0.5 * (btnHeight - internalBtnHeight)) + internalBtnHeight)
                              - btnPadding, 
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
}

-(void) setControlValue:(id)value
{ 
    if(value) {
        NSString * trimmedValue = [(NSString *) value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if ([trimmedValue length] == 0) {
            
            self.textValue = nil;
            
        } else {
            
            self.textValue = value;
            
        }
    } else {

        self.textValue = nil;
    }
}

-(id) getControlValue
{
	return self.textValue;
}

-(void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    [self.btn setEnabled:enabled];
}

- (void)dealloc 
{
    [self.notes release];
    [self.btn release];
    [super dealloc];
}




@end