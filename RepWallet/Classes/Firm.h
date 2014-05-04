//
//  Firm.h
//  repWallet
//
//  Created by Alberto Fiore on 1/31/13.
//  Copyright (c) 2013 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Mappable.h"

@class Appointment, Document, Event, Photo, Statistic, UnpaidInvoice;

@interface Firm : NSManagedObject<Mappable>

@property (nonatomic, retain) NSString * refSecondName;
@property (nonatomic, retain) NSString * state;
@property (nonatomic, retain) NSString * zip;
@property (nonatomic, retain) NSDate * insertDate;
@property (nonatomic, retain) NSString * refFirstName;
@property (nonatomic, retain) NSString * phoneNr2;
@property (nonatomic, retain) NSString * town;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSString * refRole;
@property (nonatomic, retain) NSString * street;
@property (nonatomic, retain) NSString * eMail;
@property (nonatomic, retain) NSString * econSector;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * score;
@property (nonatomic, retain) NSString * country;
@property (nonatomic, retain) NSString * firmName;
@property (nonatomic, retain) NSString * faxNr;
@property (nonatomic, retain) NSString * phoneNr1;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic, retain) NSSet *appointments;
@property (nonatomic, retain) NSSet *stats;
@property (nonatomic, retain) NSSet *photos;
@property (nonatomic, retain) NSSet *unpaidInvs;
@property (nonatomic, retain) NSSet *documents;
@property (nonatomic, retain) NSSet *events;
@end

@interface Firm (CoreDataGeneratedAccessors)

- (void)addAppointmentsObject:(Appointment *)value;
- (void)removeAppointmentsObject:(Appointment *)value;
- (void)addAppointments:(NSSet *)values;
- (void)removeAppointments:(NSSet *)values;
- (void)addStatsObject:(Statistic *)value;
- (void)removeStatsObject:(Statistic *)value;
- (void)addStats:(NSSet *)values;
- (void)removeStats:(NSSet *)values;
- (void)addPhotosObject:(Photo *)value;
- (void)removePhotosObject:(Photo *)value;
- (void)addPhotos:(NSSet *)values;
- (void)removePhotos:(NSSet *)values;
- (void)addUnpaidInvsObject:(UnpaidInvoice *)value;
- (void)removeUnpaidInvsObject:(UnpaidInvoice *)value;
- (void)addUnpaidInvs:(NSSet *)values;
- (void)removeUnpaidInvs:(NSSet *)values;
- (void)addDocumentsObject:(Document *)value;
- (void)removeDocumentsObject:(Document *)value;
- (void)addDocuments:(NSSet *)values;
- (void)removeDocuments:(NSSet *)values;
- (void)addEventsObject:(Event *)value;
- (void)removeEventsObject:(Event *)value;
- (void)addEvents:(NSSet *)values;
- (void)removeEvents:(NSSet *)values;
@end
