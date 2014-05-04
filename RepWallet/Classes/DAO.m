//
//  DAO.m
//  repWallet
//
//  Created by Alberto Fiore on 3/13/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "DAO.h"
#import "RepWalletAppDelegate.h"
#import "BusinessCategory.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "FMResultSet.h"
#import "NSFileManager+DirectoryLocations.h"

@implementation DAO

@synthesize managedObjectContext=__managedObjectContext;
@synthesize managedObjectModel=__managedObjectModel;
@synthesize persistentStoreCoordinator=__persistentStoreCoordinator;
@synthesize businessCategoryDBName, businessCategoryDBPath;
@synthesize persistedFirms;

- (void)dealloc 
{
    [self.persistedFirms release];
    [self.businessCategoryDBPath release];
    [self.businessCategoryDBName release];
    [__managedObjectContext release];
    [__managedObjectModel release];
    [__persistentStoreCoordinator release];
    [super dealloc];
}

- (NSEntityDescription *) getEntityDescriptionForName: (NSString *)entityName
{
    NSManagedObjectModel *model =
    [[self persistentStoreCoordinator] managedObjectModel];
    NSEntityDescription *entity = [[model entitiesByName] objectForKey:entityName];
    return entity;
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = __managedObjectContext;
    
//    NSLog(@"about to save this ctxt %@",[__managedObjectContext description]);
    
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            [managedObjectContext rollback];
            NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while saving the application data. Changes haven't been committed. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
            [alertView release];            
        }
    }
}


// Save entity (not yet assigned to manObjCtxt) and (optionally) discard other pending entities

- (void) saveEntity:(NSManagedObject *)entity andDiscardOthers:(BOOL)discardOtherPendingInsertions
{
//    NSLog(@"entity %@", [entity description]);

    [__managedObjectContext insertObject:entity];
    
    if(discardOtherPendingInsertions) {
        
        NSSet * firmsNotSaved = [__managedObjectContext insertedObjects];
        
        for(NSManagedObject * firmNotSaved in firmsNotSaved) {
            
            if (![[firmNotSaved objectID] isEqual:[entity objectID]]) {
                [self deleteEntity:firmNotSaved];
            }
        }
        
    }
    
    [self saveContext];
}

- (void) cleanPendingInsertionsInContext 
{
    NSSet * firmsNotSaved = [__managedObjectContext insertedObjects];
    
    for(NSManagedObject * firmNotSaved in firmsNotSaved) {

        [self deleteEntity:firmNotSaved];
    }
}

- (Statistic *) insertStatsToRemoveForEntity:(NSManagedObject *)entity {
        
    if([entity isMemberOfClass:[Event class]]){
        
        return [self insertStatsToRemoveForEvent:(Event *)entity];
        
    } else if([entity isMemberOfClass:[UnpaidInvoice class]]){
         
        return [self insertStatsToRemoveForUnpaidInvoice:(UnpaidInvoice *)entity];
    }
    
    return nil;
}

// Return: -1 if error, 0 if inserted, 1 if update

- (NSMutableDictionary *) insertStatsForEntity:(NSManagedObject *)entity {
    
    if([entity isMemberOfClass:[Event class]]){
        
        return [self insertStatsForEvent:(Event *)entity];
        
    } else if([entity isMemberOfClass:[UnpaidInvoice class]]){
        
        return [self insertStatsForUnpaidInvoice:(UnpaidInvoice *)entity];
        
    } else if([entity isMemberOfClass:[Firm class]]){
        
        NSMutableDictionary * dict = [NSMutableDictionary dictionary];
        [dict setObject:[NSNumber numberWithInt:0] forKey:@"result"];
        [dict setObject:[NSNull null] forKey:@"stat"];
        return dict;
        
    }
    
    return nil;
}


// Stats for Event

// Return: the stat to remove (now inserted in context)

- (Statistic *) insertStatsToRemoveForEvent:(Event *)evt
{
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[evt date]];
    
    Statistic *stat = (Statistic *)[[NSManagedObject alloc] initWithEntity:[self getEntityDescriptionForName:NSStringFromClass([Statistic class])] insertIntoManagedObjectContext:nil];
    
    // Setting the PK Statistic fields
    // [stat setFirm:[evt firm]]; I'll set the Firm in AddEditViewController
    
//    [stat setItemCategory: [evt itemCategory]]; I'll set the Category in AddEditViewController
    
    [stat setRefMonth:[NSNumber numberWithInt:[components month]]];
    
    [stat setRefYear:[NSNumber numberWithInt:[components year]]];
    
    // Setting other fields
    
    if ([[evt subject] isEqualToString:EVENT_SUBJECT_CONTACT]) {
        
//        NSLog(@"Created stat to be removed for contact event: %@", [evt description]);
        
        [stat setNumContacts:[NSNumber numberWithInt:-1]];
        
        [stat setTotMinContacts:[NSNumber numberWithInteger:[[evt duration] integerValue] * -1]];
        
    } else if ([[evt result] isEqualToString:EVENT_RESULT_SELL_OK]
               && [[evt subject] isEqualToString:EVENT_SUBJECT_SELL]) {
        
//        NSLog(@"Created stat to be removed for OK sell event");
        
        [stat setNumSellsOK:[NSNumber numberWithInt:-1]];
        
        double netAmt = [[evt itemPerUnitValue] doubleValue]
        * [[evt itemQuantity] doubleValue];
        
        double taxes = netAmt * [[evt taxRate] doubleValue] / 100.0;
        
        [stat setAmtSellsOK:[NSNumber numberWithDouble: -1.0 * (netAmt + taxes) ]];
        
        [stat setTotMinSellsOK:[NSNumber numberWithInteger:[[evt duration] integerValue] * -1]];
        
    } else {
        
//        NSLog(@"Created stat to be removed for KO sell event");
        
        [stat setNumSellsKO:[NSNumber numberWithInt:-1]];
        
        [stat setTotMinSellsKO:[NSNumber numberWithInteger:[[evt duration] integerValue] * -1]];
        
    }
    
