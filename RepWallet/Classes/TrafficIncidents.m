//
//  TrafficIncidents.m
//  repWallet
//
//  Created by Alberto Fiore on 11/7/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "TrafficIncidents.h"
#import "RepWalletAppDelegate.h"
#import "JSONKit.h"
#import "TrafficIncident.h"
#import "TTURLConnection.h"

@implementation TrafficIncidents

@synthesize delegate;

- (void) startGettingIncidentsInBBoxWithNorthEast:(CLLocationCoordinate2D)ne southWest:(CLLocationCoordinate2D)sw {
    
    if (self = [super init]) {

        // South Latitude, West Longitude, North Latitude, East Longitude
        
        NSString *url = [NSString stringWithFormat:@"http://dev.virtualearth.net/REST/v1/Traffic/Incidents/%f,%f,%f,%f?key=%@", sw.latitude, sw.longitude, ne.latitude, ne.longitude, BING_API_KEY];
        
        NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        
        [[[TTURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES] autorelease];
        
    }
    
    return;
}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    TTURLConnection* ttConnection = (TTURLConnection*)connection;
    ttConnection.response = response;
    ttConnection.responseData = [NSMutableData dataWithLength:0];
    
    NSDictionary * d = nil;
    
	if ([ttConnection.response respondsToSelector:@selector(allHeaderFields)]) {
		NSDictionary *dictionary = [ttConnection.response allHeaderFields];
		if ([dictionary objectForKey:@"X-MS-BM-WS-INFO"]
            && [[dictionary objectForKey:@"X-MS-BM-WS-INFO"] intValue] == 1) {
            d = [NSDictionary dictionaryWithObjectsAndKeys:@"There's a problem with the service right now. Please try again in a few seconds.",@"value", nil];
        }
	}
    
    int code = [ttConnection.response statusCode];
    
    if (code == 400) {
        d = [NSDictionary dictionaryWithObjectsAndKeys:@"The request contained an error.",@"value", nil];
    } else if (code == 401) {
        d = [NSDictionary dictionaryWithObjectsAndKeys:@"Access was denied.",@"value", nil];
    } else if (code == 403) {
        d = [NSDictionary dictionaryWithObjectsAndKeys:@"The request is for something forbidden.",@"value", nil];
    } else if (code == 404) {
        d = [NSDictionary dictionaryWithObjectsAndKeys:@"The requested resource was not found.",@"value", nil];
    }  else if (code == 500) {
        d = [NSDictionary dictionaryWithObjectsAndKeys:@"Your request could not be completed because there was a problem with the service.",@"value", nil];
    }  else if (code == 503) {
        d = [NSDictionary dictionaryWithObjectsAndKeys:@"There's a problem with the service right now. Please try again later.",@"value", nil];
    } else;
    
    if(d) {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(trafficIncidentsQueryFailedWithError:)]) {
            [self.delegate trafficIncidentsQueryFailedWithError:[d objectForKey:@"value"]];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data 
{        
    TTURLConnection* ttConnection = (TTURLConnection*)connection;
    [ttConnection.responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error 
{  
    NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(trafficIncidentsQueryFailedWithError:)]) {
        [self.delegate trafficIncidentsQueryFailedWithError:errorDesc];
    }
}

// se non trovo nulla, xe i stesso!

-(void) setTrafficIncidents: (NSDictionary *)dictio 
{
    NSArray * resSets = [dictio objectForKey:@"resourceSets"];
    
    if(resSets && [resSets count] > 0) {
        
        NSArray * r = [[resSets objectAtIndex:0] objectForKey:@"resources"];
        
        if (!r || [r count] == 0) {
            
            return;
            
        } else {
            
            NSMutableArray * a = [NSMutableArray array];
            
            for(NSDictionary * d in r) {
                
                TrafficIncident * t = [[[TrafficIncident alloc] init] autorelease];
                
                for(id key in d) {
                    
                    if ([key isEqualToString:@"point"]) {
                        
                        NSArray * coords = [[d objectForKey:key] objectForKey:@"coordinates"];
                        
                        [t setLatitude:[coords objectAtIndex:0]];
                        [t setLongitude:[coords objectAtIndex:1]];
                        
                    } else if ([key isEqualToString:@"type"]) {
                        
                        [t setTypeWithCode:[[d objectForKey:key] intValue]];
                        
                    } else if ([key isEqualToString:@"severity"]) {
                        
                        [t setSeverityWithCode:[[d objectForKey:key] intValue]];
                        
                    } else if ([key isEqualToString:@"congestion"]) {
                        
                        [t setCongestion:[d objectForKey:key]];
                        
                    } else if ([key isEqualToString:@"description"]) {
                        
                        [t setDescription:[d objectForKey:key]];
                        
                    }  else if ([key isEqualToString:@"detour"]) {
                        
                        [t setDetour:[d objectForKey:key]];
                    }  
                }
                [a addObject:t];
            }
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(trafficIncidentsQueryFoundIncidents:)]) {
                [self.delegate trafficIncidentsQueryFoundIncidents:a];
            }
            
            return;
        }
        
    } else {
        
        return;
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection 
{
    //    NSLog(@"Succeeded! Received %d bytes of data", [self.receivedData length]);
    
//    NSLog(@"ocio %@", [self.receivedData objectFromJSONData]);
    
    TTURLConnection* ttConnection = (TTURLConnection*)connection;
    
    if (ttConnection.response.statusCode == 200) {
        [self setTrafficIncidents:[ttConnection.responseData objectFromJSONData]];
    }
}

-(void)dealloc {
    [super dealloc];
}

@end
