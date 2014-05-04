//
//  TTURLConnection.h
//  repWallet
//
//  Created by Alberto Fiore on 10/3/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TTURLConnection : NSURLConnection {
    NSHTTPURLResponse* _response;
    NSMutableData* _responseData;
    NSDictionary * _accessoryData;
}
@property(nonatomic,retain) NSHTTPURLResponse* response;
@property(nonatomic,retain) NSMutableData* responseData;
@property(nonatomic,retain) NSDictionary * accessoryData;

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate accessoryData: (NSDictionary *)acc;

@end
