//
//  RouteForAppointmentViewController.m
//  repWallet
//
//  Created by Alberto Fiore on 1/30/13.
//  Copyright (c) 2013 Alberto Fiore. All rights reserved.
//

#import "RouteForAppointmentViewController.h"
#import "RepWalletAppDelegate.h"
#import "AddEditViewController.h"
#import "JSONKit.h"
#import "TTURLConnection.h"
#import "UITableViewController+CustomDrawing.h"
#import "Appointment.h"
#import <libkern/OSAtomic.h>
#import "SettingsViewController.h"
#import "NSObject+CheckConnectivity.h"
#import "FirmViewController.h"
#import "AppointmentForFirmViewController.h"
#import "MapController.h"

@implementation RouteForAppointmentViewController

@synthesize dao;
@synthesize apps;
@synthesize appTrips;
@synthesize toBeReloaded;
@synthesize progressHUD;
@synthesize token;
@synthesize connections;
@synthesize locationManager;
@synthesize userLocation;
@synthesize locationTimer;

# pragma mark - Change orientation

- (NSUInteger)supportedInterfaceOrientations
{
    return (1 << UIInterfaceOrientationPortrait) | (1 << UIInterfaceOrientationPortraitUpsideDown) | (1 << UIInterfaceOrientationLandscapeLeft) | (1 << UIInterfaceOrientationLandscapeRight);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return ((orientation == UIInterfaceOrientationPortrait) ||
            (orientation == UIInterfaceOrientationPortraitUpsideDown) ||
            (orientation == UIInterfaceOrientationLandscapeLeft) ||
            (orientation == UIInterfaceOrientationLandscapeRight));
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    int rowHeight;
    
    if ([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate]  isIpad]) {
        rowHeight = 179;
    } else
        rowHeight = 98;
    
    [self customizeTableViewDrawingWithHeader:nil headerBg:nil footer:nil footerBg:nil background:nil backgroundColor:nil rowHeight:rowHeight headerHeight:10 footerHeight:0 deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    [self.tableView reloadData];
    
}

#pragma mark - MBProgressHUD

- (MBProgressHUD *)createProgressHUDForView:(UIView *)view {
    if (!self.progressHUD || ![self.progressHUD.superview isEqual:view]) {
        MBProgressHUD * p = [[MBProgressHUD alloc] initWithView:view];
        self.progressHUD = p;
        [p release];
        self.progressHUD.minSize = CGSizeMake(120, 120);
        self.progressHUD.minShowTime = 0.5;
        self.progressHUD.customView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MWPhotoBrowser.bundle/images/Checkmark.png"]] autorelease];
        [view addSubview:self.progressHUD];
    }
    return self.progressHUD;
}

- (void)showProgressHUDWithMessage:(NSString *)message {
    self.progressHUD.labelText = message;
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    [self.progressHUD show:YES];
}

- (void)hideProgressHUD:(BOOL)animated {
    [self.progressHUD hide:animated];
}

