//
//  DocumentViewController.h
//  repWallet
//
//  Created by Alberto Fiore on 28/02/13.
//  Copyright (c) 2013 Alberto Fiore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>

@protocol DocumentViewControllerDelegate <NSObject>

@optional

- (void) documentViewControllerAddedDocumentWithURL:(NSURL *)docURL;
- (void) documentViewControllerRemovedDocumentWithURL:(NSURL *)docURL;
- (void) documentViewControllerCanceled;

@end

@interface DocumentViewController : UIViewController<QLPreviewControllerDataSource>

@property (nonatomic, assign) id<DocumentViewControllerDelegate> delegate;

- (id)initWithDocumentsURLs:(NSArray *)documentsURLs;

@end
