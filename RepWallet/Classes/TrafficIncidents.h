//
//  TrafficIncidents.h
//  repWallet
//
//  Created by Alberto Fiore on 11/7/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


@protocol TrafficIncidentsDelegate <NSObject>

@optional

-(void) trafficIncidentsQueryFailedWithError:(NSString *)errorMsg;
-(void) trafficIncidentsQueryFoundIncidents:(NSMutableArray *)incidents;

@end

@interface TrafficIncidents : NSObject


@property (nonatomic, assign) id<TrafficIncidentsDelegate> delegate;

- (void) startGettingIncidentsInBBoxWithNorthEast:(CLLocationCoordinate2D)ne southWest:(CLLocationCoordinate2D)sw;
- (void) setTrafficIncidents: (NSDictionary *)dictio;

@end
