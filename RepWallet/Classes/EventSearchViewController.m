//
//  EventSearchViewController.m
//  repWallet
//
//  Created by Alberto Fiore on 1/25/13.
//  Copyright (c) 2013 Alberto Fiore. All rights reserved.
//

#import "EventSearchViewController.h"
#import "DatePickerCell.h"
#import "FirmSelectionCell.h"
#import "SwitchCell.h"
#import "LabeledStringSelectionCell.h"
#import "ItemCategorySuggestionCell.h"
#import "UITableViewController+CustomDrawing.h"
#import "NumberCell.h"
#import "SwitchCell.h"
#import "BusinessCategorySuggestionCell.h"

@implementation EventSearchViewController

@synthesize cells;
@synthesize cacheDict;
@synthesize dao;
@synthesize delegate;
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


- (BOOL) checkFieldValidationConstraints 
{    
    for (NSString* key in self.cells) {
        if (![[self.cells objectForKey:key] hasValidControlValue]) {
            return NO;
        }
    }
    
    return YES;
}

#pragma mark -
#pragma mark Initialization

- (id)initWithStyle:(UITableViewStyle)style andDao:(DAO *)dao
{
    self = [super initWithStyle:style];
    
    if (self) {
        
        if(dao)
            self.dao = dao;
        
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
    [self.dao release];
    [self.cacheDict release];
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

#pragma mark - Send

- (void) send {
    
    BOOL isDataValid = [self checkFieldValidationConstraints];
    
    if(!isDataValid) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Some values are not valid." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
        return;
    }
    
    NSString *type = nil;
    
    NSString *result = nil;
    
    NSDate *startDate = nil;
    
    NSDate *endDate = nil;
    
    ItemCategory *category = nil;
    
    NSNumber *minDuration = nil;
    
    NSNumber *maxDuration = nil;
    
    NSNumber *minValue = nil;
    
    NSNumber *maxValue = nil;
    
    for (NSString* dk in self.cells) {
        
        BaseDataEntryCell *cell = (BaseDataEntryCell *)[self.cells objectForKey:dk];
        
        switch ([dk intValue]) {
                
            case 0:
            {
                LabeledStringSelectionCell *typeCell = (LabeledStringSelectionCell *)cell;
                type = [typeCell getControlValue];                
            }
                break;
                
            case 1:
            {
                LabeledStringSelectionCell *resultCell = (LabeledStringSelectionCell *)cell;
                result = [resultCell enabledCell] ? [resultCell getControlValue] : nil;
            }
                break;
                
            case 2:
            {
                DatePickerCell *startDateCell = (DatePickerCell *)cell;
                startDate = [startDateCell getControlValue];                
            }
                break;
                
            case 3:
            {
                DatePickerCell *endDateCell = (DatePickerCell *)cell;
                endDate = [endDateCell getControlValue];
            }
                break;
                
            case 4:
            {                   
                NumberCell *minDurationCell = (NumberCell *)cell;
                minDuration = [minDurationCell enabledCell] ? [minDurationCell getControlValue] : nil;
            }
                break;
                
            case 5:
            {                   
                NumberCell *maxDurationCell = (NumberCell *)cell;
                maxDuration = [maxDurationCell enabledCell] ? [maxDurationCell getControlValue] : nil;
            }
                break;
                
            case 6:
            {                   
                NumberCell *minValueCell = (NumberCell *)cell;
                minValue = [minValueCell enabledCell] ? [minValueCell getControlValue] : nil;
            }
                break;
                
            case 7:
            {                   
                NumberCell *maxValueCell = (NumberCell *)cell;
                maxValue = [maxValueCell enabledCell] ? [maxValueCell getControlValue] : nil;
            }
                break;
                
            case 8:
            {                   
                ItemCategorySuggestionCell *categoryCell = (ItemCategorySuggestionCell *)cell;
                category = [categoryCell getControlValue];
            }
                break;
                
            default:
                break;
        }
        
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(eventSearchControllerFilteredEventsOfType:result:startDate:endDate:itemCategory:minDuration:maxDuration:minValue:maxValue:)]) {
        [self.delegate eventSearchControllerFilteredEventsOfType:type result:result startDate:startDate endDate:endDate itemCategory:category minDuration:minDuration maxDuration:maxDuration minValue:minValue maxValue:maxValue];
    }
    
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else if ([self respondsToSelector:@selector(dismissModalViewControllerAnimated:)]) {
        [self dismissModalViewControllerAnimated:YES];
    } 
    
}


#pragma mark - Reset

