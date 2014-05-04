//
//  ImportViewController.m
//  repWallet
//
//  Created by Alberto Fiore on 10/11/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "ImportViewController.h"
#import "LabeledStringSelectionCell.h"
#import "NumberCell.h"
#import "CHCSVParser.h"
#import "AddEditViewController.h"
#import "OneCharTextCell.h"
#import "StringSelectionCell.h"
#import "UITableViewController+CustomDrawing.h"
#import "RepWalletAppDelegate.h"
#import "NSArray+CHCSVAdditions.h"
#import "NSFileManager+DirectoryLocations.h"

@implementation ImportViewController

@synthesize dao, cacheDict, indexOfRowExtracted, rowsExtracted, cells, nrCols, progressHUD, fileBrowser;
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
    
    [self.tableView setFrame:CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y, self.tableView.frame.size.width, fHeight
                                        - [UIApplication sharedApplication].statusBarFrame.size.height
                                        - self.navigationController.toolbar.frame.size.height
                                        - self.navigationController.navigationBar.frame.size.height
                                        )];
    [UIView commitAnimations];
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
    
    [self.tableView setFrame:CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y, self.tableView.frame.size.width, fHeight - [UIApplication sharedApplication].statusBarFrame.size.height
                                        - self.navigationController.toolbar.frame.size.height
                                        - self.navigationController.navigationBar.frame.size.height
                                        )];
    
    [UIView commitAnimations];
}

- (void) hideTabBar {
    
    [self hideTabBar:self.tabBarController];
}

- (void) showTabBar {
    
    [self showTabBar:self.tabBarController];
}

- (void) createToolbar {
    
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"import"] style:UIBarButtonItemStylePlain target:self action:@selector(chooseFile)];
    NSArray *items = [NSArray arrayWithObjects:flexibleItem, item2, flexibleItem, nil];
    
    [self setToolbarItems:items animated:YES];
    
    [flexibleItem release];

    [item2 release];
    
}


#pragma mark -
#pragma mark Initialization

- (id)initWithStyle:(UITableViewStyle)style andDao:(DAO *)dao
{
    self = [super initWithStyle:style];
    
    if (self) {
        
        self.navigationController.toolbarHidden = NO;
        self.navigationController.toolbar.translucent = NO;
        
        if(dao)
            self.dao = dao;
        
        UITabBarItem * barIt = [[UITabBarItem alloc] initWithTitle:@"Import" image:[UIImage imageNamed:@"import.png"] tag:0];
        self.tabBarItem = barIt;
        [barIt release];
        
        self.cacheDict = [NSMutableDictionary dictionary];
        
        viewDidDisappear = NO;
    }
    
    return self;
}

- (void)dealloc
{
    if (self.fileBrowser) {
        self.fileBrowser.delegate = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.lastVisibleIndexPath release];
    [self.firstVisibleIndexPath release];
    [self.cacheDict release];
    [self.fileBrowser release];
    [self.dao release];
    [self.cells release];
    [self.rowsExtracted release];
    [self.progressHUD release];
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
    
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else if ([self respondsToSelector:@selector(dismissModalViewControllerAnimated:)]) {
        [self dismissModalViewControllerAnimated:YES];
    }
}

#pragma mark - File browser

- (void) chooseFile
{
    DocumentSelectionViewController * docSelVC = [[DocumentSelectionViewController alloc] initWithDirPath:[[NSFileManager defaultManager] applicationDocumentsDirectory] actualDocumentsURLs:[NSMutableSet set] onlyOneToSelect:YES];
    [docSelVC browseForFileWithType:@"csv"];
    self.fileBrowser = docSelVC;
    [docSelVC release];
    self.fileBrowser.delegate = self;
    [self.navigationController pushViewController:self.fileBrowser animated:YES];
}


