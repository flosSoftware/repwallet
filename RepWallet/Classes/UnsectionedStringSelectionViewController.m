//
//  UnsectionedStringSelectionViewController.m
//  repWallet
//
//  Created by Alberto Fiore on 3/13/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "UnsectionedStringSelectionViewController.h"


@implementation UnsectionedStringSelectionViewController

@synthesize tableView;
@synthesize tableViewStyle;
@synthesize isFiltered;
@synthesize searchTxt;
@synthesize searchBar;
@synthesize dataSource;
@synthesize delegate;
@synthesize filteredDataSource;


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

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    [self.tableView reloadData];
}


#pragma mark -
#pragma mark Initialization

- (id)initWithStyle:(UITableViewStyle)style andDatasource:(NSArray *)aDatasourceArray
{
    self = [super init];
    
    if (self) {
        
        shouldBeginEditing = YES;
        
        self.dataSource = aDatasourceArray;
        self.tableViewStyle = style;
        
    }
    
    return self;
}


#pragma mark -
#pragma mark View lifecycle

- (void) updateFilteredData:(NSString *)text {
    
    [self.filteredDataSource removeAllObjects];
    
    for (NSString *s in self.dataSource) {

        NSRange textRange;
        textRange = [s rangeOfString:text options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)];
        
        if(textRange.location != NSNotFound && [text isEqualToString:s])
        {
            [self.filteredDataSource addObject:s];
        }
        else if(textRange.location != NSNotFound)
        {
            [self.filteredDataSource addObject:s];
        }

    }
}

-(void)reloadTable
{
    if (self.isFiltered) {
        [self updateFilteredData:self.searchTxt];
    }
    
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UISearchBar * sb = [[UISearchBar alloc] initWithFrame:CGRectMake(0,
                                                                     0,
                                                                     self.view.bounds.size.width,
                                                                     44)];
    
    self.searchBar = sb;
    
    [sb release];
    
    [self.searchBar setShowsCancelButton:YES animated:YES];
    self.searchBar.tintColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    self.searchBar.delegate = self;
    
    self.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    
    [self.view addSubview:self.searchBar];
    
    UITableView * tb = [[UITableView alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x,
                                                                     self.view.bounds.origin.y
                                                                     + self.searchBar.frame.size.height,
                                                                     self.view.bounds.size.width,
                                                                     self.view.bounds.size.height
                                                                     - self.searchBar.frame.size.height)
                                                    style:self.tableViewStyle];
    
    self.tableView = tb;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth
    | UIViewAutoresizingFlexibleHeight
    | UIViewAutoresizingFlexibleRightMargin
    | UIViewAutoresizingFlexibleBottomMargin;
    
    [self.view addSubview:self.tableView];
    
    UIBarButtonItem * cButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissModalViewControllerAnimated:)];
    cButton.style = UIBarButtonItemStyleBordered;
    
    self.navigationItem.rightBarButtonItem = cButton;
    
    [cButton release];
    
    [tb release];
    
    self.filteredDataSource = [NSMutableArray arrayWithCapacity:[self.dataSource count]];
    
    if (self.searchTxt && [self.searchTxt length] != 0) {
        
        [self.searchBar setText:self.searchTxt];
        self.isFiltered = YES;
        [self updateFilteredData:self.searchTxt];
        [self.searchBar becomeFirstResponder];
        
    } else {
        
        self.isFiltered = NO;
    }
    
}

- (void)viewDidUnload
{
    if (self.searchBar) {
        self.searchBar.delegate = nil;
    }
    
    if (self.tableView) {
        self.tableView.delegate = nil;
    }
    
    self.searchTxt = [self.searchBar text];
    self.searchBar = nil;
    self.filteredDataSource = nil;
    self.tableView = nil;
    
    [super viewDidUnload];
}


#pragma mark -
#pragma mark Search bar data source

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    
    [searchBar resignFirstResponder];
}

-(void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)text
{
    self.searchTxt = text;
    
    if(![searchBar isFirstResponder]) {
        // user tapped the 'clear' button
        shouldBeginEditing = NO;
        // do whatever I want to happen when the user clears the search...
    }
    
    if(text.length == 0) {
        
        self.isFiltered = NO;
        
    } else {
        
        self.isFiltered = YES;
        
        [self updateFilteredData:self.searchTxt];
    }
    
    [self.tableView reloadData];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)bar {
    // reset the shouldBeginEditing BOOL ivar to YES, but first take its value and use it to return it from the method call
    BOOL boolToReturn = shouldBeginEditing;
    shouldBeginEditing = YES;
    return boolToReturn;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int rowCount;
    
    if(self.isFiltered)
        rowCount = self.filteredDataSource.count;
    else
        rowCount = self.dataSource.count;
    
    return rowCount;
}


- (void)configureCell:(UITableViewCell *)cell dequeued:(BOOL)dequeued atIndexPath:(NSIndexPath *)indexPath {
    
    NSString * s = nil;
    
    if (!self.isFiltered) {
        s = [self.dataSource objectAtIndex:indexPath.row];
    } else {
        s = [self.filteredDataSource objectAtIndex:indexPath.row];
    }
    
    cell.textLabel.text = s;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    BOOL dequeued = YES;
    
    if (cell == nil) {
        
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        
        dequeued = NO;
        
    }
    
    [self configureCell:cell dequeued:dequeued atIndexPath:indexPath];
    
    return cell;
}

- (void)setEditing:(BOOL)isEditing animated:(BOOL)animated
{
    [super setEditing:isEditing animated:animated];
    [self.tableView setEditing:isEditing animated:animated];
}


#pragma mark -
#pragma mark Table view delegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(unsectionedStringSelectionViewControllerSelectedString:)]) {
        [self.delegate unsectionedStringSelectionViewControllerSelectedString:cell.textLabel.text];
    }
    
    [self dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Memory management

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

- (void)dealloc
{
    if (self.searchBar) {
        self.searchBar.delegate = nil;
    }
    
    if (self.tableView) {
        self.tableView.delegate = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.searchBar release];
    [self.searchTxt release];
    [self.dataSource release];
    [self.filteredDataSource release];
    [self.tableView release];
    [super dealloc];
}

@end
