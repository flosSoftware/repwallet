//
//  FirmViewController.h
//  repWallet
//
//  Created by Alberto Fiore on 11/02/11.
//  Copyright 2011 Alberto Fiore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DAO.h"


#define ANIMATION_DURATION 0.4
#define ANIMATION_DELAY 0
#define REMOVED_FIRM_NOTIFICATION @"removedFirm"


@interface FirmViewController : UIViewController {

    BOOL viewDidDisappear;
    UIInterfaceOrientation lastOrientation;
    
}

- (void)performFetch;

- (void)reloadFetchedResults:(NSNotification*)note;

- (id)initWithStyle:(UITableViewStyle)style andDao:(DAO *)dao;

@end
