//
//  RepWalletAppDelegate.h
//  repWallet
//
//  Created by Alberto Fiore on 11/02/11.
//  Copyright 2011 Alberto Fiore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DAO.h"

#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_5 (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 568.0f)
#define IS_IPHONE_4 (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 480.0f)
#define IS_RETINA ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0))
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#define BING_API_KEY @"YourAPIKey"
#define CLOUDMADE_API_KEY @"DEPRECATED"
#define FILEPICKER_IO_API_KEY @"YourAPIKey"
#define REPWALLET_APP_ID @"YourAppID"
#define REPWALLET_DB_NAME @"__coreDataStore.sqlite"
#define BUSINESS_CATEGORIES_DB_NAME @"__businessCategories.sqlite"

@interface RepWalletAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate>
{

}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) UITabBarController *tabBarController;
@property (nonatomic, retain) DAO *dao;
@property (nonatomic, assign) BOOL isRetina;
@property (nonatomic, assign) BOOL isIpad;
@property (nonatomic, assign) BOOL isIphone5;

- (void)setNetworkActivityIndicatorVisible:(BOOL)setVisible force:(BOOL)force;

@end