//    NSLog(@"Stat to be removed: %@", [stat description]);
    
    return [stat autorelease];
}

// Return: -1 if error, 0 if inserted, 1 if update

-(NSMutableDictionary *) insertStatsForEvent:(Event *)evt 
{
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[evt date]];
    
    Statistic *stat = (Statistic *)[NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Statistic class]) inManagedObjectContext:__managedObjectContext];
    
    // Setting the PK Statistic fields
    [stat setFirm:[evt firm]];

    [stat setItemCategory: [evt itemCategory]];
    
    [stat setRefMonth:[NSNumber numberWithInt:[components month]]];
    
    [stat setRefYear:[NSNumber numberWithInt:[components year]]];
    
    // Setting other fields
    
    if ([[evt subject] isEqualToString:EVENT_SUBJECT_CONTACT]) {
        
//        NSLog(@"Created stat to be inserted for contact event : %@", [evt description]);
        
        [stat setNumContacts:[NSNumber numberWithInt:1]];
        
        [stat setTotMinContacts:[evt duration]];
        
    } else if ([[evt result] isEqualToString:EVENT_RESULT_SELL_OK]
               && [[evt subject] isEqualToString:EVENT_SUBJECT_SELL]) {
        
//        NSLog(@"Created stat to be inserted for OK sell event");
                   
        [stat setNumSellsOK:[NSNumber numberWithInt:1]];
        
        double netAmt = [[evt itemPerUnitValue] doubleValue]
        * [[evt itemQuantity] doubleValue];
        
        double taxes = netAmt * [[evt taxRate] doubleValue] / 100.0;
        
        [stat setAmtSellsOK:[NSNumber numberWithDouble: netAmt + taxes]];
        
        [stat setTotMinSellsOK:[evt duration]];
        
    } else {
        
//        NSLog(@"Created stat to be inserted for KO sell event");
        
        [stat setNumSellsKO:[NSNumber numberWithInt:1]];
        
        [stat setTotMinSellsKO:[evt duration]];
        
    }
    
//    NSLog(@"Stat description: %@", [stat description]);
    
    return [self addOrUpdateStatistic:stat];
}


// Stats for UnpaidInvoice

// Return: the stat to remove (now inserted in context)

- (Statistic *) insertStatsToRemoveForUnpaidInvoice:(UnpaidInvoice *)unp
{
    // Insert a new stat (autoreleased)
    Statistic *stat = (Statistic *)[[NSManagedObject alloc] initWithEntity:[self getEntityDescriptionForName:NSStringFromClass([Statistic class])] insertIntoManagedObjectContext:nil];
    
    // Setting the PK Statistic fields
    
    // [stat setFirm:[unp firm]]; I'll set the Firm in AddEditViewController
    
//    [stat setItemCategory: [unp itemCategory]]; I'll set the Category in AddEditViewController
    
    // Setting other fields
    
    if ([unp endDate]) {
        
        NSDateComponents *endDateComponents = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[unp endDate]];
        
//        NSLog(@"Created stat to be removed for closed unpaid");
        
        [stat setRefMonth:[NSNumber numberWithInt:[endDateComponents month]]];
            
        [stat setRefYear:[NSNumber numberWithInt:[endDateComponents year]]];
        
        [stat setNumClosedUnpaidInv:[NSNumber numberWithInt:-1]];
        
        [stat setAmtClosedUnpaidInv:[NSNumber numberWithDouble: [[unp amount] doubleValue] * -1.0]];
        
        NSTimeInterval secondsBetween = [[unp endDate] timeIntervalSinceDate:[unp startDate]];
        
        int numberOfDays = secondsBetween / 86400; // 24 * 60 * 60
        
        [stat setTotDayUnresUnpaidInv:[NSNumber numberWithInt: -1 * numberOfDays]];
        
    } else {
        
//        NSLog(@"Created stat to be removed for open unpaid");
        
        NSDateComponents *startDateComponents = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[unp startDate]];
        
        [stat setRefMonth:[NSNumber numberWithInt:[startDateComponents month]]];
        
        [stat setRefYear:[NSNumber numberWithInt:[startDateComponents year]]];
        
        [stat setNumOpenUnpaidInv:[NSNumber numberWithInt:-1]];
        
        [stat setAmtOpenUnpaidInv:[NSNumber numberWithDouble: [[unp amount] doubleValue] * -1.0]];
        
    } 
    
    return [stat autorelease];
}

// Return: -1 if error, 0 if inserted, 1 if update

-(NSMutableDictionary *) insertStatsForUnpaidInvoice:(UnpaidInvoice *)unp
{
    Statistic *stat = (Statistic *)[NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Statistic class]) inManagedObjectContext:__managedObjectContext];
    
    // Setting the PK Statistic fields
    
    [stat setFirm:[unp firm]];
    
    [stat setItemCategory: [unp itemCategory]];
    
    if ([unp endDate]) {
        
        NSDateComponents *endDateComponents = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[unp endDate]];
        
