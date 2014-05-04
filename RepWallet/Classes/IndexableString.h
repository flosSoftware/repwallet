//
//  IndexableString.h
//  repWallet
//
//  Created by Alberto Fiore on 10/31/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface IndexableString : NSObject {
    
}

@property (nonatomic, retain) NSString * string;
+ (id)indexableStringWithString:(NSString *)s;
@end
