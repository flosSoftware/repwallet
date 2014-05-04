//
//  MathUtils.h
//  repWallet
//
//  Created by Alberto Fiore on 10/19/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MathUtils : NSObject {
    
}

- (BOOL) firstDouble:(double)first isEqualTo:(double)second;
- (double) getRandomValuewithMin: (double) lowerBound Max:(double) upperBound;

@end