//        NSLog(@"Created stat to be inserted for closed unpaid");
        
        // Setting the PK Statistic fields
        
        [stat setRefMonth:[NSNumber numberWithInt:[endDateComponents month]]];
        
        [stat setRefYear:[NSNumber numberWithInt:[endDateComponents year]]];
        
        // Setting other fields
        
        [stat setNumClosedUnpaidInv:[NSNumber numberWithInt:1]];
        
        [stat setAmtClosedUnpaidInv:[NSNumber numberWithDouble: [[unp amount] doubleValue]]];
        
        NSTimeInterval secondsBetween = [[unp endDate] timeIntervalSinceDate:[unp startDate]];
        
        int numberOfDays = secondsBetween / 86400; // 24 * 60 * 60
        
        [stat setTotDayUnresUnpaidInv:[NSNumber numberWithInt: numberOfDays]];
        
    } else {
        
        NSDateComponents *startDateComponents = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[unp startDate]];
        
//        NSLog(@"Created stat to be inserted for open unpaid");
        
        // Setting the PK Statistic fields
        
        [stat setRefMonth:[NSNumber numberWithInt:[startDateComponents month]]];
        
        [stat setRefYear:[NSNumber numberWithInt:[startDateComponents year]]];
        
        // Setting other fields
        
        [stat setNumOpenUnpaidInv:[NSNumber numberWithInt:1]];
        
        [stat setAmtOpenUnpaidInv:[NSNumber numberWithDouble: [[unp amount] doubleValue]]];
        
    } 
    
//    NSLog(@"Stat description: %@", [stat description]);
    
    return [self addOrUpdateStatistic:stat];
}

// Return dict with 2 values: -1 if error (and stat is is nil), 0 if inserted (and stat is inserted), 1 if update (and stat is updated)

- (NSMutableDictionary *) addOrUpdateStatistic:(Statistic *)stat 
{
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];

    int i = -1;
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease]; 
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([Statistic class]) inManagedObjectContext:__managedObjectContext]; 
    [request setEntity:entity];
    
    NSPredicate *predicate = nil;
    NSError *error = nil;
    NSMutableArray *array = nil;
    
    if ([stat itemCategory] != nil) {
        
        predicate = [NSPredicate predicateWithFormat: @"(firm == %@) AND (refMonth == %@) AND (refYear == %@) AND (itemCategory == %@)", [stat firm], [stat refMonth], [stat refYear], [stat itemCategory]];
        
    } else {
    
        predicate = [NSPredicate predicateWithFormat: @"(firm == %@) AND (refMonth == %@) AND (refYear == %@) AND (itemCategory = nil)", [stat firm], [stat refMonth], [stat refYear]];
    
    }
    
    [request setPredicate:predicate];
    
    array = [[__managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
    
    if (!array) { // handle the error
        
        NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while retrieving the application data. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        
        [dict setObject:[NSNull null] forKey:@"stat"];
        
        [dict setObject:[NSNumber numberWithInt:i] forKey:@"result"];
        
        return dict;
    }
    
//    for (Statistic * st in array) {
//        NSLog(@"addOrUpdateStatistc: array fetched : stat: %@", [st description]);
//    }

    if ([array count] == 1) { // there's already the stat I've inserted in insertStatsForEntity!
        
//        NSLog(@"Inserted statistic %@", [stat description]);
        
        [dict setObject:stat forKey:@"stat"];
        
        i = 0;
        
    } else if([array count] == 2) { // Update the statistic
        
        // Search for the stat with OBJECTID != stat's OBJECTID!
        // NOTE: THERE SHOULD BE ONLY 2 STATS IN THIS ARRAY!
        
        Statistic *stOnDB = [[[array objectAtIndex:0] objectID] isEqual:[stat objectID]]?[array objectAtIndex:1]:[array objectAtIndex:0];
        
//        NSLog(@"Merging stat %@ with stat %@", [stOnDB description], [stat description]);
        
        // Check fields to update and update 'em all
        if ([stat amtSellsOK] != nil) {
            double amtSellsOk = [[stOnDB amtSellsOK] doubleValue];
            [stOnDB setAmtSellsOK:[NSNumber numberWithDouble:[[stat amtSellsOK] doubleValue]  + amtSellsOk]];
        }
        if ([stat amtClosedUnpaidInv] != nil) {
            double amtResUnpaidInv = [[stOnDB amtClosedUnpaidInv] doubleValue];
            [stOnDB setAmtClosedUnpaidInv:[NSNumber numberWithDouble:[[stat amtClosedUnpaidInv] doubleValue]  + amtResUnpaidInv]];
        }
        if ([stat amtOpenUnpaidInv] != nil) {
            double amtUnresUnpaidInv = [[stOnDB amtOpenUnpaidInv] doubleValue];
            [stOnDB setAmtOpenUnpaidInv:[NSNumber numberWithDouble:[[stat amtOpenUnpaidInv] doubleValue]  + amtUnresUnpaidInv]];
        }
        if ([stat numClosedUnpaidInv] != nil) {
            int numResUnpaidInv = [[stOnDB numClosedUnpaidInv] intValue];
            [stOnDB setNumClosedUnpaidInv:[NSNumber numberWithInt:[[stat numClosedUnpaidInv] intValue]  + numResUnpaidInv]];
        }
        if ([stat numOpenUnpaidInv] != nil) {
            int numUnresUnpaidInv = [[stOnDB numOpenUnpaidInv] intValue];
            [stOnDB setNumOpenUnpaidInv:[NSNumber numberWithInt:[[stat numOpenUnpaidInv] intValue]  + numUnresUnpaidInv]];
        }
        if ([stat numContacts] != nil) {
            int numContacts = [[stOnDB numContacts] intValue];
            [stOnDB setNumContacts:[NSNumber numberWithInt:[[stat numContacts] intValue]  + numContacts]];
        }
        if ([stat numSellsOK] != nil) {
            int numSellsOK = [[stOnDB numSellsOK] intValue];
            [stOnDB setNumSellsOK:[NSNumber numberWithInt:[[stat numSellsOK] intValue]  + numSellsOK]];
        }
        if ([stat numSellsKO] != nil) {
            int numSellsKO = [[stOnDB numSellsKO] intValue];
            [stOnDB setNumSellsKO:[NSNumber numberWithInt:[[stat numSellsKO] intValue]  + numSellsKO]];
        }
        if ([stat totMinContacts] != nil) {
            NSInteger totMinContacts = [[stOnDB totMinContacts] integerValue];
            [stOnDB setTotMinContacts:[NSNumber numberWithInteger:[[stat totMinContacts] integerValue]  + totMinContacts]];
        }
        if ([stat totMinSellsOK] != nil) {
            NSInteger totMinSellsOK = [[stOnDB totMinSellsOK] integerValue];
            [stOnDB setTotMinSellsOK:[NSNumber numberWithInteger:[[stat totMinSellsOK] integerValue]  + totMinSellsOK]];
        }
        if ([stat totMinSellsKO] != nil) {
            NSInteger totMinSellsKO = [[stOnDB totMinSellsKO] integerValue];
            [stOnDB setTotMinSellsKO:[NSNumber numberWithInteger:[[stat totMinSellsKO] integerValue]  + totMinSellsKO]];
        }
        if ([stat totDayUnresUnpaidInv] != nil) {
            NSInteger totDayUnresUnpaidInv = [[stOnDB totDayUnresUnpaidInv] integerValue];
            [stOnDB setTotDayUnresUnpaidInv:[NSNumber numberWithInteger:[[stat totDayUnresUnpaidInv] integerValue]  + totDayUnresUnpaidInv]];
        }
        
        // Done with merging
        [self deleteEntity:stat];
        
//        NSLog(@"Updated statistic to %@", [stOnDB description]);
        
        [dict setObject:stOnDB forKey:@"stat"];
        
        // let's clean the stats graph from stats with all zero-valued fields (except PK)
        
        if([stOnDB isEmpty])
            [self deleteEntity:stOnDB];
        
        i = 1;
        
    } else
        
        [dict setObject:[NSNull null] forKey:@"stat"]; // i = -1
    
//    NSLog(@"%i", i);
    
    [dict setObject:[NSNumber numberWithInt:i] forKey:@"result"];
    
    [array release];
    
    return dict;
}

#pragma mark - Core Data stack


/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil)
    {
        return __managedObjectContext;
    }
    // else
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        // TODO: ICLOUD SYNC BETWEEN DEVICES
        // borrowed from http://timroadley.com/2012/04/03/core-data-in-icloud/
        
