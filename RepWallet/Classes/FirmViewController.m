//
//  FirmViewController.m
//  repWallet
//
//  Created by Alberto Fiore on 11/02/11.
//  Copyright 2011 Alberto Fiore. All rights reserved.
//
#import "FirmViewController.h"
#import "AddEditViewController.h"
#import "Firm.h"
#import <QuartzCore/QuartzCore.h>
#import "RepWalletAppDelegate.h"
#import "UIViewController+CustomDrawing.h"
#import "ImportViewController.h"
#import <AddressBook/AddressBook.h>
#import "NSObject+CheckConnectivity.h"
#import <AddressBookUI/AddressBookUI.h>
#import "MBProgressHUD.h"
#import "FwdGeocoder.h"
#import "MapController.h"

static BOOL tabBarShouldBeHidden = NO;

@interface FirmViewController () <UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, NSFetchedResultsControllerDelegate, ABPeoplePickerNavigationControllerDelegate, FwdGeocoderDelegate, MapControllerDelegate, AddEditViewControllerDelegate> {
    
    BOOL shouldBeginEditing;
    
}

@property (nonatomic, retain) MapController *mapC;
@property (nonatomic, retain) Firm *pendingFirmFromContacts;
@property (nonatomic, retain) MBProgressHUD *progressHUD;
@property (nonatomic, retain) FwdGeocoder * geocoderV2;
@property (nonatomic, retain) DAO *dao;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, assign) UITableViewStyle tableViewStyle;
@property (nonatomic, assign) BOOL isFiltered;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) NSString *searchTxt;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSFetchedResultsController *filteredFetchedResultsController;
@property (nonatomic, retain) NSIndexPath* indexPathToDelete;

- (void) hideTabBar;

- (void) showTabBar;

- (void) showPeoplePicker;

@end

@implementation FirmViewController

@synthesize dao;
@synthesize tableView;
@synthesize tableViewStyle;
@synthesize isFiltered;
@synthesize fetchedResultsController;
@synthesize searchTxt;
@synthesize searchBar;
@synthesize filteredFetchedResultsController;
@synthesize progressHUD, geocoderV2;
@synthesize pendingFirmFromContacts;
@synthesize indexPathToDelete;
@synthesize mapC;


# pragma mark - Syncing

