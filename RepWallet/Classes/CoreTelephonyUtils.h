//
//  CoreTelephonyUtils.h
//  repWallet
//
//  Created by Alberto Fiore on 21/02/13.
//  Copyright 2013 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

@interface CoreTelephonyUtils : NSObject

+ (NSString *) ISOCountryCodeByCarrier;
+ (NSString *) countryNameByISO:(NSString *)iso;

@end
