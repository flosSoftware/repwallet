//
//  FwdGeocoder.h
//  repWallet
//
//  Created by Alberto Fiore on 11/16/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol FwdGeocoderDelegate <NSObject>

@optional

-(void) geocoderFailedWithError:(NSString *)errorMsg;
-(void) geocoderFoundLocation:(CLLocation *)location;

@end

@interface FwdGeocoder : NSObject

@property (nonatomic, assign) id<FwdGeocoderDelegate> delegate;

-(void)startGeocodingWithAddress:(NSString *)address locality:(NSString *)locality ZIP:(NSString *)zip adminDistrict:(NSString *)adminDistrict countryCode:(NSString *)countryCode;

@end