- (void)performFetch
{
    if (self.fetchedResultsController) {
        if (self.fetchedResultsController.fetchRequest.predicate) {
            NSLog(@"[%@ %@] fetching %@ with predicate: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.fetchedResultsController.fetchRequest.entityName, self.fetchedResultsController.fetchRequest.predicate);
        } else {
            NSLog(@"[%@ %@] fetching all %@ (i.e., no predicate)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.fetchedResultsController.fetchRequest.entityName);
        }
        NSError *error;
        [self.fetchedResultsController performFetch:&error];
        if (error) NSLog(@"[%@ %@] %@ (%@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [error localizedDescription], [error localizedFailureReason]);
    } else {
        NSLog(@"[%@ %@] no NSFetchedResultsController (yet?)", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    }
    [self.tableView reloadData];
}


- (void)reloadFetchedResults:(NSNotification*)note {
    NSLog(@"Underlying data changed ... refreshing!");
    [self performFetch];
}

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


#pragma mark - MBProgressHUD

- (MBProgressHUD *)createProgressHUDForView:(UIView *)view {
    if (!self.progressHUD || ![self.progressHUD.superview isEqual:view]) {
        MBProgressHUD * p = [[MBProgressHUD alloc] initWithView:view];
        self.progressHUD = p;
        [p release];
        self.progressHUD.minSize = CGSizeMake(120, 120);
        self.progressHUD.minShowTime = 0.5;
        self.progressHUD.customView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MWPhotoBrowser.bundle/images/Checkmark.png"]] autorelease];
        [view addSubview:self.progressHUD];
    }
    return self.progressHUD;
}

- (void)showProgressHUDWithMessage:(NSString *)message {
    self.progressHUD.labelText = message;
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    [self.progressHUD show:YES];
}

- (void)hideProgressHUD:(BOOL)animated {
    [self.progressHUD hide:animated];
}

- (void)showProgressHUDCompleteMessage:(NSString *)message {
    if (message) {
        if (self.progressHUD.isHidden) [self.progressHUD show:YES];
        self.progressHUD.labelText = message;
        self.progressHUD.mode = MBProgressHUDModeCustomView;
        [self.progressHUD hide:YES afterDelay:1.5];
    } else {
        [self.progressHUD hide:YES];
    }
}

#pragma mark -
#pragma mark Geocoding

- (void) updateMapCoordinateForEntity:(NSNotification *)notification
{
    [self.pendingFirmFromContacts setLatitude:[[notification userInfo] objectForKey:@"latitude"]];
    [self.pendingFirmFromContacts setLongitude:[[notification userInfo] objectForKey:@"longitude"]];
}

-(void) geocoderFailedWithError:(NSString *)errorMsg
{
    [self.pendingFirmFromContacts setLatitude:[NSNumber numberWithDouble:-360.0]];
    [self.pendingFirmFromContacts setLongitude:[NSNumber numberWithDouble:0]];
    
    [self.dao.managedObjectContext insertObject:self.pendingFirmFromContacts];
    
    [self.dao saveContext];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:ADDED_OR_EDITED_FIRM_NOTIFICATION
     object:nil];
    
    self.pendingFirmFromContacts = nil;
    
    [(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO force:NO];
    [self hideProgressHUD:YES];
    
    NSString * s = @"";
    
    if (errorMsg) {
        s = errorMsg;
    }
    
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Cannot obtain point coordinates. %@", s] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
	[alertView show];
	[alertView release];
}

-(void) geocoderFoundLocation:(CLLocation *)location
{
    [(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO force:NO];
    
    [self hideProgressHUD:YES];
    
    NSNumber *lat = [NSNumber numberWithDouble:location.coordinate.latitude];
    NSNumber *lng = [NSNumber numberWithDouble:location.coordinate.longitude];
    
    [self.pendingFirmFromContacts setLatitude:lat];
    [self.pendingFirmFromContacts setLongitude:lng];
    
    MapController *mapController = [[MapController alloc] initWithArray:[NSArray arrayWithObjects:self.pendingFirmFromContacts, nil] andDao:self.dao isPreSave:YES centerLocation:location.coordinate zoomLvl:0.5 longPressureEnabled:NO];
    self.mapC = mapController;
    [mapController release];
    self.mapC.title = @"Map";
    self.mapC.delegate = self;
    
    [self.navigationController pushViewController:self.mapC animated:YES];
}

#pragma mark -
#pragma mark Contact import


-(void)mapControllerCanceledEditingForObjectOfClass:(NSString *)clazz {
    self.pendingFirmFromContacts = nil;
}

-(void)mapControllerEndedEditingForObjectOfClass:(NSString *)clazz {
    [self.dao.managedObjectContext insertObject:self.pendingFirmFromContacts];
    [self.dao saveContext];
    [[NSNotificationCenter defaultCenter]
     postNotificationName:ADDED_OR_EDITED_FIRM_NOTIFICATION
     object:nil];
}

- (void) importPersonContact:(ABRecordRef)ref {
    
    Firm * firm = [(Firm *)[[NSManagedObject alloc] initWithEntity:[self.dao getEntityDescriptionForName:NSStringFromClass([Firm class])] insertIntoManagedObjectContext:nil] autorelease];
    [firm setInsertDate:[NSDate date]];
    
    CFStringRef firstName = ABRecordCopyValue (
                                               ref,
                                               kABPersonFirstNameProperty
                                               );
    if (firstName != NULL) {
        firm.refFirstName = (NSString *)firstName;
    } else {
        
    }
    
    CFStringRef lastName = ABRecordCopyValue (
                                              ref,
                                              kABPersonLastNameProperty
                                              );
    if (lastName != NULL) {
        firm.refSecondName = (NSString *)lastName;
    } else {
        
    }
    
    CFStringRef jobTitle = ABRecordCopyValue (
                                              ref,
                                              kABPersonJobTitleProperty
                                              );
    if (jobTitle != NULL) {
        firm.refRole = (NSString *)jobTitle;
    } else {
        
    }
    
    CFStringRef firmName = ABRecordCopyValue (
                                              ref,
                                              kABPersonOrganizationProperty
                                              );
    if (firmName != NULL) {
        
        firm.firmName = (NSString *)firmName;
        
        if(![self.dao checkPrimaryKeyOfEntity:firm ofType:NSStringFromClass([Firm class]) testUsingFakeObj:NO]) {
            NSString *pkField = @"";
            if([firm isMemberOfClass: [Firm class]]) {
                pkField = @"Name";
            }
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:[NSString stringWithFormat:@"The field '%@' must be unique.", pkField] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
            [alertView release];
            return;
        }
        
    } else {
        
        int i = [self.dao countFirmsWithNamesContaining:@"Imported from Contacts - " excludingPending:YES];
        firm.firmName = [NSString stringWithFormat:@"Imported from Contacts - %i", i+1];
    }
    
    CFTypeRef address = ABRecordCopyValue (
                                           ref,
                                           kABPersonAddressProperty
                                           );
    
    NSString *cCode = nil;
    
    if (ABMultiValueGetCount(address) > 0)
    {
        CFDictionaryRef anAddress = ABMultiValueCopyValueAtIndex(address, 0);
        CFStringRef town = CFDictionaryGetValue(anAddress, kABPersonAddressCityKey);
        if (town != NULL) {
            firm.town = (NSString *)town;
        } else {
        }
        CFStringRef state = CFDictionaryGetValue(anAddress, kABPersonAddressStateKey);
        if (state != NULL) {
            firm.state = (NSString *)state;
        } else {
        }
        CFStringRef address = CFDictionaryGetValue(anAddress, kABPersonAddressStreetKey);
        if (address != NULL) {
            firm.street = (NSString *)address;
        } else {
        }
        CFStringRef country = CFDictionaryGetValue(anAddress, kABPersonAddressCountryKey);
        if (country != NULL) {
            firm.country = (NSString *)country;
        } else {
        }
        CFStringRef zip = CFDictionaryGetValue(anAddress, kABPersonAddressZIPKey);
        if (zip != NULL) {
            firm.zip = (NSString *)zip;
        } else {
        }
        CFStringRef countryCode = CFDictionaryGetValue(anAddress, kABPersonAddressCountryCodeKey);
        if (countryCode != NULL) {
            cCode = (NSString *)countryCode;
        } else {
            ;
        }
        
        CFRelease(anAddress);
    }
    
    CFTypeRef phoneProperty = ABRecordCopyValue(ref, kABPersonPhoneProperty);
    NSArray *phones = (NSArray *)ABMultiValueCopyArrayOfAllValues(phoneProperty);
    int i = 0;
    for (NSString *phone in phones) {
        if(i == 0) {
            if (phone != NULL) {
                firm.phoneNr1 = (NSString *)phone;
            } else {
                i--;
            }
        }
        else if(i == 1) {
            if (phone != NULL) {
                firm.phoneNr2 = (NSString *)phone;
            } else {
                i--;
            }
        }
        else
            break;
        i++;
    }
    
    [phones release];
    
    CFTypeRef mailProperty = ABRecordCopyValue(ref, kABPersonEmailProperty);
    NSArray *mails = (NSArray *)ABMultiValueCopyArrayOfAllValues(mailProperty);
    i = 0;
    for (NSString *mail in mails) {
        if(i == 0) {
            if (mail != NULL) {
                firm.eMail = (NSString *)mail;
            } else {
                i--;
            }
        }
        else
            break;
        i++;
    }
    
    [mails release];
    
    CFStringRef notes = ABRecordCopyValue (
                                           ref,
                                           kABPersonNoteProperty
                                           );
    if (notes != NULL) {
        firm.notes = (NSString *)notes;
    }
    
    if (firstName != NULL) {
        CFRelease(firstName);
    }
    if (lastName != NULL) {
        CFRelease(lastName);
    }
    if (firmName != NULL) {
        CFRelease(firmName);
    }
    if (address != NULL) {
        CFRelease(address);
    }
    if (phoneProperty != NULL) {
        CFRelease(phoneProperty);
    }
    if (mailProperty != NULL) {
        CFRelease(mailProperty);
    }
    if (jobTitle != NULL) {
        CFRelease(jobTitle);
    }
    if (notes != NULL) {
        CFRelease(notes);
    }
    
    self.pendingFirmFromContacts = firm;
    
    [(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES force:NO];
    [self showProgressHUDWithMessage:@"Loading"];
    
    //    NSLog(@"%@", self.pendingFirmFromContacts);
    
    if ([self hasConnectivity]) {
        
        [self.geocoderV2 startGeocodingWithAddress:firm.street locality:firm.town ZIP:firm.zip adminDistrict:firm.state countryCode:cCode];
        
    } else {
        
        [self.pendingFirmFromContacts setLatitude:[NSNumber numberWithDouble:-360.0]];
        [self.pendingFirmFromContacts setLongitude:[NSNumber numberWithDouble:0]];
        [self.dao.managedObjectContext insertObject:self.pendingFirmFromContacts];
        
        [self.dao saveContext];
        
        [[NSNotificationCenter defaultCenter]
         postNotificationName:ADDED_OR_EDITED_FIRM_NOTIFICATION
         object:nil];
        
        [(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO force:NO];
        [self hideProgressHUD:YES];
        
    }
    
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
    
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else if ([self respondsToSelector:@selector(dismissModalViewControllerAnimated:)]) {
        [self dismissModalViewControllerAnimated:YES];
    }
}

// Called after a person has been selected by the user.
// Return YES if you want the person to be displayed.
// Return NO  to do nothing (the delegate is responsible for dismissing the peoplePicker).
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    
    [self importPersonContact:person];
    
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else if ([self respondsToSelector:@selector(dismissModalViewControllerAnimated:)]) {
        [self dismissModalViewControllerAnimated:YES];
    }
    
    return NO;
}

// Called after a value has been selected by the user.
// Return YES if you want default action to be performed.
// Return NO to do nothing (the delegate is responsible for dismissing the peoplePicker).
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else if ([self respondsToSelector:@selector(dismissModalViewControllerAnimated:)]) {
        [self dismissModalViewControllerAnimated:YES];
    }
    
    return NO;
}

- (void) showPeoplePicker {
    ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    UIColor * c = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    picker.navigationBar.tintColor = c;
    if ([self respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        
        [self presentViewController:picker animated:YES completion:NULL];
        
    } else if([self respondsToSelector:@selector(presentModalViewController:animated:)]) {
        
        [self presentModalViewController:picker animated:YES];
        
    }
    [picker release];
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
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"map"] style:UIBarButtonItemStylePlain target:self action:@selector(pushNewMap)];
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"import"] style:UIBarButtonItemStylePlain target:self action:@selector(pushNewImport)];
    UIBarButtonItem *item3 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"contacts"] style:UIBarButtonItemStylePlain target:self action:@selector(showPeoplePicker)];
    UIBarButtonItem *item4 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"hide"] style:UIBarButtonItemStylePlain target:self action:@selector(hideTabBar)];
    UIBarButtonItem *item5 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"show"] style:UIBarButtonItemStylePlain target:self action:@selector(showTabBar)];
    NSArray *items = [NSArray arrayWithObjects:item1, flexibleItem, item2, flexibleItem, item3, flexibleItem, item4, flexibleItem, item5, nil];
    
    [self setToolbarItems:items animated:YES];
    
    [flexibleItem release];
    [item1 release];
    [item2 release];
    [item3 release];
    [item4 release];
    [item5 release];
    
}


