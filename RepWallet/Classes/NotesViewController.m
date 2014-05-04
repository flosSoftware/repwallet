//
//  NotesViewController.m
//  repWallet
//
//  Created by Alberto Fiore on 11/15/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "NotesViewController.h"
#import "NotesCell.h"

@implementation NotesViewController

@synthesize t, nn;

# pragma mark - Change orientation

- (NSUInteger)supportedInterfaceOrientations
{
    return (1 << UIInterfaceOrientationPortrait) | (1 << UIInterfaceOrientationPortraitUpsideDown) | (1 << UIInterfaceOrientationLandscapeLeft) | (1 << UIInterfaceOrientationLandscapeRight);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return ((orientation == UIInterfaceOrientationPortrait) ||
            (orientation == UIInterfaceOrientationPortraitUpsideDown) ||
            (orientation == UIInterfaceOrientationLandscapeLeft) ||
            (orientation == UIInterfaceOrientationLandscapeRight));
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    
}

-(void)okBtnPressed {
    
    [self.nn setControlValue:self.t.text];
    
    [self.nn postEndEditingNotification];
    
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else if ([self respondsToSelector:@selector(dismissModalViewControllerAnimated:)]) {
        [self dismissModalViewControllerAnimated:YES];
    } 
    
}

-(void)cancelBtnPressed {
    if ([self.nn getControlValue]) {
        self.t.text = [self.nn getControlValue];
    } else
        self.t.text = @"";
    
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else if ([self respondsToSelector:@selector(dismissModalViewControllerAnimated:)]) {
        [self dismissModalViewControllerAnimated:YES];
    } 
}

- (id)initWithNotesCell:(NotesCell *)nn
{
    self = [super init];
    if (self) {
        // Custom initialization
        self.nn = nn;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.nn release];
    [self.t release];
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

- (void)loadView
{
    [super loadView];
    
    UIBarButtonItem *okButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(okBtnPressed)];
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelBtnPressed)];
    
    self.navigationItem.title = @"Take a note";
    
    [self.navigationItem setLeftBarButtonItem:cancelBtn animated:NO];
    [self.navigationItem setRightBarButtonItem:okButton animated:NO];
    
    [cancelBtn release];
    [okButton release];
    
}

- (void)keyboardWasShown:(NSNotification *)notification{
    
    NSDictionary* info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    float offset;
    if UIInterfaceOrientationIsPortrait(self.interfaceOrientation)
        offset = kbSize.height;
    else
        offset = kbSize.width; // WTF??
    
    [UIView animateWithDuration:0.5
                     animations:^{
                         CGRect frameTxtField = self.t.frame;
                         frameTxtField.size.height = self.view.bounds.size.height - offset;
                         self.t.frame = frameTxtField;
                     }
     ];
}

-(void)viewDidAppear:(BOOL)animated {
    [self.t becomeFirstResponder];
    [super viewDidAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated{
    [self.t resignFirstResponder];
    [super viewWillDisappear:animated];
}

-(void)viewDidLoad{
    
    [super viewDidLoad];
    
    float fontSize;
    if([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad]){
        fontSize = [UIFont labelFontSize] + 14;
    } else {
        fontSize = [UIFont labelFontSize];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];

    UITextView *tt = [[UITextView alloc] initWithFrame:self.view.bounds];
    tt.textAlignment = UITextAlignmentLeft;
    tt.returnKeyType = UIReturnKeyDefault;
    tt.font = [UIFont systemFontOfSize:fontSize];		
    tt.autocorrectionType = UITextAutocorrectionTypeNo;
    tt.autocapitalizationType = UITextAutocapitalizationTypeNone;
    tt.clipsToBounds = NO;
    tt.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    if ([self.nn getControlValue]) {
        tt.text = [self.nn getControlValue];
    } else
        tt.text = @"";
    self.t = tt;
    [tt release];
    
    [self.view addSubview:self.t];
    
}

- (void)viewDidUnload
{
    self.t = nil;
    [super viewDidUnload];
}

@end
