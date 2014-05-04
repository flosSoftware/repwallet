//
//  RepWalletAppDelegate.m
//  repWallet
//
//  Created by Alberto Fiore on 11/02/11.
//  Copyright 2011 Alberto Fiore. All rights reserved.
//

#import "RepWalletAppDelegate.h"
#import "FirmViewController.h"
#import "UnpaidInvoiceViewController.h"
#import "EventViewController.h"
#import "StatsViewController.h"
#import "RouteListViewController.h"
#import "ImportViewController.h"
#import "SettingsViewController.h"
#import "NSFileManager+DirectoryLocations.h"
#import "AppointmentViewController.h"
#import "AppointmentForFirmViewController.h"
#import "Appointment.h"
#import "AddEditViewController.h"
#import "RouteForAppointmentViewController.h"

@implementation RepWalletAppDelegate

@synthesize window, tabBarController, dao, isRetina, isIpad, isIphone5;

#pragma mark -
#pragma mark Network activity indicator

- (void)setNetworkActivityIndicatorVisible:(BOOL)setVisible force:(BOOL)force {
    
    static NSInteger NumberOfCallsToSetVisible = 0;
    
    if (setVisible) 
        NumberOfCallsToSetVisible++;
    else 
        NumberOfCallsToSetVisible--;
    
    // The assertion helps to find programmer errors in activity indicator management.
    // Since a negative NumberOfCallsToSetVisible is not a fatal error, 
    // it should probably be removed from production code.
//    NSAssert(NumberOfCallsToSetVisible >= 0, @"Network Activity Indicator was asked to hide more often than shown");
    
    if (NumberOfCallsToSetVisible < 0) {
        NumberOfCallsToSetVisible = 0;
    }
    
    if (force && !setVisible) {
        NumberOfCallsToSetVisible = 0;
    } else if(force && setVisible) {
        NumberOfCallsToSetVisible = 1;
    }

    // Display the indicator as long as our static counter is > 0.
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(NumberOfCallsToSetVisible > 0)];
}

- (void) checkAndCreateUserDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults objectForKey:MAP_TYPE_SETTING_KEY]) {
        
        [defaults setObject:MAP_TYPE_SETTING_DEFAULT_VALUE forKey:MAP_TYPE_SETTING_KEY];
        
    }
    
    if (![defaults objectForKey:TRAVEL_MODE_SETTING_KEY]) {
        
        [defaults setObject:TRAVEL_MODE_SETTING_DEFAULT_VALUE forKey:TRAVEL_MODE_SETTING_KEY];
        
    }
    
    if (![defaults objectForKey:NR_OF_WORK_HOURS_SETTING_KEY]) {
        
        [defaults setObject:[NSNumber numberWithInt:NR_OF_WORK_HOURS_SETTING_DEFAULT_VALUE] forKey:NR_OF_WORK_HOURS_SETTING_KEY];
        
    }
    
    if (![defaults objectForKey:MAX_NR_OF_FIRMS_FOR_ROUTING_SETTING_KEY]) {
        
        [defaults setObject:[NSNumber numberWithInt:MAX_NR_OF_FIRMS_FOR_ROUTING_SETTING_DEFAULT_VALUE] forKey:MAX_NR_OF_FIRMS_FOR_ROUTING_SETTING_KEY];
    } 
    
    if (![defaults objectForKey:TAX_RATE_SETTING_KEY]) {
        
        [defaults setObject:[NSNumber numberWithDouble:TAX_RATE_SETTING_DEFAULT_VALUE] forKey:TAX_RATE_SETTING_KEY];
    }
    
    if (![defaults objectForKey:@"firstRun"])
        [defaults setObject:[NSDate date] forKey:@"firstRun"];
    
    [defaults synchronize];
}

#pragma mark -
#pragma mark Local notifications

// update the remind date (and dueDate) for the appointment in the local notification (if recurrent)