#pragma mark -
#pragma mark Actions

- (void)pushNewMap
{
    //    NSArray * props = [NSArray arrayWithObjects:
    //                       @"latitude", @"longitude", @"firmName", @"country", @"town", @"street", nil];
    MapController *mapController = [[MapController alloc] initWithArray:[self.dao getFirmsExcludingPending:YES excludingSubentities:YES withSorting:NO propsToFetch:nil] andDao:self.dao isPreSave:NO longPressureEnabled:YES];
    mapController.title = @"Map";
    [self.navigationController pushViewController:mapController animated:YES];
    [mapController release];
}

- (void)pushNewImport
{
    ImportViewController *iController = [[ImportViewController alloc] initWithStyle:UITableViewStylePlain andDao:self.dao];
	iController.title = @"Import";
    iController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    iController.modalPresentationStyle = UIModalPresentationFormSheet;
    
	// Add create and configure the navigation controller.
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:iController];
    UIColor * c = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    navigationController.navigationBar.tintColor = c;
    navigationController.toolbar.tintColor = c;
    
    if ([self respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        
        [self presentViewController:navigationController animated:YES completion:NULL];
        
    } else if([self respondsToSelector:@selector(presentModalViewController:animated:)]) {
        
        [self presentModalViewController:navigationController animated:YES];
        
    }
    
	[navigationController release];
    [iController release];
}

