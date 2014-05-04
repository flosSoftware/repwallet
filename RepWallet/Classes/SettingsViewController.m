//
//  SettingsViewController.m
//  repWallet
//
//  Created by Alberto Fiore on 12/14/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//

#import "SettingsViewController.h"
#import "LabeledStringSelectionCell.h"
#import "NonNegativeNumberCell.h"
#import "AddEditViewController.h"
#import "UITableViewController+CustomDrawing.h"
#import "RepWalletAppDelegate.h"
#import "RMMapQuestOpenAerialSource.h"
#import "RMMapQuestOSMSource.h"
#import "RMOpenCycleMapSource.h"
#import "RMOpenSeaMapSource.h"
#import "RMOpenStreetMapSource.h"
#import "IntegerCell.h"
#import "BusinessCategorySuggestionCell.h"
#import "ItemCategorySuggestionCell.h"

@implementation SettingsViewController

@synthesize cells, progressHUD, cacheDict;
@synthesize lastVisibleIndexPath;
@synthesize firstVisibleIndexPath;

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
    
    if([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad])
        rowHeight = 120;
    else
        rowHeight = 50;
    
    [self customizeTableViewDrawingWithHeader:nil headerBg:@"bgHeaderSearch" footer:nil footerBg:@"bgFooterSearch" background:nil backgroundColor:[UIColor whiteColor] rowHeight:rowHeight headerHeight:rowHeight footerHeight:rowHeight deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    self.firstVisibleIndexPath = nil;
    
    self.lastVisibleIndexPath = nil;
    
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

- (BOOL) checkFieldValidationConstraints 
{    
    //    NSLog(@"Validating fields... ");
    
    for (NSString* key in self.cells) {
        if (![[self.cells objectForKey:key] hasValidControlValue]) {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL) checkMandatoryConstraints 
{
    for (NSString* dk in self.cells) {
        
        BaseDataEntryCell *cell = (BaseDataEntryCell *)[self.cells objectForKey:dk];
        
        id v = [cell getControlValue];
        
//        NSLog(@"Checking cell at index %@, mandatory: %@", dk, [cell isMandatory] ? @"TRUE" : @"FALSE");
        
        if(v == nil && [cell isMandatory]) {
            
            return NO;
            
        } else {
            
            ;
        }
    }
    
    return YES;
}

- (void) saveSettings {
    
    BOOL isDataComplete = [self checkMandatoryConstraints];
    
    if(!isDataComplete) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Some mandatory values are missing." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
        return;
    }
    
    BOOL isDataValid = [self checkFieldValidationConstraints];
    
    if(!isDataValid) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Some values are not valid." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
        return;
    }
    
    [self showProgressHUDWithMessage:@"Saving"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    for (int row = 0; row < [self.tableView numberOfRowsInSection:0]; row++) {
        
        NSIndexPath* cellPath = [NSIndexPath indexPathForRow:row inSection:0];
        UITableViewCell* cell = [self tableView:self.tableView cellForRowAtIndexPath:cellPath];
        if (row == 0) {
            LabeledStringSelectionCell *mapTypeCell = (LabeledStringSelectionCell *)cell;

            NSString *key = MAP_TYPE_SETTING_KEY;
            NSString *value = [mapTypeCell getControlValue];

            [defaults setObject:value forKey:key];

        } else if (row == 1) {
            LabeledStringSelectionCell *travelModeCell = (LabeledStringSelectionCell *)cell;
            
            NSString *key = TRAVEL_MODE_SETTING_KEY;
            NSString *value = [travelModeCell getControlValue];
            
            [defaults setObject:value forKey:key];
            
        } else if (row == 2) {
            IntegerCell *maxNrOfFirmsForRouteCell = (IntegerCell *)cell;
            
            NSString *key = MAX_NR_OF_FIRMS_FOR_ROUTING_SETTING_KEY;
            NSNumber *value = [maxNrOfFirmsForRouteCell getControlValue];
            
            [defaults setObject:value forKey:key];
            
        } else if (row == 3) {
            IntegerCell *nrOfWorkHrsCell = (IntegerCell *)cell;
            
            NSString *key = NR_OF_WORK_HOURS_SETTING_KEY;
            NSNumber *value = [nrOfWorkHrsCell getControlValue];
            
            [defaults setObject:value forKey:key];
            
        } else if (row == 4) {
            NonNegativeNumberCell *taxRateCell = (NonNegativeNumberCell *)cell;
            
            NSString *key = TAX_RATE_SETTING_KEY;
            NSNumber *value = [taxRateCell getControlValue];
            
            [defaults setObject:value forKey:key];
            
        } else
            ;
    }
    
    // save it
    [defaults synchronize];
    
    [self showProgressHUDCompleteMessage:@"Saved"];
    
}

#pragma mark -
#pragma mark Initialization

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    
    if (self) {
        
        UITabBarItem * barIt = [[UITabBarItem alloc] initWithTitle:@"Settings" image:[UIImage imageNamed:@"settings.png"] tag:0];
        self.tabBarItem = barIt;
        [barIt release];
        
        self.cacheDict = [NSMutableDictionary dictionary];
        
        viewDidDisappear = NO;
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.lastVisibleIndexPath release];
    [self.firstVisibleIndexPath release];
    [self.cacheDict release];
    [self.progressHUD release];
    [self.cells release];
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

- (void) getBack {
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.firstVisibleIndexPath = nil;
    
    self.lastVisibleIndexPath = nil;
    
    self.cells = [NSMutableDictionary dictionary];
    
    UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveSettings)]; 
    
    self.navigationItem.rightBarButtonItem = btn;
    
    [btn release];
    
    int rowHeight;
    
    if([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad])
        rowHeight = 120;
    else
        rowHeight = 50;
    
    [self customizeTableViewDrawingWithHeader:nil headerBg:@"bgHeaderSearch" footer:nil footerBg:@"bgFooterSearch" background:nil backgroundColor:[UIColor whiteColor] rowHeight:rowHeight headerHeight:rowHeight footerHeight:rowHeight deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
    
    [self createProgressHUDForView:self.tableView];
    
}

- (void)viewDidUnload
{
    [self.cacheDict removeAllObjects];
    
    for (NSString *dataKey in self.cells) {
        
        BaseDataEntryCell *cell = [self.cells objectForKey:dataKey];
        
        id val = [cell getControlValue] ? [cell getControlValue] : [NSNull null];
        
        [self.cacheDict setObject:val forKey:dataKey];
        
    }
    
    self.progressHUD = nil;
    self.cells = nil;
    
    [super viewDidUnload];
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    if (viewDidDisappear
        && self.interfaceOrientation != lastOrientation) {
        
        
        int rowHeight;
        
        if([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad])
            rowHeight = 120;
        else
            rowHeight = 50;
        
        [self customizeTableViewDrawingWithHeader:nil headerBg:@"bgHeaderSearch" footer:nil footerBg:@"bgFooterSearch" background:nil backgroundColor:[UIColor whiteColor] rowHeight:rowHeight headerHeight:rowHeight footerHeight:rowHeight deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];

        self.firstVisibleIndexPath = nil;
        
        self.lastVisibleIndexPath = nil;
        
        [self.tableView reloadData];
        
    }
}

-(void)viewDidDisappear:(BOOL)animated {
    viewDidDisappear = YES;
    
    [super viewDidDisappear:animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *visibleIPath = [[tableView indexPathsForVisibleRows] sortedArrayUsingSelector:@selector(compare:)];
    
    if(self.lastVisibleIndexPath
       && ![visibleIPath containsObject:self.lastVisibleIndexPath]
       ) {
        
        NSInteger row = self.lastVisibleIndexPath.row;
        
        [[self.cells objectForKey:
          [NSString stringWithFormat:@"%i", row]]
         setBackgroundView:nil];
        
    } else if(self.firstVisibleIndexPath
              && ![visibleIPath containsObject:self.firstVisibleIndexPath]
              ) {
        
        NSInteger row = self.firstVisibleIndexPath.row;
        
        [[self.cells objectForKey:
          [NSString stringWithFormat:@"%i", row]]
         setBackgroundView:nil];
    }
    
    self.firstVisibleIndexPath = [visibleIPath objectAtIndex:0];
    self.lastVisibleIndexPath = [visibleIPath lastObject];
    
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    
    NSString *CellIdentifier;
    
    UITableViewCell *cell = nil;
    
    BOOL dequeued = NO;
    
    UIColor * color = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    
    switch (indexPath.row) {
            
        case 0:
        {
            CellIdentifier = @"0";
            
            LabeledStringSelectionCell *mapTypeCell = (LabeledStringSelectionCell *)[self.cells objectForKey:CellIdentifier];
            
            if (mapTypeCell == nil) {
                
                mapTypeCell = [[[LabeledStringSelectionCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                                dataSource:[NSMutableArray arrayWithObjects:
                                                                               [NSDictionary dictionaryWithObjectsAndKeys:
                                                                                @"Open Sea Maps", @"label", NSStringFromClass([RMOpenSeaMapSource class]), @"val", nil],
                                                                               [NSDictionary dictionaryWithObjectsAndKeys:
                                                                                @"Open Cycle Maps", @"label", NSStringFromClass([RMOpenCycleMapSource class]), @"val", nil],
                                                                               [NSDictionary dictionaryWithObjectsAndKeys:
                                                                                @"Open Street Maps", @"label", NSStringFromClass([RMOpenStreetMapSource class]), @"val", nil],
                                                                               [NSDictionary dictionaryWithObjectsAndKeys:
                                                                                @"MapQuest OSM", @"label", NSStringFromClass([RMMapQuestOSMSource class]), @"val", nil],
                                                                               [NSDictionary dictionaryWithObjectsAndKeys:
                                                                                @"MapQuest Open Aerial", @"label", NSStringFromClass([RMMapQuestOpenAerialSource class]), @"val", nil],
                                                                               nil] 
                                                              reuseIdentifier:nil 
                                                               boundClassName:nil 
                                                                      dataKey:nil 
                                                                        label:@"Map Source"] 
                               autorelease];
                
                [mapTypeCell changeMandatoryStatusTo:YES];
                
                [mapTypeCell setIsAddEditCell:NO];
                
                [mapTypeCell setControlValue:[d objectForKey:MAP_TYPE_SETTING_KEY]];
                
                [self.cells setObject:mapTypeCell forKey:CellIdentifier];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [mapTypeCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [mapTypeCell setControlValue:nil];
                    
                }
                
            } else
                dequeued = YES;
            
            [self customizeDrawingForSearchFormCell:mapTypeCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return mapTypeCell;
        }
            break;
            
        case 1:
        {
            CellIdentifier = @"1";
            
            LabeledStringSelectionCell *travelModeCell = (LabeledStringSelectionCell *)[self.cells objectForKey:CellIdentifier];
            if (travelModeCell == nil) {
                
                travelModeCell = [[[LabeledStringSelectionCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                                                dataSource:[NSMutableArray arrayWithObjects:
                                                                               [NSDictionary dictionaryWithObjectsAndKeys:
                                                                                @"By car", @"label", @"Driving", @"val", nil],
                                                                               [NSDictionary dictionaryWithObjectsAndKeys:
                                                                                @"Walking", @"label", @"Walking", @"val", nil],
//                                                                               [NSDictionary dictionaryWithObjectsAndKeys:
//                                                                                @"Bicycling", @"label", @"bicycle", @"val", nil],
                                                                               nil]
                                                              reuseIdentifier:nil 
                                                               boundClassName:nil 
                                                                      dataKey:nil
                                                                        label:@"Travel Mode"] 
                               autorelease];
                
                [travelModeCell changeMandatoryStatusTo:YES];
                
                [travelModeCell setIsAddEditCell:NO];
                
                [travelModeCell setControlValue:[d objectForKey:TRAVEL_MODE_SETTING_KEY]];
                
                [self.cells setObject:travelModeCell forKey:CellIdentifier];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [travelModeCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [travelModeCell setControlValue:nil];
                    
                }
                
            } else
                dequeued = YES;
            
            [self customizeDrawingForSearchFormCell:travelModeCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return travelModeCell;
        }
            break;
            
        case 2:
        {
            CellIdentifier = @"2";
            
            IntegerCell *maxNrOfFirmsForRouteCell = (IntegerCell *)[self.cells objectForKey:CellIdentifier];
            if (maxNrOfFirmsForRouteCell == nil) {
                
                maxNrOfFirmsForRouteCell = [[[IntegerCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil boundClassName:nil dataKey:nil label:@"Nr. of Customers in Routes" color:color]  autorelease];
                
                [maxNrOfFirmsForRouteCell setLowerLimitnumber:[NSNumber numberWithInt:2]];
                
                [maxNrOfFirmsForRouteCell changeMandatoryStatusTo:YES];
                
                [maxNrOfFirmsForRouteCell setIsAddEditCell:NO];
                
                [maxNrOfFirmsForRouteCell setControlValue:[d objectForKey:MAX_NR_OF_FIRMS_FOR_ROUTING_SETTING_KEY]];
                
                [self.cells setObject:maxNrOfFirmsForRouteCell forKey:CellIdentifier];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [maxNrOfFirmsForRouteCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [maxNrOfFirmsForRouteCell setControlValue:nil];
                    
                }
                
            } else
                dequeued = YES;
            
            [self customizeDrawingForSearchFormCell:maxNrOfFirmsForRouteCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return maxNrOfFirmsForRouteCell;
        }
            break;
            
        case 3:
        {
            CellIdentifier = @"3";
            
            IntegerCell *nrOfWorkHrsCell = (IntegerCell *)[self.cells objectForKey:CellIdentifier];
            if (nrOfWorkHrsCell == nil) {
                
                nrOfWorkHrsCell = [[[IntegerCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil boundClassName:nil dataKey:nil label:@"Working Hours / Day" color:color] autorelease];
                
                [nrOfWorkHrsCell setLowerLimitnumber:[NSNumber numberWithInt:1]];
                
                [nrOfWorkHrsCell changeMandatoryStatusTo:YES];
                
                [nrOfWorkHrsCell setIsAddEditCell:NO];
                
                [nrOfWorkHrsCell setControlValue:[d objectForKey:NR_OF_WORK_HOURS_SETTING_KEY]];
                
                [self.cells setObject:nrOfWorkHrsCell forKey:CellIdentifier];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [nrOfWorkHrsCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [nrOfWorkHrsCell setControlValue:nil];
                    
                }
                
            } else
                dequeued = YES;
            
            [self customizeDrawingForSearchFormCell:nrOfWorkHrsCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return nrOfWorkHrsCell;
        }
            break;
            
        case 4:
        {
            CellIdentifier = @"4";
            
            NonNegativeNumberCell *taxRateCell = (NonNegativeNumberCell *)[self.cells objectForKey:CellIdentifier];
            if (taxRateCell == nil) {
                
                taxRateCell = [[[NonNegativeNumberCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil boundClassName:nil dataKey:nil label:@"Default Tax Rate (%)" color:color] autorelease];
                
                [taxRateCell changeMandatoryStatusTo:YES];
                
                [taxRateCell setIsAddEditCell:NO];
                
                [taxRateCell setControlValue:[d objectForKey:TAX_RATE_SETTING_KEY]];
                
                [self.cells setObject:taxRateCell forKey:CellIdentifier];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [taxRateCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [taxRateCell setControlValue:nil];
                    
                }
                
            } else
                dequeued = YES;
            
            [self customizeDrawingForSearchFormCell:taxRateCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return taxRateCell;
        }
            break;
            
        default:
            break;
    }
    
    return cell;
}

- (TextCell *) prevTextCellForIndexpath:(NSIndexPath *)indexPath {
    
    int i = 1;
    
    TextCell *textCell = nil;
    
    NSIndexPath * ip;
    
    while (YES) {
        
        if (indexPath.row - i < 0) {
            break;
        }
        
        ip = [NSIndexPath indexPathForRow:indexPath.row - i inSection:indexPath.section];
        
        id cell = [self tableView:self.tableView cellForRowAtIndexPath:ip];
        
        if ([(BaseDataEntryCell *)cell enabledCell]
            && [cell isKindOfClass:([TextCell class])]
            && ![cell isMemberOfClass:([BusinessCategorySuggestionCell class])]
            && ![cell isMemberOfClass:([ItemCategorySuggestionCell class])]) {
            textCell = cell;
            break;
        }
        
        i += 1;
    }
    
    if (textCell) {
        [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    
    return textCell;
}

- (TextCell *) nextTextCellForIndexpath:(NSIndexPath *)indexPath {
    
    int i = 1;
    
    TextCell *textCell = nil;
    
    NSIndexPath * ip;
    
    while (YES) {
        
        if (indexPath.row + i > [self tableView:self.tableView numberOfRowsInSection:indexPath.section] - 1) {
            break;
        }
        
        ip = [NSIndexPath indexPathForRow:indexPath.row + i inSection:indexPath.section];
        
        id cell = [self tableView:self.tableView cellForRowAtIndexPath:ip];
        
        if ([(BaseDataEntryCell *)cell enabledCell]
            && [cell isKindOfClass:([TextCell class])]
            && ![cell isMemberOfClass:([BusinessCategorySuggestionCell class])]
            && ![cell isMemberOfClass:([ItemCategorySuggestionCell class])]) {
            textCell = cell;
            break;
        }
        
        i += 1;
        
    }
    
    if (textCell) {
        [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
    
    return textCell;
}


@end
