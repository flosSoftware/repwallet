//
//  RevGeocoderResponse.m
//  repWallet
//
//  Created by Alberto Fiore on 11/17/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//

#import "RevGeocoderResponse.h"


@implementation RevGeocoderResponse

@synthesize addressLine, locality, neighborhood, adminDistrict, adminDistrict2, formattedAddress, postalCode, countryRegion, landmark, point;

- (void)dealloc {
    [point release];
    [addressLine release];
    [locality release];
    [neighborhood release];
    [adminDistrict release];
    [adminDistrict2 release];
    [formattedAddress release];
    [postalCode release];
    [countryRegion release];
    [landmark release];
    [super dealloc];
}

@end
