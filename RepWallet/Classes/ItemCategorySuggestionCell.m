//
//  ItemCategorySuggestionCell.m
//  repWallet
//
//  Created by Alberto Fiore on 10/31/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "ItemCategorySuggestionCell.h"
#import "RepWalletAppDelegate.h"
#import "AddEditViewController.h"

@implementation ItemCategorySuggestionCell

@synthesize category;
@synthesize dao;
@synthesize suggVC;

- (void) singleTapRecognized:(UIGestureRecognizer *)gestureRecognizer {
    
    [self show:self.textField];
}

- (void) updateText: (NSString *)txt {
    
    self.textField.text = txt;
    
}

- (void) checkIfItemCategoryHasBeenRemoved: (NSNotification*)n {
    
    NSSet * set = [[n userInfo] objectForKey:NSDeletedObjectsKey];
    
    [set enumerateObjectsUsingBlock:^(id obj, BOOL *stop){
        if ([[obj objectID] isEqual:category.objectID]) {
            [self setControlValue:nil];
            [self postEndEditingNotification];
            *stop = YES;
        }
    } ];
}

#pragma mark ItemCategorySuggestionViewControllerDelegate

- (void)itemCategorySuggestionViewControllerMadeNewSuggestion:(ItemCategory *)cat {
    
    [self setControlValue:cat];
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
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(checkIfItemCategoryHasBeenRemoved:)
                                                     name:NSManagedObjectContextObjectsDidChangeNotification
                                                   object:self.dao.managedObjectContext];
        
        self.category = nil;
                
    }
    return self;
}


-(void) setControlValue:(id)value
{
    if(value) { 
        self.category = (ItemCategory *)value;
        [self updateText:self.category.name];
        
    } else {
        self.category = nil;
        [self updateText:@"<empty>"];
    }
}

-(id) getControlValue
{
    return self.category;
}

- (void) show: (id) sender {
    
    NSString * t = nil;
    if ([((UITextField *)sender).text isEqualToString:@"<empty>"]) {
        t = @"";
    } else
        t = ((UITextField *)sender).text;
    
	// Create and configure the main view controller.
	ItemCategorySuggestionViewController *mainViewController = [[ItemCategorySuggestionViewController alloc] initWithStyle:UITableViewStylePlain dao:self.dao searchTxt:t];
    self.suggVC = mainViewController;
    [mainViewController release];
    self.suggVC.delegate = self;
    self.suggVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    self.suggVC.modalPresentationStyle = UIModalPresentationFormSheet;
    
	// Add create and configure the navigation controller.
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.suggVC];
    UIColor * c = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    navigationController.navigationBar.tintColor = c;
	UIViewController *vc = [self viewController];
    
    if ([vc respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        
        [vc presentViewController:navigationController animated:YES completion:NULL];
        
    } else if([vc respondsToSelector:@selector(presentModalViewController:animated:)]) {
        
        [vc presentModalViewController:navigationController animated:YES];
        
    }
	[navigationController release];
}



#pragma mark UITextFieldDelegate

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return NO;  // Hide both keyboard and blinking cursor.
}

- (void)dealloc
{
    if (self.suggVC) {
        self.suggVC.delegate = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.suggVC release];
    [self.dao release];
    [self.category release];
    [super dealloc];
}

@end