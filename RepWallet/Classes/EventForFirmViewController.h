
#import <Foundation/Foundation.h>
#import "DAO.h"
#import "Firm.h"
#import "AddEditViewController.h"
#import "EventSearchViewController.h"

#define REMOVED_EVENT_NOTIFICATION @"removedEvent"


@interface EventForFirmViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, NSFetchedResultsControllerDelegate, AddEditViewControllerDelegate, EventSearchViewControllerDelegate, UIAccelerometerDelegate> {
    
    BOOL shouldBeginEditing;
    BOOL histeresisExcited;
    BOOL viewDidDisappear;
    UIInterfaceOrientation lastOrientation;
}

@property (nonatomic, retain) UIAcceleration* lastAcceleration;
@property (nonatomic, retain) DAO *dao;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, assign) UITableViewStyle tableViewStyle;
@property (nonatomic, assign) BOOL isFiltered;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) NSString *searchTxt;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSFetchedResultsController *filteredFetchedResultsController;
@property (nonatomic, retain) Firm *firmForEvent;
@property (nonatomic, retain) EventSearchViewController *eventSearchVC;

- (id)initWithStyle:(UITableViewStyle)style firm:(Firm *)aFirm andDao:(DAO *)dao;

- (void) showSearch;

- (void) hideTabBar;

- (void) showTabBar;

@end