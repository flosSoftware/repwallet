//
//  LowLevelBusinessCategorySuggestionViewController.h
//  repWallet
//
//  Created by Alberto Fiore on 10/30/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DAO.h"

#define REMOVED_BUSINESS_CATEGORY_SUGGESTION @"removedBusinessCategorySuggestion"
#define INSERTED_BUSINESS_CATEGORY_SUGGESTION @"insertedBusinessCategorySuggestion"
#define GOT_BUSINESS_CATEGORY_SUGGESTION @"gotBusinessCategorySuggestion"

@interface LowLevelBusinessCategorySuggestionViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate> 
{
    BOOL shouldBeginEditing;
}

@property (nonatomic, retain) NSString *parentCode;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) DAO *dao;
@property (nonatomic, retain) NSMutableArray *dataSourceArray;
@property (nonatomic, retain) NSMutableArray* filteredDataSourceArray;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, assign) UITableViewStyle tableViewStyle;
@property (nonatomic, assign) BOOL isFiltered;
@property (nonatomic, retain) NSString *searchTxt;
@property (nonatomic, retain) NSMutableArray *sectionedDataSourceArray;
@property (nonatomic, assign) BOOL withCancelBtn;
@property (nonatomic, retain) NSString *dataKey;
@property (nonatomic, retain) NSString *boundClassName;

- (id)initWithStyle:(UITableViewStyle)style parentCode:(NSString *)parentCode dao:(DAO *)dao dataSourceArray:(NSMutableArray *)dataSourceArray searchTxt:(NSString *)search boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey cancelBtn:(BOOL)cancelBtn;
- (void) loadData;
- (void) reloadTable;

@end
