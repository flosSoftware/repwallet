//
//  FwdGeocoder.m
//  repWallet
//
//  Created by Alberto Fiore on 11/16/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "FwdGeocoder.h"
#import "RepWalletAppDelegate.h"
#import "JSONKit.h"
#import "IPAddr.h"
#import "TTURLConnection.h"

@implementation FwdGeocoder

@synthesize delegate;

-(void)startGeocodingWithAddress:(NSString *)address locality:(NSString *)locality ZIP:(NSString *)zip adminDistrict:(NSString *)adminDistrict countryCode:(NSString *)countryCode
{
    NSString * ip = [[IPAddr sharedIPAddr] ip];
    
    NSString *url = @"http://dev.virtualearth.net/REST/v1/Locations?";
    
    BOOL needsAmpersand = NO;
    
    if (locality && [[locality stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0) {
        url = [NSString stringWithFormat:@"%@locality=%@", url, [locality stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        needsAmpersand = YES;
    }
    
    if (countryCode && [[countryCode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0) {
        url = [NSString stringWithFormat:@"%@%@countryRegion=%@", url, needsAmpersand? @"&" : @"", [countryCode stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        needsAmpersand = YES;
    }
    
    if (adminDistrict && [[adminDistrict stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0) {
        url = [NSString stringWithFormat:@"%@%@adminDistrict=%@", url, needsAmpersand? @"&" : @"", [adminDistrict stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        needsAmpersand = YES;
    }
    
    if (zip && [[zip stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0) {
        url = [NSString stringWithFormat:@"%@%@postalCode=%@", url, needsAmpersand? @"&" : @"", [zip stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        needsAmpersand = YES;
    }
    
    if (address && [[address stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0) {
        url = [NSString stringWithFormat:@"%@%@addressLine=%@", url, needsAmpersand? @"&" : @"", [address stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        needsAmpersand = YES;
    }
    
    if(![ip isEqualToString:@"0.0.0.0"]) {
        url = [NSString stringWithFormat:@"%@%@userIp=%@", url, needsAmpersand? @"&" : @"", ip];
        needsAmpersand = YES;
    }
    
    url = [NSString stringWithFormat:@"%@%@maxResults=1&key=%@", url, needsAmpersand? @"&" : @"", BING_API_KEY];
    
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
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(geocoderFailedWithError:)]) {
            [self.delegate geocoderFailedWithError:[d objectForKey:@"value"]];
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

    if (self.delegate && [self.delegate respondsToSelector:@selector(geocoderFailedWithError:)]) {
        [self.delegate geocoderFailedWithError:errorDesc];
    }
}

-(void) setGeocodedPoint: (NSDictionary *)dictio 
{
    NSArray * resSets = [dictio objectForKey:@"resourceSets"];
    
    if(resSets && [resSets count] > 0) {
        
        NSArray * r = [[resSets objectAtIndex:0] objectForKey:@"resources"];
        
        if (!r || [r count] == 0) {
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(geocoderFailedWithError:)]) {
                [self.delegate geocoderFailedWithError:@"No resources found."];
            }
            
            return;
            
        } else {
            
            for(NSDictionary * d in r) {
                
                for(id key in d) {
                    
                    if ([key isEqualToString:@"point"]) {
                        
                        NSArray * coords = [[d objectForKey:key] objectForKey:@"coordinates"];
                        
                        CLLocation * l = [[[CLLocation alloc] initWithLatitude:[[coords objectAtIndex:0] doubleValue] longitude:[[coords objectAtIndex:1] doubleValue]] autorelease];

                        if (self.delegate && [self.delegate respondsToSelector:@selector(geocoderFoundLocation:)]) {
                            [self.delegate geocoderFoundLocation:l];
                        }
                        
                        return;
                        
                    } 
                }
            }
        }
        
    } else {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(geocoderFailedWithError:)]) {
            [self.delegate geocoderFailedWithError:@"No resource sets found."];
        }
        
        return;
        
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection 
{
    //    NSLog(@"Succeeded! Received %d bytes of data", [self.receivedData length]);

    TTURLConnection* ttConnection = (TTURLConnection*)connection;
    
//    NSLog(@"ocio %@", [ttConnection.responseData objectFromJSONData]);
    
    if (ttConnection.response.statusCode == 200) {
     
        [self setGeocodedPoint:[ttConnection.responseData objectFromJSONData]];
        
    }
        
}

-(void)dealloc {

    [super dealloc];
}
@end