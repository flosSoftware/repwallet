//
//  ImportViewController.h
//  repWallet
//
//  Created by Alberto Fiore on 10/11/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "DAO.h"
#import "MBProgressHUD.h"
#import "DocumentSelectionViewController.h"


@interface ImportViewController : UITableViewController<DocumentSelectionViewControllerDelegate> {
    BOOL viewDidDisappear;
    UIInterfaceOrientation lastOrientation;
}

@property (nonatomic, retain) DAO *dao;
@property (nonatomic, retain) NSArray * rowsExtracted;
@property (nonatomic, assign) NSInteger indexOfRowExtracted;
@property (nonatomic, retain) NSMutableDictionary *cells;
@property (nonatomic, retain) NSMutableDictionary *cacheDict;
@property (nonatomic, assign) NSInteger nrCols;
@property (nonatomic, retain) MBProgressHUD *progressHUD;
@property (nonatomic, retain) DocumentSelectionViewController *fileBrowser;
@property (nonatomic, retain) NSIndexPath *firstVisibleIndexPath;
@property (nonatomic, retain) NSIndexPath *lastVisibleIndexPath;

- (id)initWithStyle:(UITableViewStyle)style andDao:(DAO *)dao;
- (void) chooseFile;

@end
