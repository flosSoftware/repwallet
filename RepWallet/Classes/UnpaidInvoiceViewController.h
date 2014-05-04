//
//  UnpaidInvoiceViewController.h
//  repWallet
//
//  Created by Alberto Fiore on 12/11/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DAO.h"

@interface UnpaidInvoiceViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, NSFetchedResultsControllerDelegate> {
    BOOL shouldBeginEditing;
    BOOL addAnotherUnpaid;
    BOOL viewDidDisappear;
    UIInterfaceOrientation lastOrientation;
}

@property (nonatomic, retain) DAO *dao;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, assign) UITableViewStyle tableViewStyle;
@property (nonatomic, assign) BOOL isFiltered;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) NSString *searchTxt;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSFetchedResultsController *filteredFetchedResultsController;

- (id)initWithStyle:(UITableViewStyle)style andDao:(DAO *)dao;
- (void)enableAnotherUnpaidInsertion;
- (void)disableAnotherUnpaidInsertion;
- (void)getToRootView;

@end