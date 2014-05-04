//
//  ItemCategorySuggestionViewController.h
//  repWallet
//
//  Created by Alberto Fiore on 10/30/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DAO.h"

@protocol ItemCategorySuggestionViewControllerDelegate <NSObject>

@optional

- (void) itemCategorySuggestionViewControllerMadeNewSuggestion:(ItemCategory *)cat;

@end


@interface ItemCategorySuggestionViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate> 
{
    BOOL shouldBeginEditing;
}

@property (nonatomic, assign) id<ItemCategorySuggestionViewControllerDelegate> delegate;

@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) DAO *dao;
@property (nonatomic, retain) NSMutableArray *dataSourceArray;
@property (retain, nonatomic) NSMutableArray* filteredDataSourceArray;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, assign) UITableViewStyle tableViewStyle;
@property (nonatomic, assign) BOOL isFiltered;
@property (nonatomic, retain) NSString *searchTxt;
@property (nonatomic, retain) NSMutableArray *sectionedDataSourceArray;
@property (nonatomic, assign) BOOL withCancelBtn;


- (id)initWithStyle:(UITableViewStyle)style dao:(DAO *)dao searchTxt:(NSString *)search;
- (id)initWithStyle:(UITableViewStyle)style dao:(DAO *)dao searchTxt:(NSString *)search cancelBtn:(BOOL)cancelBtn;

@end
