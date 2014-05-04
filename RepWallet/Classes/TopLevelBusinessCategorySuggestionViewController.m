//
//  TopLevelBusinessCategorySuggestionViewController.m
//  repWallet
//
//  Created by Alberto Fiore on 12/4/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//

#import "TopLevelBusinessCategorySuggestionViewController.h"
#import "RepWalletAppDelegate.h"
#import "ItemCategorySuggestionViewController.h"
#import "LowLevelBusinessCategorySuggestionViewController.h"

@implementation TopLevelBusinessCategorySuggestionViewController

@synthesize businessCategories;
@synthesize dataSourceArray;
@synthesize dao;
@synthesize filteredDataSourceArray;
@synthesize tableView;
@synthesize tableViewStyle;
@synthesize isFiltered;
@synthesize dataKey;
@synthesize boundClassName;
@synthesize searchBar;
@synthesize searchTxt;

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

-(void)insertParentBCat 
{
    int i = 0;
    
    for (BusinessCategory *b in self.dataSourceArray) {
        
        if ([b.businessCategoryCode hasPrefix:@"#"]) {
            
            int pCode = [[b.businessCategoryCode substringFromIndex:1] intValue];
            
            if (pCode > i) {
                i = pCode;
            }
        }
    }
    
    BusinessCategory *b = [[BusinessCategory alloc] initWithCode:[NSString stringWithFormat:@"#%i", i+1] parentCode:nil description:self.searchTxt];
    
    [self.businessCategories addObject:b];
    
    NSDictionary* dict = [NSDictionary dictionaryWithObject:b forKey:@"value"];
    [[NSNotificationCenter defaultCenter] 
     postNotificationName:
     [NSString stringWithFormat:@"%@%@%@", self.boundClassName, self.dataKey, INSERTED_PARENT_BUSINESS_CATEGORY_SUGGESTION]
     object:nil 
     userInfo:dict];
    
    [b release];
    [self reloadTable];
}

- (id)initWithStyle:(UITableViewStyle)style dao:(DAO *)aDao businessCategories:(NSMutableArray *)businessCategories boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey
{
    self = [super init];
    
    if (self) {
        
        shouldBeginEditing = YES;
        
        self.searchTxt = nil;
        
        self.businessCategories = businessCategories;
        
        self.boundClassName = boundClassName;
        self.dataKey = dataKey;
        
        self.dao = aDao;
        self.tableViewStyle = style;
        
    }
    
    return self;
}