- (void) updateAppointmentFromLocalNotification:(UILocalNotification *)localNotif {
    
    if (localNotif.repeatInterval != 0) {
        
        NSCalendar *calendar = localNotif.repeatCalendar;
        
        if (!calendar) {
            calendar = [NSCalendar currentCalendar];
        }
        
        NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
        
        if (localNotif.repeatInterval == NSDayCalendarUnit) {
            
            components.day = 1;
            
        } else if (localNotif.repeatInterval == NSWeekCalendarUnit) {
            
            components.week = 1;
            
        } else if (localNotif.repeatInterval == NSMonthCalendarUnit) {
            
            components.month = 1;
            
        } else if (localNotif.repeatInterval == NSYearCalendarUnit) {
            
            components.year = 1;
            
        }
        
        NSDate *nextFireDate = [calendar dateByAddingComponents:components toDate:localNotif.fireDate options:0];
        
        Appointment *app = (Appointment *)[self.dao objectWithURI:[NSURL URLWithString:[localNotif.userInfo objectForKey:@"appointmentId"]]];
        
//        NSLog(@"updated appointement %@ to ...", app);
        
        app.remindDateTime = nextFireDate;
        
        app.dateTime = [calendar dateByAddingComponents:components toDate:app.dateTime options:0];
        
        [self.dao saveContext];
        
//        NSLog(@"... %@", app);
    }
}

- (void)deleteNotificationForAppointment:(NSString *)idString {
    
//    NSLog(@"deleting notfication for appointment %@", idString);
        
    UIApplication *application = [UIApplication sharedApplication];
    
    NSArray *localNotifications = [application scheduledLocalNotifications];
    
    for (UILocalNotification * localNotification in localNotifications) {
        
//        NSLog(@"looking at notification %@ with userInfo %@", localNotification, localNotification.userInfo);
        
        if ([idString isEqualToString:
             [localNotification.userInfo objectForKey:@"appointmentId"]]) {
            
            [application cancelLocalNotification:localNotification];
            
//            NSLog(@"deleted local notification %@", localNotification);
            
            break;
        }
    }
}

- (void)scheduleNotificationForAppointment:(Appointment *)item {
    
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    
    if (localNotif == nil)
        return;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    int secondsToSub = -[item.timeLeftToRemind intValue];
    
    NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
    [components setSecond:secondsToSub];
    
    NSDate *remindDate = [calendar dateByAddingComponents:components toDate:item.dateTime options:0];
    
    localNotif.fireDate = remindDate;
    
    localNotif.timeZone = [NSTimeZone localTimeZone];
    
    if ([item.repeat boolValue]) {

        if ([item.calendarRepeatUnit isEqualToString:@"day"]) {
            localNotif.repeatInterval = NSDayCalendarUnit;
        } else if ([item.calendarRepeatUnit isEqualToString:@"week"]) {
            localNotif.repeatInterval = NSWeekCalendarUnit;
        } else if ([item.calendarRepeatUnit isEqualToString:@"month"]) {
            localNotif.repeatInterval = NSMonthCalendarUnit;
        }  else if ([item.calendarRepeatUnit isEqualToString:@"year"]) {
            localNotif.repeatInterval = NSYearCalendarUnit;
        }
    }
    
    double timeInHours = - secondsToSub / 3600.0;
    double intPart, fractPart;
    fractPart = modf(timeInHours, &intPart);
    fractPart = 60.0 * fractPart;
    
    NSString *plForHrs = (int)intPart == 1 ? @"" : @"s";
    
    NSString *plForMins = (int)fractPart == 1 ? @"" : @"s";
    
    NSString *hoursStr = ((int)intPart == 0 ? @"" : [NSString stringWithFormat:@"%i hour%@", (int)intPart, plForHrs]);
    
    NSString *spaceStr = (hoursStr.length == 0 ? @"" : @" ");
    
    NSString *minsStr = [NSString stringWithFormat:@"%i min%@", (int)fractPart, plForMins];
    
    NSString *str = [NSString stringWithFormat:@"%@%@%@", hoursStr, spaceStr, minsStr];
    
    localNotif.alertBody = [NSString stringWithFormat:@"Appointment with %@ in %@.",
                            item.firm.firmName, str];
    
    localNotif.alertAction = @"View";
    
    localNotif.soundName = UILocalNotificationDefaultSoundName;
    
    localNotif.applicationIconBadgeNumber = 1;
    
    localNotif.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:item.firm.firmName, @"firmName", item.objectID.URIRepresentation.absoluteString, @"appointmentId", nil];
    
    if ([localNotif.fireDate timeIntervalSinceNow] >= 0 || localNotif.repeatInterval != 0) {
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
//         NSLog(@"scheduled local notification %@ with userInfo %@ for appointment %@", localNotif, localNotif.userInfo, item);
    }

    
    [localNotif release];
}

