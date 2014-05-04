//
//  Appointment.h
//  repWallet
//
//  Created by Alberto Fiore on 1/31/13.
//  Copyright (c) 2013 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Document, Firm, ItemCategory, Photo;

@interface Appointment : NSManagedObject

@property (nonatomic, retain) NSDate * dateTime;
@property (nonatomic, retain) NSNumber * timeLeftToRemind;
@property (nonatomic, retain) NSDate * remindDateTime;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic, retain) NSString * repeat;
@property (nonatomic, retain) NSString * calendarRepeatUnit;
@property (nonatomic, retain) NSDate * insertDate;
@property (nonatomic, retain) NSSet *documents;
@property (nonatomic, retain) Firm *firm;
@property (nonatomic, retain) NSSet *photos;
@property (nonatomic, retain) ItemCategory *itemCategory;
@end

@interface Appointment (CoreDataGeneratedAccessors)

- (void)addDocumentsObject:(Document *)value;
- (void)removeDocumentsObject:(Document *)value;
- (void)addDocuments:(NSSet *)values;
- (void)removeDocuments:(NSSet *)values;
- (void)addPhotosObject:(Photo *)value;
- (void)removePhotosObject:(Photo *)value;
- (void)addPhotos:(NSSet *)values;
- (void)removePhotos:(NSSet *)values;
@end
