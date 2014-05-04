//
//  LowLevelBusinessCategorySuggestionViewController.m
//  repWallet
//
//  Created by Alberto Fiore on 10/30/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//
#include <stdlib.h>
#import "LowLevelBusinessCategorySuggestionViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "RepWalletAppDelegate.h"
#import "IndexableString.h"

@interface NSArray (SSArrayOfArrays)
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;
@end

@implementation NSArray (SSArrayOfArrays)

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    return [[self objectAtIndex:[indexPath section]] objectAtIndex:[indexPath row]];
}

@end

@interface NSMutableArray (SSArrayOfArrays)
// If idx is beyond the bounds of the receiver, this method automatically extends the receiver to fit with empty subarrays.
- (void)addObject:(id)anObject toSubarrayAtIndex:(NSUInteger)idx;
- (void)deleteObjectAtIndexPath:(NSIndexPath *)indexPath;
@end

@implementation NSMutableArray (SSArrayOfArrays)

- (void)addObject:(id)anObject toSubarrayAtIndex:(NSUInteger)idx
{
    while ([self count] <= idx) {
        [self addObject:[NSMutableArray array]];
    }
    
    [[self objectAtIndex:idx] addObject:anObject];
}

- (void)deleteObjectAtIndexPath:(NSIndexPath *)indexPath
{
    [[self objectAtIndex:[indexPath section]] removeObjectAtIndex:[indexPath row]];
}

@end

@implementation LowLevelBusinessCategorySuggestionViewController

@synthesize dataSourceArray;
@synthesize filteredDataSourceArray;
@synthesize tableView;
@synthesize tableViewStyle;
@synthesize isFiltered;
@synthesize searchTxt;
@synthesize searchBar;
@synthesize dao;
@synthesize sectionedDataSourceArray;
@synthesize withCancelBtn;
@synthesize boundClassName, dataKey;
@synthesize parentCode;

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

- (id)initWithStyle:(UITableViewStyle)style parentCode:(NSString *)parentCode dao:(DAO *)dao dataSourceArray:(NSMutableArray *)dataSourceArray searchTxt:(NSString *)search boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey cancelBtn:(BOOL)cancelBtn;
{
    self = [super init];
    
    if (self) {
        
        self.boundClassName = boundClassName;
        
        self.dataKey = dataKey;
        
        self.dao = dao;
        
        shouldBeginEditing = YES;
        
        self.dataSourceArray = dataSourceArray;
        
        self.tableViewStyle = style;
        self.searchTxt = search;

        self.withCancelBtn = cancelBtn;
        self.parentCode = parentCode;
    }    
    
    return self;
}

-(void)insertBCat 
{
    int i = 0;

    for (BusinessCategory *b in self.dataSourceArray) {
        
        NSRange r = [b.businessCategoryCode rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"-"]];
        
        if (r.location != NSNotFound) {
            int pCode = [[b.businessCategoryCode substringFromIndex:r.location + 1] intValue];
            if (pCode > i) {
                i = pCode;
            }
        }
    }
    
    BusinessCategory *b = [[BusinessCategory alloc] initWithCode:[NSString stringWithFormat:@"%@-%i", self.parentCode, i+1] parentCode:self.parentCode description:self.searchTxt];
    
    NSDictionary* dict = [NSDictionary dictionaryWithObject:b forKey:@"value"];
    [[NSNotificationCenter defaultCenter] 
     postNotificationName:
     [NSString stringWithFormat:@"%@%@%@", self.boundClassName, self.dataKey, INSERTED_BUSINESS_CATEGORY_SUGGESTION]
     object:nil 
     userInfo:dict];
    
    [b release];
    
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else if ([self respondsToSelector:@selector(dismissModalViewControllerAnimated:)]) {
        [self dismissModalViewControllerAnimated:YES];
    } 
}