- (void)rescheduleNotificationForAppointment:(Appointment *)item {
    
    [self deleteNotificationForAppointment:item.objectID.URIRepresentation.absoluteString];
    
    [self scheduleNotificationForAppointment:item];
    
}

- (void) handleAppointmentInsertion:(NSNotification *)notification {
    
    [self scheduleNotificationForAppointment:[notification.userInfo objectForKey:@"value"]];
    
}

- (void) handleAppointmentModification:(NSNotification *)notification {
    
    [self rescheduleNotificationForAppointment:[notification.userInfo objectForKey:@"value"]];
    
}

- (void) handleAppointmentRemoval:(NSNotification *)notification {
    
    [self deleteNotificationForAppointment:[notification.userInfo objectForKey:@"appointmentId"]];
    
}


#pragma mark -
#pragma mark Application lifecycle

//-(void)createTestData {
//    double startLng = 12.056022;
//    for (int i = 0; i < 150; i++) {
//        startLng+=0.002;
//        Firm *firm = [(Firm *)[[NSManagedObject alloc] initWithEntity:[self.dao getEntityDescriptionForName:NSStringFromClass([Firm class])] insertIntoManagedObjectContext:self.dao.managedObjectContext] autorelease];
//        [firm setInsertDate:[NSDate date]];
//        firm.firmName = [NSString stringWithFormat:@"azienda di test %i SRL", i];
//        firm.town = @"Rovigo";
//        firm.street = [NSString stringWithFormat:@"corso del popolo %i", i];
//        firm.zip = @"45100";
//        firm.country =@"Italy";
//        firm.econSector =@"tubazioni, scavo e interramento";
//        firm.refFirstName =@"Mario";
//        firm.refSecondName = @"Rossi";
//        firm.refRole = @"Direttore tecnico";
//        firm.phoneNr1 = @"111-01234567889";
//        firm.phoneNr2 = @"111-01234567889";
//        firm.faxNr = @"111-01234567889";
//        firm.eMail = @"miamail@gmail.com";
//        firm.notes = @"ciao bello! PROVIAMO A POMPARE UN PO'...";
//        firm.latitude = [NSNumber numberWithDouble:45.057595]; 
//        firm.longitude = [NSNumber numberWithDouble:startLng]; 
//    }
//    [self.dao saveContext];
//}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // proxy
    
//    NSURLCredentialStorage * credentialStorage=[NSURLCredentialStorage sharedCredentialStorage];
//    NSURLCredential * newCredential;
//    newCredential=[NSURLCredential credentialWithUser:@"yyi3868" password:@"alberto2" persistence:NSURLCredentialPersistencePermanent]; //(2)
//    NSURLProtectionSpace * mySpaceHTTP=[[NSURLProtectionSpace alloc] initWithProxyHost:@"proxyic.icnet" port:38080 type:NSURLProtectionSpaceHTTPProxy realm:nil authenticationMethod:nil]; //(3)
//    NSURLProtectionSpace * mySpaceHTTPS=[[NSURLProtectionSpace alloc] initWithProxyHost:@"proxyic.icnet" port:38080 type:NSURLProtectionSpaceHTTPSProxy realm:nil authenticationMethod:nil]; //(4)
//    [credentialStorage setCredential:newCredential forProtectionSpace:mySpaceHTTP]; //(5)
//    [credentialStorage setCredential:newCredential forProtectionSpace:mySpaceHTTPS]; 
//    
//    [mySpaceHTTP release];
//    [mySpaceHTTPS release];
    
    // log file
    
