//
//  PhotoAlbumViewControllerDelegate.h
//  repWallet
//
//  Created by Alberto Fiore on 12/27/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//
#import <UIKit/UIKit.h>

@protocol PhotoAlbumViewControllerDelegate <NSObject>

@optional

- (void) photoAlbumAddedAssetWithURL:(NSURL *)assetURL;

- (void) photoAlbumRemovedAssetWithURL:(NSURL *)assetURL;

@end

@interface PhotoAlbumViewController : UIViewController

@property (nonatomic, assign) id<PhotoAlbumViewControllerDelegate> delegate;

- (id)initWithAlbumAssets:(NSMutableArray *)albumAssets URLsOfActualAssets:(NSMutableArray *)assetsURLs;

@end