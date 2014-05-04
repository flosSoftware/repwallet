//
//  BusinessCategorySuggestionCell.m
//  repWallet
//
//  Created by Alberto Fiore on 12/4/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//

#import "BusinessCategorySuggestionCell.h"
#import "TopLevelBusinessCategorySuggestionViewController.h"
#import "LowLevelBusinessCategorySuggestionViewController.h"
#import "AddEditViewController.h"

@implementation BusinessCategorySuggestionCell

@synthesize businessCategories, dao;

- (void) singleTapRecognized:(UIGestureRecognizer *)gestureRecognizer {
    
    [self show:self.textField];
}

- (void) insertedParentBusinessCategory: (NSNotification*)n {
    BusinessCategory *b = [[n userInfo] objectForKey:@"value"];
    [self.dao insertBusinessCategory:b];
    self.businessCategories = [self.dao getBusinessCategoriesFromDatabase];
}

- (void) insertedBusinessCategory: (NSNotification*)n {
    BusinessCategory *b = [[n userInfo] objectForKey:@"value"];
    [self.dao insertBusinessCategory:b];
    self.businessCategories = [self.dao getBusinessCategoriesFromDatabase];
    [self setControlValue:b.businessCategoryDescription];
    [self postEndEditingNotification];
}

- (void) removedBusinessCategory: (NSNotification*)n {
    BusinessCategory *b = [[n userInfo] objectForKey:@"value"];
    [self.dao deleteBusinessCategoryWithDescription:b.businessCategoryDescription];
    self.businessCategories = [self.dao getBusinessCategoriesFromDatabase];
    [self setControlValue:nil];
    [self postEndEditingNotification];
}

- (void) removedParentBusinessCategory: (NSNotification*)n {
    BusinessCategory *b = [[n userInfo] objectForKey:@"value"];
    [self.dao deleteBusinessCategoryWithDescription:b.businessCategoryDescription];
    [self.dao deleteBusinessCategoryWithParentCode:b.businessCategoryCode];
    self.businessCategories = [self.dao getBusinessCategoriesFromDatabase];
    [self setControlValue:nil];
    [self postEndEditingNotification];
}

- (void) gotSuggestion: (NSNotification*)n {
    
    [super setControlValue:[[n userInfo] objectForKey:@"value"]];
    [self postEndEditingNotification];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label dao:(DAO *)dao
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier boundClassName:boundClassName dataKey:dataKey label:label]) {
        
        self.dao = dao;
        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapRecognized:)];
        singleTap.numberOfTapsRequired = 1;
        [self.textField addGestureRecognizer:singleTap];
        [singleTap release];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(removedBusinessCategory:)
         name:[NSString stringWithFormat:@"%@%@%@", self.boundClassName, self.dataKey, REMOVED_BUSINESS_CATEGORY_SUGGESTION]
         object:nil];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(removedParentBusinessCategory:)
         name:[NSString stringWithFormat:@"%@%@%@", self.boundClassName, self.dataKey, REMOVED_PARENT_BUSINESS_CATEGORY_SUGGESTION]
         object:nil];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(insertedParentBusinessCategory:)
         name:[NSString stringWithFormat:@"%@%@%@", self.boundClassName, self.dataKey, INSERTED_PARENT_BUSINESS_CATEGORY_SUGGESTION]
         object:nil];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(insertedBusinessCategory:)
         name:[NSString stringWithFormat:@"%@%@%@", self.boundClassName, self.dataKey, INSERTED_BUSINESS_CATEGORY_SUGGESTION]
         object:nil];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(gotSuggestion:)
         name:[NSString stringWithFormat:@"%@%@%@", self.boundClassName, self.dataKey, GOT_BUSINESS_CATEGORY_SUGGESTION]
         object:nil];
        
        self.businessCategories = [self.dao getBusinessCategoriesFromDatabase];        

    }
    return self;
}

- (void) show: (id) sender {

	// Create and configure the main view controller.

	TopLevelBusinessCategorySuggestionViewController *mainViewController = [[TopLevelBusinessCategorySuggestionViewController alloc] initWithStyle:UITableViewStylePlain dao:self.dao businessCategories:self.businessCategories boundClassName:self.boundClassName dataKey:self.dataKey];
    
    mainViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    mainViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    
	// Add create and configure the navigation controller.
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:mainViewController];
    UIColor * c = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    navigationController.navigationBar.tintColor = c;
    
    UIViewController *vc = [self viewController];
    
    if ([vc respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        
        [vc presentViewController:navigationController animated:YES completion:NULL];
        
    } else if([vc respondsToSelector:@selector(presentModalViewController:animated:)]) {
        
        [vc presentModalViewController:navigationController animated:YES];
        
    }

	[navigationController release];
    
    [mainViewController release];
}

#pragma mark UITextFieldDelegate

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return NO;  // Hide both keyboard and blinking cursor.
}

- (void)dealloc
{
    [self.businessCategories release];
    [self.dao release];
    
    [super dealloc];
}

@end