//    NSString *logPath = [[[NSFileManager defaultManager] applicationCachesDirectory] stringByAppendingPathComponent:@"repWalletLog.txt"];
//    freopen([logPath UTF8String], "w+", stderr);
//    NSLog(@"Application launched");
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if(![defaults objectForKey:@"firstRun"])
    {
        // first run of the app ...
        
//        NSLog(@"first run...");
        
        [application cancelAllLocalNotifications];
    }
    
    // Setup some globals
    
    [self checkAndCreateUserDefaults];
    
    DAO * d = [[DAO alloc] init];
    
    self.dao = d;
    
    [d release];
    
    NSManagedObjectContext *context = [self.dao managedObjectContext]; 
    
    if (!context) {
        // Handle the error.
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was a problem while retrieving the application data." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        return YES;
    }
    
	self.dao.businessCategoryDBName = BUSINESS_CATEGORIES_DB_NAME;
    NSFileManager *theFiles = [[NSFileManager alloc] init];
	self.dao.businessCategoryDBPath = [[theFiles applicationSupportDirectory] stringByAppendingPathComponent:self.dao.businessCategoryDBName];
    [theFiles release];
    
	[self.dao checkAndCreateDatabase];
    
    // -------------------- TEST ---------------------
    
//    if ([self.dao countEntitiesOfType:@"Firm"] == 0) {
//        [self createTestData];
//    }
    
    // -------------------- END OF TEST ---------------------

    self.isRetina = IS_RETINA;
    
    self.isIpad = IS_IPAD;
    
    self.isIphone5 = IS_IPHONE_5;
    
