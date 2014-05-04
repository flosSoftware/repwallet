//
//  CloudMadeToken.h
//  repWallet
//
//  Created by Alberto Fiore on 11/5/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//


// NOTE: CLoudMade API is dismissed from May 1st 2014
// These classes are deprecated

#import <Foundation/Foundation.h>
#import "TTURLConnection.h"

@protocol CloudMadeTokenDelegate <NSObject>

@optional

-(void) cloudMadeTokenFailedWithError:(NSString *)errorMsg;
-(void) cloudMadeTokenReceivedToken:(NSString *)token;

@end

@interface CloudMadeToken : NSObject

@property (nonatomic, assign) id<CloudMadeTokenDelegate> delegate;

@property (nonatomic, retain) NSString *cloudMadeToken;

- (void) getTokenFromService;

@end