- (void) updateFilteredData:(NSString *)text {
    
    [self.filteredDataSourceArray removeAllObjects];
    
    for (NSArray *section in self.sectionedDataSourceArray) {
        for (IndexableString *s in section)
        {
            NSRange textRange;
            textRange = [s.string rangeOfString:text options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)];
            
            if(textRange.location != NSNotFound && [text isEqualToString:s.string])
            {
                [self.filteredDataSourceArray addObject:s];
                [self.navigationItem.rightBarButtonItem setEnabled:NO];
            }
            else if(textRange.location != NSNotFound)
            {
                [self.filteredDataSourceArray addObject:s];
            }
        }
    }
    
    if ([[text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) {
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
    }
}


- (void) updateSectionedData {
    
    NSMutableArray *sections = [NSMutableArray array];
    UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];
    for (BusinessCategory *b in self.dataSourceArray) {
        IndexableString *s = [[IndexableString alloc] init];
        [s setString:b.businessCategoryDescription];
        NSInteger section = [collation sectionForObject:s collationStringSelector:@selector(string)];
        [sections addObject:s toSubarrayAtIndex:section];
        [s release];
    }
    
    NSInteger section = 0;
    for (section = 0; section < [sections count]; section++) {
        NSMutableArray *sortedSubarray = [[collation sortedArrayFromArray:[sections objectAtIndex:section]
                                                  collationStringSelector:@selector(string)] mutableCopy];
        [sections replaceObjectAtIndex:section withObject:sortedSubarray];
        [sortedSubarray release];
    }
    
    self.sectionedDataSourceArray = sections;
}

- (void) loadData {
    
    [self updateSectionedData];
    if (self.searchTxt) {
        [self updateFilteredData:self.searchTxt];
    }
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

    self.filteredDataSourceArray = [NSMutableArray arrayWithCapacity:[self.dataSourceArray count]];
    
    if (self.searchTxt && [self.searchTxt length] != 0) {
        
        [self.searchBar setText:self.searchTxt];
        [self.searchBar becomeFirstResponder];
        self.isFiltered = YES;
        
    } else {
        
        self.isFiltered = NO;
    }
    
    [self loadData];
    
    [self.view addSubview:self.searchBar];
    
    UITableView * tb = [[UITableView alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x, 
                                                                     self.view.bounds.origin.y
                                                                     + self.searchBar.frame.size.height, 
                                                                     self.view.bounds.size.width, 
                                                                     self.view.bounds.size.height
                                                                     - self.searchBar.frame.size.height) 
                                                    style:self.tableViewStyle];
    
    tb.scrollEnabled = YES;
    self.tableView = tb;   
    self.tableView.dataSource = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth
    | UIViewAutoresizingFlexibleHeight
    | UIViewAutoresizingFlexibleRightMargin
    | UIViewAutoresizingFlexibleBottomMargin;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    
    if (self.withCancelBtn) {
        UIBarButtonItem * cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(getBack)]; 
        cancelButton.style = UIBarButtonItemStyleBordered;
        self.navigationItem.leftBarButtonItem = cancelButton;
        [cancelButton release];
    }
    
    UIBarButtonItem * addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertBCat)]; 
    addButton.style = UIBarButtonItemStyleBordered;
    self.navigationItem.rightBarButtonItem = addButton;
    if (self.isFiltered) {
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
    } else {
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
    }
    self.title = @"Business Class";
    [addButton release];
    
    [tb release];
}