- (void)documentSelectionControllerSelectedDocumentWithURL:(NSURL *)docURL {
    
    NSData *file = [NSData dataWithContentsOfURL:docURL];
    NSIndexPath *cellPath = [NSIndexPath indexPathForRow:0 inSection:0];
    UITableViewCell* cell = [self tableView:self.tableView cellForRowAtIndexPath:cellPath];
    
    OneCharTextCell *delimiterCell = (OneCharTextCell *)cell;
    
    if ([delimiterCell getControlValue] == nil) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Some mandatory values are missing." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        return;
        
    } else if(![delimiterCell hasValidControlValue]) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Some values are not valid." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        return;
        
    }
    
    NSError * error = nil;
    
	NSArray * arr = [[NSArray alloc] initWithContentsOfCSVData:file encoding:NSUTF8StringEncoding delimiter:[delimiterCell getControlValue] error:&error];
    self.rowsExtracted = arr;
    [arr release];
    
    if (error) {
        NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while parsing the .csv file. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        return;
    }
    
    if([self.rowsExtracted count] > 0) {
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
    }
    
    cellPath = [NSIndexPath indexPathForRow:1 inSection:0];
    cell = [self tableView:self.tableView cellForRowAtIndexPath:cellPath];
    
    NSMutableArray * m = [NSMutableArray array];
    for (int i = 0; i < [self.rowsExtracted count]; i++) {
        [m addObject:[NSString stringWithFormat:@"%i", i+1]];
    }
    
    StringSelectionCell *rowNumberCell = (StringSelectionCell *)cell;
    [rowNumberCell changeMandatoryStatusTo:YES];
    [rowNumberCell setDataSourceArray:m];
    [rowNumberCell reload];
}

#pragma mark -
#pragma mark Cell notification

- (void) cellHasBeenEdited:(NSNotification *) notification 
{
    BaseDataEntryCell *cell = [[notification userInfo] objectForKey:@"value"];
    
    if([[self.tableView indexPathForCell:cell] row] == 1) {
        
        self.indexOfRowExtracted = [[cell getControlValue] intValue] - 1;
        NSMutableArray * mutArr = [NSMutableArray array];
        [mutArr addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"<empty>", @"label", @"<empty>", @"val", nil]];
        
        int i = 1;
        for (NSString * str in [self.rowsExtracted objectAtIndex:self.indexOfRowExtracted]) {
            NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:str, @"label", [NSString stringWithFormat:@"Col. nr %i", i++], @"val", nil];
            [mutArr addObject:dict];
        }

        for (int row = 2; row < [self.tableView numberOfRowsInSection:0]; row++) {

            NSIndexPath* cellPath = [NSIndexPath indexPathForRow:row inSection:0];
            UITableViewCell* cell = [self tableView:self.tableView cellForRowAtIndexPath:cellPath];
            LabeledStringSelectionCell *mapperCell = (LabeledStringSelectionCell *)cell;
            [mapperCell changeMandatoryStatusTo:YES];
            [mapperCell setDataSourceArray:mutArr];
            [mapperCell reload];
            
        }
        
    }
}

