//
//  ItemCategory.h
//  repWallet
//
//  Created by Alberto Fiore on 1/31/13.
//  Copyright (c) 2013 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Appointment, Event, Statistic, UnpaidInvoice;

@interface ItemCategory : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *stats;
@property (nonatomic, retain) NSSet *events;
@property (nonatomic, retain) NSSet *unpaids;
@property (nonatomic, retain) NSSet *appointments;
@end

@interface ItemCategory (CoreDataGeneratedAccessors)

- (void)addStatsObject:(Statistic *)value;
- (void)removeStatsObject:(Statistic *)value;
- (void)addStats:(NSSet *)values;
- (void)removeStats:(NSSet *)values;
- (void)addEventsObject:(Event *)value;
- (void)removeEventsObject:(Event *)value;
- (void)addEvents:(NSSet *)values;
- (void)removeEvents:(NSSet *)values;
- (void)addUnpaidsObject:(UnpaidInvoice *)value;
- (void)removeUnpaidsObject:(UnpaidInvoice *)value;
- (void)addUnpaids:(NSSet *)values;
- (void)removeUnpaids:(NSSet *)values;
- (void)addAppointmentsObject:(Appointment *)value;
- (void)removeAppointmentsObject:(Appointment *)value;
- (void)addAppointments:(NSSet *)values;
- (void)removeAppointments:(NSSet *)values;
@end
