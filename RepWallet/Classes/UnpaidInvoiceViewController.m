//
//  UnpaidInvoiceViewController.m
//  repWallet
//
//  Created by Alberto Fiore on 12/11/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//

#import "UnpaidInvoiceViewController.h"
#import "AddEditViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "RepWalletAppDelegate.h"
#import "UIViewController+CustomDrawing.h"
#import "Firm.h"
#import "UnpaidInvoice.h"
#import "UnpaidForFirmViewController.h"
#import "FirmViewController.h"

@implementation UnpaidInvoiceViewController

@synthesize dao;
@synthesize tableView;
@synthesize tableViewStyle;
@synthesize isFiltered;
@synthesize fetchedResultsController;
@synthesize searchTxt;
@synthesize searchBar;
@synthesize filteredFetchedResultsController;

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
    
    int rowHeight;
    
    if ([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad]) {
        rowHeight = 179;
    } else
        rowHeight = 98;
    
    [self customizeTableViewDrawingWithHeader:nil headerBg:nil footer:nil footerBg:nil background:nil backgroundColor:nil rowHeight:rowHeight headerHeight:10 footerHeight:0 forTableView:self.tableView deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(toInterfaceOrientation)];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    [self.tableView reloadData];
    
}


#pragma mark -
#pragma mark Actions


- (void)showAddForm 
{
    UnpaidInvoice *unp = [(UnpaidInvoice *)[[NSManagedObject alloc] initWithEntity:[self.dao getEntityDescriptionForName:NSStringFromClass([UnpaidInvoice class])] insertIntoManagedObjectContext:nil] autorelease];
    [unp setInsertDate:[NSDate date]];
    AddEditViewController * formViewController = [[AddEditViewController alloc] initWithStyle:UITableViewStylePlain title:ADDEDITVIEWCONTROLLER_INSERT_MODE_TITLE entity:unp andDao:self.dao addAnotherOne:addAnotherUnpaid];
    [self.navigationController pushViewController:formViewController animated:YES];
    [formViewController release];
}

- (void)showUnpaidsForFirm:(Firm *) selectedFirm 
{
    UnpaidForFirmViewController *viewController = [[UnpaidForFirmViewController alloc] initWithStyle:UITableViewStylePlain firm:selectedFirm andDao:self.dao];
    viewController.title = [NSString stringWithFormat:@"Unpaid Invoices - %@", selectedFirm.firmName];
    [self.navigationController pushViewController:viewController animated:YES];
    [viewController release];
}

#pragma mark -
#pragma mark Initialization

- (id)initWithStyle:(UITableViewStyle)style andDao:(DAO *)aDao
{
    self = [super init];
    
    if (self) {
        
        [self disableAnotherUnpaidInsertion];
        
        shouldBeginEditing = YES;
        
        self.dao = aDao;
        self.tableViewStyle = style;
        
        UITabBarItem * item = [[UITabBarItem alloc] initWithTitle:@"Unpaids" image:[UIImage imageNamed:@"unpaids.png"] tag:0];
        self.tabBarItem = item;
        [item release];
        
        [[NSNotificationCenter defaultCenter] 
         addObserver:self 
         selector:@selector(reloadTable) 
         name:REMOVED_UNPAID_NOTIFICATION 
         object:nil];
        
        [[NSNotificationCenter defaultCenter] 
         addObserver:self selector:@selector(getToRootView) 
         name:REMOVED_FIRM_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] 
         addObserver:self 
         selector:@selector(enableAnotherUnpaidInsertion) 
         name:ENABLE_INSERTION_OF_ANOTHER_UNPAID_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] 
         addObserver:self 
         selector:@selector(disableAnotherUnpaidInsertion) 
         name:DISABLE_INSERTION_OF_ANOTHER_UNPAID_NOTIFICATION object:nil];
        
        viewDidDisappear = NO;
    }
    
    return self;
}


#pragma mark -
#pragma mark View lifecycle