- (void) resetFields {
    
    for (NSString* dk in self.cells) {
        
        BaseDataEntryCell *cell = (BaseDataEntryCell *)[self.cells objectForKey:dk];
        
        switch ([dk intValue]) {
                
            case 0:
            {
                LabeledStringSelectionCell *typeCell = (LabeledStringSelectionCell *)cell;
                if([typeCell getControlValue]) {
                    [typeCell setControlValue:nil];
                }
                
            }
                break;
                
            case 1:
            {
                LabeledStringSelectionCell *resultCell = (LabeledStringSelectionCell *)cell;
                if([resultCell getControlValue]) {
                    [resultCell setControlValue:nil];
                }
                [resultCell setEnabled:NO];
            }
                break;
                
            case 2:
            {
                DatePickerCell *startDateCell = (DatePickerCell *)cell;
                if([startDateCell getControlValue]) {
                    [startDateCell setControlValue:nil];
                }
                
            }
                break;
                
            case 3:
            {
                DatePickerCell *endDateCell = (DatePickerCell *)cell;
                if([endDateCell getControlValue]) {
                    [endDateCell setControlValue:nil];
                }
            }
                break;

            case 4:
            {                   
                NumberCell *minDurationCell = (NumberCell *)cell;
                if ([minDurationCell getControlValue]) {
                    [minDurationCell setControlValue:nil];
                }
                
                if (![minDurationCell hasValidControlValue]) {
                    [minDurationCell clearField];
                    [minDurationCell removeRedAlert];
                }
                
                [minDurationCell setEnabled:YES];
            }
                break;
                
            case 5:
            {                   
                NumberCell *maxDurationCell = (NumberCell *)cell;
                if ([maxDurationCell getControlValue]) {
                    [maxDurationCell setControlValue:nil];
                }
                
                if (![maxDurationCell hasValidControlValue]) {
                    [maxDurationCell clearField];
                    [maxDurationCell removeRedAlert];
                }
                
                [maxDurationCell setEnabled:YES];
            }
                break;
                
            case 6:
            {                   
                NumberCell *minValueCell = (NumberCell *)cell;
                if ([minValueCell getControlValue]) {
                    [minValueCell setControlValue:nil];
                }
                
                if (![minValueCell hasValidControlValue]) {
                    [minValueCell clearField];
                    [minValueCell removeRedAlert];
                }
                
                [minValueCell setEnabled:NO];
            }
                break;
                
            case 7:
            {                   
                NumberCell *maxValueCell = (NumberCell *)cell;
                if ([maxValueCell getControlValue]) {
                    [maxValueCell setControlValue:nil];
                }
                
                if (![maxValueCell hasValidControlValue]) {
                    [maxValueCell clearField];
                    [maxValueCell removeRedAlert];
                }
                
                [maxValueCell setEnabled:NO];
            }
                break;
                
            case 8:
            {                   
                ItemCategorySuggestionCell *categoryCell = (ItemCategorySuggestionCell *)cell;
                if ([categoryCell getControlValue]) {
                    [categoryCell setControlValue:nil];
                }
            }
                break;

            default:
                break;
        }
        
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(eventSearchControllerReset)]) {
        [self.delegate eventSearchControllerReset];
    }
}

#pragma mark - View lifecycle

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
    
    UIBarButtonItem *uibarbtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(send)];
    self.navigationItem.rightBarButtonItem = uibarbtn; 
    [uibarbtn release];
    UIBarButtonItem *uibarbtn2 = [[UIBarButtonItem alloc] initWithTitle:@"Reset" style:UIBarButtonItemStyleBordered target:self action:@selector(resetFields)];
    self.navigationItem.leftBarButtonItem = uibarbtn2;
    [uibarbtn2 release];
}

