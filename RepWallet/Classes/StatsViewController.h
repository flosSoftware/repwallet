//
//  StatsViewController.h
//  repWallet
//
//  Created by Alberto Fiore on 3/12/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "DAO.h"

#define PREDICTION_MODE_SWITCH_DATAKEY @"predictionModeSwitch"
#define ON_VALUE @"ON"
#define OFF_VALUE @"OFF"


@interface StatsViewController : UITableViewController {
    BOOL viewDidDisappear;
    UIInterfaceOrientation lastOrientation;
}

@property (nonatomic, retain) DAO *dao;
@property (nonatomic, assign) BOOL predictionModeIsOn;
@property (nonatomic, retain) NSMutableDictionary *cells;
@property (nonatomic, retain) NSMutableDictionary *cacheDict;
@property (nonatomic, retain) NSIndexPath *firstVisibleIndexPath;
@property (nonatomic, retain) NSIndexPath *lastVisibleIndexPath;

- (id)initWithStyle:(UITableViewStyle)style andDao:(DAO *)dao;
- (NSMutableArray *)fromStatsToDataSeries:(NSMutableArray *) stats forStatType:(NSString *) statType;
- (void)predictionModeChanged:(NSNotification *)notification;

@end