- (void)showProgressHUDCompleteMessage:(NSString *)message {
    if (message) {
        if (self.progressHUD.isHidden) [self.progressHUD show:YES];
        self.progressHUD.labelText = message;
        self.progressHUD.mode = MBProgressHUDModeCustomView;
        [self.progressHUD hide:YES afterDelay:1.5];
    } else {
        [self.progressHUD hide:YES];
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)stopLocationManager
{
    [self.locationManager stopUpdatingLocation];
    [self.locationTimer invalidate];
    
    if (self.userLocation) {
        
        [self startAsyncCallWithLocation:self.userLocation];
        
    } else {
        
        [self hideProgressHUD:YES];
        
        [(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO force:NO];
        
        self.navigationItem.rightBarButtonItem.enabled = YES;
        self.navigationItem.leftBarButtonItem.enabled = YES;
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was a problem getting your current location." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        
        //        NSLog(@"-- failed location monitoring");
        
    }
}

- (void)startLocationUpdates
{
    // Create the location manager if this object does not
    // already have one.
    if (nil == self.locationManager) {
        CLLocationManager *man = [[CLLocationManager alloc] init];
        self.locationManager = man;
        [man release];
    }
    
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    self.locationTimer = [NSTimer scheduledTimerWithTimeInterval:20.0 target:self selector:@selector(stopLocationManager) userInfo:nil repeats:NO];
//    NSLog(@"-- started location monitoring");
}

// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    //    NSLog(@"-- locationManager got event(s) %@", locations);
    //  The most recent event is in the last position
    CLLocation* nuLocation = [locations lastObject];
    
    NSDate* eventDate = nuLocation.timestamp;
    NSTimeInterval howRecent = -[eventDate timeIntervalSinceNow];
    
    if (howRecent > 5.0) return;
    
    // test that the horizontal accuracy does not indicate an invalid measurement
    if (nuLocation.horizontalAccuracy < 0) return;
    
    // test the measurement to see if it is more accurate than the previous measurement
    if (self.userLocation == nil || self.userLocation.horizontalAccuracy > nuLocation.horizontalAccuracy) {
        // store the location as the "best effort"
        self.userLocation = nuLocation;
        
        // test the measurement to see if it meets the desired accuracy
        //
        // IMPORTANT!!! kCLLocationAccuracyBest should not be used for comparison with location coordinate or altitidue
        // accuracy because it is a negative value. Instead, compare against some predetermined "real" measure of
        // acceptable accuracy, or depend on the timeout to stop updating. This sample depends on the timeout.
        //
        if (nuLocation.horizontalAccuracy <= 500) {
            
            // we have a measurement that meets our requirements, so we can stop updating the location
            [self.locationTimer invalidate];
            [manager stopUpdatingLocation];
            [self startAsyncCallWithLocation:self.userLocation];
        }
    }
}

-(void)locationManager:(CLLocationManager *)manager 
   didUpdateToLocation:(CLLocation *)newLocation 
          fromLocation:(CLLocation *)oldLocation
{
    NSMutableArray *locations = [NSMutableArray array];
    if (oldLocation) {
        [locations addObject:oldLocation];
    }
    if (newLocation) {
        [locations addObject:newLocation];
    }
    if (locations.count > 0) {
        [self locationManager:manager didUpdateLocations:locations];
    }
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    [self hideProgressHUD:YES];
    
    [(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO force:NO];
    
    self.navigationItem.rightBarButtonItem.enabled = YES;
    
    NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem getting your current location. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alertView show];
    [alertView release];
    
//    NSLog(@"-- failed location monitoring");
}

#pragma mark - Initialization

- (id)initWithStyle:(UITableViewStyle)style andDao:(DAO *)dao 
{
    if(self = [super initWithStyle:style]) {
        
        pthread_mutex_init(&mutex, NULL);
        
        self.userLocation = nil;
        
        self.dao = dao;
        
        UITabBarItem * item = [[UITabBarItem alloc] initWithTitle:@"What's Next?" image:[UIImage imageNamed:@"appointment_routes.png"] tag:0];
        
        self.tabBarItem = item;
        
        [item release];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(markViewStatusToBeReloaded) name:ADDED_APPOINTMENT_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(markViewStatusToBeReloaded) name:EDITED_APPOINTMENT_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(markViewStatusToBeReloaded) name:REMOVED_APPOINTMENT_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(markViewStatusToBeReloaded) name:REMOVED_FIRM_NOTIFICATION object:nil];
        
        viewDidDisappear = NO;
        
    }
    
    return self;
}

- (void)dealloc 
{
    if (self.locationManager) {
        self.locationManager.delegate = nil;
    }

    if (self.token) {
        self.token.delegate = nil;
    }
    
    pthread_mutex_destroy(&mutex);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.locationTimer release];
    [self.userLocation release];
    [self.locationManager release];
    [self.connections release];
    [self.token release];
    [self.appTrips release];
    [self.apps release];
    [self.dao release];
    [self.progressHUD release];
    [super dealloc];
}

#pragma mark - View lifecycle