//        __managedObjectContext = [[NSManagedObjectContext alloc] init];
//        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
        
        NSManagedObjectContext* moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        
        [moc performBlockAndWait:^{
            [moc setPersistentStoreCoordinator: coordinator];
            [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(mergeChangesFrom_iCloud:) name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:coordinator];
        }];
        __managedObjectContext = moc;
    }
    return __managedObjectContext;
}


- (void)mergeChangesFrom_iCloud:(NSNotification *)notification {
    
	NSLog(@"Merging in changes from iCloud...");
    
    NSManagedObjectContext* moc = [self managedObjectContext];
    
    [moc performBlock:^{
        
        [moc mergeChangesFromContextDidSaveNotification:notification];
        
        NSNotification* refreshNotification = [NSNotification notificationWithName:@"SomethingChanged"
                                                                            object:self
                                                                          userInfo:[notification userInfo]];
        
        [[NSNotificationCenter defaultCenter] postNotification:refreshNotification];
    }];
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil)
    {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"DataModel" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];   
    
//    if(modelURL)
//        NSLog(@"MODEL URL %@",[modelURL path]);
    
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil)
    {
        return __persistentStoreCoordinator;
    }
    
    
    NSString *dataFileName = REPWALLET_DB_NAME;
    
    NSFileManager *theFiles = [[NSFileManager alloc] init];
    
    NSString *storePath = [[theFiles applicationSupportDirectory] stringByAppendingPathComponent:dataFileName];
    
