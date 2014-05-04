//
//  PhotoViewControllerDelegate.h
//  repWallet
//
//  Created by Alberto Fiore on 12/27/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

@protocol PhotoViewControllerDelegate <NSObject>

@optional

-(void) photoViewControllerAddedAssetWithURL:(NSURL *)assetURL;
-(void) photoViewControllerRemovedAssetWithURL:(NSURL *)assetURL;
-(void) photoViewControllerWillBePoppedWithAssets:(NSArray *)assetsArray;
-(void) photoViewControllerCanceled;

@end

@interface PhotoViewController : UIViewController

@property (nonatomic, assign) id<PhotoViewControllerDelegate> delegate;

- (id)initWithImageAssets:(NSMutableArray *)imageAssets;

@end