-(void)viewDidUnload
{
    if (self.token) {
        self.token.delegate = nil;
    }
    
    self.token = nil;
    
    self.progressHUD = nil;
    
    self.apps = nil;
    self.appTrips = nil;
    
    [super viewDidUnload];
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    UIBarButtonItem *reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)]; 
    self.navigationItem.rightBarButtonItem = reloadButton;
    [reloadButton release];
    
    self.appTrips = [NSMutableArray array];
    
    int rowHeight;
    
    if ([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate]  isIpad]) {
        rowHeight = 179;
    } else
        rowHeight = 98;
    
    [self customizeTableViewDrawingWithHeader:nil headerBg:nil footer:nil footerBg:nil background:nil backgroundColor:nil rowHeight:rowHeight headerHeight:10 footerHeight:0 deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
    
    self.toBeReloaded = FALSE;

    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    CloudMadeToken *t = [[CloudMadeToken alloc] init];
    
    self.token = t;
    
    [t release];
    
    self.token.delegate = self;
    
    [self createProgressHUDForView:self.tableView];
    
    [self showProgressHUDWithMessage:@"Loading"];
    
    [self orderAppointments];
    
    if ([self hasConnectivity] && [self.apps count] > 0) {
        [self startLocationUpdates];
    } else {
        self.navigationItem.rightBarButtonItem.enabled = YES;
        [self hideProgressHUD:YES];
    }
}

- (void) reload
{
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [self showProgressHUDWithMessage:@"Loading"];
    
    [self orderAppointments];
    
    if ([self hasConnectivity] && [self.apps count] > 0) {
        
        [self startLocationUpdates];
        
    } else {
        
        [self.appTrips removeAllObjects];
        [self reloadTable];
        self.navigationItem.rightBarButtonItem.enabled = YES;
        [self hideProgressHUD:YES];
    }
    
}

- (void) reloadTable
{
    [self.tableView reloadData];
}

- (void) markViewStatusToBeReloaded
{
    self.toBeReloaded = TRUE;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.toBeReloaded == TRUE) {
        self.toBeReloaded = FALSE;
        [self reload];
    }
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    if (viewDidDisappear
        && self.interfaceOrientation != lastOrientation) {
        
        int rowHeight;
        
        if ([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad]) {
            rowHeight = 179;
        } else
            rowHeight = 98;
        
        [self customizeTableViewDrawingWithHeader:nil headerBg:nil footer:nil footerBg:nil background:nil backgroundColor:nil rowHeight:rowHeight headerHeight:10 footerHeight:0 deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
        
        [self.tableView reloadData];
        
    }
}

-(void)viewDidDisappear:(BOOL)animated {
    
    viewDidDisappear = YES;
    
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // only want to do this on iOS 6
    if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
        //  Don't want to rehydrate the view if it's already unloaded
        BOOL isLoaded = [self isViewLoaded];
        
        //  We check the window property to make sure that the view is not visible
        if (isLoaded && self.view.window == nil) {
            
            //  Give a chance to implementors to get model data from their views
            [self performSelectorOnMainThread:@selector(viewWillUnload)
                                   withObject:nil
                                waitUntilDone:YES];
            
            //  Detach it from its parent (in cases of view controller containment)
            [self.view removeFromSuperview];
            self.view = nil;    //  Clear out the view.  Goodbye!
            
            //  The view is now unloaded...now call viewDidUnload
            [self performSelectorOnMainThread:@selector(viewDidUnload)
                                   withObject:nil
                                waitUntilDone:YES];
        }
    }
}

- (void)dismiss:(id)sender
{
	if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else if ([self respondsToSelector:@selector(dismissModalViewControllerAnimated:)]) {
        [self dismissModalViewControllerAnimated:YES];
    }
}


#pragma mark - CloudMadeToken delegate

- (void) cloudMadeTokenReceivedToken:(NSString *)token {
    
//    NSLog(@"token ricevuto, c'mon!");
    
    [self getRoutesFromServiceWithToken:token startLocation:self.userLocation];
    
}

