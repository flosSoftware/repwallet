//
//  RevGeocoder.m
//  repWallet
//
//  Created by Alberto Fiore on 11/16/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//

#import "RevGeocoder.h"
#import "RepWalletAppDelegate.h"
#import "JSONKit.h"
#import "TTURLConnection.h"

@implementation RevGeocoder

@synthesize delegate;

-(void)startGeocodingWithLatitude:(double)latitude longitude:(double)longitude
{
    
    NSString *url = [NSString stringWithFormat:@"http://dev.virtualearth.net/REST/v1/Locations/%f,%f?includeEntityTypes=postcode1,address&key=%@", latitude, longitude, BING_API_KEY];
    
    //    NSLog(@"url %@", url);
    
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15.0];
    
    [[[TTURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES] autorelease];

}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    TTURLConnection* ttConnection = (TTURLConnection*)connection;
    ttConnection.response = response;
    ttConnection.responseData = [NSMutableData dataWithLength:0];
    
    NSDictionary * d = nil;
    
	if ([response respondsToSelector:@selector(allHeaderFields)]) {
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
    } else ;
    
    if(d) {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(revGeocoderFailedWithError:)]) {
            [self.delegate revGeocoderFailedWithError:[d objectForKey:@"value"]];
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

    if (self.delegate && [self.delegate respondsToSelector:@selector(revGeocoderFailedWithError:)]) {
        [self.delegate revGeocoderFailedWithError:errorDesc];
    }
}

-(void) setGeocodedAddress: (NSDictionary *)dictio 
{
    NSArray * resSets = [dictio objectForKey:@"resourceSets"];
    
    if(resSets && [resSets count] > 0) {
        
        NSArray * r = [[resSets objectAtIndex:0] objectForKey:@"resources"];
        
        if (!r  || [r count] == 0) {
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(revGeocoderFailedWithError:)]) {
                [self.delegate revGeocoderFailedWithError:@"No resources found."];
            }
            
            return;
            
        } else {
            
            for(NSDictionary * d in r) {
                
                BOOL addressSet = NO, pointSet = NO;
                
                RevGeocoderResponse * resp = [[RevGeocoderResponse alloc] init];
                
                for(id key in d) {
                    
                    if ([key isEqualToString:@"address"]) {
                        
                        addressSet = YES;
                        
                        NSDictionary * addrDictio = [d objectForKey:key];

                        [addrDictio objectForKey:@"addressLine"] ? 
                        [resp setAddressLine:[addrDictio objectForKey:@"addressLine"]]
                        : [resp setAddressLine:@""];
                        
                        [addrDictio objectForKey:@"locality"] ? 
                        [resp setLocality:[addrDictio objectForKey:@"locality"]]
                        : [resp setLocality:@""];
                        
                        [addrDictio objectForKey:@"neighborhood"] ? 
                        [resp setNeighborhood:[addrDictio objectForKey:@"neighborhood"]]
                        : [resp setNeighborhood:@""];
                        
                        [addrDictio objectForKey:@"adminDistrict"] ? 
                        [resp setAdminDistrict:[addrDictio objectForKey:@"adminDistrict"]]
                        : [resp setAdminDistrict:@""];
                        
                        [addrDictio objectForKey:@"adminDistrict2"] ? 
                        [resp setAdminDistrict2:[addrDictio objectForKey:@"adminDistrict2"]]
                        : [resp setAdminDistrict2:@""];
                        
                        [addrDictio objectForKey:@"formattedAddress"] ? 
                        [resp setFormattedAddress:[addrDictio objectForKey:@"formattedAddress"]]
                        : [resp setFormattedAddress:@""];
                        
                        [addrDictio objectForKey:@"postalCode"] ? 
                        [resp setPostalCode:[addrDictio objectForKey:@"postalCode"]]
                        : [resp setPostalCode:@""];
                        
                        [addrDictio objectForKey:@"countryRegion"] ? 
                        [resp setCountryRegion:[addrDictio objectForKey:@"countryRegion"]]
                        : [resp setCountryRegion:@""];
                        
                        [addrDictio objectForKey:@"landmark"] ? 
                        [resp setLandmark:[addrDictio objectForKey:@"landmark"]]
                        : [resp setLandmark:@""];

                    } else if ([key isEqualToString:@"point"]) {
                        
                        pointSet = YES;
                        
                        NSArray * coords = [[d objectForKey:key] objectForKey:@"coordinates"];
                        CLLocation * l = [[CLLocation alloc] initWithLatitude:[[coords objectAtIndex:0] doubleValue] longitude:[[coords objectAtIndex:1] doubleValue]];
                        
                        [resp setPoint:l];
                        
                        [l release];
                        
                    
                    } else if(pointSet && addressSet) {
                        
                        if (self.delegate && [self.delegate respondsToSelector:@selector(revGeocoderFoundAddress:)]) {
                            [self.delegate revGeocoderFoundAddress:resp];
                        }
                        
                        [resp release];
                        
                        return;
                    }
                }
                
                [resp release];
            }
        }
        
    } else {

        if (self.delegate && [self.delegate respondsToSelector:@selector(revGeocoderFailedWithError:)]) {
            [self.delegate revGeocoderFailedWithError:@"No resource sets found."];
        }
        
        return;
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection 
{
    //    NSLog(@"Succeeded! Received %d bytes of data", [self.receivedData length]);
    
//    NSLog(@"ocio %@", [self.receivedData objectFromJSONData]);
    
    TTURLConnection* ttConnection = (TTURLConnection*)connection;
    
    if (ttConnection.response.statusCode == 200) {
     
        [self setGeocodedAddress:[ttConnection.responseData objectFromJSONData]];
        
    }
}

-(void)dealloc {
    [super dealloc];
}
@end