- (void) importFirmData
{
    for (NSString* dk in self.cells) {
        
        BaseDataEntryCell *cell = (BaseDataEntryCell *)[self.cells objectForKey:dk];
        
        id v = [cell getControlValue];

        if(v == nil && [cell isMandatory]) {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Some mandatory values are missing." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
            [alertView release];
            return;
            
        } else {
            
            ;
        }
    }
    
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    
    [self showProgressHUDWithMessage:@"Loading"];
    
    NSMutableArray * idxArr = [NSMutableArray array];
    
    for (int row = 2; row < [self.tableView numberOfRowsInSection:0]; row++) {
        
        NSIndexPath* cellPath = [NSIndexPath indexPathForRow:row inSection:0];
        UITableViewCell* cell = [self tableView:self.tableView cellForRowAtIndexPath:cellPath];
        LabeledStringSelectionCell *mapperCell = (LabeledStringSelectionCell *)cell;
        NSString * string = [mapperCell getControlValue];
        if ([string isEqualToString:@"<empty>"]) {
            [idxArr addObject:[NSNumber numberWithInt:-1]];
        } else {
            [idxArr addObject:[NSNumber numberWithInt:[[string substringFromIndex:8] intValue]-1]];
        } 
    }
    
    NSMutableDictionary *dictio = [NSMutableDictionary dictionary];
    
    for (NSArray * arr in self.rowsExtracted) {
        
        Firm *firm = [(Firm *)[[NSManagedObject alloc] initWithEntity:[self.dao getEntityDescriptionForName:@"Firm"] insertIntoManagedObjectContext:[self.dao managedObjectContext]] autorelease];
        
        int i = [[idxArr objectAtIndex:0] intValue];
        if (i != -1 && i < [arr count]) {
            [firm setFirmName:[arr objectAtIndex:i]];
        } else {
            [firm setFirmName:@""];
        }
        
        i = [[idxArr objectAtIndex:1] intValue];
        if (i != -1 && i < [arr count]) {
            [firm setStreet:[arr objectAtIndex:i]];
        } else {
            [firm setStreet:@""];
        }
        
        i = [[idxArr objectAtIndex:2] intValue];
        if (i != -1 && i < [arr count]) {
            [firm setTown:[arr objectAtIndex:i]];
        } else {
            [firm setTown:@""];
        }
        
        i = [[idxArr objectAtIndex:3] intValue];
        if (i != -1 && i < [arr count]) {
            [firm setZip:[arr objectAtIndex:i]];
        } else {
            [firm setZip:@""];
        }
        
        i = [[idxArr objectAtIndex:4] intValue];
        if (i != -1 && i < [arr count]) {
            [firm setState:[arr objectAtIndex:i]];
        } else {
            [firm setState:@""];
        }
        
        i = [[idxArr objectAtIndex:5] intValue];
        if (i != -1 && i < [arr count]) {
            [firm setCountry:[arr objectAtIndex:i]];
        } else {
            [firm setCountry:@""];
        }
        
        i = [[idxArr objectAtIndex:6] intValue];
        if (i != -1 && i < [arr count]) {
            [firm setEconSector:[arr objectAtIndex:i]];
        } else {
            [firm setEconSector:@""];
        }
        
        i = [[idxArr objectAtIndex:7] intValue];
        if (i != -1 && i < [arr count]) {
            [firm setRefFirstName:[arr objectAtIndex:i]];
        } else {
            [firm setRefFirstName:@""];
        }
        
        i = [[idxArr objectAtIndex:8] intValue];
        if (i != -1 && i < [arr count]) {
            [firm setRefSecondName:[arr objectAtIndex:i]];
        } else {
            [firm setRefSecondName:@""];
        }
        
        i = [[idxArr objectAtIndex:9] intValue];
        if (i != -1 && i < [arr count]) {
            [firm setRefRole:[arr objectAtIndex:i]];
        } else {
            [firm setRefRole:@""];
        }
        
        i = [[idxArr objectAtIndex:10] intValue];
        if (i != -1 && i < [arr count]) {
            [firm setPhoneNr1:[arr objectAtIndex:i]];
        } else {
            [firm setPhoneNr1:@""];
        }
        
        i = [[idxArr objectAtIndex:11] intValue];
        if (i != -1 && i < [arr count]) {
            [firm setPhoneNr2:[arr objectAtIndex:i]];
        } else {
            [firm setPhoneNr2:@""];
        }
        
        i = [[idxArr objectAtIndex:12] intValue];
        if (i != -1 && i < [arr count]) {
            [firm setFaxNr:[arr objectAtIndex:i]];
        } else {
            [firm setFaxNr:@""];
        }
        
        i = [[idxArr objectAtIndex:13] intValue];
        if (i != -1 && i < [arr count]) {
            [firm setEMail:[arr objectAtIndex:i]];
        } else {
            [firm setEMail:@""];
        }
        
        i = [[idxArr objectAtIndex:14] intValue];
        if (i != -1 && i < [arr count]) {
            [firm setNotes:[arr objectAtIndex:i]];
        } else {
            [firm setNotes:@""];
        }
        
        [firm setLatitude:[NSNumber numberWithDouble:-360.0]];
        [firm setLongitude:[NSNumber numberWithDouble:-360.0]];
        
        [firm setInsertDate:[NSDate date]];
        
        int counterForName;
        
        if([dictio objectForKey:firm.firmName]) {
            
            counterForName = [[dictio objectForKey:firm.firmName] intValue];
            
            counterForName++;
            
            [dictio setObject:[NSNumber numberWithInt:counterForName] forKey:firm.firmName];
            
        } else {
            
            counterForName = 1;
            
            [dictio setObject:[NSNumber numberWithInt:counterForName] forKey:firm.firmName];
        }
        
        if (counterForName > 1) {
            
            [firm setFirmName:[NSString stringWithFormat:@"%@ (%i)", firm.firmName, counterForName]];
            
        }
        
//        NSLog(@"imported firm %@", [firm description]);
        
    }
    
    [self.dao saveContext];
    
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
    
    [self hideProgressHUD:NO];
    
    [[NSNotificationCenter defaultCenter] 
     postNotificationName:ADDED_OR_EDITED_FIRM_NOTIFICATION 
     object:nil];
    
    [self getBack];
}

