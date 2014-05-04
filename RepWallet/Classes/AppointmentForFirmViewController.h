//
//  AppointmentForFirmViewController.h
//  repWallet
//
//  Created by Alberto Fiore on 1/27/13.
//  Copyright (c) 2013 Alberto Fiore. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "DAO.h"
#import "Firm.h"
#import "AddEditViewController.h"

#define REMOVED_APPOINTMENT_NOTIFICATION @"removedAppointment"


@interface AppointmentForFirmViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, NSFetchedResultsControllerDelegate, AddEditViewControllerDelegate> {
    
    BOOL shouldBeginEditing;
    BOOL forceCellUpdate;
    BOOL viewDidDisappear;
    UIInterfaceOrientation lastOrientation;
}

@property (nonatomic, retain) NSString *removedAppointmentId;
@property (nonatomic, retain) DAO *dao;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, assign) UITableViewStyle tableViewStyle;
@property (nonatomic, assign) BOOL isFiltered;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) NSString *searchTxt;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSFetchedResultsController *filteredFetchedResultsController;
@property (nonatomic, retain) Firm *firmForAppointment;

- (id)initWithStyle:(UITableViewStyle)style firm:(Firm *)aFirm andDao:(DAO *)dao;

@end