//    if(storePath)
//        NSLog(@"Path of core data store is %@", storePath);
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSPersistentStoreCoordinator *psc = __persistentStoreCoordinator;
    
    
    // TODO: ICLOUD SYNC BETWEEN DEVICES
    // borrowed from http://timroadley.com/2012/04/03/core-data-in-icloud/
    
    // Set up iCloud in another thread:
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // iCloud ID
        NSString *iCloudEnabledAppID = REPWALLET_APP_ID;
        
        NSString *iCloudDataDirectoryName = @"Data.nosync";
        NSString *iCloudLogsDirectoryName = @"Logs";
        NSURL *localStore = [NSURL fileURLWithPath:[[theFiles applicationDocumentsDirectory] stringByAppendingPathComponent:dataFileName]];
        NSURL *iCloud = [theFiles URLForUbiquityContainerIdentifier:nil];
        
        if (iCloud) {
            
            NSLog(@"iCloud is working");
            
            NSURL *iCloudLogsPath = [NSURL fileURLWithPath:[[iCloud path] stringByAppendingPathComponent:iCloudLogsDirectoryName]];
            
            NSLog(@"iCloudEnabledAppID = %@",iCloudEnabledAppID);
            NSLog(@"dataFileName = %@", dataFileName);
            NSLog(@"iCloudDataDirectoryName = %@", iCloudDataDirectoryName);
            NSLog(@"iCloudLogsDirectoryName = %@", iCloudLogsDirectoryName);
            NSLog(@"iCloud = %@", iCloud);
            NSLog(@"iCloudLogsPath = %@", iCloudLogsPath);
            
            if([theFiles fileExistsAtPath:[[iCloud path] stringByAppendingPathComponent:iCloudDataDirectoryName]] == NO) {
                NSError *fileSystemError;
                [theFiles createDirectoryAtPath:[[iCloud path] stringByAppendingPathComponent:iCloudDataDirectoryName]
                       withIntermediateDirectories:YES
                                        attributes:nil
                                             error:&fileSystemError];
                if(fileSystemError != nil) {
                    NSLog(@"Error creating database directory %@", fileSystemError);
                }
            }
            
            NSString *iCloudData = [[[iCloud path]
                                     stringByAppendingPathComponent:iCloudDataDirectoryName]
                                    stringByAppendingPathComponent:dataFileName];
            
            NSLog(@"iCloudData = %@", iCloudData);
            
            NSMutableDictionary *options = [NSMutableDictionary dictionary];
            [options setObject:[NSNumber numberWithBool:YES] forKey:NSMigratePersistentStoresAutomaticallyOption];
            [options setObject:[NSNumber numberWithBool:YES] forKey:NSInferMappingModelAutomaticallyOption];
            [options setObject:iCloudEnabledAppID            forKey:NSPersistentStoreUbiquitousContentNameKey];
            [options setObject:iCloudLogsPath                forKey:NSPersistentStoreUbiquitousContentURLKey];
            
            [psc lock];
            
            [psc addPersistentStoreWithType:NSSQLiteStoreType
                              configuration:nil
                                        URL:[NSURL fileURLWithPath:iCloudData]
                                    options:options
                                      error:nil];
            
            [psc unlock];
        }
        else {
//            NSLog(@"iCloud is NOT working - using a local store");
            NSMutableDictionary *options = [NSMutableDictionary dictionary];
            [options setObject:[NSNumber numberWithBool:YES] forKey:NSMigratePersistentStoresAutomaticallyOption];
            [options setObject:[NSNumber numberWithBool:YES] forKey:NSInferMappingModelAutomaticallyOption];
            
            [psc lock];
            
            [psc addPersistentStoreWithType:NSSQLiteStoreType
                              configuration:nil
                                        URL:localStore
                                    options:options
                                      error:nil];
            [psc unlock];
            
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self userInfo:nil];
        });
    });

    
    
//    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[NSURL fileURLWithPath:storePath] options:nil error:&error])
//    {
//        /*
//         Replace this implementation with code to handle the error appropriately.
//         
//         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
//         
//         Typical reasons for an error here include:
//         * The persistent store is not accessible;
//         * The schema for the persistent store is incompatible with current managed object model.
//         Check the error message to determine what the actual problem was.
//         
//         
//         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
//         
//         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
//         * Simply deleting the existing store:
//         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
//         
//         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
//         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
//         
//         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
//         
//         */
//        
//        NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while connecting to the application database. Please quit the application using the Home button. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
//        [alertView show];
//        [alertView release];
//    }
    
    [theFiles release];
    
    return __persistentStoreCoordinator;
}

#pragma mark -
#pragma mark Deletion methods

- (void)deleteEntity:(NSManagedObject *)entity
{
    [__managedObjectContext deleteObject:entity];
}

#pragma mark -
#pragma mark query methods

- (NSManagedObject *)objectWithURI:(NSURL *)uri
{
    NSManagedObjectID *objectID =
    [[self persistentStoreCoordinator]
     managedObjectIDForURIRepresentation:uri];
    
    if (!objectID)
    {
        return nil;
    }
    
    NSManagedObject *objectForID = [__managedObjectContext objectWithID:objectID];
    if (![objectForID isFault])
    {
        return objectForID;
    }
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:[objectID entity]];
    
    // Equivalent to
    // predicate = [NSPredicate predicateWithFormat:@"SELF = %@", objectForID];
    NSPredicate *predicate =
    [NSComparisonPredicate
     predicateWithLeftExpression:
     [NSExpression expressionForEvaluatedObject]
     rightExpression:
     [NSExpression expressionForConstantValue:objectForID]
     modifier:NSDirectPredicateModifier
     type:NSEqualToPredicateOperatorType
     options:0];
    [request setPredicate:predicate];
    
    NSArray *results = [__managedObjectContext executeFetchRequest:request error:nil];
    if ([results count] > 0 )
    {
        return [results objectAtIndex:0];
    }
    
    return nil;
}

