//
//  IPAddr.h
//  repWallet
//
//  Created by Alberto Fiore on 11/16/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface IPAddr : NSObject {
    
}

@property (nonatomic, retain) NSString *ip;
+ (IPAddr *)sharedIPAddr;
@end
