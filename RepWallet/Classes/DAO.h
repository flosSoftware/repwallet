//
//  DAO.h
//  repWallet
//
//  Created by Alberto Fiore on 3/13/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Firm.h"
#import "Event.h"
#import "UnpaidInvoice.h"
#import "Statistic.h"
#import "ItemCategory.h"
#import "BusinessCategory.h"
#import "Photo.h"

#define EVENT_SUBJECT_CONTACT @"CON"
#define EVENT_SUBJECT_SELL @"SAL"
#define EVENT_RESULT_SELL_OK @"OK"
#define EVENT_RESULT_SELL_KO @"KO"

@interface DAO : NSObject {
@private
    NSManagedObjectContext *managedObjectContext;
    NSManagedObjectModel *managedObjectModel;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
}

@property (nonatomic, retain) NSArray *persistedFirms;
@property (nonatomic, retain) NSString *businessCategoryDBName;
@property (nonatomic, retain) NSString *businessCategoryDBPath;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)mergeChangesFrom_iCloud:(NSNotification *)notification;

- (NSEntityDescription *) getEntityDescriptionForName:(NSString *)entityName;
- (void) saveContext;
- (void) saveEntity:(NSManagedObject *)entity andDiscardOthers:(BOOL)discardOtherPendingInsertions;
- (void) cleanPendingInsertionsInContext;
- (void) deleteEntity:(NSManagedObject *)entity;

- (NSManagedObject *)objectWithURI:(NSURL *)uri;

- (NSArray *) getEntitiesOfType:(NSString *)type excludingPending:(BOOL)excludePending;
- (NSUInteger) countEntitiesOfType:(NSString *)type; 

- (NSArray *) getEntitiesOfType:(NSString *)type forFirm:(Firm *)f excludingPending:(BOOL)excludePending;
- (NSArray *) getFirmsExcludingPending:(BOOL)excludePending excludingSubentities:(BOOL)excludeSubentities withSorting:(BOOL)sortingEnabled propsToFetch:(NSArray *)propsToFetch;
- (NSArray *) getFirmsWithNamesContaining:(NSString *)s excludingPending:(BOOL)excludePending;
- (NSArray *) getFirmWithName:(NSString *)s excludingPending:(BOOL)excludePending;
- (NSUInteger) countFirmsWithNamesContaining:(NSString *)s excludingPending:(BOOL)excludePending;
- (NSArray *) getFirmsWithBusiness:(BusinessCategory *)biz excludingPending:(BOOL)excludePending;
- (NSUInteger) countFirmsWithBusiness:(BusinessCategory *)biz excludingPending:(BOOL)excludePending;

- (NSMutableArray *) getAllItemCategories;
- (ItemCategory *) getItemCategoryWithName:(NSString *)catName;

- (Photo *) getPhotoWithURL:(NSString *)photoURL;

- (BOOL) checkPrimaryKeyOfEntity:(NSManagedObject *)entity ofType:(NSString *)type testUsingFakeObj:(BOOL)usingFake;

- (Statistic *) insertStatsToRemoveForEntity:(NSManagedObject *)entity;
- (NSMutableDictionary *) insertStatsForEntity:(NSManagedObject *)entity;

- (Statistic *) insertStatsToRemoveForEvent:(Event *)evt;
- (NSMutableDictionary *) insertStatsForEvent:(Event *)evt;

- (Statistic *) insertStatsToRemoveForUnpaidInvoice:(UnpaidInvoice *)unp;
- (NSMutableDictionary *) insertStatsForUnpaidInvoice:(UnpaidInvoice *)unp;

- (NSMutableDictionary *) addOrUpdateStatistic:(Statistic *)stat;

- (void) checkAndCreateDatabase;
- (NSMutableArray *) getBusinessCategoriesFromDatabase;
- (void) insertBusinessCategory:(BusinessCategory *)b;
- (void) deleteBusinessCategoryWithDescription:(NSString *)description;
- (void) deleteBusinessCategoryWithParentCode:(NSString *)pCode;

- (NSFetchedResultsController *)fetchedResultsControllerForEntityType:(NSString *)entityType withDelegate:(id)delegate cacheName:(NSString *)cacheName;

@end
