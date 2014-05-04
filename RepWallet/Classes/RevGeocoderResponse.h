//
//  RevGeocoderResponse.h
//  repWallet
//
//  Created by Alberto Fiore on 11/17/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface RevGeocoderResponse : NSObject
@property (nonatomic, retain) NSString *addressLine;
@property (nonatomic, retain) NSString *locality;
@property (nonatomic, retain) NSString *neighborhood;
@property (nonatomic, retain) NSString *adminDistrict;
@property (nonatomic, retain) NSString *adminDistrict2;
@property (nonatomic, retain) NSString *formattedAddress;
@property (nonatomic, retain) NSString *postalCode;
@property (nonatomic, retain) NSString *countryRegion;
@property (nonatomic, retain) NSString *landmark;
@property (nonatomic, retain) CLLocation *point;
@end
