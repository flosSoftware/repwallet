//
//  RouteListViewController.h
//  repWallet
//
//  Created by Alberto Fiore on 09/08/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DAO.h"
#import "CloudMadeToken.h"
#import <CoreLocation/CoreLocation.h>
#import "MapController.h"
#import "MBProgressHUD.h"

@interface RouteListViewController : UITableViewController<MapControllerDelegate, CloudMadeTokenDelegate, CLLocationManagerDelegate> {
    NSInteger failedConn;
    NSInteger badStatusCode;
    NSInteger threadCounter;
    NSInteger threadCounterUpperLimit;
    pthread_mutex_t mutex;
    BOOL viewDidDisappear;
    UIInterfaceOrientation lastOrientation;
}

@property (nonatomic,retain) MapController *mapC;
@property (nonatomic,retain) DAO *dao;
@property (nonatomic,retain) NSArray * firms;
@property (nonatomic,retain) NSMutableArray * dailyTrips;
@property (nonatomic,retain) MBProgressHUD *progressHUD;
@property (nonatomic,assign) BOOL toBeReloaded;
@property (nonatomic,retain) CloudMadeToken *token;
@property (nonatomic, assign) CLLocationCoordinate2D filterBBoxNorthEast;
@property (nonatomic, assign) CLLocationCoordinate2D filterBBoxSouthWest;
@property (nonatomic,retain) NSMutableArray *connections;
@property (nonatomic,retain) CLLocationManager *locationManager;
@property (nonatomic,retain) CLLocation *userLocation;
@property (nonatomic,retain) NSTimer *locationTimer;

- (id) initWithStyle:(UITableViewStyle)style andDao:(DAO *)dao;
- (void) orderFirms;
- (void) orderTrips;
- (void) reload;
- (void) reloadTable;
- (void) markViewStatusToBeReloaded;
- (NSString *) createConnectionUrlWithStartLocation:(CLLocation *)startLocation endFirm:(Firm *)endFirm token:(NSString *)token;
- (NSString *) createConnectionUrlWithStartFirm:(Firm *)startFirm endFirm:(Firm *)endFirm token:(NSString *)token;
- (void) startAsyncCallWithLocation:(CLLocation *)location;
- (void) getRoutesFromServiceWithToken:(NSString *)token startLocation:(CLLocation *)startLocation;
- (void) calculateDayForTrips;
- (void) atomicCancelConnection:(NSString *)message;
- (NSMutableDictionary *) massageRoute:(NSDictionary *)dictio;

@end
