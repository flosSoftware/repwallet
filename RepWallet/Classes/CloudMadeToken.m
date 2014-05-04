//
//  CloudMadeToken.m
//  repWallet
//
//  Created by Alberto Fiore on 11/5/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//



// NOTE: CLoudMade API is dismissed from May 1st 2014
// These classes are deprecated


#import "CloudMadeToken.h"
#import "RepWalletAppDelegate.h"
#import "MD5.h"

@implementation CloudMadeToken

@synthesize cloudMadeToken, delegate;

-(id)init {
    
    if (self = [super init]) {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if(nil != [defaults stringForKey:@"cloudMadeToken"]) {
            
            self.cloudMadeToken = [defaults stringForKey:@"cloudMadeToken"];
       
        } else {
            
            self.cloudMadeToken = nil;

        }
        
    }
    
    return self;
}

- (void) getTokenFromService
{
    NSString *name = [[UIDevice currentDevice] name];
    
    NSString *udid = [[UIDevice currentDevice] uniqueIdentifier]; // deprecated from ios 5	
    
    NSString *user = [[NSString stringWithFormat:@"%@%@",name,udid] MD5];
    
    NSString *url = [NSString stringWithFormat:@"http://auth.cloudmade.com/token/%@?userid=%@&deviceid=%@", CLOUDMADE_API_KEY, user, udid];
    
//    NSLog(@"getting cloudmade token with url %@", url);
    
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    [request setHTTPMethod:@"POST"];
    
    [[[TTURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES] autorelease];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    TTURLConnection* ttConnection = (TTURLConnection*)connection;
    ttConnection.response = response;
    ttConnection.responseData = [NSMutableData dataWithLength:0];
    
    NSDictionary * d = nil;
    
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
        if (self.delegate && [self.delegate respondsToSelector:@selector(cloudMadeTokenFailedWithError:)]) {
            [self.delegate cloudMadeTokenFailedWithError:[d objectForKey:@"value"]];
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
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(cloudMadeTokenFailedWithError:)]) {
        [self.delegate cloudMadeTokenFailedWithError:errorDesc];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection 
{
    TTURLConnection* ttConnection = (TTURLConnection*)connection;
    
    if (ttConnection.response.statusCode == 200) {
        
        NSString *responseText = [[NSString alloc] initWithData:ttConnection.responseData encoding:NSUTF8StringEncoding];
        
//        NSLog(@"cloudmade token is %@", responseText);
        
        self.cloudMadeToken = responseText;
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        NSString *key = @"cloudMadeToken";
        NSString *value = self.cloudMadeToken;
        
        // set the value
        [defaults setObject:value forKey:key];
        
        // save it
        [defaults synchronize];
        
        [responseText release];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(cloudMadeTokenReceivedToken:)]) {
            [self.delegate cloudMadeTokenReceivedToken:self.cloudMadeToken];
        }
        
    }
}

-(void)dealloc {
    [self.cloudMadeToken release];
    [super dealloc];
}


@end
