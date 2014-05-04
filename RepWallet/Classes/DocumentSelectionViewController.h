//
//  DocumentSelectionViewController.h
//  repWallet
//
//  Created by Alberto Fiore on 27/02/13.
//  Copyright (c) 2013 Alberto Fiore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>

@protocol DocumentSelectionViewControllerDelegate <NSObject>

@optional

- (void) documentSelectionControllerSelectedDocumentWithURL:(NSURL *)docURL;
- (void) documentSelectionControllerUnselectedDocumentWithURL:(NSURL *)docURL;

@end

@interface DocumentSelectionViewController : UIViewController<QLPreviewControllerDataSource>

@property (nonatomic, assign) id<DocumentSelectionViewControllerDelegate> delegate;

- (id)initWithDirPath:(NSString *)dirPath actualDocumentsURLs:(NSMutableSet *)actualDocumentsURLs onlyOneToSelect:(BOOL)onlyOneToSelect;
- (void)browseForFileWithType:(NSString*)fileType;
- (void)browseForFileWithTypes:(NSArray*)ft;

@end
