//
//  ManagedObjectCloner.m
//  repWallet
//
//  Created by Alberto Fiore on 3/7/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "ManagedObjectCloner.h"


@implementation ManagedObjectCloner

+(NSManagedObject *) clone:(NSManagedObject *)source inContext:(NSManagedObjectContext *)context{
    NSString *entityName = [[source entity] name];
    
    //create new object in data store
    NSManagedObject *cloned = [NSEntityDescription
                               insertNewObjectForEntityForName:entityName
                               inManagedObjectContext:context];
    
    //loop through all attributes and assign then to the clone
    NSDictionary *attributes = [[NSEntityDescription
                                 entityForName:entityName
                                 inManagedObjectContext:context] attributesByName];
    
    for (NSString *attr in attributes) {
        [cloned setValue:[source valueForKey:attr] forKey:attr];
    }
    
    //Loop through all relationships, and clone them.
    NSDictionary *relationships = [[NSEntityDescription
                                    entityForName:entityName
                                    inManagedObjectContext:context] relationshipsByName];
    
    for (NSString *relName in [relationships allKeys]){
        
        NSRelationshipDescription *rel = [relationships objectForKey:relName];
        if ([rel isToMany]) {
            //get a set of all objects in the relationship
            NSArray *sourceArray = [[source mutableSetValueForKey:relName] allObjects];
            NSMutableSet *clonedSet = [cloned mutableSetValueForKey:relName];
            for(NSManagedObject *relatedObject in sourceArray) {
                NSManagedObject *clonedRelatedObject = [ManagedObjectCloner clone:relatedObject inContext:context];
                [clonedSet addObject:clonedRelatedObject];
            }
        } else {
            [cloned setValue:[source valueForKey:relName] forKey:relName];
        }
        
    }
    
    return cloned;
}

@end
