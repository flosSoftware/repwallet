//
//  ALAssetsManager.m
//  repWallet
//
//  Created by Alberto Fiore on 12/28/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//

#import "ALAssetsManager.h"

@implementation ALAssetsManager

+ (ALAssetsLibrary *)defaultAssetsLibrary {
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
        [library writeImageToSavedPhotosAlbum:nil metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
        }]; // *** horrible *** workaround for iOS 5.1 - https://devforums.apple.com/message/549591
    });
    return library; 
}

@end
