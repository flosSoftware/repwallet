//
//  ItemCategorySuggestionCell.h
//  repWallet
//
//  Created by Alberto Fiore on 10/31/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ItemCategory.h"
#import "TextCell.h"
#import "DAO.h"
#import "ItemCategorySuggestionViewController.h"

@interface ItemCategorySuggestionCell : TextCell<ItemCategorySuggestionViewControllerDelegate> {
    
}

@property (nonatomic, retain) ItemCategory* category;
@property (nonatomic, retain) DAO * dao;
@property (nonatomic, retain) ItemCategorySuggestionViewController *suggVC;

- (void) show:(id)sender;
- (void) updateText: (NSString *)txt;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label dao:(DAO *)aDao;

@end
