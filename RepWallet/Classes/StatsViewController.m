//
//  StatsViewController.m
//  repWallet
//
//  Created by Alberto Fiore on 3/12/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "StatsViewController.h"
#import "DatePickerCell.h"
#import "FirmSelectionCell.h"
#import "SwitchCell.h"
#import "ItemCategorySuggestionCell.h"
#import "GraphView.h"
#import "AddEditViewController.h"
#include <Accelerate/Accelerate.h>
#include <stdio.h>
#include <stdlib.h>
#import "UITableViewController+CustomDrawing.h"
#import "LabeledStringSelectionCell.h"

#pragma mark -
#pragma mark C function prototypes

/* DGELS prototype */
extern void dgels( char* trans, int* m, int* n, int* nrhs, double* a, int* lda,
                  double* b, int* ldb, double* work, int* lwork, int* info );
/* Auxiliary routines prototypes */
extern void print_matrix( char* desc, int m, int n, double* a, int lda );
extern void print_vector_norm( char* desc, int m, int n, double* a, int lda );

#pragma mark -
#pragma mark Parameters

/* Parameters */
#define M 6 // numero di punti su cui faccio la regressione (6 = 6 mesi)
#define N 2 // fisso
#define NRHS 1 // fisso
#define LDA M
#define LDB M

#pragma mark -
#pragma mark C functions for linear fitting

/* linear least squares fitting */
int linearFitting(double * a, double * b) {
    /* Locals */
    __CLPK_integer m = M, n = N, nrhs = NRHS, lda = LDA, ldb = LDB, info, lwork;
    double wkopt;
    double* work;
    
    /* Executable statements */
//    printf( "DGELS Example Program Results\n" );
    /* Query and allocate the optimal workspace */
    lwork = -1;
    dgels_( "No transpose", &m, &n, &nrhs, a, &lda, b, &ldb, &wkopt, &lwork,
          &info );
    lwork = (int)wkopt;
    work = (double*)malloc( lwork*sizeof(double) );
    /* Solve the equations A*X = B */
    dgels_( "No transpose", &m, &n, &nrhs, a, &lda, b, &ldb, work, &lwork,
          &info );
    /* Check for the full rank */
    if( info > 0 ) {
//        printf( "The diagonal element %ld of the triangular factor ", info);
//        printf( "of A is zero, so that A does not have full rank;\n" );
//        printf( "the least squares solution could not be computed.\n" );
        free( (void*)work );
        return 0;
    }
    /* Print least squares solution */
//    print_matrix( "Least squares solution", n, nrhs, b, ldb );
    /* Print residual sum of squares for the solution */
//    print_vector_norm( "Residual sum of squares for the solution", m-n, nrhs,
//                      &b[n], ldb );
    /* Print details of QR factorization */
//    print_matrix( "Details of QR factorization", m, n, a, lda );
    /* Free workspace */
    free( (void*)work );
    return 1;
}

/* Auxiliary routine: printing a matrix */
void print_matrix( char* desc, int m, int n, double* a, int lda ) {
    int i, j;
    printf( "\n %s\n", desc );
    for( i = 0; i < m; i++ ) {
        for( j = 0; j < n; j++ ) printf( " %6.2f", a[i+j*lda] );
        printf( "\n" );
    }
}

/* Auxiliary routine: printing norms of matrix columns */
void print_vector_norm( char* desc, int m, int n, double* a, int lda ) {
    int i, j;
    double norm;
    printf( "\n %s\n", desc );
    for( j = 0; j < n; j++ ) {
        norm = 0.0;
        for( i = 0; i < m; i++ ) norm += a[i+j*lda] * a[i+j*lda];
        printf( " %6.2f", norm );
    }
    printf( "\n" );
}

#pragma mark -

@implementation StatsViewController

@synthesize dao;
@synthesize predictionModeIsOn;
@synthesize cells;
@synthesize cacheDict;
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


#pragma mark -
#pragma mark Initialization