//    NSLog(@"isRetina? %@. isIpad? %@. isIphone5? %@.", self.isRetina ? @"YES":@"NO", self.isIpad ? @"YES":@"NO", self.isIphone5 ? @"YES":@"NO");
    
    UIColor * c = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    
    NSMutableArray *controllers = [[NSMutableArray alloc] init];

    UITabBarController * tabC = [[UITabBarController alloc] init];
    self.tabBarController = tabC;
    [tabC release];
    self.tabBarController.moreNavigationController.navigationBar.tintColor = c;
    [self.tabBarController setDelegate:self];
    
	// -----------------------------------------
    
    RouteListViewController *routeController = [[RouteListViewController alloc] initWithStyle:UITableViewStylePlain andDao:self.dao];
    routeController.title = @"Routes";
    
    UINavigationController *mapNavController = [[UINavigationController alloc] initWithRootViewController:routeController];
    mapNavController.navigationBar.tintColor = c;
	[controllers addObject:mapNavController];
    
    [mapNavController release];
	[routeController release];
    
    // -----------------------------------------
    
    StatsViewController *sController = [[StatsViewController alloc] initWithStyle:UITableViewStylePlain andDao:self.dao];
	sController.title = @"Statistics";
	
	UINavigationController *sNavController = [[UINavigationController alloc] initWithRootViewController:sController];
    sNavController.navigationBar.tintColor = c;
	[controllers addObject:sNavController];
	
	[sNavController release];
	[sController release];

	// -----------------------------------------
    
    
    FirmViewController *firmController = [[FirmViewController alloc] initWithStyle:UITableViewStylePlain andDao:self.dao];
	firmController.title = @"Customers";

	UINavigationController *firmNavController = [[UINavigationController alloc] initWithRootViewController:firmController];
    firmNavController.navigationBar.tintColor = c;
    firmNavController.toolbar.tintColor = c;
	[controllers addObject:firmNavController];
	
	[firmNavController release];
	[firmController release];
	
	// -----------------------------------------
    
    UnpaidInvoiceViewController *unpController = [[UnpaidInvoiceViewController alloc] initWithStyle:UITableViewStylePlain andDao:self.dao];
	unpController.title = @"Unpaid Invoices";
	
	UINavigationController *unpNavController = [[UINavigationController alloc] initWithRootViewController:unpController];
    unpNavController.navigationBar.tintColor = c;
	[controllers addObject:unpNavController];
	
	[unpNavController release];
	[unpController release];
    
    // -----------------------------------------
    
    EventViewController *evtController = [[EventViewController alloc] initWithStyle:UITableViewStylePlain andDao:self.dao];
	evtController.title = @"Events";
	
	UINavigationController *evtNavController = [[UINavigationController alloc] initWithRootViewController:evtController];
    evtNavController.navigationBar.tintColor = c;
	[controllers addObject:evtNavController];
	
	[evtNavController release];
	[evtController release];
    
    // -----------------------------------------
    
    AppointmentViewController *appController = [[AppointmentViewController alloc] initWithStyle:UITableViewStylePlain andDao:self.dao];
	appController.title = @"Appointments";
	
	UINavigationController *appNavController = [[UINavigationController alloc] initWithRootViewController:appController];
    appNavController.navigationBar.tintColor = c;
	[controllers addObject:appNavController];
    
    [appNavController release];
	[appController release];
    
    // -----------------------------------------
    
    RouteForAppointmentViewController *routeAppController = [[RouteForAppointmentViewController alloc] initWithStyle:UITableViewStylePlain andDao:self.dao];
    routeAppController.title = @"What's Next?";
    
    UINavigationController *routeAppNavController = [[UINavigationController alloc] initWithRootViewController:routeAppController];
    routeAppNavController.navigationBar.tintColor = c;
	[controllers addObject:routeAppNavController];
    
    [routeAppNavController release];
	[routeAppController release];
	
	
	// -----------------------------------------
    
    SettingsViewController *settingsController = [[SettingsViewController alloc] initWithStyle:UITableViewStylePlain];
	settingsController.title = @"Settings";
	
	UINavigationController *settingsNavController = [[UINavigationController alloc] initWithRootViewController:settingsController];
    settingsNavController.navigationBar.tintColor = c;
	[controllers addObject:settingsNavController];
	
	[settingsController release];
	[settingsNavController release];
    
	self.tabBarController.viewControllers = controllers;
	[controllers release];
    
    // Local notifications
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(handleAppointmentInsertion:) 
                                                 name:ADDED_APPOINTMENT_NOTIFICATION 
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(handleAppointmentModification:) 
                                                 name:EDITED_APPOINTMENT_NOTIFICATION 
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(handleAppointmentRemoval:) 
                                                 name:REMOVED_APPOINTMENT_NOTIFICATION 
                                               object:nil];
    
    UILocalNotification *localNotif =
    [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    
    if (localNotif) {
        
//        NSLog(@"found UIApplicationLaunchOptionsLocalNotificationKey in launchOptions");

        [self updateAppointmentFromLocalNotification:localNotif];
        
        for(int i = 0; i < self.tabBarController.viewControllers.count; i++) {
            
            NSArray * arr = [[self.tabBarController.viewControllers objectAtIndex:i] viewControllers];
            
            if(arr && arr.count > 0 && [[arr objectAtIndex:0] isMemberOfClass:[AppointmentViewController class]]) {
                
                self.tabBarController.selectedIndex = i;
                
                NSString *firmName = [localNotif.userInfo objectForKey:@"firmName"];
                
                NSArray *a = [self.dao getFirmWithName:firmName excludingPending:YES];
                
                if ([a count] == 1) {
                    
                    Firm * f = [a objectAtIndex:0];
                    
                    if (f.appointments.count > 0) {
                        [[arr objectAtIndex:0] showAppointmentsForFirm:f];
                    }
                }
                
                break;
                
            }
        }
        
        application.applicationIconBadgeNumber = localNotif.applicationIconBadgeNumber-1;
    }

//	[self.window addSubview:self.tabBarController.view];
    [self.window setRootViewController:self.tabBarController];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)localNotif 
{
        
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:localNotif.alertBody delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alertView show];
    [alertView release];
    
    [self updateAppointmentFromLocalNotification:localNotif];
    
    application.applicationIconBadgeNumber = localNotif.applicationIconBadgeNumber-1;
}

#pragma mark -
#pragma mark Tab Bar Delegate

-(void)tabBarController:(UITabBarController *)tabBarController willBeginCustomizingViewControllers:(NSArray *)viewControllers 
{
    UIView *editView = [tabBarController.view.subviews objectAtIndex:1];
    UINavigationBar *modalNavBar = [editView.subviews objectAtIndex:0];
    modalNavBar.tintColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    modalNavBar.topItem.title = @"Edit Tabs";
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    
//    UINavigationController * navContr = (UINavigationController *)tabBarController.selectedViewController;
//    [navContr popToRootViewControllerAnimated:YES];
    
//    UIViewController * c = [navContr.viewControllers objectAtIndex:0];
//    c.navigationItem.backBarButtonItem = nil;

}


- (void)dealloc {
    [self.dao release];
    [self.tabBarController release];
    [self.window release];
    [super dealloc];
}


@end
