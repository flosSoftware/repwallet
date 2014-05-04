//
//  LabeledStringSelectionViewController.h
//  repWallet
//
//  Created by Alberto Fiore on 3/13/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol StringSelectionViewControllerDelegate <NSObject>

@optional

- (void) stringSelectionViewControllerSelectedString:(NSString *)string;

@end

@interface StringSelectionViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate> {
    
    BOOL shouldBeginEditing;
    
}

@property (nonatomic, assign) id<StringSelectionViewControllerDelegate> delegate;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, assign) UITableViewStyle tableViewStyle;
@property (nonatomic, assign) BOOL isFiltered;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) NSString *searchTxt;
@property (nonatomic, retain) NSArray *dataSource;
@property (nonatomic, retain) NSMutableArray *filteredDataSource;
@property (nonatomic, retain) NSMutableArray *sectionedDataSource;

- (id)initWithStyle:(UITableViewStyle)style andDatasource:(NSArray *)aDatasourceArray;

@end
