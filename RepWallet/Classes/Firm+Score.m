//
//  Firm+Score.m
//  repWallet
//
//  Created by Alberto Fiore on 6/4/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "Firm+Score.h"
#import "ItemCategory.h"


@implementation Firm (Firm_Score)

double variance(double* array, int length) {
    
    if (length == 0)
        return 0;
    
    if (length == 1)
        return 0;
    
    double sum1 = 0.0;
    double sum2 = 0.0;
    
    for (double * x = array; x < array + length; x++) {
        sum1 = sum1 + *x;
    }
    
    double mean = sum1 / length;
    
    for (double * x = array; x < array + length; x++) {
        sum2 = sum2 + (*x - mean) * (*x - mean);
    }
    
    double variance = sum2 / (length - 1);
    
    return variance;
}

// Normalizza seguendo il metodo num. 1 descritto in
// http://people.revoledu.com/kardi/tutorial/Similarity/Normalization.html
// restituisce un valore tra [0, 1]

double normalize(double d, double smoothparam) {
    
    if (smoothparam < 0)
        return -1.0;
    
    double normalized = 0.5 * (1.0 - (d / sqrt(pow(d, 2.0)
                                               + smoothparam)));
    
    return normalized;
}

- (NSComparisonResult)compareTo:(Firm *)anObject {
    return [self.firmName compare:[anObject firmName]];
}

