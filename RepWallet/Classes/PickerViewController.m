//
//  PickerViewController.m
//  repWallet
//
//  Created by Alberto Fiore on 11/13/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "PickerViewController.h"


@implementation PickerViewController

@synthesize pickerCell;

-(void)okBtnPressed {
    [self.pickerCell.popover dismissPopoverAnimated:YES];
    [self.pickerCell actionSheet:nil didDismissWithButtonIndex:0];
}

-(void)cancelBtnPressed {
    [self.pickerCell.popover dismissPopoverAnimated:YES];
}

- (id)initWithPickerCell:(BasePickerCell *)pv
{
    self = [super init];
    if (self) {
        self.pickerCell = pv;
    }
    return self;
}

- (void)dealloc
{
    [self.pickerCell release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // only want to do this on iOS 6
    if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
        //  Don't want to rehydrate the view if it's already unloaded
        BOOL isLoaded = [self isViewLoaded];
        
        //  We check the window property to make sure that the view is not visible
        if (isLoaded && self.view.window == nil) {
            
            //  Give a chance to implementors to get model data from their views
            [self performSelectorOnMainThread:@selector(viewWillUnload)
                                   withObject:nil
                                waitUntilDone:YES];
            
            //  Detach it from its parent (in cases of view controller containment)
            [self.view removeFromSuperview];
            self.view = nil;    //  Clear out the view.  Goodbye!
            
            //  The view is now unloaded...now call viewDidUnload
            [self performSelectorOnMainThread:@selector(viewDidUnload)
                                   withObject:nil
                                waitUntilDone:YES];
        }
    }
}

#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    [super loadView];
    
    UIView * vw = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.pickerCell.pickerView.frame.size.width, self.pickerCell.pickerView.frame.size.height)];
    [vw addSubview:self.pickerCell.pickerView];
    
    self.view = vw;
    
    [vw release];
    
    self.contentSizeForViewInPopover = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
    
    UIBarButtonItem *okButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(okBtnPressed)];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelBtnPressed)];
    
    self.navigationItem.title = @"Set Value";
    
    [self.navigationItem setLeftBarButtonItem:cancelButton animated:NO];
    [self.navigationItem setRightBarButtonItem:okButton animated:NO];
    
    [cancelButton release];
    [okButton release];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}


@end
