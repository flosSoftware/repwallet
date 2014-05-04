//
//  TopLevelBusinessCategorySuggestionViewController.h
//  repWallet
//
//  Created by Alberto Fiore on 12/4/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BusinessCategory.h"
#import "DAO.h"

#define INSERTED_PARENT_BUSINESS_CATEGORY_SUGGESTION @"insertedParentBusinessCategorySuggestion"
#define REMOVED_PARENT_BUSINESS_CATEGORY_SUGGESTION @"removedParentBusinessCategorySuggestion"

@interface TopLevelBusinessCategorySuggestionViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate> {
    BOOL shouldBeginEditing;
}

@property (nonatomic, retain) DAO *dao;
@property (nonatomic, retain) NSMutableArray *businessCategories;
@property (nonatomic, retain) NSMutableArray *dataSourceArray;
@property (nonatomic, retain) NSMutableArray* filteredDataSourceArray;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, assign) UITableViewStyle tableViewStyle;
@property (nonatomic, assign) BOOL isFiltered;
@property (nonatomic, retain) NSString * boundClassName;
@property (nonatomic, retain) NSString * dataKey;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) NSString * searchTxt;

- (id)initWithStyle:(UITableViewStyle)style dao:(DAO *)dao businessCategories:(NSArray *)businessCategories boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey;
- (void)loadData;
- (void)reloadTable;


@end
