//
//  RevGeocoder.h
//  repWallet
//
//  Created by Alberto Fiore on 11/16/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "RevGeocoderResponse.h"


@protocol RevGeocoderDelegate <NSObject>

@optional

-(void) revGeocoderFailedWithError:(NSString *)errorMsg;
-(void) revGeocoderFoundAddress:(RevGeocoderResponse *)address;

@end

@interface RevGeocoder : NSObject

@property (nonatomic, assign) id<RevGeocoderDelegate> delegate;

-(void)startGeocodingWithLatitude:(double)latitude longitude:(double)longitude;

@end
