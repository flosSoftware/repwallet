//
//  EventSearchViewController.h
//  repWallet
//
//  Created by Alberto Fiore on 1/25/13.
//  Copyright (c) 2013 Alberto Fiore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "DAO.h"
#import "TextCell.h"

@protocol EventSearchViewControllerDelegate <NSObject>

@optional

- (void) eventSearchControllerFilteredEventsOfType:(NSString *)type result:(NSString *)result startDate:(NSDate *)startDate endDate:(NSDate *)endDate itemCategory:(ItemCategory *)itemCategory minDuration:(NSNumber *)minDuration maxDuration:(NSNumber *)maxDuration minValue:(NSNumber *)minValue maxValue:(NSNumber *)maxValue;

- (void) eventSearchControllerReset;

@end

@interface EventSearchViewController : UITableViewController {
    BOOL viewDidDisappear;
    UIInterfaceOrientation lastOrientation;
}

@property (nonatomic, assign) id<EventSearchViewControllerDelegate> delegate;
@property (nonatomic, retain) NSMutableDictionary *cells;
@property (nonatomic, retain) NSMutableDictionary *cacheDict;
@property (nonatomic, retain) DAO *dao;
@property (nonatomic, retain) NSIndexPath *firstVisibleIndexPath;
@property (nonatomic, retain) NSIndexPath *lastVisibleIndexPath;

- (id)initWithStyle:(UITableViewStyle)style andDao:(DAO *)dao;

- (TextCell *) prevTextCellForIndexpath:(NSIndexPath *)indexPath;

- (TextCell *) nextTextCellForIndexpath:(NSIndexPath *)indexPath;

@end