- (NSNumber *)calculateScore:(DAO *)dao {
    
    double score = 0.0;
    
    // Recupero le item categories dalle stats del cliente:
    
    // Le stats con categorie NIL (se esistono)
    // si riferiscono a contatti di non pre-vendita
    // (contatti generici),
    // quindi non sono utili ai fini statistici
    // (per le componenti relative a una categoria).
    // Pertanto s'è deciso di non considerare
    // i contatti generici nel computo del punteggio.
    
    NSPredicate *predicate = nil;
    NSSet * statsSet = nil;
    NSSet * evtSet = nil;
    
    // calcolo gli estremi temporali di ricerca
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDate * today = [NSDate date];
    NSDateComponents *todayComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:today];
    int todayMonth = [todayComponents month];
    int todayYear = [todayComponents year];
    
    // sottraggo 1 mese
    
    int monthsToSub = -1;
    
    NSDateComponents *comp = [[[NSDateComponents alloc] init] autorelease];
    [comp setMonth:monthsToSub];
    
    NSDate *prevMonth = [calendar dateByAddingComponents:comp toDate:today options:0];
    NSDateComponents *prevMonthComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:prevMonth];
    int prevMonthMonth = [prevMonthComponents month];
    int prevMonthYear = [prevMonthComponents year];
    
    NSDate *twoMonthsAgo = [calendar dateByAddingComponents:comp toDate:prevMonth options:0];
    NSDateComponents *twoMonthsAgoComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:twoMonthsAgo];
    int twoMonthsAgoMonth = [twoMonthsAgoComponents month];
    int twoMonthsAgoYear = [twoMonthsAgoComponents year];
    
    monthsToSub = -12;
    
    [comp setMonth:monthsToSub];
    
    NSDate *oneYearAgo = [calendar dateByAddingComponents:comp toDate:today options:0];
    NSDateComponents *oneYearAgoComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:oneYearAgo];
    int oneYearAgoMonth = [oneYearAgoComponents month];
    int oneYearAgoYear = [oneYearAgoComponents year];
    
    // Insoluti aperti/chiusi (12 mesi precedenti)
    // per tutte le categorie del cliente
    
    int numUnpaidsUnresAllCatThisYear = 0;
    int numUnpaidsResAllCatThisYear = 0;
    
    double avgAmtUnpaidsUnresAllCatThisYear = 0.0;
    double avgAmtUnpaidsResAllCatThisYear = 0.0;
    
    // Fatturato (12 mesi precedenti)
    // per tutte le categorie del cliente
    // il default = 1 per evitare NaN
    
    double incomeAllCatThisYear = 1.0;
    
    NSNumber * startSearchMonth = [NSNumber numberWithInt:oneYearAgoMonth];
    NSNumber * startSearchYear = [NSNumber numberWithInt:oneYearAgoYear];
    NSNumber * endSearchMonth = [NSNumber numberWithInt:todayMonth];
    NSNumber * endSearchYear = [NSNumber numberWithInt:todayYear];
    
    
    predicate = [NSPredicate predicateWithFormat: @"(refMonth >= %@ AND refYear == %@) OR (refMonth <= %@ AND refYear == %@) OR (refYear > %@ AND refYear < %@)", 
                 startSearchMonth, startSearchYear,
                 endSearchMonth, endSearchYear,
                 startSearchYear, endSearchYear];
    
    statsSet = [self.stats filteredSetUsingPredicate:predicate];
    
    int statsSetCount = [statsSet count];
    
    double amtUnpaidsUnresAllCatThisYear[statsSetCount];
    double amtUnpaidsResAllCatThisYear[statsSetCount];
    
    int amtUnpaidsPointer = 0;
    
    for (Statistic * stat in statsSet) {
        incomeAllCatThisYear += [stat.amtSellsOK doubleValue];
        numUnpaidsUnresAllCatThisYear += [stat.numOpenUnpaidInv intValue];
        numUnpaidsResAllCatThisYear += [stat.numClosedUnpaidInv intValue];
        amtUnpaidsUnresAllCatThisYear[amtUnpaidsPointer] = [stat.amtOpenUnpaidInv doubleValue];
        amtUnpaidsResAllCatThisYear[amtUnpaidsPointer] = [stat.amtClosedUnpaidInv doubleValue];
        amtUnpaidsPointer++;
    }
    
    double sumOfAmtUnpaidsUnresAllCatThisYear = 0.0;
    
    for (int i = 0; i < statsSetCount; i++) {
        sumOfAmtUnpaidsUnresAllCatThisYear += amtUnpaidsUnresAllCatThisYear[i];
    }
    
    avgAmtUnpaidsUnresAllCatThisYear = sumOfAmtUnpaidsUnresAllCatThisYear / 12.0;
    
    double sumOfAmtUnpaidsResAllCatThisYear = 0.0;
    
    for (int i = 0; i < statsSetCount; i++) {
        sumOfAmtUnpaidsResAllCatThisYear += amtUnpaidsResAllCatThisYear[i];
    }
    
    avgAmtUnpaidsResAllCatThisYear = sumOfAmtUnpaidsResAllCatThisYear / 12.0;
    
    // Per ogni categoria
    
    NSArray * arr = [dao getEntitiesOfType:NSStringFromClass([ItemCategory class]) excludingPending:YES];
    
    for (ItemCategory * itemCat in arr) {
        
        // Fatturato (mese scorso)
        
        // Num. vendite (mese scorso)
        
        double incomeSingleCatOneMonthAgo = 0.0;
        
        int numSellsOKSingleCatOneMonthAgo = 0;
        
        predicate = [NSPredicate predicateWithFormat: @"itemCategory == %@ AND refMonth == %@ AND refYear == %@", 
                     itemCat,
                     [NSNumber numberWithInt:prevMonthMonth], [NSNumber numberWithInt:prevMonthYear]];
        
        statsSet = [self.stats filteredSetUsingPredicate:predicate];
        
        for (Statistic *stat in statsSet) {
            incomeSingleCatOneMonthAgo += [stat.amtSellsOK doubleValue];
            numSellsOKSingleCatOneMonthAgo += [stat.numSellsOK intValue];
        }
        
        // Fatturato (2 mesi fa)
        
        // Num. vendite (2 mesi fa)
        
        double incomeSingleCatTwoMonthsAgo = 0.0;
        
        int numSellsOKSingleCatTwoMonthsAgo = 0;
        
        predicate = [NSPredicate predicateWithFormat: @"itemCategory == %@ AND refMonth == %@ AND refYear == %@", 
                     itemCat,
                     [NSNumber numberWithInt:twoMonthsAgoMonth], [NSNumber numberWithInt:twoMonthsAgoYear]];
        
        statsSet = [self.stats filteredSetUsingPredicate:predicate];
        
        for (Statistic *stat in statsSet) {
            incomeSingleCatTwoMonthsAgo += [stat.amtSellsOK doubleValue];
            numSellsOKSingleCatTwoMonthsAgo += [stat.numSellsOK intValue];
        }
        
        // Fatturato (12 mesi precedenti)
        
        // Varianza del numero di unità vendute al mese (12 mesi
        // precedenti)
        // se la varianza è nulla la pongo = 1
        
        // Num. mesi con vendite OK, KO, OK e KO
        
        double incomeSingleCatThisYear = 0.0;
        
        // il default è 1 per evitare NaN
        double varianceSingleCatThisYear = 1.0;
        
        int numMonthsWithOKSellsAndNoKOSells = 0;
        
        int numMonthsWithOKSellsAndKOSells = 0;
        
        int numMonthsWithKOSellsAndNoOKSells = 0;
        
        predicate = [NSPredicate predicateWithFormat: @"itemCategory == %@ AND ((refMonth >= %@ AND refYear == %@) OR (refMonth <= %@ AND refYear == %@) OR (refYear > %@ AND refYear < %@))", 
                     itemCat,
                     startSearchMonth, startSearchYear,
                     endSearchMonth, endSearchYear,
                     startSearchYear, endSearchYear];
        
//        NSLog(@"predicate: %@ -- category: %@", predicate, [itemCat name]);
        
//        NSLog(@"---------------------------------------------");
        
//        for (Statistic * s in self.stats) {
//            NSLog(@"%@", [s description]);
//        }
        
//        NSLog(@"---------------------------------------------");
        
        statsSet = [self.stats filteredSetUsingPredicate:predicate];
        
//        for (Statistic * s in statsSet) {
//            NSLog(@"%@", [s description]);
//        }
        
        double numSellsOK[12];
        
        int numSellsOKPointer = 0;
        
        for (Statistic *stat in statsSet) {
            
            if ([stat.numSellsOK intValue] > 0 && [stat.numSellsKO intValue] == 0)
                numMonthsWithOKSellsAndNoKOSells ++;
            
            else if ([stat.numSellsOK intValue] > 0 && [stat.numSellsKO intValue] > 0)
                numMonthsWithOKSellsAndKOSells ++;
            
            else if ([stat.numSellsOK intValue] == 0 && [stat.numSellsKO intValue] > 0)
                numMonthsWithKOSellsAndNoOKSells ++;
            
            numSellsOK[numSellsOKPointer] = [stat.numSellsOK doubleValue];
            incomeSingleCatThisYear += [stat.amtSellsOK doubleValue];
            numSellsOKPointer++;
        }
        
        for (int i = numSellsOKPointer; i < 12; i++) {
            numSellsOK[i] = 0;
        }
        
        varianceSingleCatThisYear = variance(numSellsOK, 12);
        
        // Eventuale ripristino del default
        
        if (varianceSingleCatThisYear == 0)
            varianceSingleCatThisYear = 1.0;
        
        // Num. mesi trascorsi dall'ultima vendita
        
        int numMonthsFromLastSell = 0;
        
        predicate = [NSPredicate predicateWithFormat: @"itemCategory == %@ AND numSellsOK > 0",  
                     itemCat];
        
        statsSet = [self.stats filteredSetUsingPredicate:predicate];
        
        if ([statsSet count] > 0) {
            
            predicate = [NSPredicate predicateWithFormat: @"result == %@ AND itemCategory == %@", @"OK", itemCat];
            evtSet = [self.events filteredSetUsingPredicate:predicate];
            NSDate * maxDate = nil;
            
            for (Event * evt in evtSet) {
                if(maxDate == nil || (maxDate != nil && [maxDate compare:evt.date] == NSOrderedAscending)) {
                    
                    maxDate = [[[evt date] copy] autorelease];
                    
                }
            }
            
            comp = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
                                fromDate:maxDate
                                  toDate:today
                                 options:0];
            
            numMonthsFromLastSell = [comp month];

        }
        
        score = score
        + (((2.0/7) * numMonthsWithOKSellsAndNoKOSells
                     + (1.0/7) * numMonthsWithOKSellsAndKOSells 
                     - (2.0/7) * numMonthsWithKOSellsAndNoOKSells 
                     + (2.0/7) * MIN(12, numMonthsFromLastSell))
                    * (incomeSingleCatThisYear / incomeAllCatThisYear))
        + (fabs(numSellsOKSingleCatOneMonthAgo
                        - numSellsOKSingleCatTwoMonthsAgo)
                    / sqrt(varianceSingleCatThisYear));
    }
    
    score = 1.0 / normalize(
                      score
    - (sumOfAmtUnpaidsUnresAllCatThisYear / incomeAllCatThisYear)
    - (sumOfAmtUnpaidsResAllCatThisYear / incomeAllCatThisYear), 100.0);
    
    [self setScore:[NSNumber numberWithDouble:score]];
    
//    NSLog(@"got score for firmName %@: %g", self.firmName, [self.score doubleValue]);
    
    return [self score];
    
}


@end
