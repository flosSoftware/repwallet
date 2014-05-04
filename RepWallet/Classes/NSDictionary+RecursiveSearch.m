//
//  NSDictionary+RecursiveSearch.m
//  repWallet
//
//  Created by Alberto Fiore on 6/12/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "NSDictionary+RecursiveSearch.h"


@implementation NSDictionary (NSDictionary_RecursiveSearch)

- (NSMutableArray *) searchForObjectsWithKey: (NSString *) keyToFind {
    
    NSMutableArray * result = [NSMutableArray array];
    
    for(id key in self) {
        
//        NSLog(@"Ispeziono la chiave: %@", key);
        
        if([key isKindOfClass:[NSString class]] && [key isEqualToString:keyToFind] && [[self objectForKey:key] isKindOfClass:[NSString class]]) {
            
//            NSLog(@"Trovata una corrispondenza");
            
            [result addObject:[self objectForKey:key]];
            
        } else if([key isKindOfClass:[NSString class]] && ![key isEqualToString:keyToFind] && [[self objectForKey:key] isKindOfClass:[NSDictionary class]]) {
            
            [result addObjectsFromArray:[[self objectForKey:key] searchForObjectsWithKey: keyToFind]];
            
        } else if([key isKindOfClass:[NSString class]] && ![key isEqualToString:keyToFind] && [[self objectForKey:key] isKindOfClass:[NSArray class]]) {
            
//            NSLog(@"Il valore è un array");
            
            [result addObjectsFromArray:searchInArrayForObjectsWithKey ([self objectForKey:key], keyToFind)];
            
        } else if([key isKindOfClass:[NSDictionary class]]) {
            
            [result addObjectsFromArray:[key searchForObjectsWithKey: keyToFind]];
            
            if([[self objectForKey:key] isKindOfClass:[NSDictionary class]]) {
                
                [result addObjectsFromArray:[[self objectForKey:key] searchForObjectsWithKey: keyToFind]];
                
            } else if([[self objectForKey:key] isKindOfClass:[NSArray class]]) {
                
//                NSLog(@"Il valore è un array");
                
                [result addObjectsFromArray:searchInArrayForObjectsWithKey ([self objectForKey:key], keyToFind)];
            }
            
        } else if([key isKindOfClass:[NSArray class]]) {
            
//            NSLog(@"La chiave è un array");
            
            if([[self objectForKey:key] isKindOfClass:[NSDictionary class]]) {
                
                [result addObjectsFromArray:[[self objectForKey:key] searchForObjectsWithKey: keyToFind]];
                
            } else if([[self objectForKey:key] isKindOfClass:[NSArray class]]) {
                
//                NSLog(@"Il valore è un array");
                
                [result addObjectsFromArray:searchInArrayForObjectsWithKey ([self objectForKey:key], keyToFind)];
            }
            
        } else
            ;
    }
    
    return result;
}


NSMutableArray * searchInArrayForObjectsWithKey (NSArray * array, NSString * keyToFind) {
    
    NSMutableArray * result = [NSMutableArray array];
    
    for(id item in array) {
        
//        NSLog(@"Ispeziono l'elemento: %@", item);
        
        if([item isKindOfClass:[NSArray class]]) {
            
            [result addObjectsFromArray:searchInArrayForObjectsWithKey (item, keyToFind)];
            
        } else if([item isKindOfClass:[NSDictionary class]]) {
            
            [result addObjectsFromArray:[item searchForObjectsWithKey: keyToFind]];
            
        } else
            ;
    }
    
    return result;
}

@end
