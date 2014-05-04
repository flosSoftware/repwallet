//
//  Mappable.h
//  repWallet
//
//  Created by Alberto Fiore on 3/5/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol Mappable <NSObject>
-(NSNumber *)latitude;
-(NSNumber *)longitude;
-(void)setLatitude:(NSNumber *)lat;
-(void)setLongitude:(NSNumber *)lng;
@end