- (void)showAddForm
{
    Firm *firm = [(Firm *)[[NSManagedObject alloc] initWithEntity:[self.dao getEntityDescriptionForName:NSStringFromClass([Firm class])] insertIntoManagedObjectContext:nil] autorelease];
    [firm setInsertDate:[NSDate date]];
    AddEditViewController *viewController = [[AddEditViewController alloc] initWithStyle:UITableViewStylePlain  title:ADDEDITVIEWCONTROLLER_INSERT_MODE_TITLE entity:firm andDao:self.dao];
    [self.navigationController pushViewController:viewController animated:YES];
    [viewController release];
}

- (void)showEditForm:(NSIndexPath *)indexPath
{
    Firm *firm;
    
    if(self.isFiltered) {
        firm = [self.filteredFetchedResultsController objectAtIndexPath:indexPath];
    } else {
        firm = [self.fetchedResultsController objectAtIndexPath:indexPath];
    }
    
    if([AddEditViewController isEditingFirmWithID:[firm objectID]]) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"This firm is already open for modification in another tab" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        
        return;
    }
    
    AddEditViewController *viewController = [[AddEditViewController alloc] initWithStyle:UITableViewStylePlain title:ADDEDITVIEWCONTROLLER_EDIT_MODE_TITLE entity:firm andDao:self.dao];
    [self.navigationController pushViewController:viewController animated:YES];
    [viewController release];
}


