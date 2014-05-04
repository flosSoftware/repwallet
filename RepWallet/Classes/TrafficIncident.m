//
//  TrafficIncident.m
//  repWallet
//
//  Created by Alberto Fiore on 11/8/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "TrafficIncident.h"


@implementation TrafficIncident

@synthesize latitude,longitude,type,severity,description,congestion,detour;

-(id)init {
    return [super init];
}

-(void)setTypeWithCode:(int)code {
    if(code == 1) {
        [self setType:@"Accident"];
    } else if(code == 2) {
        [self setType:@"Congestion"];
    } else if(code == 3) {
        [self setType:@"Disabled Vehicle"];
    } else if(code == 4) {
        [self setType:@"Mass Transit"];
    } else if(code == 5) {
        [self setType:@"Miscellaneous"];
    } else if(code == 6) {
        [self setType:@"Other News"];
    } else if(code == 7) {
        [self setType:@"Planned Event"];
    } else if(code == 8) {
        [self setType:@"Road Hazard"];
    } else if(code == 9) {
        [self setType:@"Construction"];
    } else if(code == 10) {
        [self setType:@"Alert"];
    } else if(code == 11) {
        [self setType:@"Weather"];
    } else
        ;
}

-(void)setSeverityWithCode:(int)code {
    
    if(code == 1) {
        [self setSeverity:@"Low Impact"];
    } else if(code == 2) {
        [self setSeverity:@"Minor"];
    } else if(code == 3) {
        [self setSeverity:@"Moderate"];
    } else if(code == 4) {
        [self setSeverity:@"Serious"];
    } else
        ;
    
}

-(void)dealloc {
    [self.congestion release];
    [self.detour release];
    [self.latitude release];
    [self.longitude release];
    [self.type release];
    [self.severity release];
    [self.description release];
    [super dealloc];
}

@end
