//
//  FirmSelectionViewController.m
//  repWallet
//
//  Created by Alberto Fiore on 11/02/11.
//  Copyright 2011 Alberto Fiore. All rights reserved.
//
#import "FirmSelectionViewController.h"
#import "Firm.h"
#import <QuartzCore/QuartzCore.h>
#import "RepWalletAppDelegate.h"
#import "NSObject+CheckConnectivity.h"

@implementation FirmSelectionViewController

@synthesize dao;
@synthesize tableView;
@synthesize tableViewStyle;
@synthesize isFiltered;
@synthesize fetchedResultsController;
@synthesize searchTxt;
@synthesize searchBar;
@synthesize filteredFetchedResultsController;
@synthesize delegate;

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

- (id)initWithStyle:(UITableViewStyle)style andDao:(DAO *)aDao
{
    self = [super init];
    
    if (self) {
        
        shouldBeginEditing = YES;
        
        self.dao = aDao;
        self.tableViewStyle = style;
        
    }
    
    return self;
}


#pragma mark -
#pragma mark View lifecycle

- (void) loadFilteredData:(NSString *)text {
    
    [self.filteredFetchedResultsController.fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"firmName CONTAINS[cd] %@", text]];
    
    NSError *error;
	if (![self.filteredFetchedResultsController performFetch:&error]) {
		// Update to handle the error appropriately.
        NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while retrieving the application data. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
	}
}

- (void) loadData 
{
    [NSFetchedResultsController deleteCacheWithName:@"FirmsForPicker"];
    NSError *error;
	if (![self.fetchedResultsController performFetch:&error]) {
		// Update to handle the error appropriately.
        NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while retrieving the application data. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
	}
}

-(void)reloadTable 
{
    if (self.isFiltered) {
        [self loadFilteredData:self.searchTxt];
    } else
        [self loadData];
    
    [self.tableView reloadData];
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.fetchedResultsController = [self.dao fetchedResultsControllerForEntityType:NSStringFromClass([Firm class]) withDelegate:self cacheName:@"FirmsForPicker"];
    
    self.filteredFetchedResultsController = [self.dao fetchedResultsControllerForEntityType:NSStringFromClass([Firm class]) withDelegate:self cacheName:nil];
    
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
    
    if (self.searchTxt && [self.searchTxt length] != 0) {
        
        [self.searchBar setText:self.searchTxt];
        self.isFiltered = YES;
        [self loadFilteredData:self.searchTxt];
        [self.searchBar becomeFirstResponder];
        
    } else {
        
        self.isFiltered = NO;
        [self loadData];
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
    
    self.fetchedResultsController = nil;
    self.filteredFetchedResultsController = nil;
    
    self.tableView = nil;
    
    [super viewDidUnload];
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];

}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
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
        
        [self loadFilteredData:self.searchTxt];
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
    
    if(self.isFiltered) {
        id  sectionInfo =
        [[self.filteredFetchedResultsController sections] objectAtIndex:section];
        rowCount = [sectionInfo numberOfObjects];
        
    } else {
        
        id  sectionInfo =
        [[self.fetchedResultsController sections] objectAtIndex:section];
        rowCount = [sectionInfo numberOfObjects];
    }
    
    return rowCount;
}

- (void)configureCell:(UITableViewCell *)cell dequeued:(BOOL)dequeued atIndexPath:(NSIndexPath *)indexPath {
    
    Firm *firm;
    
    if(self.isFiltered) {
        firm = [self.filteredFetchedResultsController objectAtIndexPath:indexPath];
    } else {
        firm = [self.fetchedResultsController objectAtIndexPath:indexPath];
    }
    
    NSString *firmName = ![firm firmName] ? @"<no name>" : [firm firmName];
    
    cell.textLabel.text = firmName;
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

- (void)setEditing:(BOOL)isEditing animated:(BOOL)animated {
    [super setEditing:isEditing animated:animated]; 
    [self.tableView setEditing:isEditing animated:animated];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath 
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        Firm *entityToDelete = nil;
        
        if (!self.isFiltered) {
            entityToDelete = [self.fetchedResultsController objectAtIndexPath:indexPath];
            [self.dao deleteEntity:entityToDelete];
        } else {
            entityToDelete = [self.filteredFetchedResultsController objectAtIndexPath:indexPath];
            [self.dao deleteEntity:entityToDelete];
        }
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}


#pragma mark -
#pragma mark Table view delegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    Firm *firm;
    
    if(self.isFiltered) {
        firm = [self.filteredFetchedResultsController objectAtIndexPath:indexPath];
    } else {
        firm = [self.fetchedResultsController objectAtIndexPath:indexPath];
    }

    
    if (self.delegate && [self.delegate respondsToSelector:@selector(firmSelectionViewControllerSelectedFirm:)]) {
        [self.delegate firmSelectionViewControllerSelectedFirm:firm];
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

#pragma mark - fetchedResultsController delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    
    BOOL isFilteredController = (controller.cacheName == nil);
    
    if (! (
           (isFilteredController && self.isFiltered) || 
           (!isFilteredController && !self.isFiltered) 
           )) {
        return;
    }
    
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    BOOL isFilteredController = (controller.cacheName == nil);
    
    if (! (
           (isFilteredController && self.isFiltered) || 
           (!isFilteredController && !self.isFiltered) 
           )) {
        return;
    }
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
        {
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
            break;
            
        case NSFetchedResultsChangeDelete:
        {
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            
            [self.dao saveContext];
            
        } 
            break;
            
        case NSFetchedResultsChangeUpdate:
        {
            //            [self reloadTable];
        }
            break;
            
        case NSFetchedResultsChangeMove:
        {
            [tableView deleteRowsAtIndexPaths:[NSArray
                                               arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray
                                               arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    BOOL isFilteredController = (controller.cacheName == nil);
    
    if (! (
           (isFilteredController && self.isFiltered) || 
           (!isFilteredController && !self.isFiltered) 
           )) {
        return;
    }
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    
    BOOL isFilteredController = (controller.cacheName == nil);
    
    if (! (
           (isFilteredController && self.isFiltered) || 
           (!isFilteredController && !self.isFiltered) 
           )) {
        return;
    }
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    
    [self.tableView endUpdates];
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
    [self.fetchedResultsController release];
    [self.filteredFetchedResultsController release];
    [self.tableView release];
    [self.dao release];
    [super dealloc];
}


@end