#pragma mark -
#pragma mark Initialization

- (id)initWithStyle:(UITableViewStyle)style andDao:(DAO *)aDao
{
    self = [super init];
    
    if (self) {
        
        self.navigationController.toolbarHidden = NO;
        self.navigationController.toolbar.translucent = NO;
        
        self.pendingFirmFromContacts = nil;
        
        shouldBeginEditing = YES;
        
        self.dao = aDao;
        self.tableViewStyle = style;
        
        UITabBarItem * item = [[UITabBarItem alloc] initWithTitle:@"Customers" image:[UIImage imageNamed:@"firms.png"] tag:0];
        self.tabBarItem = item;
        [item release];
        
        viewDidDisappear = NO;
        
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
    [NSFetchedResultsController deleteCacheWithName:@"Firms"];
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

-(void)loadView {
    
    [super loadView];
    [self createToolbar];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    FwdGeocoder * geo = [[FwdGeocoder alloc] init];
    
    self.geocoderV2 = geo;
    
    [geo release];
    
    self.geocoderV2.delegate = self;
    
    self.fetchedResultsController = [self.dao fetchedResultsControllerForEntityType:NSStringFromClass([Firm class]) withDelegate:self cacheName:@"Firms"];
    
    self.filteredFetchedResultsController = [self.dao fetchedResultsControllerForEntityType:NSStringFromClass([Firm class]) withDelegate:self cacheName:nil];
    
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
    
    if ([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad]) {
        rowHeight = 179;
    } else
        rowHeight = 98;
    
    [self customizeTableViewDrawingWithHeader:nil headerBg:nil footer:nil footerBg:nil background:nil backgroundColor:nil rowHeight:rowHeight headerHeight:10 footerHeight:0 forTableView:self.tableView deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
    
    // create a standard "add" button
    UIBarButtonItem * addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showAddForm)];
    addButton.style = UIBarButtonItemStyleBordered;
    
    self.navigationItem.rightBarButtonItem = addButton;
    
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
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
    
    [self createProgressHUDForView:self.tableView];
    
    // Refresh this view whenever data changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadFetchedResults:)
                                                 name:@"SomethingChanged"
                                               object:[[UIApplication sharedApplication] delegate]];
    
}

