//
//  TrafficIncident.h
//  repWallet
//
//  Created by Alberto Fiore on 11/8/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Mappable.h"


@interface TrafficIncident : NSObject<Mappable> {
    
}
@property (nonatomic,retain) NSNumber *latitude;
@property (nonatomic,retain) NSNumber *longitude;
@property (nonatomic,retain) NSString *type;
@property (nonatomic,retain) NSString *severity;
@property (nonatomic,retain) NSString *description;
@property (nonatomic,retain) NSString *congestion;
@property (nonatomic,retain) NSString *detour;

-(void)setSeverityWithCode:(int)code;
-(void)setTypeWithCode:(int)code;

@end