#pragma mark - View lifecycle

- (void)loadView {
    
    [super loadView];
    
    [self createToolbar];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.firstVisibleIndexPath = nil;
    
    self.lastVisibleIndexPath = nil;

    self.cells = [NSMutableDictionary dictionary];
    
    int rowHeight;
    
    if([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad])
        rowHeight = 120;
    else
        rowHeight = 50;
    
    [self customizeTableViewDrawingWithHeader:nil headerBg:@"bgHeaderSearch" footer:nil footerBg:@"bgFooterSearch" background:nil backgroundColor:[UIColor whiteColor] rowHeight:rowHeight headerHeight:rowHeight footerHeight:rowHeight deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
    
    UIBarButtonItem *cancelBt = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(getBack)];
    
    self.navigationItem.leftBarButtonItem = cancelBt;
    
    [cancelBt release];
    
    UIBarButtonItem *bt = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(importFirmData)];
    
    self.navigationItem.rightBarButtonItem = bt;
    
    [bt release];
    
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    
    [self createProgressHUDForView:self.tableView];
}

- (void)viewDidUnload
{
    if (self.fileBrowser) {
        self.fileBrowser.delegate = nil;
    }
    
    [self.cacheDict removeAllObjects];
    
    for (NSString *dataKey in self.cells) {
        
        BaseDataEntryCell *cell = [self.cells objectForKey:dataKey];
        
        id val = [cell getControlValue] ? [cell getControlValue] : [NSNull null];
        
        [self.cacheDict setObject:val forKey:dataKey];
        
    }
    
    self.progressHUD = nil;
    self.cells = nil;
    self.fileBrowser = nil;
    
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(cellHasBeenEdited:)
     name:CELL_ENDEDIT_NOTIFICATION_NAME
     object:nil];
    
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

-(void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    [self.navigationController setToolbarHidden:NO animated:animated];
}

