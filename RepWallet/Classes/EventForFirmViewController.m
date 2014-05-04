//
//  EventForFirmViewController.m
//  repWallet
//
//  Created by Alberto Fiore on 12/12/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//


#import "EventForFirmViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "RepWalletAppDelegate.h"
#import "UIViewController+CustomDrawing.h"
#import "Event.h"
#import "FirmViewController.h"

static BOOL tabBarShouldBeHidden = NO;

@implementation EventForFirmViewController

@synthesize dao;
@synthesize tableView;
@synthesize tableViewStyle;
@synthesize isFiltered;
@synthesize fetchedResultsController;
@synthesize searchTxt;
@synthesize searchBar;
@synthesize filteredFetchedResultsController;
@synthesize firmForEvent;
@synthesize lastAcceleration;
@synthesize eventSearchVC;

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
#pragma mark Toolbar

- (void) showTabBar:(UITabBarController *) tabbarcontroller
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    float fHeight = screenRect.size.height - self.tabBarController.tabBar.frame.size.height;
    
    if(  UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) )
    {
        fHeight = screenRect.size.width - self.tabBarController.tabBar.frame.size.height;
    }
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.2];
    for(UIView *view in tabbarcontroller.view.subviews)
    {
        if([view isKindOfClass:[UITabBar class]])
        {
            [view setFrame:CGRectMake(view.frame.origin.x, fHeight, view.frame.size.width, view.frame.size.height)];
        }
        else
        {
            [view setFrame:CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, fHeight)];
        }
    }

    [UIView commitAnimations];
    
    tabBarShouldBeHidden = NO;
}

- (void) hideTabBar:(UITabBarController *) tabbarcontroller
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.2];
    float fHeight = screenRect.size.height;
    if(  UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) )
    {
        fHeight = screenRect.size.width;
    }
    
    for(UIView *view in tabbarcontroller.view.subviews)
    {
        if([view isKindOfClass:[UITabBar class]])
        {
            [view setFrame:CGRectMake(view.frame.origin.x, fHeight, view.frame.size.width, view.frame.size.height)];
        }
        else
        {
            [view setFrame:CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, fHeight)];
            view.backgroundColor = [UIColor blackColor];
        }
    }
    
    [UIView commitAnimations];
    
    tabBarShouldBeHidden = YES;
}

- (void) hideTabBar {
    
    [self hideTabBar:self.tabBarController];
}

- (void) showTabBar {
    
    [self showTabBar:self.tabBarController];
}

- (void) createToolbar {
    
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *item3 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"search"] style:UIBarButtonItemStylePlain target:self action:@selector(showSearch)];
    UIBarButtonItem *item4 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"hide"] style:UIBarButtonItemStylePlain target:self action:@selector(hideTabBar)];
    UIBarButtonItem *item5 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"show"] style:UIBarButtonItemStylePlain target:self action:@selector(showTabBar)];
    NSArray *items = [NSArray arrayWithObjects:item3, flexibleItem, item4, flexibleItem, item5, nil];
    
    [self setToolbarItems:items animated:YES];
    
    [flexibleItem release];
    
    [item3 release];
    [item4 release];
    [item5 release];
    
}

#pragma mark -
#pragma mark Actions

- (void) showSearch {
    
    EventSearchViewController * evsVC = [[EventSearchViewController alloc] initWithStyle:UITableViewStylePlain andDao:self.dao];
    self.eventSearchVC = evsVC;
    [evsVC release];
    self.eventSearchVC.title = @"Search";
    self.eventSearchVC.delegate = self;
    self.eventSearchVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    self.eventSearchVC.modalPresentationStyle = UIModalPresentationFormSheet;
    
	// Add create and configure the navigation controller.
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:evsVC];
    UIColor * c = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    navigationController.navigationBar.tintColor = c;
    
    if ([self respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        
        [self presentViewController:navigationController animated:YES completion:NULL];
        
    } else if([self respondsToSelector:@selector(presentModalViewController:animated:)]) {
        
        [self presentModalViewController:navigationController animated:YES];
        
    }
    
	[navigationController release]; 
}

- (void)showEditForm:(NSIndexPath *) indexPath 
{
    Event *evt;
    
    if(self.isFiltered) {
        evt = [self.filteredFetchedResultsController objectAtIndexPath:indexPath];
    } else {
        evt = [self.fetchedResultsController objectAtIndexPath:indexPath];
    }
    
    if([AddEditViewController isEditingEventWithID:[evt objectID]]) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"This event is already open for modification in another tab" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        
        return;
    }
    
    AddEditViewController * formViewController = [[AddEditViewController alloc] initWithStyle:UITableViewStylePlain title:ADDEDITVIEWCONTROLLER_EDIT_MODE_TITLE entity:evt andDao:self.dao];
    [self.navigationController pushViewController:formViewController animated:YES];
    [formViewController release];
}

