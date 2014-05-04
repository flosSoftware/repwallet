//
//  ManagedObjectCloner.h
//  repWallet
//
//  Created by Alberto Fiore on 3/7/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface ManagedObjectCloner : NSObject

+(NSManagedObject *)clone:(NSManagedObject *)source inContext:(NSManagedObjectContext *)context;

@end