- (void) loadFilteredData:(NSString *)text {
    
    if(!self.filteredFetchedResultsController)
        return;
    
    [self.filteredFetchedResultsController.fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"unpaidInvs.@count > 0 AND firmName CONTAINS[cd] %@", text]];
    
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
    [NSFetchedResultsController deleteCacheWithName:@"FirmsWithUnpaids"];
    
    NSError *error;
    
	if (
        self.fetchedResultsController 
        && ![self.fetchedResultsController performFetch:&error]) {
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

    if (self.tableView) {
        [self.tableView reloadData];
    }
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.fetchedResultsController = [self.dao fetchedResultsControllerForEntityType:NSStringFromClass([Firm class]) withDelegate:self cacheName:@"FirmsWithUnpaids"];
    
    [self.fetchedResultsController.fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"unpaidInvs.@count > 0"]];
    
    self.filteredFetchedResultsController = [self.dao fetchedResultsControllerForEntityType:NSStringFromClass([Firm class]) withDelegate:self cacheName:nil];
    
    RepWalletAppDelegate *app = (RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    UISearchBar * sb = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 
                                                                     0, 
                                                                     self.view.bounds.size.width, 
                                                                     44)];
    self.searchBar = sb;
    [sb release];
    [self.searchBar setShowsCancelButton:YES animated:YES];
    self.searchBar.tintColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    self.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    self.searchBar.delegate = self;
    
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
    
    int rowHeight;
    
    if ([app isIpad]) {
        rowHeight = 179;
    } else
        rowHeight = 98;
    
    [self customizeTableViewDrawingWithHeader:nil headerBg:nil footer:nil footerBg:nil background:nil backgroundColor:nil rowHeight:rowHeight headerHeight:10 footerHeight:0 forTableView:self.tableView deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
    
    // create a standard "add" button
    UIBarButtonItem * addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showAddForm)]; 
    addButton.style = UIBarButtonItemStyleBordered;
    
    self.navigationItem.rightBarButtonItem = addButton;
    
    [addButton release];
    
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

- (void)viewDidAppear:(BOOL)animated 
{    
    [super viewDidAppear:animated];
    
    if (addAnotherUnpaid == YES) {
        [self showAddForm];
    } else {
        if (!([self.dao countEntitiesOfType:NSStringFromClass([Firm class])] > 0)) {
            [self.navigationItem.rightBarButtonItem setEnabled:FALSE];
        } else
            [self.navigationItem.rightBarButtonItem setEnabled:TRUE];
    }
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    if (viewDidDisappear
        && self.interfaceOrientation != lastOrientation) {
        
        int rowHeight;
        
        if ([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad]) {
            rowHeight = 179;
        } else
            rowHeight = 98;
        
        [self customizeTableViewDrawingWithHeader:nil headerBg:nil footer:nil footerBg:nil background:nil backgroundColor:nil rowHeight:rowHeight headerHeight:10 footerHeight:0 forTableView:self.tableView deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
        
        [self.tableView reloadData];
        
    }
}

-(void)viewDidDisappear:(BOOL)animated {
    
    viewDidDisappear = YES;
    
    [super viewDidDisappear:animated];
}

- (void) getToRootView 
{
    [self.navigationController popToRootViewControllerAnimated:NO];
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
    
    NSDate *date = firm.insertDate;
    
    if(date != nil) {
        
        NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
        
        NSDateComponents *components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
                                                   fromDate:date
                                                     toDate:[NSDate date]
                                                    options:0];
        
        float rowWithoutShadowHeight;
        
        if([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad]){
            cell.indentationWidth = 20.0f;
            rowWithoutShadowHeight = 165.34f;
        } else
            rowWithoutShadowHeight = 92.87f;
        
        NSString *firmName = nil;
        
        if(![firm firmName] 
           || [[[firm firmName] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) 
        {
            firmName = @"<no name>";
        } else {
            firmName = [firm firmName];
        }
        
        NSString *firmAddress = nil;
        
        if(![firm street] 
           || [[[firm street] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) 
        {
            firmAddress = @"<no street>";
        } else {
            firmAddress = [firm street];
        }
        
        NSString *firmTown = nil;
        
        if(![firm town] 
           || [[[firm town] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) 
        {
            firmTown = @"<no town>";
        } else {
            firmTown = [firm town];
        }
        
        if([components day] < 7) {
            
            [self customizeDrawingForCell:cell atIndexPath:indexPath dequeued:dequeued topText:firmName bottomText:firmAddress subBottomText:firmTown subSubBottomText:nil showImage:YES imageName:@"chili" forTableView:self.tableView rowWithoutShadowHeight:rowWithoutShadowHeight deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
        } else {
            
            [self customizeDrawingForCell:cell atIndexPath:indexPath dequeued:dequeued topText:firmName bottomText:firmAddress subBottomText:firmTown subSubBottomText:nil showImage:YES imageName:@"icecube" forTableView:self.tableView rowWithoutShadowHeight:rowWithoutShadowHeight deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    BOOL dequeued = NO;
    
    if (cell == nil) {
        
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        
//        dequeued = NO;
        
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    Firm *firm = nil;
    
    if (!self.isFiltered) {
        firm = [self.fetchedResultsController objectAtIndexPath:indexPath];
    } else {
        firm = [self.filteredFetchedResultsController objectAtIndexPath:indexPath];
    }
    
    if(firm)
        [self showUnpaidsForFirm:firm];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
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
            
            [[NSNotificationCenter defaultCenter] 
             postNotificationName:REMOVED_FIRM_NOTIFICATION 
             object:nil 
             ];
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

#pragma mark -
#pragma mark Automatic Insertion Form Reloading

- (void)enableAnotherUnpaidInsertion
{
	addAnotherUnpaid = YES;
}

- (void)disableAnotherUnpaidInsertion
{
	addAnotherUnpaid = NO;
}


@end