-(void)updateFilteredData:(NSString *)filterString {
    
    [self.filteredDataSourceArray removeAllObjects];
    
    for (BusinessCategory *b in self.dataSourceArray)
    {
        NSRange textRange;
        textRange = [b.businessCategoryDescription rangeOfString:filterString options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)];
        
        if(textRange.location != NSNotFound && [filterString isEqualToString:b.businessCategoryDescription])
        {
            [self.navigationItem.rightBarButtonItem setEnabled:NO];
            [self.filteredDataSourceArray addObject:b];
            
        } 
        else if(textRange.location != NSNotFound)
        {
            [self.filteredDataSourceArray addObject:b];
        }
    }
    
    if ([[filterString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) {
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
    }
}

- (void) loadData 
{
    NSMutableArray *parentCats = [NSMutableArray array];
    for (BusinessCategory *bCat in self.businessCategories) {
        if (!bCat.parentBusinessCategoryCode) { // queste sono del top
            [parentCats addObject:bCat];
        }
    }
    
    NSMutableArray *mutArr = [[parentCats sortedArrayUsingComparator:^(id a, id b) {
        
        NSString *first = [(BusinessCategory *)a businessCategoryDescription];
        NSString *second = [(BusinessCategory *)b businessCategoryDescription];
        
        return [first compare:second];
        
    }] mutableCopy];
    
    [self setDataSourceArray:mutArr];
    
    [mutArr release];
    
    if (self.searchTxt) {
        [self updateFilteredData:self.searchTxt];
    }
}

-(void)reloadTable 
{
    [self loadData];
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark View lifecycle

-(void) getBack {
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else if ([self respondsToSelector:@selector(dismissModalViewControllerAnimated:)]) {
        [self dismissModalViewControllerAnimated:YES];
    } 
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.filteredDataSourceArray = [NSMutableArray arrayWithCapacity:[self.dataSourceArray count]];
    
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
    
    if (self.searchTxt && self.searchTxt != 0) {
        [self.searchBar setText:self.searchTxt];
        [self.searchBar becomeFirstResponder];
        self.isFiltered = YES;
    } else
        self.isFiltered = NO;
    
    [self loadData];
    
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
    
    UIBarButtonItem * cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(getBack)]; 
    cancelButton.style = UIBarButtonItemStyleBordered;
    self.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];

    UIBarButtonItem * addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertParentBCat)]; 
    addButton.style = UIBarButtonItemStyleBordered;
    self.navigationItem.rightBarButtonItem = addButton;
    if (self.isFiltered) {
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
    } else {
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
    }
    self.title = @"Business Section";
    [addButton release];
    
    [tb release];
    
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
        
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
        
    } else {
        
        self.isFiltered = YES;
        
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
        
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
        rowCount = self.filteredDataSourceArray.count;
    else
        rowCount = self.dataSourceArray.count;
    
    return rowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        
    }
    
    BusinessCategory *cat;
    
    if(self.isFiltered) {
        cat = [self.filteredDataSourceArray objectAtIndex:indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cat = [self.dataSourceArray objectAtIndex:indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    cell.textLabel.text = cat.businessCategoryDescription;
    
    return cell;
}

- (void)setEditing:(BOOL)isEditing animated:(BOOL)animated {
    [super setEditing:isEditing animated:animated]; 
    [self.tableView setEditing:isEditing animated:animated];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath 
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        BusinessCategory * b = nil;
        
        if (!self.isFiltered) {
            
            b = [[self.dataSourceArray objectAtIndex:indexPath.row] retain];

        } else {
            
            b = [[self.filteredDataSourceArray objectAtIndex:indexPath.row] retain];
            
        }
        
        
        for (BusinessCategory *bb in businessCategories) {
            if([bb.parentBusinessCategoryCode isEqualToString:b.businessCategoryCode]
               &&
               [self.dao countFirmsWithBusiness:bb excludingPending:YES] > 0) {
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"This section contains business categories referenced by other entities and cannot be deleted." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alertView show];
                [alertView release];
                
                [b release];
                
                return;
            }
        }
        
        if (!self.isFiltered) {
            
            [self.dataSourceArray removeObjectAtIndex:indexPath.row];
            
        } else {
            
            for(int i = 0; i < [self.dataSourceArray count]; i++) {
                
                BusinessCategory *bb = [self.dataSourceArray objectAtIndex:i];
                
                if([b.businessCategoryDescription isEqualToString:bb.businessCategoryDescription])
                {
                    [self.dataSourceArray removeObjectAtIndex:i];
                    
                    break;
                }
            }
            
            [self.filteredDataSourceArray removeObjectAtIndex:indexPath.row];
        }

        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
        
        [self.tableView reloadData];
        
        if([self.searchBar.text isEqualToString:b.businessCategoryDescription]) {
            [self.navigationItem.rightBarButtonItem setEnabled:YES];
        }
        
        NSDictionary* dict = [NSDictionary dictionaryWithObject:b forKey:@"value"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:[NSString stringWithFormat:@"%@%@%@", self.boundClassName, self.dataKey, REMOVED_PARENT_BUSINESS_CATEGORY_SUGGESTION]
                                                            object:nil 
                                                          userInfo:dict];
        
        [b release];
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {

    }   
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSMutableArray *businesses = [NSMutableArray array];
    
    BusinessCategory *b = nil;
    
    if (self.isFiltered) {
        
        b = [self.filteredDataSourceArray objectAtIndex:indexPath.row];
        
    } else {
        
        b = [self.dataSourceArray objectAtIndex:indexPath.row];

    }
    
    for (BusinessCategory *bb in businessCategories) {
        if([bb.parentBusinessCategoryCode isEqualToString:b.businessCategoryCode]) {
            [businesses addObject:bb];
        }
    }
    
    LowLevelBusinessCategorySuggestionViewController *mainViewController = [[LowLevelBusinessCategorySuggestionViewController alloc] initWithStyle:UITableViewStylePlain parentCode:b.businessCategoryCode dao:self.dao dataSourceArray:businesses searchTxt:@"" boundClassName:self.boundClassName dataKey:self.dataKey cancelBtn:NO];
    [self.navigationController pushViewController:mainViewController animated:YES];
    [mainViewController release];
    
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

- (void)viewDidUnload 
{
    if (self.searchBar) {
        self.searchBar.delegate = nil;
    }
    
    if (self.tableView) {
        self.tableView.delegate = nil;
    }
    
    self.searchTxt = [self.searchBar text];
    self.tableView = nil;
    self.searchBar = nil;
    self.filteredDataSourceArray = nil;
    self.dataSourceArray = nil;
    
    [super viewDidUnload];
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
    [self.boundClassName release];
    [self.dataKey release];
    [self.businessCategories release];
    [self.tableView release];
	[self.dataSourceArray release];
    [self.filteredDataSourceArray release];
    [self.dao release];
    [super dealloc];
}

@end