- (void) viewControllerWillBePopped {
    
    [self showTabBar];
    
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:CELL_ENDEDIT_NOTIFICATION_NAME
     object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    if (viewControllers.count > 1 && [viewControllers objectAtIndex:viewControllers.count-2] == self) {
        // View is disappearing because a new view controller was pushed onto the stack
    } else if ([viewControllers indexOfObject:self] == NSNotFound) {
        // View is disappearing because it was popped from the stack
        //        NSLog(@"View controller was popped");
        [self viewControllerWillBePopped];
    }
    
    [super viewWillDisappear:animated];
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
    return 17;
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
    
    NSString *CellIdentifier;
    
    UITableViewCell *cell = nil;
    
    BOOL dequeued = NO;
    
    UIColor * color = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    
    switch (indexPath.row) {
            
        case 0:
        {
            CellIdentifier = @"0";
            
            OneCharTextCell *delimiterCell = (OneCharTextCell *)[self.cells objectForKey:CellIdentifier];
            if (delimiterCell == nil) {
                
                delimiterCell = [[[OneCharTextCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil boundClassName:nil dataKey:nil label:@"Field Separator" color:color] autorelease];
                [delimiterCell setIsAddEditCell:NO];
                [delimiterCell changeMandatoryStatusTo:YES];
                [delimiterCell setControlValue:@";"];
                [self.cells setObject:delimiterCell forKey:CellIdentifier];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [delimiterCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [delimiterCell setControlValue:nil];
                    
                }
                
            } else
                dequeued = YES;
            
            [self customizeDrawingForSearchFormCell:delimiterCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return delimiterCell;
        }
            break;
            
        case 1:
        {
            CellIdentifier = @"1";
            
            StringSelectionCell *rowNumberCell = (StringSelectionCell *)[self.cells objectForKey:CellIdentifier];
            if (rowNumberCell == nil) {
                
                rowNumberCell = [[[StringSelectionCell alloc] initWithStyle:UITableViewCellStyleDefault dataSource:nil reuseIdentifier:nil boundClassName:nil dataKey:nil label:@"Row Nr."] autorelease];
                [rowNumberCell setIsAddEditCell:NO];
                
                [self.cells setObject:rowNumberCell forKey:CellIdentifier];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [rowNumberCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [rowNumberCell setControlValue:nil];
                    
                }
                
            } else
                dequeued = YES;
            
            [self customizeDrawingForSearchFormCell:rowNumberCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return rowNumberCell;
        }
            break;
            
        case 2:
        {
            CellIdentifier = @"2";

            LabeledStringSelectionCell *mapperCell = (LabeledStringSelectionCell *)[self.cells objectForKey:CellIdentifier];
            if (mapperCell == nil) {
                
                mapperCell = [[[LabeledStringSelectionCell alloc] initWithStyle:UITableViewCellStyleDefault dataSource:nil reuseIdentifier:nil boundClassName:nil dataKey:nil label:@"Name"] autorelease];
                [mapperCell setIsAddEditCell:NO];
                
                [self.cells setObject:mapperCell forKey:CellIdentifier];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:nil];
                    
                }
                
            } else
                dequeued = YES;
            
            [self customizeDrawingForSearchFormCell:mapperCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return mapperCell;
        }
            break;
            
        case 3:
        {
            CellIdentifier = @"3";
            
            LabeledStringSelectionCell *mapperCell = (LabeledStringSelectionCell *)[self.cells objectForKey:CellIdentifier];
            if (mapperCell == nil) {
                
                mapperCell = [[[LabeledStringSelectionCell alloc] initWithStyle:UITableViewCellStyleDefault dataSource:nil reuseIdentifier:nil boundClassName:nil dataKey:nil label:@"Street"] autorelease];
                [mapperCell setIsAddEditCell:NO];
                
                [self.cells setObject:mapperCell forKey:CellIdentifier];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:nil];
                    
                }
                
            } else
                dequeued = YES;
            
            [self customizeDrawingForSearchFormCell:mapperCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return mapperCell;
        }
            break;
            
        case 4:
        {
            CellIdentifier = @"4";
            
            LabeledStringSelectionCell *mapperCell = (LabeledStringSelectionCell *)[self.cells objectForKey:CellIdentifier];
            if (mapperCell == nil) {
                
                mapperCell = [[[LabeledStringSelectionCell alloc] initWithStyle:UITableViewCellStyleDefault dataSource:nil reuseIdentifier:nil boundClassName:nil dataKey:nil label:@"Town"] autorelease];
                [mapperCell setIsAddEditCell:NO];
                
                [self.cells setObject:mapperCell forKey:CellIdentifier];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:nil];
                    
                }
                
            } else
                dequeued = YES;
             
            [self customizeDrawingForSearchFormCell:mapperCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return mapperCell;
        }
            break;
            
        case 5:
        {
            CellIdentifier = @"5";

            LabeledStringSelectionCell *mapperCell = (LabeledStringSelectionCell *)[self.cells objectForKey:CellIdentifier];
            if (mapperCell == nil) {
                
                mapperCell = [[[LabeledStringSelectionCell alloc] initWithStyle:UITableViewCellStyleDefault dataSource:nil reuseIdentifier:nil boundClassName:nil dataKey:nil label:@"ZIP Code"] autorelease];
                [mapperCell setIsAddEditCell:NO];
                
                [self.cells setObject:mapperCell forKey:CellIdentifier];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:nil];
                    
                }
                
            } else
                dequeued = YES;
            
            [self customizeDrawingForSearchFormCell:mapperCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return mapperCell;
        }
            break;
        
        case 6:
        {
            CellIdentifier = @"6";
            
            LabeledStringSelectionCell *mapperCell = (LabeledStringSelectionCell *)[self.cells objectForKey:CellIdentifier];
            if (mapperCell == nil) {
                
                mapperCell = [[[LabeledStringSelectionCell alloc] initWithStyle:UITableViewCellStyleDefault dataSource:nil reuseIdentifier:nil boundClassName:nil dataKey:nil label:@"State"] autorelease];
                [mapperCell setIsAddEditCell:NO];
                
                [self.cells setObject:mapperCell forKey:CellIdentifier];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:nil];
                    
                }
                
            } else
                dequeued = YES;
            
            [self customizeDrawingForSearchFormCell:mapperCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return mapperCell;
        }
            break;
        
        case 7:
        {
            CellIdentifier = @"7";

            LabeledStringSelectionCell *mapperCell = (LabeledStringSelectionCell *)[self.cells objectForKey:CellIdentifier];
            if (mapperCell == nil) {
                
                mapperCell = [[[LabeledStringSelectionCell alloc] initWithStyle:UITableViewCellStyleDefault dataSource:nil reuseIdentifier:nil boundClassName:nil dataKey:nil label:@"Country"] autorelease];
                [mapperCell setIsAddEditCell:NO];
                
                [self.cells setObject:mapperCell forKey:CellIdentifier];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:nil];
                    
                }
                
            } else
                dequeued = YES;
            
            [self customizeDrawingForSearchFormCell:mapperCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return mapperCell;
        }
            break;
            
        case 8:
        {
            CellIdentifier = @"8";

            LabeledStringSelectionCell *mapperCell = (LabeledStringSelectionCell *)[self.cells objectForKey:CellIdentifier];
            if (mapperCell == nil) {
                
                mapperCell = [[[LabeledStringSelectionCell alloc] initWithStyle:UITableViewCellStyleDefault dataSource:nil reuseIdentifier:nil boundClassName:nil dataKey:nil label:@"Business"] autorelease];
                [mapperCell setIsAddEditCell:NO];
                
                [self.cells setObject:mapperCell forKey:CellIdentifier];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:nil];
                    
                }
                
            } else
                dequeued = YES;
            
            [self customizeDrawingForSearchFormCell:mapperCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return mapperCell;
        }
            break;
            
        case 9:
        {
            CellIdentifier = @"9";

            LabeledStringSelectionCell *mapperCell = (LabeledStringSelectionCell *)[self.cells objectForKey:CellIdentifier];
            if (mapperCell == nil) {
                
                mapperCell = [[[LabeledStringSelectionCell alloc] initWithStyle:UITableViewCellStyleDefault dataSource:nil reuseIdentifier:nil boundClassName:nil dataKey:nil label:@"Ref. Name"] autorelease];
                [mapperCell setIsAddEditCell:NO];
                
                [self.cells setObject:mapperCell forKey:CellIdentifier];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:nil];
                    
                }
                
            } else
                dequeued = YES;
            
            [self customizeDrawingForSearchFormCell:mapperCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return mapperCell;
        }
            break;
            
        case 10:
        {
            CellIdentifier = @"10";

            LabeledStringSelectionCell *mapperCell = (LabeledStringSelectionCell *)[self.cells objectForKey:CellIdentifier];
            if (mapperCell == nil) {
                
                mapperCell = [[[LabeledStringSelectionCell alloc] initWithStyle:UITableViewCellStyleDefault dataSource:nil reuseIdentifier:nil boundClassName:nil dataKey:nil label:@"Ref. Surname"] autorelease];
                [mapperCell setIsAddEditCell:NO];
                
                [self.cells setObject:mapperCell forKey:CellIdentifier];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:nil];
                    
                }
                
            } else
                dequeued = YES;
            
            [self customizeDrawingForSearchFormCell:mapperCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return mapperCell;
        }
            break;
            
        case 11:
        {
            CellIdentifier = @"11";

            LabeledStringSelectionCell *mapperCell = (LabeledStringSelectionCell *)[self.cells objectForKey:CellIdentifier];
            if (mapperCell == nil) {
                mapperCell = [[[LabeledStringSelectionCell alloc] initWithStyle:UITableViewCellStyleDefault dataSource:nil reuseIdentifier:nil boundClassName:nil dataKey:nil label:@"Ref. Role"] autorelease];
                [mapperCell setIsAddEditCell:NO];
                
                [self.cells setObject:mapperCell forKey:CellIdentifier];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:nil];
                    
                }
                
            } else
                dequeued = YES;
            
            [self customizeDrawingForSearchFormCell:mapperCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return mapperCell;
        }
            break;
            
        case 12:
        {
            CellIdentifier = @"12";
            
            LabeledStringSelectionCell *mapperCell = (LabeledStringSelectionCell *)[self.cells objectForKey:CellIdentifier];
            if (mapperCell == nil) {
                mapperCell = [[[LabeledStringSelectionCell alloc] initWithStyle:UITableViewCellStyleDefault dataSource:nil reuseIdentifier:nil boundClassName:nil dataKey:nil label:@"Phone Nr. 1"] autorelease];
                [mapperCell setIsAddEditCell:NO];
                
                [self.cells setObject:mapperCell forKey:CellIdentifier];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:nil];
                    
                }
                
            } else
                dequeued = YES;
            
            [self customizeDrawingForSearchFormCell:mapperCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return mapperCell;
        }
            break;
            
        case 13:
        {
            CellIdentifier = @"13";
            
            LabeledStringSelectionCell *mapperCell = (LabeledStringSelectionCell *)[self.cells objectForKey:CellIdentifier];
            if (mapperCell == nil) {
                mapperCell = [[[LabeledStringSelectionCell alloc] initWithStyle:UITableViewCellStyleDefault dataSource:nil reuseIdentifier:nil boundClassName:nil dataKey:nil label:@"Phone Nr. 2"] autorelease];
                [mapperCell setIsAddEditCell:NO];
                
                [self.cells setObject:mapperCell forKey:CellIdentifier];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:nil];
                    
                }
                
            } else
                dequeued = YES;
            
            [self customizeDrawingForSearchFormCell:mapperCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return mapperCell;
        }
            break;
            
        case 14:
        {
            CellIdentifier = @"14";
            
            LabeledStringSelectionCell *mapperCell = (LabeledStringSelectionCell *)[self.cells objectForKey:CellIdentifier];
            if (mapperCell == nil) {
                mapperCell = [[[LabeledStringSelectionCell alloc] initWithStyle:UITableViewCellStyleDefault dataSource:nil reuseIdentifier:nil boundClassName:nil dataKey:nil label:@"Fax Nr."] autorelease];
                [mapperCell setIsAddEditCell:NO];
                
                [self.cells setObject:mapperCell forKey:CellIdentifier];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:nil];
                    
                }
                
            } else
                dequeued = YES;
            
            [self customizeDrawingForSearchFormCell:mapperCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return mapperCell;
        }
            break;
            
        case 15:
        {
            CellIdentifier = @"15";
            
            LabeledStringSelectionCell *mapperCell = (LabeledStringSelectionCell *)[self.cells objectForKey:CellIdentifier];
            if (mapperCell == nil) {
                mapperCell = [[[LabeledStringSelectionCell alloc] initWithStyle:UITableViewCellStyleDefault dataSource:nil reuseIdentifier:nil boundClassName:nil dataKey:nil label:@"E-mail"] autorelease];
                [mapperCell setIsAddEditCell:NO];
                
                [self.cells setObject:mapperCell forKey:CellIdentifier];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:nil];
                    
                }
                
            } else
                dequeued = YES;
            
            [self customizeDrawingForSearchFormCell:mapperCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return mapperCell;
        }
            break;
            
        case 16:
        {
            CellIdentifier = @"16";
            
            LabeledStringSelectionCell *mapperCell = (LabeledStringSelectionCell *)[self.cells objectForKey:CellIdentifier];
            if (mapperCell == nil) {
                mapperCell = [[[LabeledStringSelectionCell alloc] initWithStyle:UITableViewCellStyleDefault dataSource:nil reuseIdentifier:nil boundClassName:nil dataKey:nil label:@"Notes"] autorelease];
                [mapperCell setIsAddEditCell:NO];
                
                [self.cells setObject:mapperCell forKey:CellIdentifier];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [mapperCell setControlValue:nil];
                    
                }
                
            } else
                dequeued = YES;
            
            [self customizeDrawingForSearchFormCell:mapperCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return mapperCell;
        }
            break;
            
        default:
            break;
    }
    
    return cell;
}



@end