- (void) changedFirms: (NSNotification *)noti 
{
    NSString *firmName = [self.title substringFromIndex:[@"Events - " length]];
    
    if (
        noti.userInfo
        &&
        [firmName isEqualToString:[noti.userInfo objectForKey:@"oldTitle"]]) {
        
        self.title = [NSString stringWithFormat:@"Events - %@", [noti.userInfo objectForKey:@"newTitle"]];
        
    }
}

#pragma mark -
#pragma mark Shake gesture

- (BOOL) accelerationIsShakingWithLastAcc:(UIAcceleration*)last currentAcc:(UIAcceleration *)current threshold:(double) threshold {
	double
    deltaX = fabs(last.x - current.x),
    deltaY = fabs(last.y - current.y),
    deltaZ = fabs(last.z - current.z);
    
	return
    (deltaX > threshold && deltaY > threshold) ||
    (deltaX > threshold && deltaZ > threshold) ||
    (deltaY > threshold && deltaZ > threshold);
}

- (void) accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    
	if (self.lastAcceleration) {
        
		if (!histeresisExcited && [self accelerationIsShakingWithLastAcc:self.lastAcceleration currentAcc:acceleration threshold:0.7]) {
            
			histeresisExcited = YES;
            
            [self showSearch];
            
		} else if (histeresisExcited && ![self accelerationIsShakingWithLastAcc:self.lastAcceleration currentAcc:acceleration threshold:0.2]) {
			histeresisExcited = NO;
		}
	}
    
	self.lastAcceleration = acceleration;
}

#pragma mark -
#pragma mark Initialization


- (id)initWithStyle:(UITableViewStyle)style firm:(Firm *)aFirm andDao:(DAO *)aDao
{
    self = [super init];
    
    if (self) {
        
        [self setFirmForEvent:aFirm];

        shouldBeginEditing = YES;
        
        self.dao = aDao;
        self.tableViewStyle = style;
        
        self.navigationController.toolbarHidden = NO;
        self.navigationController.toolbar.translucent = NO;
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(changedFirms:)
         name:ADDED_OR_EDITED_FIRM_NOTIFICATION
         object:nil];
        
        viewDidDisappear = NO;
        
    }
    
    return self;
}


#pragma mark -
#pragma mark View lifecycle

- (void) loadFilteredDataOfType:(NSString *)type result:(NSString *)result startDate:(NSDate *)startDate endDate:(NSDate *)endDate itemCategory:(ItemCategory *)itemCategory minDuration:(NSNumber *)minDuration maxDuration:(NSNumber *)maxDuration minValue:(NSNumber *)minValue maxValue:(NSNumber *)maxValue 
{
    if(!self.filteredFetchedResultsController)
        return;
    
    if (!startDate) {
        startDate = [NSDate distantPast];
    }
    
    if (!endDate) {
        endDate = [NSDate distantFuture];
    }
    
    NSMutableArray *subPredicates = [NSMutableArray array];
    
    NSPredicate *firmP = [NSPredicate predicateWithFormat:@"firm == %@", self.firmForEvent];
    [subPredicates addObject:firmP];
    
    if (type) {
        NSPredicate *typeP = [NSPredicate predicateWithFormat:@"subject == %@", type];
        [subPredicates addObject:typeP];
    }
    
    if (result) {
        NSPredicate *resultP = [NSPredicate predicateWithFormat:@"result == %@", result];
        [subPredicates addObject:resultP];
    }

    NSPredicate *fromDateP = [NSPredicate predicateWithFormat:@"date >= %@", startDate];
    [subPredicates addObject:fromDateP];

    NSPredicate *toDateP = [NSPredicate predicateWithFormat:@"date <= %@", endDate];
    [subPredicates addObject:toDateP];

    
    if (minDuration) {
        NSPredicate *minDurationP = [NSPredicate predicateWithFormat:@"duration >= %@", minDuration];
        [subPredicates addObject:minDurationP];
    }
    
    if (maxDuration) {
        NSPredicate *maxDurationP = [NSPredicate predicateWithFormat:@"duration <= %@", maxDuration];
        [subPredicates addObject:maxDurationP];
    }
    
    if (minValue) {
        NSPredicate *minValueP = [NSPredicate predicateWithFormat:
                                  @"((itemQuantity * itemPerUnitValue) + (taxRate/100) * (itemQuantity * itemPerUnitValue)) >= %@", minValue];
        [subPredicates addObject:minValueP];
    }
    
    if (maxValue) {
        NSPredicate *maxValueP = [NSPredicate predicateWithFormat:@"((itemQuantity * itemPerUnitValue) + (taxRate/100) * (itemQuantity * itemPerUnitValue)) <= %@", maxValue];
        [subPredicates addObject:maxValueP];
    }

    if (itemCategory) {
        NSPredicate *itemCategoryP = [NSPredicate predicateWithFormat:@"itemCategory == %@", itemCategory];
        [subPredicates addObject:itemCategoryP];
    } 
    
    [self.filteredFetchedResultsController.fetchRequest setPredicate:
     [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates]];
    
    
//    NSLog(@"fetchRequest predicate %@", self.filteredFetchedResultsController.fetchRequest.predicate);
    
    NSError *error;
	if (![self.filteredFetchedResultsController performFetch:&error]) {
		// Update to handle the error appropriately.
        NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while retrieving the application data. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
	}
}