- (void)cloudMadeTokenFailedWithError:(NSString *)errorMsg {
    
    [self hideProgressHUD:YES];
    
    [(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO force:NO];
    
    self.navigationItem.rightBarButtonItem.enabled = YES;
    
    NSString * s = @"";
    
    if (errorMsg) {
        s = errorMsg;
    }
    
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while obtaining access to the routing service. %@", s] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
	[alertView show];
	[alertView release];
    
}

#pragma mark - Routing

-(void) startAsyncCallWithLocation:(CLLocation *)location
{
    //    if (!self.token.cloudMadeToken) {
    //
    //        // need a token
    //        [self.token getTokenFromService];
    //
    //    } else {
    
    //        // in possess of a token
    //        [self getRoutesFromServiceWithToken:self.token.cloudMadeToken startLocation:location];
    //    }
    
    [self getRoutesFromServiceWithToken:@"" startLocation:location];
}

- (void)atomicCancelConnection:(NSString *)message {
    
    if (OSAtomicCompareAndSwapInt(0, 1, &badStatusCode)) {
        
        for (TTURLConnection * connection in self.connections) {
            [connection cancel];
        }
        
        
        [self.appTrips removeAllObjects];
        [self reloadTable];
        
        [self hideProgressHUD:YES];
        
        [(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO force:NO];
        
        self.navigationItem.rightBarButtonItem.enabled = YES;
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
    }
    
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    TTURLConnection* ttConnection = (TTURLConnection*)connection;
    ttConnection.response = response;
    ttConnection.responseData = [NSMutableData dataWithLength:0];
    
    NSString * s = nil;
    
	if ([ttConnection.response respondsToSelector:@selector(allHeaderFields)]) {
		NSDictionary *dictionary = [ttConnection.response allHeaderFields];
		if ([dictionary objectForKey:@"X-MS-BM-WS-INFO"]
            && [[dictionary objectForKey:@"X-MS-BM-WS-INFO"] intValue] == 1) {
            
            
            s = @"There's a problem with the service right now. Please try again in a few seconds.";
        }
	}
    
    int code = [ttConnection.response statusCode];
    
    if (code == 400) {
        s = @"The request contained an error.";
    } else if (code == 401) {
        s = @"Access was denied.";
    } else if (code == 403) {
        s = @"The request is for something forbidden.";
    } else if (code == 404) {
        s = @"The requested resource was not found.";
    }  else if (code == 500) {
        s = @"Your request could not be completed because there was a problem with the service.";
    }  else if (code == 503) {
        s = @"There's a problem with the service right now. Please try again later.";
    } else if (code != 200)
        s = @"There's an unknown error with routing service.";
    
    //    NSLog(@"code -> %i", code);
    
    if(s) {
        
        [self atomicCancelConnection:s];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data 
{        
    TTURLConnection* ttConnection = (TTURLConnection*)connection;
    [ttConnection.responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error 
{    
    if (OSAtomicCompareAndSwapInt(0, 1, &failedConn)) {
        
        for (TTURLConnection * connection in self.connections) {
            [connection cancel];
        }
        
        [self.appTrips removeAllObjects];
        [self reloadTable];
        
        [self hideProgressHUD:YES];
        
        [(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO force:NO];

        self.navigationItem.rightBarButtonItem.enabled = YES;
        
        NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem calculating the routes. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection 
{
    OSAtomicIncrement32(&threadCounter);
    
    TTURLConnection* ttConnection = (TTURLConnection*)connection;
    
    if (ttConnection.response.statusCode == 200) {
        
        NSString *responseText = [[NSString alloc] initWithData:ttConnection.responseData encoding:NSUTF8StringEncoding];
        
        //        NSLog(@"received resp: start firm score is %g -- start of response --- %@ -- end of response --- ", [[[ttConnection accessoryData] objectForKey:@"startFirmScore"] doubleValue], responseText);
        
        [responseText release];
        
        // convert JSON to dictionary
        
        id res = [ttConnection.responseData objectFromJSONData];
        
        if ([res isKindOfClass:[NSDictionary class]]) {
            
            NSMutableDictionary * mutableres = [self massageRoute:res];
            
            [mutableres setObject:[[ttConnection accessoryData] objectForKey:@"appIndex"] forKey:@"appIndex"];
            
            pthread_mutex_lock(&mutex);
            [self.appTrips addObject:mutableres];
            pthread_mutex_unlock(&mutex);
            
        }
        
        if(OSAtomicCompareAndSwapInt(threadCounter, threadCounter, &threadCounterUpperLimit)) {
            
            // reload table view cells
            [self orderTrips];
            [self reloadTable];
            [(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO force:NO];
            [self hideProgressHUD:YES];
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }
        
    }  else {
        
        [self atomicCancelConnection:@"There's an unknown error with routing service."];
    }
}

// takes raw data from the routing service and returns dictionary with points and instructions

-(NSMutableDictionary *) massageRoute: (NSDictionary *)dictio
{
    NSArray * resSets = [dictio objectForKey:@"resourceSets"];
    
    if(resSets && [resSets count] > 0) {
        
        NSArray * r = [[resSets objectAtIndex:0] objectForKey:@"resources"];
        
        if (!r) {
            
            NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"status", @"No resources found.", @"error", nil];
            
            return d;
            
        } else {
            
            NSMutableArray * routes = [NSMutableArray array];
            
            NSMutableArray * locArr = [NSMutableArray array];
            NSMutableArray * instrArr = [NSMutableArray array];
            NSMutableDictionary * statsDict = [NSMutableDictionary dictionary];
            
            BOOL locAdded = NO;
            BOOL instrAdded = NO;
            BOOL durationAdded = NO;
            BOOL distanceAdded = NO;
            
            for(NSDictionary * d in r) { // for each Route
                
                for(id key in d) {
                    
                    if ([key isEqualToString:@"routePath"]) {
                        
                        locAdded = YES;
                        
                        NSArray * coords = [[[d objectForKey:key] objectForKey:@"line"] objectForKey:@"coordinates"];
                        
                        for (NSArray * coord in coords) {
                            CLLocation * t = [[CLLocation alloc] initWithLatitude:[[coord objectAtIndex:0] doubleValue] longitude:[[coord objectAtIndex:1] doubleValue]];
                            [locArr addObject:t];
                            [t release];
                        }
                        
                        //                       NSLog(@"locArr -> %@", locArr);
                        
                    } else if ([key isEqualToString:@"routeLegs"]) {
                        
                        instrAdded = YES;
                        
                        NSArray * itItems = [[[d objectForKey:key] objectAtIndex:0] objectForKey:@"itineraryItems"];
                        
                        for (NSDictionary * itItem in itItems) {
                            NSArray * coord = [[itItem objectForKey:@"maneuverPoint"] objectForKey:@"coordinates"];
                            CLLocation * loc = [[CLLocation alloc] initWithLatitude:[[coord objectAtIndex:0] doubleValue] longitude:[[coord objectAtIndex:1] doubleValue]];
                            NSDictionary * instro = [NSDictionary dictionaryWithObjectsAndKeys: [[itItem objectForKey:@"instruction"] objectForKey:@"text"], @"text", loc, @"location", nil];
                            [instrArr addObject:instro];
                            [loc release];
                        }
                        
                        //                      NSLog(@"instrArr -> %@", instrArr);
                        
                    } else if ([key isEqualToString:@"travelDistance"]) {
                        
                        distanceAdded = YES;
                        
                        [statsDict setObject:[NSNumber numberWithDouble:[[d objectForKey:key] doubleValue]] forKey:@"distance"];
                        
                        
                        //                         NSLog(@"statsDict -> %@", statsDict);
                        
                    }  else if ([key isEqualToString:@"travelDuration"]) {
                        
                        durationAdded = YES;
                        
                        [statsDict setObject:[NSNumber numberWithDouble:[[d objectForKey:key] doubleValue]] forKey:@"duration"];
                        
                        
                        //                        NSLog(@"statsDict -> %@", statsDict);
                        
                    }
                }
                
                if(locAdded && instrAdded && durationAdded && distanceAdded) {
                    
                    
                    NSMutableDictionary * route = [NSMutableDictionary dictionaryWithObjectsAndKeys:locArr, @"routePoints", instrArr, @"routeInstructions", statsDict, @"routeStats", nil];
                    
                    [routes addObject:route];
                }
            }
            
            
            NSMutableDictionary * d = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0], @"status", routes, @"routes", nil];
            
            return d;
        }
        
    } else {
        
        NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"status", @"No resource sets found.", @"error", nil];
        
        return d;
    }
    
    return nil;
}

- (void) orderTrips 
{
    NSMutableArray *mutArr = [[self.appTrips sortedArrayUsingComparator:^(id a, id b) {
        
        int first = [[(NSDictionary *)a objectForKey:@"appIndex"] intValue];
        int second = [[(NSDictionary *)b objectForKey:@"appIndex"] intValue];
        
        // in ascending order	
        
        if(first == second)
            return NSOrderedSame;
        else if(first < second)
            return NSOrderedAscending;
        else if(first > second)
            return NSOrderedDescending;
        else;
        
        return NSOrderedSame;
    }] mutableCopy];
    self.appTrips = mutArr;
    [mutArr release];
}

- (void) orderAppointments 
{
    __block NSDate *date = [NSDate date];
    
    NSMutableArray * arr = [[self.dao getEntitiesOfType:NSStringFromClass([Appointment class]) excludingPending:YES] mutableCopy];
    
    double oneDayInSeconds = 24 * 3600;
    
    for (int i = 0; i < [arr count]; i++) {
        
        Appointment *app = (Appointment *)[arr objectAtIndex:i];
        
//        NSLog(@"appointment app %@", app);
        
        Firm *f = app.firm; 
        
        if(f) {
        
            CLLocationCoordinate2D c = CLLocationCoordinate2DMake([f.latitude doubleValue] , [f.longitude doubleValue]);
            
            if ([app.dateTime timeIntervalSinceDate:date] < 0 
                || [app.dateTime timeIntervalSinceDate:date] >= oneDayInSeconds
                || !CLLocationCoordinate2DIsValid(c)) {
                
                [arr removeObjectAtIndex:i];
                i--;
                
            }
            
        } else {
            
            [arr removeObjectAtIndex:i];
            i--;
            
        }
    }
    
    int maxApps = 5;
    
    NSRange theRange;
    theRange.location = 0;
    theRange.length = MIN(maxApps, [arr count]); 
    
    self.apps = [[arr sortedArrayUsingComparator:^(id a, id b) {
        
        double first = [[(Appointment *)a dateTime] timeIntervalSinceDate:date];
        double second = [[(Appointment *)b dateTime] timeIntervalSinceDate:date];
        
        // in ascending order	
        
        if(first == second)
            return NSOrderedSame;
        else if(first < second)
            return NSOrderedAscending;
        else if(first > second)
            return NSOrderedDescending;
        else;
        
        return NSOrderedSame;
        
    }] subarrayWithRange:theRange];
    
    [arr release];
    
}

- (NSString *) createConnectionUrlWithStartLocation:(CLLocation *)startLocation endFirm:(Firm *)endFirm token:(NSString *)token
{
    //    NSString * connectionUrl = [NSString stringWithFormat:@"http://routes.cloudmade.com/%@/api/0.3/", CLOUDMADE_API_KEY];
    //
    CLLocationCoordinate2D coord = [startLocation coordinate];
    //
    //    NSString * pointString = [NSString stringWithFormat:@"%g,%g,%g,%g", coord.latitude, coord.longitude, [[endFirm latitude] doubleValue], [[endFirm longitude] doubleValue]];
    //
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *travelMode = [defaults stringForKey:TRAVEL_MODE_SETTING_KEY];
    //
    //    NSString * tok = nil;
    //
    //    if ([travelMode isEqualToString:@"car"]) {
    //        tok = [NSString stringWithFormat:@"/%@/shortest.js?token=%@", travelMode, token];
    //    } else
    //        tok = [NSString stringWithFormat:@"/%@.js?token=%@", travelMode, token];
    //
    //    return [NSString stringWithFormat:@"%@%@%@", connectionUrl, pointString, tok];
    
    NSString *url = [NSString stringWithFormat:@"http://dev.virtualearth.net/REST/V1/Routes/%@?wp.0=%g,%g&wp.1=%g,%g&optmz=timeWithTraffic&rpo=Points&key=%@", travelMode, coord.latitude, coord.longitude, [[endFirm latitude] doubleValue], [[endFirm longitude] doubleValue], BING_API_KEY];
    
    return url;
}

- (void) getRoutesFromServiceWithToken:(NSString *)token startLocation:(CLLocation *)startLocation
{
    failedConn = 0; // 0 means 'No connection has failed'
    badStatusCode = 0; // 0 means 'No bad status code received'
    
    [self.appTrips removeAllObjects];
    
    threadCounter = 0;
    threadCounterUpperLimit = [self.apps count];
    
    [(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES force:NO];
    
    self.connections = [NSMutableArray arrayWithCapacity:[self.apps count] - 1];
    
    for (int i = 0; i < [self.apps count]; i++) {
        
        NSString *url = [self createConnectionUrlWithStartLocation:startLocation
                                                           endFirm:[[self.apps objectAtIndex:i] firm]
                         token:token];
        
//        NSLog(@"URL %@", url);
        
        NSURLRequest *request = [NSURLRequest requestWithURL:
                                 [NSURL URLWithString:url]
                                                 cachePolicy:NSURLRequestUseProtocolCachePolicy
                                             timeoutInterval:60.0];
        
        [self.connections addObject:[[[TTURLConnection alloc] initWithRequest:request delegate:self accessoryData:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:i] forKey:@"appIndex"]] autorelease]];
    }
}


#pragma mark Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return [self.appTrips count];
}

- (NSString *)secondsToFormattedTimeString:(double)seconds {
    
    double timeInHours = seconds / 3600.0;
    
    double intPart, fractPart;
    fractPart = modf(timeInHours, &intPart);
    fractPart = 60.0 * fractPart;
    
    NSString *plForHrs = (int)intPart == 1 ? @"" : @"s";
    
    NSString *plForMins = (int)fractPart == 1 ? @"" : @"s";
    
    NSString *hoursStr = ((int)intPart == 0 ? @"" : [NSString stringWithFormat:@"%i hour%@", (int)intPart, plForHrs]);
    
    NSString *spaceStr = (hoursStr.length == 0 ? @"" : @" ");
    
    NSString *minsStr = [NSString stringWithFormat:@"%i min%@", (int)fractPart, plForMins];
    
    return [NSString stringWithFormat:@"%@%@%@", hoursStr, spaceStr, minsStr];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    BOOL dequeued = NO;
    
    if (cell == nil) {
        
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        
//        dequeued = NO;
        
    }
    
    NSDictionary * trip = [self.appTrips objectAtIndex:indexPath.row];
    Appointment * app = [self.apps objectAtIndex:indexPath.row];
    
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init]; 
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle]; 
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    
    NSString *topText = [NSString stringWithFormat:@"%@", app.firm.firmName];

    NSString *bottomText = [NSString stringWithFormat:@"Date: %@", [dateFormatter stringFromDate:app.dateTime]];
    
    [dateFormatter release];
    
    NSString *str = [self secondsToFormattedTimeString:[app.dateTime timeIntervalSinceNow]];
    
    NSString *subBottomText = [NSString stringWithFormat:@"Time Left: %@", str];
    
    if ([[trip objectForKey:@"status"] intValue] == 0) {
        
        double timeInSeconds = [[[[[trip objectForKey:@"routes"] objectAtIndex:0] objectForKey:@"routeStats"] objectForKey:@"duration"] doubleValue];
        
        double timeInHours = timeInSeconds / 3600.0;
        
        NSString *str = [self secondsToFormattedTimeString:timeInSeconds];
        
        NSString *subSubBottomText = [NSString stringWithFormat:@"Trip Time: %@", str];
        
        float rowWithoutShadowHeight;
        
        if([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad]){
            cell.indentationWidth = 20.0f;
            rowWithoutShadowHeight = 165.34f;
        } else
            rowWithoutShadowHeight = 92.87f;
        
        if(timeInHours >= 0 && timeInHours < 0.25)
            [self customizeDrawingForCell:cell atIndexPath:indexPath dequeued:dequeued topText:topText bottomText:bottomText subBottomText:subBottomText subSubBottomText:subSubBottomText  showImage:YES imageName:@"running" rowWithoutShadowHeight:rowWithoutShadowHeight deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
        
        else if(timeInHours >= 0.25 && timeInHours < 0.5)
            [self customizeDrawingForCell:cell atIndexPath:indexPath dequeued:dequeued topText:topText bottomText:bottomText subBottomText:subBottomText subSubBottomText:subSubBottomText showImage:YES imageName:@"bike" rowWithoutShadowHeight:rowWithoutShadowHeight deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
        
        else if(timeInHours >= 0.5 && timeInHours < 4)
            [self customizeDrawingForCell:cell atIndexPath:indexPath dequeued:dequeued topText:topText bottomText:bottomText subBottomText:subBottomText subSubBottomText:subSubBottomText showImage:YES imageName:@"car" rowWithoutShadowHeight:rowWithoutShadowHeight deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
        
        else
            [self customizeDrawingForCell:cell atIndexPath:indexPath dequeued:dequeued topText:topText bottomText:bottomText subBottomText:subBottomText subSubBottomText:subSubBottomText showImage:YES imageName:@"airplane" rowWithoutShadowHeight:rowWithoutShadowHeight deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
        
    } else {
        
        NSString *subSubBottomText = [NSString stringWithFormat:@"Time: N/A"];
        
        float rowWithoutShadowHeight;
        
        if([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate]  isIpad]){
            cell.indentationWidth = 20.0f;
            rowWithoutShadowHeight = 165.34f;
        } else
            rowWithoutShadowHeight = 92.87f;
        
        [self customizeDrawingForCell:cell atIndexPath:indexPath dequeued:dequeued topText:topText bottomText:bottomText subBottomText:subBottomText subSubBottomText:subSubBottomText showImage:YES imageName:@"qmarks" rowWithoutShadowHeight:rowWithoutShadowHeight deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    NSDictionary * trip = [self.appTrips objectAtIndex:indexPath.row];

    Firm * endFirm = [[self.apps objectAtIndex:indexPath.row] firm];
    
    if ([[trip objectForKey:@"status"] intValue] == 0) {
        
        NSArray * coords = [[[trip objectForKey:@"routes"] objectAtIndex:0] objectForKey:@"routePoints"];
        
        CLLocationDegrees maxLat = -90.0f;
        CLLocationDegrees maxLon = -180.0f;
        CLLocationDegrees minLat = 90.0f;
        CLLocationDegrees minLon = 180.0f;
        
        for (CLLocation * coord in coords) {
            
            double currLat = [coord coordinate].latitude;
            
            double currLng = [coord coordinate].longitude;
            
            if(currLat > maxLat) {
                maxLat = currLat;
            }
            if(currLat < minLat) {
                minLat = currLat;
            }
            if(currLng > maxLon) {
                maxLon = currLng;
            }
            if(currLng < minLon) {
                minLon = currLng;
            }

        }
        
        MKCoordinateRegion region;
        region.center.latitude     = (maxLat + minLat) / 2.0;
        region.center.longitude    = (maxLon + minLon) / 2.0;
        region.span.latitudeDelta  = maxLat - minLat;
        region.span.longitudeDelta = maxLon - minLon;
        
        MapController * rlVController = [[MapController alloc] 
                                         initWithArray:[NSArray arrayWithObject:endFirm] 
                                         routePoints:coords 
                                         boundingBoxForRoute:region 
                                         routeInstructions:[[[trip objectForKey:@"routes"] objectAtIndex:0] objectForKey:@"routeInstructions"] 
                                         andDao:self.dao];
        
        rlVController.title = @"Appointment Route";
        [self.navigationController pushViewController:rlVController animated:YES];
        [rlVController release];
        
    } else {
        
        double maxLat, maxLon, minLat, minLon;
        
        maxLat = fmax(self.userLocation.coordinate.latitude, [[endFirm latitude] doubleValue]);
        maxLon = fmax(self.userLocation.coordinate.longitude, [[endFirm longitude] doubleValue]);
        minLat = fmin(self.userLocation.coordinate.latitude, [[endFirm latitude] doubleValue]);
        minLon = fmin(self.userLocation.coordinate.longitude, [[endFirm longitude] doubleValue]);
        
        MKCoordinateRegion region;
        region.center.latitude     = (maxLat + minLat) / 2.0;
        region.center.longitude    = (maxLon + minLon) / 2.0;
        region.span.latitudeDelta  = maxLat - minLat;
        region.span.longitudeDelta = maxLon - minLon;
        
        MapController * rlVController = [[MapController alloc] 
                                         initWithArray:[NSArray arrayWithObject:endFirm] andDao:self.dao isPreSave:NO bBoxForZoom:region longPressureEnabled:NO];  
        
        rlVController.title = @"Appointment Route";
        [self.navigationController pushViewController:rlVController animated:YES];
        [rlVController release];
    }
    
    
}


@end