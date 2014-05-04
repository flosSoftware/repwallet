//
//  TTURLConnection.m
//  repWallet
//
//  Created by Alberto Fiore on 10/3/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "TTURLConnection.h"


@implementation TTURLConnection

@synthesize response = _response, responseData = _responseData, accessoryData = _accessoryData;

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate accessoryData: (NSDictionary *)acc
{
    NSAssert(self != nil, @"self is nil!");
    
    // Initialize the ivars before initializing with the request
    // because the connection is asynchronous and may start
    // calling the delegates before we even return from this
    // function.
    
    self.response = nil;
    self.responseData = nil;
    self.accessoryData = acc;
    
    self = [super initWithRequest:request delegate:delegate];
    return self;
}

- (void)dealloc {
    [self.response release];
    [self.responseData release];
    [self.accessoryData release];
    [super dealloc];
}

@end