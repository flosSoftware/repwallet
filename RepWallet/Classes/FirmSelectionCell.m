//
//  FirmSelectionCell.m
//  repWallet
//
//  Created by Alberto Fiore on 2/7/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "FirmSelectionCell.h"
#import "AddEditViewController.h"
#import "FirmViewController.h"

@implementation FirmSelectionCell

@synthesize dao;
@synthesize firm;
@synthesize firmSelectionVC;

- (void) changedFirms:(NSNotification *)noti {
    
    int count = [self.dao countEntitiesOfType:NSStringFromClass([Firm class])];
    
    if(count == 0)
        [self setEnabled:NO];
    else
        [self setEnabled:YES];
    
    if ([self.btn backgroundImageForState:UIControlStateNormal] == nil && [noti userInfo]) {

        NSString *newTitle = [[noti userInfo] objectForKey:@"newTitle"];
        [self.btn setTitle:newTitle forState:UIControlStateNormal];
    }
    
}

- (void) firmSelectionViewControllerSelectedFirm:(Firm *)firm {
    
    [self setControlValue:firm];
    [self postEndEditingNotification];
}


- (void) show {
    
    FirmSelectionViewController *mainViewController = [[FirmSelectionViewController alloc] initWithStyle:UITableViewStylePlain andDao:self.dao];
    self.firmSelectionVC = mainViewController;
    [mainViewController release];
	self.firmSelectionVC.title = @"Customers";
    self.firmSelectionVC.delegate = self;
    self.firmSelectionVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    self.firmSelectionVC.modalPresentationStyle = UIModalPresentationFormSheet;
    
	// Add create and configure the navigation controller.
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.firmSelectionVC];
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

- (id) initWithStyle:(UITableViewCellStyle)style dao:(DAO *)aDao reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)aClassName dataKey:(NSString *)aDataKey label:(NSString *)aLabel
{
        
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier boundClassName:aClassName dataKey:aDataKey label:aLabel]) {	
        
        self.dao = aDao;
        
        self.firm = nil;
        
        int count = [self.dao countEntitiesOfType:NSStringFromClass([Firm class])];
        
        if(count == 0)
            [self setEnabled:NO];
        else
            [self setEnabled:YES];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(changedFirms:)
         name:ADDED_OR_EDITED_FIRM_NOTIFICATION
         object:nil];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(changedFirms:)
         name:REMOVED_FIRM_NOTIFICATION
         object:nil];
        
    }
    
    return self;
}

-(void) setControlValue:(id)value
{
    if (value) {
        self.firm = (Firm *)value;
        [self.btn setBackgroundImage:nil forState:UIControlStateNormal];
        [self.btn setTitle:self.firm.firmName forState:UIControlStateNormal];
    } else {
        self.firm = nil;
        [self.btn setBackgroundImage:[UIImage imageNamed:@"chooseElement.png"] forState:UIControlStateNormal];
        [self.underline removeFromSuperview];
        self.underline = nil;
        self.addedUnderline = NO;
        [self.btn setTitle:nil forState:UIControlStateNormal];
    }
    
    [self layoutSubviews];
	
}

-(id) getControlValue
{
    return self.firm;
}

-(void)layoutSubviews {
    
    [super layoutSubviews];
    
    if (!_isAddEditCell && [self getControlValue] != nil && !self.addedUnderline) {
        
        self.addedUnderline = YES;
        
        // aggiungo la riga sotto
        
        float underlinePadding;
        
        if ([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad]) {
            underlinePadding = IPAD_UNDERLINE_PADDING;

        } else {
            underlinePadding = UNDERLINE_PADDING;

        }
        
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
    }
}

-(void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    
    [self layoutSubviews];
}

- (void)dealloc 
{
    if (self.firmSelectionVC) {
        self.firmSelectionVC.delegate = nil;
    }
    
    [self.firmSelectionVC release];
    [self.firm release];
    [self.dao release];
    [super dealloc];
}

@end