- (id)initWithStyle:(UITableViewStyle)style andDao:(DAO *)dao
{
    self = [super initWithStyle:style];
    if (self) {
        self.cacheDict = [NSMutableDictionary dictionary];
        if(dao)
            self.dao = dao;
        UITabBarItem * ui = [[UITabBarItem alloc] initWithTitle:@"Statistics" image:[UIImage imageNamed:@"stats.png"] tag:0];
        self.tabBarItem = ui;
        [ui release];
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
    [self.dao release];
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

#pragma mark - Reset

- (void) resetFields {
    
    for (NSString* dk in self.cells) {
        
        BaseDataEntryCell *cell = (BaseDataEntryCell *)[self.cells objectForKey:dk];
        
        switch ([dk intValue]) {
            case 0:
            {
                DatePickerCell *startDateCell = (DatePickerCell *)cell;
                if([startDateCell getControlValue]) {
                    [startDateCell setControlValue:nil];
                }
                
            }
                break;
                
            case 1:
            {
                DatePickerCell *endDateCell = (DatePickerCell *)cell;
                if([endDateCell getControlValue]) {
                    [endDateCell setControlValue:nil];
                }
            }
                break;
                
            case 2:
            {
                FirmSelectionCell *firmPickerCell = (FirmSelectionCell *)cell;
                if ([firmPickerCell getControlValue]) {
                    [firmPickerCell setControlValue:nil];
                }
            }
                break;
                
            case 3:
            {                   
                LabeledStringSelectionCell *statsTypePickerCell = (LabeledStringSelectionCell *)cell;
                if ([statsTypePickerCell getControlValue]) {
                    [statsTypePickerCell setControlValue:nil];
                }
            }
                break;
                
            case 4:
            {                   
                ItemCategorySuggestionCell *categoryCell = (ItemCategorySuggestionCell *)cell;
                if ([categoryCell getControlValue]) {
                    [categoryCell setControlValue:nil];
                }
            }
                break;
                
            case 5:
            {
                SwitchCell *swCell = (SwitchCell *)cell;
                [swCell setControlValue:OFF_VALUE];
                predictionModeIsOn = NO;
            }
                break;
                
            default:
                break;
        }
        
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
    
    [[NSNotificationCenter defaultCenter] 
     addObserver:self 
     selector:@selector(predictionModeChanged:) 
     name:[NSString stringWithFormat:@"%@%@", NSStringFromClass([self class]), PREDICTION_MODE_SWITCH_DATAKEY] 
     object:nil];
    
    UIBarButtonItem *uibarbtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(addPlotAndShow)];
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

- (void)viewWillAppear:(BOOL)animated
{
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
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
    return 6;
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
    
    BOOL dequeued = YES;

    switch (indexPath.row) {
        case 0:
        {
            CellIdentifier = @"0";
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
       
        case 1:
        {
            CellIdentifier = @"1";
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
            
        case 2:
        {
            CellIdentifier = @"2";
            FirmSelectionCell *firmPickerCell = (FirmSelectionCell *)[self.cells objectForKey:CellIdentifier];
            if (firmPickerCell == nil) {
                firmPickerCell = [[[FirmSelectionCell alloc] initWithStyle:UITableViewCellStyleDefault dao:self.dao reuseIdentifier:nil boundClassName:NSStringFromClass([self class]) dataKey:@"firm" label:@"Customer"] autorelease];
                [firmPickerCell setIsAddEditCell:NO];
                [firmPickerCell changeMandatoryStatusTo:YES];
             
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [firmPickerCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [firmPickerCell setControlValue:nil];
                    
                }
                
                [self.cells setObject:firmPickerCell forKey:CellIdentifier];
                
                dequeued = NO;
            }
            
            [self customizeDrawingForSearchFormCell:firmPickerCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return firmPickerCell;
        }
            break;
            
        case 3:
        {
            CellIdentifier = @"3";
            NSMutableArray *statsTypeArray = [NSMutableArray arrayWithObjects:
                                              [NSDictionary dictionaryWithObjectsAndKeys:@"number of OK sales", @"label", @"numSellsOK", @"val", nil],
                                              [NSDictionary dictionaryWithObjectsAndKeys:@"time spent for OK sales", @"label", @"totMinSellsOK", @"val", nil],
                                              [NSDictionary dictionaryWithObjectsAndKeys:@"value of OK sales", @"label", @"amtSellsOK", @"val", nil],
                                              [NSDictionary dictionaryWithObjectsAndKeys:@"number of KO sales", @"label", @"numSellsKO", @"val", nil],
                                              [NSDictionary dictionaryWithObjectsAndKeys:@"time spent for KO sales", @"label", @"totMinSellsKO", @"val", nil],
                                              [NSDictionary dictionaryWithObjectsAndKeys:@"number of contacts", @"label", @"numContacts", @"val", nil],
                                              [NSDictionary dictionaryWithObjectsAndKeys:@"time spent for contacts", @"label", @"totMinContacts", @"val", nil],
                                              [NSDictionary dictionaryWithObjectsAndKeys:@"number of open unpaid invoices", @"label", @"numOpenUnpaidInv", @"val", nil],
                                              [NSDictionary dictionaryWithObjectsAndKeys:@"value of open unpaid invoices", @"label", @"amtOpenUnpaidInv", @"val", nil],
                                              [NSDictionary dictionaryWithObjectsAndKeys:@"days of open unpaid invoices", @"label", @"totDayUnresUnpaidInv", @"val", nil],
                                              [NSDictionary dictionaryWithObjectsAndKeys:@"number of closed unpaid invoices", @"label", @"numClosedUnpaidInv", @"val", nil],
                                              [NSDictionary dictionaryWithObjectsAndKeys:@"value of closed unpaid invoices", @"label", @"amtClosedUnpaidInv", @"val", nil],
                                              
                                              nil];
            
            LabeledStringSelectionCell *statsTypePickerCell = (LabeledStringSelectionCell *)[self.cells objectForKey:CellIdentifier];
            if (statsTypePickerCell == nil) {
                statsTypePickerCell = [[[LabeledStringSelectionCell alloc] initWithStyle:UITableViewCellStyleDefault dataSource:statsTypeArray reuseIdentifier:nil boundClassName:NSStringFromClass([self class]) dataKey:@"statisticType" label:@"Statistic"] autorelease];
                [statsTypePickerCell setIsAddEditCell:NO];
                [statsTypePickerCell changeMandatoryStatusTo:YES];
             
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [statsTypePickerCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [statsTypePickerCell setControlValue:nil];
                    
                }
                
                [self.cells setObject:statsTypePickerCell forKey:CellIdentifier];
                
                dequeued = NO;
            }
            
            [self customizeDrawingForSearchFormCell:statsTypePickerCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return statsTypePickerCell;
        }
            break;
            
        case 4:
        {
            CellIdentifier = @"4";
            
            ItemCategorySuggestionCell *categoryCell = (ItemCategorySuggestionCell *)[self.cells objectForKey:CellIdentifier];
            if (categoryCell == nil) {
                categoryCell = [[[ItemCategorySuggestionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil boundClassName:NSStringFromClass([self class]) dataKey:@"itemCategory" label:@"Item Category" dao:self.dao] autorelease];
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
            
        case 5:
        {
            CellIdentifier = @"5";
            SwitchCell *swCell = (SwitchCell *)[self.cells objectForKey:CellIdentifier];
            if (swCell == nil) {
                swCell = [[[SwitchCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil leftText:OFF_VALUE rightText:ON_VALUE boundClassName:NSStringFromClass([self class]) dataKey:PREDICTION_MODE_SWITCH_DATAKEY label:@"Prediction"] autorelease];
                [swCell setIsAddEditCell:NO];
                [swCell setControlValue:OFF_VALUE];
        
                id val = [self.cacheDict objectForKey:CellIdentifier];
                
                if(val && ![val isMemberOfClass:[NSNull class]]) {
                    
                    [swCell setControlValue:val];
                    
                } else if(val && [val isMemberOfClass:[NSNull class]]) {
                    
                    [swCell setControlValue:nil];
                    
                }
                
                [self.cells setObject:swCell forKey:CellIdentifier];
                
                dequeued = NO;
            
            }
            
            [self customizeDrawingForSearchFormCell:swCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return swCell;
        }
            break;
            
        default:
            break;
    }
    
    return cell;
}

#pragma mark - Graph preparation

- (void) addPlotAndShow
{
    Firm * firm = nil;
    NSNumber * startRefMonth = nil;
    NSNumber * endRefMonth = nil;
    NSNumber * startRefYear = nil;
    NSNumber * endRefYear = nil;
    ItemCategory * itemCat = nil;
    NSString * statsType = nil;
    NSString *statsLabel = nil;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSTimeZone * timeZone = [NSTimeZone localTimeZone];
    
    for (NSString* dk in self.cells) {
        
        BaseDataEntryCell *cell = (BaseDataEntryCell *)[self.cells objectForKey:dk];
        
        switch ([dk intValue]) {
            case 0:
            {
                DatePickerCell *startDateCell = (DatePickerCell *)cell;
                if([startDateCell getControlValue]) {
                    NSDateComponents *startDateComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:(NSDate *)[startDateCell getControlValue]];
                    startRefMonth = [NSNumber numberWithInt:[startDateComponents month]];
                    startRefYear = [NSNumber numberWithInt:[startDateComponents year]];
                } else {
                    NSDateComponents *startDateComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate distantPast]];
                    startRefMonth = [NSNumber numberWithInt:[startDateComponents month]];
                    startRefYear = [NSNumber numberWithInt:[startDateComponents year]];
                }
                
            }
                break;
                
            case 1:
            {
                DatePickerCell *endDateCell = (DatePickerCell *)cell;
                if([endDateCell getControlValue]) {
                    NSDateComponents *endDateComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:(NSDate *)[endDateCell getControlValue]];
                    endRefMonth = [NSNumber numberWithInt:[endDateComponents month]];
                    endRefYear = [NSNumber numberWithInt:[endDateComponents year]];
                } else {
                    NSDateComponents *endDateComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate distantFuture]];
                    endRefMonth = [NSNumber numberWithInt:[endDateComponents month]];
                    endRefYear = [NSNumber numberWithInt:[endDateComponents year]];
                }
            }
                break;
                
            case 2:
            {
                FirmSelectionCell *firmPickerCell = (FirmSelectionCell *)cell;
                firm = (Firm *)[firmPickerCell getControlValue];
            }
                break;
                
            case 3:
            {                   
                LabeledStringSelectionCell *statsTypePickerCell = (LabeledStringSelectionCell *)cell;
                statsType = [statsTypePickerCell getControlValue];
                statsLabel = [statsTypePickerCell getLabelValue];
            }
                break;
                
            case 4:
            {                   
                ItemCategorySuggestionCell *categoryCell = (ItemCategorySuggestionCell *)cell;
                itemCat = (ItemCategory *)[categoryCell getControlValue];
            }
                break;
                
            case 5:
            {
                SwitchCell *swCell = (SwitchCell *)cell;
                predictionModeIsOn = ![swCell.switchField isOn];
            }
                break;
                
            default:
                break;
        }
        
    }
    
//    NSLog(@"start y %i m %i end y %i m %i", [startRefYear intValue], [startRefMonth intValue], [endRefYear intValue], [endRefMonth intValue]);
    
    // check mandatory fields
    
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
    
    // get the stats
    
    // copy NSNumbers
    
    NSNumber * startSearchMonth = [NSNumber numberWithInt:[startRefMonth intValue]];
    NSNumber * startSearchYear  = [NSNumber numberWithInt:[startRefYear intValue]];
    NSNumber * endSearchMonth = [NSNumber numberWithInt:[endRefMonth intValue]];
    NSNumber * endSearchYear = [NSNumber numberWithInt:[endRefYear intValue]]; 
    
    if(self.predictionModeIsOn) {
        
        // set a new date interval where to search for stats (from six month ago to first day of next month - from where we'll calculate the stats)
        // first day of this month
        
        NSDateComponents *comp = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:[NSDate date]];
        [comp setDay:1];
        NSDate *firstDayOfMonthDate = [calendar dateFromComponents:comp];
        
        // now let's substract 5 (!) months
        
        int monthsToSubstract = -5; 
        
        comp = [[[NSDateComponents alloc] init] autorelease];
        [comp setMonth:monthsToSubstract];
        
        NSDate *newStartDate = [calendar dateByAddingComponents:comp toDate:firstDayOfMonthDate options:0];
        
        NSDateComponents *newStartDateComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:newStartDate];
        startSearchMonth = [NSNumber numberWithInt:[newStartDateComponents month]];
        startSearchYear = [NSNumber numberWithInt:[newStartDateComponents year]];
        
        //        NSLog(@"new start date %@/%@", startSearchMonth, startSearchYear);
        
        NSDateComponents *endDateComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
        endSearchMonth = [NSNumber numberWithInt:[endDateComponents month]];
        endSearchYear = [NSNumber numberWithInt:[endDateComponents year]];
        
    }
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease]; 
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Statistic" inManagedObjectContext:self.dao.managedObjectContext]; 
    [request setEntity:entity];
    
    NSPredicate *predicate = nil;
    NSError *error = nil;
    NSMutableArray *statsArray = nil;
    
    if (itemCat != nil && firm != nil) {
        
        if ([startSearchYear intValue] != [endSearchYear intValue]) {
            predicate = [NSPredicate predicateWithFormat: @"firm == %@ AND ((refMonth >= %@ AND refYear == %@) OR (refMonth <= %@ AND refYear == %@) OR (refYear > %@ AND refYear < %@)) AND itemCategory == %@", 
                         firm, 
                         startSearchMonth, startSearchYear,
                         endSearchMonth, endSearchYear,
                         startSearchYear, endSearchYear,
                         itemCat];
        } else {
            predicate = [NSPredicate predicateWithFormat: @"firm == %@ AND (refYear == %@ AND refMonth <= %@ AND refMonth >= %@)  AND itemCategory == %@", 
                         firm, 
                         startSearchYear,
                         endSearchMonth,
                         startSearchMonth,
                         itemCat];
        }
        
    } else if(itemCat == nil && firm != nil) {
        
        if ([startSearchYear intValue] != [endSearchYear intValue]) {
            predicate = [NSPredicate predicateWithFormat: @"firm == %@ AND ((refMonth >= %@ AND refYear == %@) OR (refMonth <= %@ AND refYear == %@) OR (refYear > %@ AND refYear < %@))", 
                         firm, 
                         startSearchMonth, startSearchYear,
                         endSearchMonth, endSearchYear,
                         startSearchYear, endSearchYear];
        } else {
            predicate = [NSPredicate predicateWithFormat: @"firm == %@ AND (refYear == %@ AND refMonth <= %@ AND refMonth >= %@)", 
                         firm, 
                         startSearchYear,
                         endSearchMonth,
                         startSearchMonth];
        }
        
        
    } else if(itemCat != nil && firm == nil) {
        
        if ([startSearchYear intValue] != [endSearchYear intValue]) {
            predicate = [NSPredicate predicateWithFormat: @"(refMonth >= %@ AND refYear == %@) OR (refMonth <= %@ AND refYear == %@) OR (refYear > %@ AND refYear < %@) AND itemCategory == %@", 
                         startSearchMonth, startSearchYear,
                         endSearchMonth, endSearchYear,
                         startSearchYear, endSearchYear,
                         itemCat];
        } else {
            predicate = [NSPredicate predicateWithFormat: @"(refYear == %@ AND refMonth <= %@ AND refMonth >= %@) AND itemCategory == %@", 
                         startSearchYear,
                         endSearchMonth,
                         startSearchMonth,
                         itemCat];
        }
        
    } else if(itemCat == nil && firm == nil) {
        
        if ([startSearchYear intValue] != [endSearchYear intValue]) {
            predicate = [NSPredicate predicateWithFormat: @"(refMonth >= %@ AND refYear == %@) OR (refMonth <= %@ AND refYear == %@) OR (refYear > %@ AND refYear < %@)", 
                         startSearchMonth, startSearchYear,
                         endSearchMonth, endSearchYear,
                         startSearchYear, endSearchYear];
        } else {
            predicate = [NSPredicate predicateWithFormat: @"(refYear == %@ AND refMonth <= %@ AND refMonth >= %@)", 
                         startSearchYear,
                         endSearchMonth,
                         startSearchMonth];
        }
        
    } else
        ;
    
    //    NSLog(@"executing predicate %@", [predicate description]);
    
    [request setPredicate:predicate];
    
    NSSortDescriptor *sortMonthDescriptor = [[NSSortDescriptor alloc] initWithKey:@"refMonth" ascending:YES];
    NSSortDescriptor *sortYearDescriptor = [[NSSortDescriptor alloc] initWithKey:@"refYear" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortMonthDescriptor,sortYearDescriptor, nil]; 
    [request setSortDescriptors:sortDescriptors]; 
    [sortDescriptors release]; 
    [sortMonthDescriptor release];
    [sortYearDescriptor release];
    
    statsArray = [[[self.dao.managedObjectContext executeFetchRequest:request error:&error] mutableCopy] autorelease];
    
    if (statsArray == nil) {
        NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while retrieving the application data. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        
    } else if([statsArray count] == 0){
        
        NSString *msg = @"No statistics have been found.";
        
        if (self.predictionModeIsOn) {
            
            msg = @"No statistics in the past 6 months have been found.";
        }
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        return;
    }
    
    //    for (Statistic * st in statsArray) {
    //        NSLog(@"fetched stat: %@", [st description]);
    //    }
    
    
    NSMutableArray * dataForPlot = [self fromStatsToDataSeries:statsArray forStatType:statsType];
    
    if(self.predictionModeIsOn 
       && [dataForPlot count] == 6
       ) {
        
        // let's get the linear regression rect parameter (a, b)
        //
        //        Example:
        //
        //        double a[LDA*N] = {
        //            1.00, 1.00, 1.00, 1.00, 1.00, 1.00,
        //            1.00, 2.00, 3.00, 4.00, 5.00, 6.00
        //        };
        //        double b[LDB*NRHS] = {
        //            1.00, 2.00, 3.00, 4.00, 5.00, 6.00
        //        };
        //        linearFitting(a, b);
        
        
        // i valori futuri (e non) li computo sempre con x >= 1
        
        double a[LDA*N] = {
            1.00, 1.00, 1.00, 1.00, 1.00, 1.00,
            -5.00, -4.00, -3.00, -2.00, -1.00, 0.00
        };
        
        double b[LDB*NRHS];
        
        int i = 0;
        
        for (NSMutableDictionary * dict in dataForPlot) {
            NSNumber * val = (NSNumber *)[dict objectForKey:@"val"];
            //            NSString * label = (NSString *)[dict objectForKey:@"label"];
            //            NSLog(@"input data for regression: i = %i b[i] = %f label = %@", i, [val doubleValue], label);
            b[i] = [val doubleValue];
            i++;
        }
        
        if(linearFitting(a, b) == 0) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was a problem while calculating predictions." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
            [alertView release];
            return;
        }
        
        // let's calculate future values ...
        
        // calculate months diff from endSearchDate and startRefDate
        
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateFormat:@"yyyy-MM-dd ZZZ"];
        [dateFormatter setTimeZone:timeZone];
        NSString* fromDateString = [NSString stringWithFormat:@"%04d-%02d-%02d +000", [endSearchYear intValue] , [endSearchMonth intValue], 1];
        NSDate *fromDate = [dateFormatter dateFromString:fromDateString];
        NSString* toDateString = [NSString stringWithFormat:@"%04d-%02d-%02d +000", [startRefYear intValue] , [startRefMonth intValue], 1];
        NSDate *toDate = [dateFormatter dateFromString:toDateString];
        NSDateComponents *components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
                                                   fromDate:fromDate
                                                     toDate:toDate
                                                    options:0];
        
        int monthOffset = [components month];
        
        dataForPlot = [NSMutableArray array];
        
        int month = [startRefMonth intValue];
        int year = [startRefYear intValue];
        
        for (i = 0; true; i++) {
            
            if((month + i) % 12 == 0) 
                month = 12;
            else
                month = ([startRefMonth intValue] + i) % 12;
            
            if(month == 1) 
                year =  year + 1;
            else
                ;
            
            if (
                year > [endRefYear intValue]
                ||
                (year == [endRefYear intValue]
                 &&
                 month > [endRefMonth intValue])
                ) 
                break;
            
            // linear regression values
            
            double y = b[1] * (i + monthOffset) + b[0];
            NSString * label = [NSString stringWithFormat:@"%i/%i", month, year];
            NSNumber * val = [NSNumber numberWithDouble:y];
            //            NSLog(@"future value: x = %i y = %f label = %@", i + monthOffset, y, label);
            [dataForPlot addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:label, @"label", val, @"val", nil]];
        }
        
        // ... and let's pass them to GraphView
        
        GraphView * gView = [[GraphView alloc] initWithLabelsAndValues:dataForPlot];
        [gView setTitle:[NSString stringWithFormat:@"%@ - %@", firm.firmName, statsLabel]];
        [self.navigationController pushViewController:gView animated:YES];
        [gView release];
        
    } else if(self.predictionModeIsOn 
              && [dataForPlot count] != 6
              ) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"You need to collect statistics for the past 6 months to make a prediction." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        return;
        
    } else {
        
        GraphView * gView = [[GraphView alloc] initWithLabelsAndValues:dataForPlot];
        [gView setTitle:[NSString stringWithFormat:@"%@ - %@", firm.firmName, statsLabel]];
        [self.navigationController pushViewController:gView animated:YES];
        [gView release];
        
    }
    
}


