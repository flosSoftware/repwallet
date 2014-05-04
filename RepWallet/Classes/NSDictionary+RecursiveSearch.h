//
//  NSDictionary+RecursiveSearch.h
//  repWallet
//
//  Created by Alberto Fiore on 6/12/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDictionary (NSDictionary_RecursiveSearch)

// metodo che permette di ricercare valore di tipo stringa di una chiave di tipo stringa in un dizionario
// di tipo complesso (ad. es. dizionario che può - ricorsivamente - avere come chiave 
// e/o come valore strutture dati quali dizionari e array)
// non sono supportati insiemi (vengono tralasciati nella ricerca) o altre strutture dati diverse da dizionari
// e array

- (NSMutableArray *) searchForObjectsWithKey: (NSString *) keyToFind;

// funzione ausiliaria per ricercare in array di dizionari (complessi)

NSMutableArray * searchInArrayForObjectsWithKey (NSArray * array, NSString * keyToFind);

@end
