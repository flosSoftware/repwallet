//
//  RouteForAppointmentViewController.h
//  repWallet
//
//  Created by Alberto Fiore on 1/30/13.
//  Copyright (c) 2013 Alberto Fiore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DAO.h"
#import "CloudMadeToken.h"
#import <CoreLocation/CoreLocation.h>
#import "MBProgressHUD.h"

@interface RouteForAppointmentViewController : UITableViewController<CLLocationManagerDelegate, CloudMadeTokenDelegate> {
    NSInteger failedConn;
    NSInteger badStatusCode;
    NSInteger threadCounter;
    NSInteger threadCounterUpperLimit;
    pthread_mutex_t mutex;
    BOOL viewDidDisappear;
    UIInterfaceOrientation lastOrientation;
}

@property (nonatomic,retain) DAO *dao;
@property (nonatomic,retain) NSArray * apps;
@property (nonatomic,retain) NSMutableArray * appTrips;
@property (nonatomic,retain) MBProgressHUD *progressHUD;
@property (nonatomic,assign) BOOL toBeReloaded;
@property (nonatomic,retain) CloudMadeToken *token;
@property (nonatomic,retain) NSMutableArray *connections;
@property (nonatomic,retain) CLLocationManager *locationManager;
@property (nonatomic,retain) CLLocation *userLocation;
@property (nonatomic,retain) NSTimer *locationTimer;

- (id) initWithStyle:(UITableViewStyle)style andDao:(DAO *)dao;
- (void) orderAppointments;
- (void) orderTrips;
- (void) reload;
- (void) reloadTable;
- (void) markViewStatusToBeReloaded;
- (void) getRoutesFromServiceWithToken:(NSString *)token startLocation:(CLLocation *)startLocation;
- (NSString *) createConnectionUrlWithStartLocation:(CLLocation *)startLocation endFirm:(Firm *)endFirm token:(NSString *)token;
- (void) startAsyncCallWithLocation:(CLLocation *)location;

@end