- (void)viewDidUnload
{
    // save modified props into the cache
    
    [self.cacheDict removeAllObjects];
    
    for (NSString *dataKey in self.cells) {
        
        BaseDataEntryCell *cell = [self.cells objectForKey:dataKey];
        
        id val = [cell getControlValue] ? [cell getControlValue] : [NSNull null];
        
        [self.cacheDict setObject:val forKey:dataKey];
        
    }
    
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
    return 9;
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
    
    UIColor * color = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    
    NSString *CellIdentifier;
    
    UITableViewCell *cell = nil;
    
    BOOL dequeued = YES;
    
    switch (indexPath.row) {
        
        case 0:
        {
            CellIdentifier = @"0";
            
            NSMutableArray *typeArray = [NSMutableArray arrayWithObjects:
                                              [NSDictionary dictionaryWithObjectsAndKeys:@"sale", @"label", EVENT_SUBJECT_SELL, @"val", nil],
                                              [NSDictionary dictionaryWithObjectsAndKeys:@"contact", @"label", EVENT_SUBJECT_CONTACT, @"val", nil],                                              
                                              nil];
            
            LabeledStringSelectionCell *typeCell = (LabeledStringSelectionCell *)[self.cells objectForKey:CellIdentifier];
            
            if (typeCell == nil) {

                typeCell = [[[LabeledStringSelectionCell alloc] initWithStyle:UITableViewCellStyleDefault dataSource:typeArray reuseIdentifier:nil boundClassName:NSStringFromClass([self class]) dataKey:@"type" label:@"Event Type"] autorelease];
                
                [typeCell setIsAddEditCell:NO];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [typeCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [typeCell setControlValue:nil];
                    
                }
                
                [self.cells setObject:typeCell forKey:CellIdentifier];
                
                dequeued = NO;
            }
            
            [self customizeDrawingForSearchFormCell:typeCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return typeCell;
        }
            break;
            
        case 1:
        {
            CellIdentifier = @"1";
            
            NSMutableArray *resultArray = [NSMutableArray arrayWithObjects:
                                         [NSDictionary dictionaryWithObjectsAndKeys:EVENT_RESULT_SELL_OK, @"label", EVENT_RESULT_SELL_OK, @"val", nil],
                                         [NSDictionary dictionaryWithObjectsAndKeys:EVENT_RESULT_SELL_KO, @"label", EVENT_RESULT_SELL_KO, @"val", nil],                                              
                                         nil];
            
            LabeledStringSelectionCell *resultCell = (LabeledStringSelectionCell *)[self.cells objectForKey:CellIdentifier];
            
            if (resultCell == nil) {
                
                resultCell = [[[LabeledStringSelectionCell alloc] initWithStyle:UITableViewCellStyleDefault dataSource:resultArray reuseIdentifier:nil boundClassName:NSStringFromClass([self class]) dataKey:@"result" label:@"Event Result"] autorelease];
                
                [resultCell setIsAddEditCell:NO];
                
                [resultCell setDisablingDK:@"type" forValue:EVENT_SUBJECT_CONTACT];
                
                [resultCell setEnabled:NO];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [resultCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [resultCell setControlValue:nil];
                    
                }
                
                [self.cells setObject:resultCell forKey:CellIdentifier];
                
                dequeued = NO;
            }
            
            [self customizeDrawingForSearchFormCell:resultCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return resultCell;
        }
            break;
            
        case 2:
        {
            CellIdentifier = @"2";
            
            DatePickerCell *startDateCell = (DatePickerCell *)[self.cells objectForKey:CellIdentifier];
            
            if (startDateCell == nil) {
                
                startDateCell = [[[DatePickerCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil minDate:nil maxDate:nil datePickerMode:UIDatePickerModeDate boundClassName:NSStringFromClass([self class]) dataKey:@"startDate" label:@"Start Date"] autorelease];
                [startDateCell setIsAddEditCell:NO];
                [startDateCell setConnectedDatePickerWithDK:@"endDate" controlMode:@"Before"];

                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [startDateCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [startDateCell setControlValue:nil];
                }
                
                [self.cells setObject:startDateCell forKey:CellIdentifier];

                dequeued = NO;
            }
            
            [self customizeDrawingForSearchFormCell:startDateCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return startDateCell;
        }
            break;
            
        case 3:
        {
            CellIdentifier = @"3";
            
            DatePickerCell *endDateCell = (DatePickerCell *)[self.cells objectForKey:CellIdentifier];
            
            if (endDateCell == nil) {
                
                endDateCell = [[[DatePickerCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil minDate:nil maxDate:nil datePickerMode:UIDatePickerModeDate boundClassName:NSStringFromClass([self class]) dataKey:@"endDate" label:@"End Date"] autorelease];
                [endDateCell setIsAddEditCell:NO];
                [endDateCell setConnectedDatePickerWithDK:@"startDate" controlMode:@"After"];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [endDateCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [endDateCell setControlValue:nil];
                    
                }
                
                [self.cells setObject:endDateCell forKey:CellIdentifier];
                
                dequeued = NO;
            }
            
            [self customizeDrawingForSearchFormCell:endDateCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return endDateCell;
        }
            break;
            
        case 4:
        {
            CellIdentifier = @"4";
            
            NumberCell *minDurationCell = (NumberCell *)[self.cells objectForKey:CellIdentifier];
            
            if (minDurationCell == nil) {
                
                minDurationCell = [[[NumberCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil boundClassName:NSStringFromClass([self class]) dataKey:@"minDuration" label:@"Min Duration" color:color] autorelease];
                
                [minDurationCell setLowerLimitnumber:[NSNumber numberWithInt:0]];
                
                [minDurationCell setIsAddEditCell:NO];
                
                [minDurationCell setConnectedNumberCellWithDK:@"maxDuration" controlMode:@"LowerThanOrEqual"];
                
                [minDurationCell setDisablingDK:@"type" forValue:EVENT_SUBJECT_SELL];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [minDurationCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [minDurationCell setControlValue:nil];
                    
                }
                
                [self.cells setObject:minDurationCell forKey:CellIdentifier];
                
                dequeued = NO;
                
            }
            
            [self customizeDrawingForSearchFormCell:minDurationCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return minDurationCell;
        }
            break;
            
        case 5:
        {
            CellIdentifier = @"5";
            
            NumberCell *maxDurationCell = (NumberCell *)[self.cells objectForKey:CellIdentifier];
            
            if (maxDurationCell == nil) {
                
                maxDurationCell = [[[NumberCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil boundClassName:NSStringFromClass([self class]) dataKey:@"maxDuration" label:@"Max Duration" color:color]  autorelease];
                
                [maxDurationCell setLowerLimitnumber:[NSNumber numberWithInt:0]];
                
                [maxDurationCell setIsAddEditCell:NO];
                
                [maxDurationCell setConnectedNumberCellWithDK:@"minDuration" controlMode:@"HigherThanOrEqual"];
                
                [maxDurationCell setDisablingDK:@"type" forValue:EVENT_SUBJECT_SELL];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [maxDurationCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [maxDurationCell setControlValue:nil];
                    
                }
                
                [self.cells setObject:maxDurationCell forKey:CellIdentifier];
                
                dequeued = NO;
                
            }
            
            [self customizeDrawingForSearchFormCell:maxDurationCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return maxDurationCell;
        }
            break;
            
        case 6:
        {
            CellIdentifier = @"6";
            
            NumberCell *minValueCell = (NumberCell *)[self.cells objectForKey:CellIdentifier];
            
            if (minValueCell == nil) {
                
                minValueCell = [[[NumberCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil boundClassName:NSStringFromClass([self class]) dataKey:@"minValue" label:@"Min Value" color:color] autorelease];
                
                [minValueCell setDisablingDK:@"type" forValue:EVENT_SUBJECT_CONTACT];
                
                [minValueCell setLowerLimitnumber:[NSNumber numberWithInt:0]];
                
                [minValueCell setIsAddEditCell:NO];
                
                [minValueCell setConnectedNumberCellWithDK:@"maxValue" controlMode:@"LowerThanOrEqual"];
                
                [minValueCell setEnabled:NO];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [minValueCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [minValueCell setControlValue:nil];
                    
                }
                
                [self.cells setObject:minValueCell forKey:CellIdentifier];
                
                dequeued = NO;
                
            }
            
            [self customizeDrawingForSearchFormCell:minValueCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return minValueCell;
        }
            break;
            
        case 7:
        {
            CellIdentifier = @"7";
            
            NumberCell *maxValueCell = (NumberCell *)[self.cells objectForKey:CellIdentifier];
            
            if (maxValueCell == nil) {
                
                maxValueCell = [[[NumberCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil boundClassName:NSStringFromClass([self class]) dataKey:@"maxValue" label:@"Max Value" color:color]  autorelease];
                
                [maxValueCell setDisablingDK:@"type" forValue:EVENT_SUBJECT_CONTACT];
                
                [maxValueCell setLowerLimitnumber:[NSNumber numberWithInt:0]];
                
                [maxValueCell setIsAddEditCell:NO];
                
                [maxValueCell setConnectedNumberCellWithDK:@"minValue" controlMode:@"HigherThanOrEqual"];
                
                [maxValueCell setEnabled:NO];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [maxValueCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [maxValueCell setControlValue:nil];
                    
                }
                
                [self.cells setObject:maxValueCell forKey:CellIdentifier];
                
                dequeued = NO;
                
            }
            
            [self customizeDrawingForSearchFormCell:maxValueCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return maxValueCell;
        }
            break;
            
        case 8:
        {
            CellIdentifier = @"8";
            
            ItemCategorySuggestionCell *categoryCell = (ItemCategorySuggestionCell *)[self.cells objectForKey:CellIdentifier];
            
            if (categoryCell == nil) {
                
                categoryCell = [[[ItemCategorySuggestionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil boundClassName:NSStringFromClass([self class]) dataKey:nil label:@"Item Category" dao:self.dao] autorelease];
                [categoryCell setIsAddEditCell:NO];
                
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [categoryCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [categoryCell setControlValue:nil];
                    
                }
                
                [self.cells setObject:categoryCell forKey:CellIdentifier];
                
                dequeued = NO;
            }
            
            [self customizeDrawingForSearchFormCell:categoryCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return categoryCell;
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