- (NSMutableArray *)fromStatsToDataSeries:(NSMutableArray *)stats forStatType:(NSString *)statType
{
    NSMutableArray * data = [NSMutableArray array];
    
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    
    for (Statistic * stat in stats) {
        // dict - dizionario con key: 'anno/mese'
        // faccio un groupBy su key e la somma dei valori
        // stats arriva già ordinato per mese e anno e così dovrà essere l'array data!
        // e passo data a GraphView...
        NSString * key = [NSString stringWithFormat:@"%@/%@", [stat refMonth], [stat refYear]];
        
        if([dict objectForKey:key] == nil)
            
            [dict setObject:(NSNumber *)[stat valueForKey:statType] forKey:key];
        
        else {
            
            NSNumber * num = (NSNumber *)[dict objectForKey:key];
            num = [NSNumber numberWithDouble:[num doubleValue] + [(NSNumber *)[stat valueForKey:statType] doubleValue]];
            [dict setObject:num forKey:key];
        }
    }
    
    for (id key in dict) {
        id val = [dict objectForKey:key];
        //        NSLog(@"aggregated value for stat type %@, period %@: %@", statType, key, val);
        [data addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:key, @"label", val, @"val", nil]];
    }
    
    // sort data
    
    NSArray *sortedArray;
    sortedArray = [data sortedArrayUsingComparator:^(id a, id b) {
        NSMutableDictionary *first = (NSMutableDictionary *)a;
        NSMutableDictionary *second = (NSMutableDictionary *)b;
        
        NSString * firstLabel = (NSString *)[first objectForKey:@"label"];
        NSArray *firstLabelTokens = [firstLabel componentsSeparatedByString:@"/"];
        int firstMonth = [[firstLabelTokens objectAtIndex:0] intValue];
        int firstYear = [[firstLabelTokens objectAtIndex:1] intValue];
        
        NSString * secondLabel = (NSString *)[second objectForKey:@"label"];
        NSArray *secondLabelTokens = [secondLabel componentsSeparatedByString:@"/"];
        int secondMonth = [[secondLabelTokens objectAtIndex:0] intValue];
        int secondYear = [[secondLabelTokens objectAtIndex:1] intValue];
        
        if(firstMonth == secondMonth && firstYear == secondYear)
            return NSOrderedSame;
        else if(
                firstYear < secondYear
                ||
                (firstMonth < secondMonth && firstYear == secondYear)
                )
            return NSOrderedAscending;
        else if(firstYear > secondYear
                ||
                (firstMonth > secondMonth && firstYear == secondYear)
                )
            return NSOrderedDescending;
        else;
        
        return NSOrderedSame;
    }];
    
    //    for (int i = 0; i < [sortedArray count]; i++) {
    //        NSDictionary * dict = [sortedArray objectAtIndex:i];
    //        NSLog(@"sortedArray element: %@ %@",[dict objectForKey:@"label"],[dict objectForKey:@"val"]);
    //    }
    
    return [[sortedArray mutableCopy] autorelease];
}