// excludes or includes pending objects (firms which have been inserted but not yet saved in the persistence store)
- (NSArray *) getFirmsExcludingPending:(BOOL)excludePending excludingSubentities:(BOOL)excludeSubentities withSorting:(BOOL)sortingEnabled propsToFetch:(NSArray *)propsToFetch
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([Firm class]) inManagedObjectContext:__managedObjectContext];
    [request setEntity:entity];

    if (sortingEnabled) {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"firmName" ascending:YES];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil]; 
        [request setSortDescriptors:sortDescriptors]; 
        [sortDescriptors release]; 
        [sortDescriptor release];
    }

    if(excludeSubentities)
        [request setIncludesSubentities:NO];
    else
        [request setIncludesSubentities:YES];
    
    if(excludePending)
        [request setIncludesPendingChanges:NO];
    else
        [request setIncludesPendingChanges:YES];
    
    if (propsToFetch) {
        
        [request setResultType:NSDictionaryResultType];
        
        NSDictionary * dict = [entity attributesByName];
        
        NSMutableArray *propsDesc = [NSMutableArray arrayWithCapacity:propsToFetch.count];
        
        for (NSString * propName in propsToFetch) {
            
            if([dict objectForKey:propName]) {
                [propsDesc addObject:[dict objectForKey:propName]];
            }
        }
        
        [request setPropertiesToFetch:propsDesc];
    }
    
    NSError *error = nil;
    NSArray *fetchResults = [__managedObjectContext executeFetchRequest:request error:&error];
    [request release];
    if (fetchResults == nil) { // Handle the error.
        NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while retrieving the application data. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        return [NSArray array];
    }
    
//    self.persistedFirms = fetchResults;
//      
//    return self.persistedFirms;
    
    return fetchResults;
}

- (NSArray *) getFirmsWithBusiness:(BusinessCategory *)biz excludingPending:(BOOL)excludePending {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([Firm class]) inManagedObjectContext:__managedObjectContext];
    [request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"econSector == %@", biz.businessCategoryDescription];
    [request setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"firmName" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil]; 
    [request setSortDescriptors:sortDescriptors]; 
    [sortDescriptors release]; 
    [sortDescriptor release];
    if(excludePending)
        [request setIncludesPendingChanges:NO];
    else
        [request setIncludesPendingChanges:YES];
    NSError *error = nil;
    NSArray *fetchResults = [__managedObjectContext executeFetchRequest:request error:&error];
    [request release];
    if (fetchResults == nil) { // Handle the error.
        NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while retrieving the application data. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        return [NSArray array];
    }
    
    return fetchResults;
}

- (NSUInteger) countFirmsWithBusiness:(BusinessCategory *)biz excludingPending:(BOOL)excludePending  
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:NSStringFromClass([Firm class]) inManagedObjectContext:__managedObjectContext]];
    
    [request setIncludesSubentities:NO]; //Omit subentities. Default is YES (i.e. include subentities)
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"econSector == %@", biz.businessCategoryDescription];
    [request setPredicate:predicate];
    if(excludePending)
        [request setIncludesPendingChanges:NO];
    else
        [request setIncludesPendingChanges:YES];
    NSError *error;
    NSUInteger count = [__managedObjectContext countForFetchRequest:request error:&error];
    
    [request release];  
    
    if(count == NSNotFound) {
        NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while retrieving the application data. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        return -1;
    }
    
    return count;
}

- (NSArray *) getFirmWithName:(NSString *)s excludingPending:(BOOL)excludePending {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([Firm class]) inManagedObjectContext:__managedObjectContext];
    [request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"firmName = %@", s];
    [request setPredicate:predicate];
    if(excludePending)
        [request setIncludesPendingChanges:NO];
    else
        [request setIncludesPendingChanges:YES];
    NSError *error = nil;
    NSArray *fetchResults = [__managedObjectContext executeFetchRequest:request error:&error];
    [request release];
    if (fetchResults == nil) { // Handle the error.
        NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while retrieving the application data. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        return [NSArray array];
    }
    
    return fetchResults;
}

- (NSArray *) getFirmsWithNamesContaining:(NSString *)s excludingPending:(BOOL)excludePending {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([Firm class]) inManagedObjectContext:__managedObjectContext];
    [request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"firmName CONTAINS[cd] %@", s];
    [request setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"firmName" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil]; 
    [request setSortDescriptors:sortDescriptors]; 
    [sortDescriptors release]; 
    [sortDescriptor release];
    if(excludePending)
        [request setIncludesPendingChanges:NO];
    else
        [request setIncludesPendingChanges:YES];
    NSError *error = nil;
    NSArray *fetchResults = [__managedObjectContext executeFetchRequest:request error:&error];
    [request release];
    if (fetchResults == nil) { // Handle the error.
        NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while retrieving the application data. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        return [NSArray array];
    }
    
    return fetchResults;
}

- (NSUInteger) countFirmsWithNamesContaining:(NSString *)s excludingPending:(BOOL)excludePending  
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:NSStringFromClass([Firm class]) inManagedObjectContext:__managedObjectContext]];
    
    [request setIncludesSubentities:NO]; //Omit subentities. Default is YES (i.e. include subentities)
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"firmName CONTAINS[cd] %@", s];
    [request setPredicate:predicate];
    if(excludePending)
        [request setIncludesPendingChanges:NO];
    else
        [request setIncludesPendingChanges:YES];
    NSError *error;
    NSUInteger count = [__managedObjectContext countForFetchRequest:request error:&error];
    
    [request release];  
    
    if(count == NSNotFound) {
        NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while retrieving the application data. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        return -1;
    }
    
    return count;
}