- (void) loadFilteredData:(NSString *)text {
    
    if(!self.filteredFetchedResultsController)
        return;
    
    [self.filteredFetchedResultsController.fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"firm == %@ AND itemCategory.name CONTAINS[cd] %@", self.firmForEvent, text]];
    
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
    [NSFetchedResultsController deleteCacheWithName:@"EventsForFirm"];
    
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

-(void)loadView {
    
    [super loadView];
    [self createToolbar];
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.fetchedResultsController = [self.dao fetchedResultsControllerForEntityType:NSStringFromClass([Event class]) withDelegate:self cacheName:@"EventsForFirm"];
    
    [self.fetchedResultsController.fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"firm == %@", self.firmForEvent]];
    
    self.filteredFetchedResultsController = [self.dao fetchedResultsControllerForEntityType:NSStringFromClass([Event class]) withDelegate:self cacheName:nil];
    
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
                                                                     - self.searchBar.frame.size.height
                                                                     )
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
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
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
    
    if(self.eventSearchVC) {
        self.eventSearchVC.delegate = nil;
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
    
    [self.navigationController setToolbarHidden:NO animated:animated];
    
    if (tabBarShouldBeHidden) {
        [self hideTabBar];
    }
    
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

- (void) viewControllerWillBePopped {
    
    [self.navigationController setToolbarHidden:YES animated:YES];
}

-(void)viewWillDisappear:(BOOL)animated {
    
//    [UIAccelerometer sharedAccelerometer].delegate = nil;
    
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    if (viewControllers.count > 1 && [viewControllers objectAtIndex:viewControllers.count-2] == self) {
        // View is disappearing because a new view controller was pushed onto the stack
    } else if ([viewControllers indexOfObject:self] == NSNotFound) {
        // View is disappearing because it was popped from the stack
        [self viewControllerWillBePopped];
    }
    
    [super viewWillDisappear:animated];
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
#pragma mark Event search delegate

- (void) eventSearchControllerFilteredEventsOfType:(NSString *)type result:(NSString *)result startDate:(NSDate *)startDate endDate:(NSDate *)endDate itemCategory:(ItemCategory *)itemCategory minDuration:(NSNumber *)minDuration maxDuration:(NSNumber *)maxDuration minValue:(NSNumber *)minValue maxValue:(NSNumber *)maxValue
{
    if(!type 
       && !result
       && !startDate 
       && !endDate 
       && !itemCategory
       && !minDuration
       && !maxDuration
       && !minValue
       && !maxValue) {
        
        self.isFiltered = NO;
        
    } else {
        
        self.isFiltered = YES;
        
        [self loadFilteredDataOfType:type result:result startDate:startDate endDate:endDate itemCategory:itemCategory minDuration:minDuration maxDuration:maxDuration minValue:minValue maxValue:maxValue];
    }
    
    [self.tableView reloadData];
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

    RepWalletAppDelegate * appDelegate = (RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    Event *evt;
    
    if(self.isFiltered) {
        evt = [self.filteredFetchedResultsController objectAtIndexPath:indexPath];
    } else {
        evt = [self.fetchedResultsController objectAtIndexPath:indexPath];
    }
    
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init]; 
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle]; 
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init]; 
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle]; 
    [numberFormatter setMaximumFractionDigits:3];
    
    NSDate *date = evt.insertDate;
    
    if(date != nil) {
        
        NSCalendar *calendar = [NSCalendar currentCalendar];
        
        NSDateComponents *components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date toDate:[NSDate date] options:0];
        
        NSString * top = nil;
        NSString * bottom = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:[evt date]]];
        NSString * subBottom = [NSString stringWithFormat:@"Item: %@", evt.itemCategory.name];
        NSString * subSubBottom = nil;
        
        if ([[evt subject] isEqualToString:EVENT_SUBJECT_CONTACT]) {
            
            top = @"CONTACT"; 
            
            NSNumberFormatter * numberFormatter2 = [[NSNumberFormatter alloc] init];
            
            NSString *dursTR = [numberFormatter2 stringFromNumber:evt.duration];
            
            subSubBottom = [NSString stringWithFormat:@"Duration: %@",
                            dursTR ? [NSString stringWithFormat:@"%@ minutes", dursTR] : @"N/A"
                            ];
            
            [numberFormatter2 release];
            
        } else {
            
            top = [NSString stringWithFormat:@"%@ SALE", [evt result]];
            
            double netAmt = [[evt itemPerUnitValue] doubleValue]
            * [[evt itemQuantity] doubleValue];
            
            double taxes = netAmt * [[evt taxRate] doubleValue] / 100.0;
            
            subSubBottom = [NSString stringWithFormat:@"Value: %@",
                            [NSNumberFormatter localizedStringFromNumber:
                             [NSNumber numberWithDouble:netAmt+taxes]
                                                             numberStyle:NSNumberFormatterCurrencyStyle]];
        }
        
        float rowWithoutShadowHeight;
        
        if([appDelegate isIpad]){
            cell.indentationWidth = 20.0f;
            rowWithoutShadowHeight = 165.34f;
        } else
            rowWithoutShadowHeight = 92.87f;
        
        if([components day] < 7) {
            
            [self customizeDrawingForCell:cell atIndexPath:indexPath dequeued:dequeued topText:top bottomText:bottom subBottomText:subBottom subSubBottomText:subSubBottom showImage:YES imageName:@"chili" forTableView:self.tableView rowWithoutShadowHeight:rowWithoutShadowHeight deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
        } else {
            
            [self customizeDrawingForCell:cell atIndexPath:indexPath dequeued:dequeued topText:top bottomText:bottom subBottomText:subBottom subSubBottomText:subSubBottom showImage:YES imageName:@"icecube" forTableView:self.tableView rowWithoutShadowHeight:rowWithoutShadowHeight deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
        }
    }
    
    [numberFormatter release];
    [dateFormatter release];
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
        
        Event *entityToDelete = nil;
        
        if (!self.isFiltered) {
            entityToDelete = [self.fetchedResultsController objectAtIndexPath:indexPath];
        } else {
            entityToDelete = [self.filteredFetchedResultsController objectAtIndexPath:indexPath];
        }
        
        if([AddEditViewController isEditingEventWithID:[entityToDelete objectID]]) {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"This event is already open for modification in another tab. Cannot delete." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
            [alertView release];
            
            return;
        }
        
        ItemCategory * cat = nil;
        
        if ([(Event *)entityToDelete itemCategory]) {
            cat = [[(Event *)entityToDelete itemCategory] retain];
        }
        
        // remove associated stats
        BOOL errorWithStats = NO;
        Statistic *statToRemove = [self.dao insertStatsToRemoveForEntity:entityToDelete];
        [self.dao.managedObjectContext insertObject:statToRemove];
        [statToRemove setFirm:self.firmForEvent];
        [statToRemove setItemCategory:cat];
        [cat release];
        
        NSMutableDictionary * dict = [self.dao addOrUpdateStatistic:statToRemove];
        
        int retCode = [(NSNumber *)[dict objectForKey:@"result"] intValue];
        
        if(retCode == 1) { // Update -> stats for the old entity version have been removed
            
        } else
            errorWithStats = YES;
        
        if(errorWithStats){
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was a problem while saving the statistics." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
            [alertView release];
            return;
        }
        
        [self.dao deleteEntity:entityToDelete];
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    Event *e = nil;
    
    if (!self.isFiltered) {
        e = [self.fetchedResultsController objectAtIndexPath:indexPath];
    } else {
        e = [self.filteredFetchedResultsController objectAtIndexPath:indexPath];
    }
    
    if(e)
        [self showEditForm:indexPath];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
             postNotificationName:REMOVED_EVENT_NOTIFICATION 
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
    
    if (self.eventSearchVC) {
        self.eventSearchVC.delegate = nil;
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.eventSearchVC release];
    [self.lastAcceleration release];
    [self.searchBar release];
    [self.searchTxt release];
    [self.fetchedResultsController release];
    [self.filteredFetchedResultsController release];
    [self.tableView release];
    [self.dao release];
    [self.firmForEvent release];
    [super dealloc];
}

@end
