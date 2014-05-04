//
//  SettingsViewController.h
//  repWallet
//
//  Created by Alberto Fiore on 12/14/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

#define MAP_TYPE_SETTING_KEY @"mapType"
#define TRAVEL_MODE_SETTING_KEY @"travelMode"
#define MAX_NR_OF_FIRMS_FOR_ROUTING_SETTING_KEY @"maxNrOfFirmsForRouting"
#define NR_OF_WORK_HOURS_SETTING_KEY @"nrOfWorkHrs"
#define TAX_RATE_SETTING_KEY @"taxRate"

#define MAP_TYPE_SETTING_DEFAULT_VALUE @"RMOpenStreetMapSource"
#define TRAVEL_MODE_SETTING_DEFAULT_VALUE @"Driving"
#define MAX_NR_OF_FIRMS_FOR_ROUTING_SETTING_DEFAULT_VALUE 8
#define NR_OF_WORK_HOURS_SETTING_DEFAULT_VALUE 8
#define TAX_RATE_SETTING_DEFAULT_VALUE 0

@interface SettingsViewController : UITableViewController {
    BOOL viewDidDisappear;
    UIInterfaceOrientation lastOrientation;
}

@property (nonatomic, retain) NSMutableDictionary *cells;
@property (nonatomic, retain) NSMutableDictionary *cacheDict;
@property (nonatomic, retain) MBProgressHUD *progressHUD;
@property (nonatomic, retain) NSIndexPath *firstVisibleIndexPath;
@property (nonatomic, retain) NSIndexPath *lastVisibleIndexPath;

- (id)initWithStyle:(UITableViewStyle)style;

@end