#pragma mark - Switch cell callback

- (void)predictionModeChanged:(NSNotification *)notification 
{
    DatePickerCell * startDateCell = (DatePickerCell *)[self tableView:self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    DatePickerCell * endDateCell = (DatePickerCell *)[self tableView:self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    
    if([[[notification userInfo] objectForKey:@"value"] isEqualToString:OFF_VALUE]) {
        
        [startDateCell setMinDate:nil maxDate:nil];
        [startDateCell changeMandatoryStatusTo:NO];
        [endDateCell setMinDate:nil maxDate:nil];
        [endDateCell changeMandatoryStatusTo:NO];
        
    } else {

        // first day of this month
        
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *comp = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:[NSDate date]];
        [comp setDay:1];
        NSDate *firstDayOfMonthDate = [calendar dateFromComponents:comp];
        
        // now let's add 1 month
        
        int monthsToAdd = 1; 
        
        comp = [[[NSDateComponents alloc] init] autorelease];
        [comp setMonth:monthsToAdd];
        
        NSDate *firstDayOfNextMonthDate = [calendar dateByAddingComponents:comp toDate:firstDayOfMonthDate options:0];
        
        [startDateCell setMinDate:firstDayOfNextMonthDate maxDate:nil];

        [endDateCell setMinDate:firstDayOfNextMonthDate maxDate:nil];
        
        // reset vals
        
        if([startDateCell getControlValue])
            [startDateCell setControlValue:firstDayOfNextMonthDate];
        
        if([endDateCell getControlValue])
            [endDateCell setControlValue:firstDayOfNextMonthDate];
        
        [startDateCell changeMandatoryStatusTo:YES];
        [endDateCell changeMandatoryStatusTo:YES];
    }
    
}

@end