- (NSArray *) getEntitiesOfType:(NSString *)type forFirm:(Firm *)f excludingPending:(BOOL)excludePending 
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:type inManagedObjectContext:__managedObjectContext];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(firm == %@)", f];
    [request setEntity:entity];
    [request setPredicate:predicate];
    if(excludePending)
        [request setIncludesPendingChanges:NO];
    else
        [request setIncludesPendingChanges:YES];
    NSError *error = nil;
    NSArray *fetchResults = [__managedObjectContext executeFetchRequest:request error:&error];
    
    [request release];
    
    if (fetchResults == nil) { // Handle the error.
        NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while retrieving the application data. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        return [NSArray array];
    }
    
    return fetchResults;
}

- (NSArray *) getEntitiesOfType:(NSString *)type excludingPending:(BOOL)excludePending 
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:type inManagedObjectContext:__managedObjectContext];
    
    [request setEntity:entity];
    
    if(excludePending)
        [request setIncludesPendingChanges:NO];
    else
        [request setIncludesPendingChanges:YES];
    
    NSError *error = nil;
    
    NSArray *fetchResults = [__managedObjectContext executeFetchRequest:request error:&error];
    
    [request release];
    
    if (fetchResults == nil) { // Handle the error.
        NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while retrieving the application data. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        return [NSArray array];
    }
    
    return fetchResults;
}

- (NSUInteger) countEntitiesOfType:(NSString *)type 
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:type inManagedObjectContext:__managedObjectContext]];
    
    [request setIncludesSubentities:NO]; //Omit subentities. Default is YES (i.e. include subentities)
    
    NSError *error;
    NSUInteger count = [__managedObjectContext countForFetchRequest:request error:&error];
    
    [request release];
    
    if(count == NSNotFound) {
        NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while retrieving the application data. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        return -1;
    }
    
    return count;
}

- (NSMutableArray *) getAllItemCategories
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([ItemCategory class]) inManagedObjectContext:__managedObjectContext]; 
    [request setEntity:entity];
    
    NSDictionary * dict = [entity attributesByName];
    
    if([dict objectForKey:@"name"]) {
        [request setResultType:NSDictionaryResultType];
        [request setPropertiesToFetch:[NSArray arrayWithObject:[dict objectForKey:@"name"]]];
    }
    
    request.sortDescriptors = [NSArray arrayWithObject:
                               [NSSortDescriptor sortDescriptorWithKey:@"name" 
                                                             ascending:YES 
                                                              selector:@selector(compare:)]];
    
    [request setReturnsDistinctResults:YES];
    [request setIncludesPendingChanges:NO];
    
    NSError *error = nil;
    NSArray *fetchResults = [__managedObjectContext executeFetchRequest:request error:&error];
    
    [request release];
    
    if (fetchResults == nil) { // Handle the error.
        NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while retrieving the application data. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        return [NSMutableArray arrayWithCapacity:0];
    }
    
    NSMutableArray * mutableFetchResults = [NSMutableArray array];
    for (NSDictionary * dict in fetchResults) {
        if ([dict objectForKey:@"name"]) {
            [mutableFetchResults addObject:[dict objectForKey:@"name"]];
        }
    }
    
    return mutableFetchResults;
}