-(void)reloadTable 
{
    [self loadData];
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
    if (self.isFiltered) {
        return 1;
    } else {
        return [self.sectionedDataSourceArray count];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    int rowCount;
    
    if(self.isFiltered)
        rowCount = self.filteredDataSourceArray.count;
    else
        rowCount = [[self.sectionedDataSourceArray objectAtIndex:section] count];
    
    return rowCount;
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
    
    IndexableString *s;
    
    if(self.isFiltered)
        s = [self.filteredDataSourceArray objectAtIndex:indexPath.row];
    else
        s = [self.sectionedDataSourceArray objectAtIndexPath:indexPath];
    
    cell.textLabel.text = s.string;
    
    return cell;
}

- (void)setEditing:(BOOL)isEditing animated:(BOOL)animated {
    [super setEditing:isEditing animated:animated]; 
    [self.tableView setEditing:isEditing animated:animated];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath 
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        IndexableString * s = nil;
        
        if (!self.isFiltered) {
            s = [[self.sectionedDataSourceArray objectAtIndexPath:indexPath] retain];
        } else {
            s = [[self.filteredDataSourceArray objectAtIndex:indexPath.row] retain];
        }

        BusinessCategory * b = nil;
        
        for(int i = 0; i < [self.dataSourceArray count]; i++) {
            
            if([[[self.dataSourceArray objectAtIndex:i] businessCategoryDescription] isEqualToString:s.string])
            {
                b = [[self.dataSourceArray objectAtIndex:i] retain];
                
                BOOL okToDelete = YES;
                
                NSUInteger firmsWithBiz = [self.dao countFirmsWithBusiness:b excludingPending:YES];
                
                if (firmsWithBiz > 0) {
                    okToDelete = NO;
                }
                
                if(!okToDelete) {
                    
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"This business category is referenced by other entities and cannot be deleted." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                    [alertView show];
                    [alertView release];
                    
                    [b release];
                    [s release];
                    
                    return;
                    
                }
                
                [self.dataSourceArray removeObjectAtIndex:i];
                            
                break;
            }
        }
        
        if (!self.isFiltered) {
            [self.sectionedDataSourceArray deleteObjectAtIndexPath:indexPath];
        } else {
            [self updateSectionedData];
            [self.filteredDataSourceArray removeObjectAtIndex:indexPath.row];
        }
        
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
        
        [self.dao saveContext];
        
        [self.tableView reloadData];
        
        if([self.searchBar.text isEqualToString:s.string]) {
            [self.navigationItem.rightBarButtonItem setEnabled:YES];
        }
        
        NSDictionary* dict = [NSDictionary dictionaryWithObject:b forKey:@"value"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:[NSString stringWithFormat:@"%@%@%@", self.boundClassName, self.dataKey, REMOVED_BUSINESS_CATEGORY_SUGGESTION]
                                                            object:nil 
                                                          userInfo:dict];

        [b release];
        [s release];
                
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        
    }   
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell * cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
    
    NSDictionary* dict = [NSDictionary dictionaryWithObject:
                          cell.textLabel.text forKey:@"value"];
    [[NSNotificationCenter defaultCenter] postNotificationName:[NSString stringWithFormat:@"%@%@%@", self.boundClassName, self.dataKey, GOT_BUSINESS_CATEGORY_SUGGESTION]
                                                        object:nil 
                                                      userInfo:dict];
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else if ([self respondsToSelector:@selector(dismissModalViewControllerAnimated:)]) {
        [self dismissModalViewControllerAnimated:YES];
    } 
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (self.isFiltered) {
        return nil;
    } else {
        return [[self.sectionedDataSourceArray objectAtIndex:section] count] ? [[[UILocalizedIndexedCollation currentCollation] sectionTitles] objectAtIndex:section] : nil;
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (self.isFiltered) {
        return nil;
    } else {
        return [[NSArray arrayWithObject:UITableViewIndexSearch] arrayByAddingObjectsFromArray:
                [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles]];
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    if (self.isFiltered) {
        return 0;
    } else {
        if (title == UITableViewIndexSearch) {
            [tableView scrollRectToVisible:self.searchBar.frame animated:NO];
            return -1;
        } else {
            return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index-1];
        }
    }
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
    self.filteredDataSourceArray = nil;
    self.searchBar = nil;
    self.sectionedDataSourceArray = nil;
    
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
    [self.parentCode release];
    [self.sectionedDataSourceArray release];	
    [self.dao release];
    [self.tableView release];
	[self.dataSourceArray release];
    [self.filteredDataSourceArray release];
    [self.searchBar release];
    [self.boundClassName release];
    [self.dataKey release];
    [super dealloc];
}


@end

