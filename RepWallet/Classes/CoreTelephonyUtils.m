//
//  CoreTelephonyUtils.m
//  repWallet
//
//  Created by Alberto Fiore on 21/02/13.
//  Copyright 2013 Alberto Fiore. All rights reserved.
//

#import "CoreTelephonyUtils.h"

@implementation CoreTelephonyUtils

+ (NSString *) ISOCountryCodeByCarrier {
    CTTelephonyNetworkInfo *networkInfo = [[[CTTelephonyNetworkInfo alloc] init] autorelease];
    CTCarrier *carrier = [networkInfo subscriberCellularProvider];
    return [carrier isoCountryCode];
};

+ (NSString *) countryNameByISO:(NSString *)iso {
    //    NSLocale *locale = [NSLocale currentLocale];
    NSLocale *usLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
    return [usLocale displayNameForKey:NSLocaleCountryCode value:iso];
};

@end
