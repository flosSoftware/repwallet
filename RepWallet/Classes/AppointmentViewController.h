//
//  AppointmentViewController.h
//  repWallet
//
//  Created by Alberto Fiore on 1/27/13.
//  Copyright (c) 2013 Alberto Fiore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DAO.h"

@interface AppointmentViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, NSFetchedResultsControllerDelegate> {
    BOOL shouldBeginEditing;
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
@property (nonatomic, assign) BOOL addAnotherAppointment;

- (id)initWithStyle:(UITableViewStyle)style andDao:(DAO *)dao;
- (void)enableAnotherAppointmentInsertion;
- (void)disableAnotherAppointmentInsertion;
- (void)getToRootView;
- (void)showAppointmentsForFirm:(Firm *)selectedFirm;

@end