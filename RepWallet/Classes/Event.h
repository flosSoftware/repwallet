//
//  Event.h
//  repWallet
//
//  Created by Alberto Fiore on 1/31/13.
//  Copyright (c) 2013 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Document, Firm, ItemCategory, Photo;

@interface Event : NSManagedObject

@property (nonatomic, retain) NSString * result;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSNumber * itemQuantity;
@property (nonatomic, retain) NSDate * insertDate;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic, retain) NSString * subject;
@property (nonatomic, retain) NSNumber * itemPerUnitValue;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * taxRate;
@property (nonatomic, retain) Firm *firm;
@property (nonatomic, retain) ItemCategory *itemCategory;
@property (nonatomic, retain) NSSet *photos;
@property (nonatomic, retain) NSSet *documents;
@end

@interface Event (CoreDataGeneratedAccessors)

- (void)addPhotosObject:(Photo *)value;
- (void)removePhotosObject:(Photo *)value;
- (void)addPhotos:(NSSet *)values;
- (void)removePhotos:(NSSet *)values;
- (void)addDocumentsObject:(Document *)value;
- (void)removeDocumentsObject:(Document *)value;
- (void)addDocuments:(NSSet *)values;
- (void)removeDocuments:(NSSet *)values;
@end