- (ItemCategory *) getItemCategoryWithName:(NSString *)catName
{
    ItemCategory * cat = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([ItemCategory class]) inManagedObjectContext:__managedObjectContext]; 
    [request setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(name == %@)", catName];
    [request setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchResults = [__managedObjectContext executeFetchRequest:request error:&error];
    
    [request release];
    
    if (fetchResults == nil) { // Handle the error.
        NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while retrieving the application data. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        return [NSMutableArray arrayWithCapacity:0];
    }
    
    
    if ([fetchResults count] > 0) {
        cat = [fetchResults objectAtIndex:0];
    }
    
    return cat;
}

- (Photo *) getPhotoWithURL:(NSString *)photoURL
{
    Photo * ph = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([Photo class]) inManagedObjectContext:__managedObjectContext]; 
    [request setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(url == %@)", photoURL];
    [request setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchResults = [__managedObjectContext executeFetchRequest:request error:&error];
    
    [request release];
    
    if (fetchResults == nil) { // Handle the error.
        NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while retrieving the application data. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        return [NSMutableArray arrayWithCapacity:0];
    }
    
    if ([fetchResults count] > 0) {
        ph = [fetchResults objectAtIndex:0];
    }
    
    return ph;
}

#pragma mark -
#pragma mark validation methods

- (BOOL) checkPrimaryKeyOfEntity:(NSManagedObject *)entity ofType:(NSString *)type testUsingFakeObj:(BOOL)usingFake
{
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    
    [request setEntity:[NSEntityDescription entityForName:type inManagedObjectContext:__managedObjectContext]];
    
    if([type isEqualToString:NSStringFromClass([Firm class])]){
        Firm * f = (Firm *)entity;
        [request setPredicate:[NSPredicate predicateWithFormat:@"firmName = %@", f.firmName]];
    } else if([type isEqualToString:NSStringFromClass([ItemCategory class])]){
        ItemCategory * c = (ItemCategory *)entity;
        [request setPredicate:[NSPredicate predicateWithFormat:@"name = %@", c.name]];
    }
    NSError * error = nil;
    NSUInteger count = [__managedObjectContext countForFetchRequest:request error:&error];
    [request release];
    if (error) {
        NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while retrieving the application data. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        return false;
    }
    if(usingFake && count > 1)
        return false;
    else if(!usingFake && count > 0)
        return false;
    else
        return true;
}

#pragma mark -
#pragma mark business categories

- (void) checkAndCreateDatabase
{
	// Check if the SQL database has already been saved to the users phone, if not then copy it over
	BOOL success;
    
	// Create a FileManager object, we will use this to check the status
	// of the database and to copy it over if required
	NSFileManager *fileManager = [NSFileManager defaultManager];
    
	// Check if the database has already been created in the users filesystem
	success = [fileManager fileExistsAtPath:self.businessCategoryDBPath];
    
	// If the database already exists then return without doing anything
	if(success) 
        return;
    
	// If not then proceed to copy the database from the application to the users filesystem
    
	// Get the path to the database in the application package
	NSString *databasePathFromApp = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:self.businessCategoryDBName];
    
	// Copy the database from the package to the users filesystem
	[fileManager copyItemAtPath:databasePathFromApp toPath:self.businessCategoryDBPath error:nil];
}

- (NSMutableArray *) getBusinessCategoriesFromDatabase {

    NSMutableArray *businessCategories = [NSMutableArray array];
    
    FMDatabase *db = [FMDatabase databaseWithPath:self.businessCategoryDBPath];
    
    if (![db open]) {

        return nil;
    }
    
    FMResultSet *s = [db executeQuery:@"SELECT * FROM businessCategory"];
    
    while ([s next]) {

        BusinessCategory * businessCategory = [[[BusinessCategory alloc] 
                                                initWithCode:
                                                [s stringForColumn:@"bCatCode"]
                                                                        
                                                parentCode:
                                                [s stringForColumn:@"parentBCatCode"]
                                                                        
                                                description:
                                                [s stringForColumn:@"bCatDesc"]
                                                ] 
                                               autorelease];
        
        [businessCategories addObject:businessCategory];
    }
    
    [db close];
    
    return businessCategories;
}

- (void) insertBusinessCategory:(BusinessCategory *)b {
    
    FMDatabase *db = [FMDatabase databaseWithPath:self.businessCategoryDBPath];
    
    if (![db open]) {
        return;
    }
    
    if(![db executeUpdate:@"INSERT INTO businessCategory VALUES (?, ?, ?)", b.businessCategoryCode, b.parentBusinessCategoryCode, b.businessCategoryDescription]) {
        NSString * errorDesc = [db lastErrorMessage] ? [db lastErrorMessage] : @"";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while updating the application data. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
    }
    
    [db close];
}

- (void) deleteBusinessCategoryWithDescription:(NSString *)description {

    FMDatabase *db = [FMDatabase databaseWithPath:self.businessCategoryDBPath];
    
    if (![db open]) {
        return;
    }
    
    if(![db executeUpdate:@"DELETE FROM businessCategory WHERE bCatDesc = ?", description]) {
        NSString * errorDesc = [db lastErrorMessage] ? [db lastErrorMessage] : @"";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while updating the application data. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
    }
    
    [db close];
}

- (void) deleteBusinessCategoryWithParentCode:(NSString *)pCode {
    
    FMDatabase *db = [FMDatabase databaseWithPath:self.businessCategoryDBPath];
    
    if (![db open]) {
        return;
    }
    
    if(![db executeUpdate:@"DELETE FROM businessCategory WHERE parentBCatCode = ?", pCode]) {
        NSString * errorDesc = [db lastErrorMessage] ? [db lastErrorMessage] : @"";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while updating the application data. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
    }
    
    [db close];
}

#pragma mark -
#pragma mark fetched results controller


- (NSFetchedResultsController *)fetchedResultsControllerForEntityType:(NSString *)entityType withDelegate:(id)delegate cacheName:(NSString *)cacheName {
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityType inManagedObjectContext:__managedObjectContext];
    [request setEntity:entity];
    
    if ([entityType isEqualToString:NSStringFromClass([Firm class])]) {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"firmName" ascending:YES];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil]; 
        [request setSortDescriptors:sortDescriptors]; 
        [sortDescriptors release]; 
        [sortDescriptor release];
    } else if ([entityType isEqualToString:NSStringFromClass([Event class])]) {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil]; 
        [request setSortDescriptors:sortDescriptors]; 
        [sortDescriptors release]; 
        [sortDescriptor release];
    }  else if ([entityType isEqualToString:NSStringFromClass([UnpaidInvoice class])]) {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"startDate" ascending:NO];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil]; 
        [request setSortDescriptors:sortDescriptors]; 
        [sortDescriptors release]; 
        [sortDescriptor release];
    }  else if ([entityType isEqualToString:NSStringFromClass([Appointment class])]) {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateTime" ascending:NO];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil]; 
        [request setSortDescriptors:sortDescriptors]; 
        [sortDescriptors release]; 
        [sortDescriptor release];
    }  


    [request setIncludesPendingChanges:NO];
    
    [request setFetchBatchSize:10];
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                        managedObjectContext:__managedObjectContext sectionNameKeyPath:nil
                                                   cacheName:cacheName];
    theFetchedResultsController.delegate = delegate;
    
    [request release];
    
    return [theFetchedResultsController autorelease];
}


@end
