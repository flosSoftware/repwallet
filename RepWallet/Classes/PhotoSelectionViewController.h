//
//  PhotoSelectionViewControllerDelegate.h
//  repWallet
//
//  Created by Alberto Fiore on 12/27/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "ALAssetsManager.h"

@protocol PhotoSelectionViewControllerDelegate <NSObject>

@optional

- (void) photoSelectionControllerSelectedAssetWithURL:(NSURL *)assetURL;

- (void) photoSelectionControllerUnselectedAssetWithURL:(NSURL *)assetURL;

@end

@interface PhotoSelectionViewController : UIViewController

@property (nonatomic, assign) id<PhotoSelectionViewControllerDelegate> delegate;

@property (nonatomic, retain) NSString *assetGroupID;

- (id)initWithImageAssets:(NSMutableArray *)imageAssets actualAssetsURLs:(NSArray *)actualAssetsURLs;

@end