- (void)viewDidUnload
{
    if (self.searchBar) {
        self.searchBar.delegate = nil;
    }
    
    if (self.tableView) {
        self.tableView.delegate = nil;
    }
    
    if (self.mapC) {
        self.mapC.delegate = nil;
    }
    
    if (self.geocoderV2) {
        self.geocoderV2.delegate = nil;
    }
    
    self.progressHUD = nil;
    
    self.mapC = nil;
    
    self.geocoderV2 = nil;
    
    self.searchTxt = [self.searchBar text];
    self.searchBar = nil;
    
    self.fetchedResultsController = nil;
    self.filteredFetchedResultsController = nil;
    
    self.tableView = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
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

-(void)viewDidDisappear:(BOOL)animated {
    
    viewDidDisappear = YES;
    
    [super viewDidDisappear:animated];
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
        
        NSCalendar *calendar = [NSCalendar currentCalendar];
        
        NSDateComponents *components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
                                                   fromDate:date
                                                     toDate:[NSDate date]
                                                    options:0];
        
        float rowWithoutShadowHeight;
        
        if([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad]) {
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

// Called when an alertview button is touched
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (buttonIndex) {
        case 0:
        {
            ;
        }
            break;
            
        case 1:
        {
            // Delete the data
            
            Firm *entityToDelete = nil;
            
            if (!self.isFiltered) {
                entityToDelete = [self.fetchedResultsController objectAtIndexPath:self.indexPathToDelete];
                [self.dao deleteEntity:entityToDelete];
            } else {
                entityToDelete = [self.filteredFetchedResultsController objectAtIndexPath:self.indexPathToDelete];
                [self.dao deleteEntity:entityToDelete];
            }
        }
            break;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        self.indexPathToDelete = indexPath;
        
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Warning"
                              message:@"Are you sure you want to delete the customer in conjunction with related events, appointments and unpaid invoices?"
                              delegate: self
                              cancelButtonTitle:@"Cancel"
                              otherButtonTitles:@"Delete", nil];
        [alert show];
        [alert release];
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
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
             postNotificationName:REMOVED_FIRM_NOTIFICATION
             object:nil];
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
    
    if (self.mapC) {
        self.mapC.delegate = nil;
    }
    
    if (self.geocoderV2) {
        self.geocoderV2.delegate = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.mapC release];
    [self.indexPathToDelete release];
    [self.searchBar release];
    [self.searchTxt release];
    [self.fetchedResultsController release];
    [self.filteredFetchedResultsController release];
    [self.tableView release];
    [self.dao release];
    [self.pendingFirmFromContacts release];
    [self.geocoderV2 release];
    [self.progressHUD release];
    [super dealloc];
}


@end

