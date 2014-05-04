//
//  AddEditViewControllerDelegate.h
//  repWallet
//
//  Created by Alberto Fiore on 12/17/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Firm.h"
#import <MapKit/MapKit.h>

@protocol AddEditViewControllerDelegate <NSObject>

@optional

- (void) addEditViewControllerAsksDataReloadAndUpdateOfMapCenter:(CLLocation *)center;

- (void) addEditViewControllerOpenedUnpaidWithID:(NSManagedObjectID *)objID;
- (void) addEditViewControllerClosedUnpaidWithID:(NSManagedObjectID *)objID;

- (void) addEditViewControllerOpenedEventWithID:(NSManagedObjectID *)objID;
- (void) addEditViewControllerClosedEventWithID:(NSManagedObjectID *)objID;

- (void) addEditViewControllerOpenedFirmWithID:(NSManagedObjectID *)objID;
- (void) addEditViewControllerClosedFirmWithID:(NSManagedObjectID *)objID;

- (void) addEditViewControllerOpenedAppointmentWithID:(NSManagedObjectID *)objID;
- (void) addEditViewControllerClosedAppointmentWithID:(NSManagedObjectID *)objID;

@end
