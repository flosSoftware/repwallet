//
//  FirmSelectionViewController.h
//  repWallet
//
//  Created by Alberto Fiore on 11/02/11.
//  Copyright 2011 Alberto Fiore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Firm.h"
#import "DAO.h"

@protocol FirmSelectionViewControllerDelegate <NSObject>

@optional

- (void) firmSelectionViewControllerSelectedFirm:(Firm *)firm;

@end

@interface FirmSelectionViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, NSFetchedResultsControllerDelegate> {
    
    BOOL shouldBeginEditing;
    
}

@property (nonatomic, assign) id<FirmSelectionViewControllerDelegate> delegate;

@property (nonatomic, retain) DAO *dao;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, assign) UITableViewStyle tableViewStyle;
@property (nonatomic, assign) BOOL isFiltered;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) NSString *searchTxt;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSFetchedResultsController *filteredFetchedResultsController;

- (id)initWithStyle:(UITableViewStyle)style andDao:(DAO *)dao;

@end
