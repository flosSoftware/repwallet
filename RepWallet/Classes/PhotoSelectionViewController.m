//
//  PhotoSelectionViewController.h
//  repWallet
//
//  Created by Alberto Fiore on 12/27/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//
#import "PhotoAlbumViewController.h"
#import "PhotoSelectionViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "GMGridView.h"
#import "RepWalletAppDelegate.h"
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import "UIImage+UIImageExtras.h"
#import "MWPhotoBrowser.h"
#import "MBProgressHUD.h"
#import "SWSnapshotStackView.h"

// NSConditionLock values
enum {
    WDASSETURL_PENDINGREADS = 1,
    WDASSETURL_ALLFINISHED = 0
};

//////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark ViewController (privates methods)
//////////////////////////////////////////////////////////////

@interface PhotoSelectionViewController () <GMGridViewDataSource, GMGridViewSortingDelegate, GMGridViewActionDelegate, MWPhotoBrowserDelegate,UINavigationControllerDelegate>
{
    NSInteger _lastDeleteItemIndexAsked;
    BOOL selectionModeIsOn;
    UIInterfaceOrientation lastOrientation;
    BOOL viewDidDisappear;
}

@property (nonatomic, retain) MWPhotoBrowser *photoBrowser;
@property (nonatomic, retain) GMGridView *gmGridView;
@property (nonatomic, retain) NSMutableArray *selectedCellURLs;
@property (nonatomic, retain) NSMutableArray *currentData;
@property (nonatomic, retain) MWPhoto* currentPhoto;
@property (nonatomic, retain) MBProgressHUD *progressHUD;

@end


//////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark ViewController implementation
//////////////////////////////////////////////////////////////

@implementation PhotoSelectionViewController

@synthesize progressHUD, currentData, gmGridView, photoBrowser, delegate, currentPhoto, selectedCellURLs, assetGroupID;

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

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.gmGridView reloadData];
}

- (void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.assetGroupID release];
    [self.selectedCellURLs release];
    [self.progressHUD release];
    [self.currentPhoto release];
    [self.photoBrowser release];
    [self.currentData release];
    [self.gmGridView release];
    [super dealloc];
}

#pragma mark - MBProgressHUD

- (MBProgressHUD *)createProgressHUDForView:(UIView *)view {
    if (!self.progressHUD || ![self.progressHUD.superview isEqual:view]) {
        MBProgressHUD * p = [[MBProgressHUD alloc] initWithView:view];
        self.progressHUD = p;
        [p release];
        self.progressHUD.minSize = CGSizeMake(120, 120);
        self.progressHUD.minShowTime = 1;
        self.progressHUD.customView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MWPhotoBrowser.bundle/images/Checkmark.png"]] autorelease];
        [view addSubview:self.progressHUD];
    }
    return self.progressHUD;
}

- (void)showProgressHUDWithMessage:(NSString *)message {
    self.progressHUD.labelText = message;
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    [self.progressHUD show:YES];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
}

- (void)hideProgressHUD:(BOOL)animated {
    [self.progressHUD hide:animated];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
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
    self.navigationController.navigationBar.userInteractionEnabled = YES;
}


#pragma mark -
#pragma mark AssetsLibrary update notification

-(void)updateAssets:(NSNotification *)notification {
    
    BOOL reload = NO;
    
    // only want to do this on iOS 6
    if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
     
        if (![notification userInfo] || [[notification userInfo] count] > 0) {
            
            // ricarica
            reload = YES;
        }
        
    } else
        reload = YES;
    
    if (reload) {
        
        ALAssetsLibraryGroupsEnumerationResultsBlock assetGroupEnumerator =  ^(ALAssetsGroup *group, BOOL *stop) {
            if(group != nil
               && [[group valueForProperty:ALAssetsGroupPropertyPersistentID] isEqualToString:self.assetGroupID]) {
                
                NSMutableArray *assetsForGroup = [NSMutableArray array];
                
                ALAssetsGroupEnumerationResultsBlock assetEnumerator = ^(ALAsset *result, NSUInteger index, BOOL *stopInner) {
                    if(result != NULL
                       && [[result valueForProperty:ALAssetPropertyType] isEqual:ALAssetTypePhoto]
                       ) {
                        
                        [assetsForGroup addObject:result];
                        
                    } else if(result == NULL) {
                        
                        *stopInner = YES;
                        
                        [self.currentData removeAllObjects];
                        
                        self.currentData = [NSMutableArray arrayWithArray:assetsForGroup];
                        
                        [self.gmGridView reloadData];

                        for (int i = 0; i < self.selectedCellURLs.count; i++) {
                            
                            BOOL toRemove = YES;
                            
                            for (ALAsset * ass in self.currentData) {
                                if ([ass.defaultRepresentation.url isEqual:[self.selectedCellURLs objectAtIndex:i]]) {
                                    toRemove = NO;
                                    break;
                                }
                            }
                            
                            if (toRemove) {
                                [self.selectedCellURLs removeObjectAtIndex:i];
                                i--;
                            }
                        }
                        
                    }
                };
                
                [group enumerateAssetsUsingBlock:assetEnumerator];
                
                
                *stop = YES;
                
            } else if(group == nil) {
                
                *stop = YES;

            }
        };
        
        ALAssetsLibrary* library = [ALAssetsManager defaultAssetsLibrary];
        [library enumerateGroupsWithTypes:ALAssetsGroupAll
                               usingBlock:assetGroupEnumerator
                             failureBlock: ^(NSError *error) {
                                 
                                 NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
                                 
                                 UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while retrieving the images. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                                 [alertView show];
                                 [alertView release];
                                 
                             }];
    }
}


#pragma mark -
#pragma mark Photo browser

- (void)browsePhotosStartingAtIndex:(NSUInteger)index
{
	MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    browser.displayActionButton = YES;
    [self.navigationController pushViewController:browser animated:YES];
    [browser setInitialPageIndex:index];
    self.photoBrowser = browser;
    [browser release];
}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.currentData.count;
}

- (MWPhoto *)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    
    if (index < self.currentData.count){
        
        // sets up a condition lock with "pending reads"
        __block NSConditionLock * albumReadLock = [[NSConditionLock alloc] initWithCondition:WDASSETURL_PENDINGREADS];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSURL *assetURL = [[[self.currentData objectAtIndex:index] defaultRepresentation] url];
            
            // the result block
            ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
            {
                ALAssetRepresentation *rep = [myasset defaultRepresentation];
                
                self.currentPhoto = [MWPhoto photoWithImage:[UIImage imageWithCGImage:rep.fullScreenImage] assetURL:rep.url];
                if ([rep respondsToSelector:@selector(filename)]) {
                    self.currentPhoto.caption = rep.filename;
                } else if ([rep respondsToSelector:@selector(UTI)]) {
                    self.currentPhoto.caption = rep.UTI;
                }
                
                // notifies the lock that "all tasks are finished"
                [albumReadLock lock];
                [albumReadLock unlockWithCondition:WDASSETURL_ALLFINISHED];
            };
            
            //
            ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *error)
            {
                NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while processing the image. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alertView show];
                [alertView release];
                
                self.currentPhoto = [MWPhoto photoWithImage:[UIImage imageNamed:@"notAvailable.png"]];
                
                // important: notifies lock that "all tasks finished" (even though they failed)
                [albumReadLock lock];
                [albumReadLock unlockWithCondition:WDASSETURL_ALLFINISHED];
            };
            
            // schedules the asset read
            ALAssetsLibrary* assetslibrary = [ALAssetsManager defaultAssetsLibrary];
            
            [assetslibrary assetForURL:assetURL
                           resultBlock:resultblock
                          failureBlock:failureblock];
        });
        
        
        // non-busy wait for the asset read to finish (specifically until the condition is "all finished")
        [albumReadLock lockWhenCondition:WDASSETURL_ALLFINISHED];
        [albumReadLock unlock];
        
        // cleanup
        [albumReadLock release];
        albumReadLock = nil;
        
        return self.currentPhoto;
    }
    
    return nil;
}

- (void) switchSelectionMode {
    
    selectionModeIsOn = !selectionModeIsOn;
    
    if ([self.navigationItem.rightBarButtonItem.title isEqualToString:@"Select"]) {
        self.navigationItem.rightBarButtonItem.title = @"Done";
    } else
        self.navigationItem.rightBarButtonItem.title = @"Select";
    
}

#pragma mark - initialization

- (id)initWithImageAssets:(NSMutableArray *)imageAssets actualAssetsURLs:(NSArray *)actualAssetsURLs
{
    if ((self = [super init]))
    {
        self.title = @"Select";
        
        UIBarButtonItem *selectButton = [[UIBarButtonItem alloc] initWithTitle:@"Select" style:UIBarButtonItemStyleBordered target:self action:@selector(switchSelectionMode)];
        
        self.navigationItem.rightBarButtonItem = selectButton;
        
        [selectButton release];
        
        self.currentData = imageAssets;
        
        self.selectedCellURLs = [NSMutableArray array];
        
        for (int i = 0; i < self.currentData.count; i++) {
            
            NSURL * assURL = [[[self.currentData objectAtIndex:i] defaultRepresentation] url];
            
            
            if ([actualAssetsURLs containsObject:assURL]) {
                [self.selectedCellURLs addObject:assURL];
            }
        }
        
        selectionModeIsOn = NO;
        
        viewDidDisappear = NO;
    }
    
    return self;
}

//////////////////////////////////////////////////////////////
#pragma mark controller events
//////////////////////////////////////////////////////////////

- (void)loadView
{
    [super loadView];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSInteger spacing = ![(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad] ? 10 : 15;
    
    GMGridView *gmGridView = [[GMGridView alloc] initWithFrame:self.view.bounds];
    self.gmGridView = gmGridView;
    [gmGridView release];
    self.gmGridView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.gmGridView.style = GMGridViewStyleSwap;
    self.gmGridView.itemSpacing = spacing;
    self.gmGridView.minEdgeInsets = UIEdgeInsetsMake(spacing, spacing, spacing, spacing);
    self.gmGridView.centerGrid = YES;
    self.gmGridView.actionDelegate = self;
    self.gmGridView.sortingDelegate = self;
    self.gmGridView.dataSource = self;
    self.gmGridView.disableEditOnEmptySpaceTap = YES;
    self.gmGridView.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:self.gmGridView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.gmGridView.mainSuperView = self.navigationController.view;
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(updateAssets:)
     name:ALAssetsLibraryChangedNotification
     object:nil];
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:ALAssetsLibraryChangedNotification
     object:nil];
    
    [super viewDidUnload];
}


-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    if (viewDidDisappear
        && self.interfaceOrientation != lastOrientation) {
        
        [self.gmGridView reloadData];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    self.gmGridView.editing = NO;
    
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (void) viewControllerWillBePopped {
    
    if (self.progressHUD && self.progressHUD.superview) {
        
        [self hideProgressHUD:YES];
        
        [(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO force:NO];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    if (viewControllers.count > 1 && [viewControllers objectAtIndex:viewControllers.count-2] == self) {
        // View is disappearing because a new view controller was pushed onto the stack
    } else if ([viewControllers indexOfObject:self] == NSNotFound) {
        // View is disappearing because it was popped from the stack
        //        NSLog(@"View controller was popped");
        [self viewControllerWillBePopped];
    }
    
    [super viewWillDisappear:animated];
}

-(void)viewDidDisappear:(BOOL)animated {
    
    viewDidDisappear = YES;
    
    [super viewDidDisappear:animated];
}

//////////////////////////////////////////////////////////////
#pragma mark memory management
//////////////////////////////////////////////////////////////

- (void)didReceiveMemoryWarning {
    
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


//////////////////////////////////////////////////////////////
#pragma mark GMGridViewDataSource
//////////////////////////////////////////////////////////////

- (NSInteger)numberOfItemsInGMGridView:(GMGridView *)gridView
{
    return [self.currentData count];
}

- (CGSize)GMGridView:(GMGridView *)gridView sizeForItemsInInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    if (![(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad])
    {
        if (UIInterfaceOrientationIsLandscape(orientation))
        {
            return CGSizeMake(170, 135);
        }
        else
        {
            return CGSizeMake(140, 110);
        }
    }
    else
    {
        if (UIInterfaceOrientationIsLandscape(orientation))
        {
            return CGSizeMake(285, 205);
        }
        else
        {
            return CGSizeMake(230, 175);
        }
    }
}

- (GMGridViewCell *)GMGridView:(GMGridView *)gridView cellForItemAtIndex:(NSInteger)index
{
    CGSize size = [self GMGridView:gridView sizeForItemsInInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    
    GMGridViewCell *cell = [gridView dequeueReusableCell];
    
    if (!cell)
    {
        cell = [[[GMGridViewCell alloc] init] autorelease];
        cell.deleteButtonIcon = [UIImage imageNamed:@"close_x.png"];
        cell.deleteButtonOffset = CGPointMake(-15, -15);
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        view.backgroundColor = [UIColor clearColor];
        view.layer.masksToBounds = NO;
        
        cell.contentView = view;
        [view release];
    }
    
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    ALAsset * asset = [self.currentData objectAtIndex:index];
    CGImageRef i;
    if ([asset respondsToSelector:@selector(aspectRatioThumbnail)]) {
        i = [asset aspectRatioThumbnail];
    } else if ([asset respondsToSelector:@selector(thumbnail)]) {
        i = [asset thumbnail];
    }
    
    UIImage * img = [UIImage imageWithCGImage:i];
//    
//    NSLog(@"img %f %f", img.size.width, img.size.height);
    
    SWSnapshotStackView *snap = nil;
    
    if (img.size.height < size.height && img.size.width < size.width) {
        
        snap = [[SWSnapshotStackView alloc] initWithFrame:CGRectMake(roundf(0.5 * (size.width - img.size.width)),
                                                                roundf(0.5 * (size.height - img.size.height)),
                                                                img.size.width,
                                                                img.size.height)];
        
    } else {
        
        snap = [[SWSnapshotStackView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        
    }
    
//    CGRect imageRrect = CGRectMake(0, 0, img.size.width, img.size.height);
//    UIGraphicsBeginImageContext(imageRrect.size);
//    [img drawInRect:CGRectMake(1, 1, img.size.width-2, img.size.height-2)];
//    img = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
    
    [snap setImage:img];
    
    [snap setDisplayAsStack:NO];
    
    [cell.contentView addSubview:snap];
    
    if ([self.selectedCellURLs containsObject:asset.defaultRepresentation.url]) {
        
        CGSize scaledImageSize = [snap showMeTheSize];
//        CGRect scaledImageR = [snap showMeTheRect];
        
        UIView *mask = [[UIView alloc] initWithFrame:snap.frame];

        [mask setBackgroundColor:[UIColor
                                  colorWithWhite:1.0 alpha:0.35]
         ];
        [cell.contentView addSubview:mask];
        [mask release];
        
        UIImage *im = [UIImage imageNamed:@"tick_mark.png"];
        
        UIImageView *imV = [[UIImageView alloc] initWithImage:im];
        
        imV.frame = CGRectMake(roundf(size.width / 2.0)
                               + roundf(0.5 * scaledImageSize.width)
                               //- roundf(im.size.width * 0.5)
                               - 25
                               ,
                               roundf(size.height / 2.0)
                               + roundf(0.5 * scaledImageSize.height)
                               //- roundf(im.size.height * 0.5)
                               - 25
                               ,
                               im.size.width,
                               im.size.height);
        
        [cell.contentView addSubview:imV];
        
        [imV release];
    }
    
    [snap release];
    
    return cell;
}


- (BOOL)GMGridView:(GMGridView *)gridView canDeleteItemAtIndex:(NSInteger)index
{
    return NO; //index % 2 == 0;
}

//////////////////////////////////////////////////////////////
#pragma mark GMGridViewActionDelegate
//////////////////////////////////////////////////////////////

- (void)GMGridView:(GMGridView *)gridView didTapOnItemAtIndex:(NSInteger)position
{
//    NSLog(@"selected cell urls %@", self.selectedCellURLs);
    
    NSURL * url = [[[self.currentData objectAtIndex:position] defaultRepresentation] url];
    
    if (selectionModeIsOn && ![self.selectedCellURLs containsObject:url]) {
        
        [self.selectedCellURLs addObject:url];
        
        [self.gmGridView reloadData];
        
        if (self.delegate
            && [self.delegate respondsToSelector:@selector(photoSelectionControllerSelectedAssetWithURL:)]) {
            
            [self.delegate photoSelectionControllerSelectedAssetWithURL:url];
        }
    
    } else if (selectionModeIsOn && [self.selectedCellURLs containsObject:url]) {
        
        if (self.delegate
            && [self.delegate respondsToSelector:@selector(photoSelectionControllerUnselectedAssetWithURL:)]) {
            
            [self.delegate photoSelectionControllerUnselectedAssetWithURL:url];
        }
        
        [self.selectedCellURLs removeObject:url];
        
        [self.gmGridView reloadData];
        
    } else {
        
        [self browsePhotosStartingAtIndex:position];
        
    }
}

//////////////////////////////////////////////////////////////
#pragma mark GMGridViewSortingDelegate
//////////////////////////////////////////////////////////////

- (BOOL)GMGridView:(GMGridView *)gridView shouldAllowShakingBehaviorWhenMovingCell:(GMGridViewCell *)cell atIndex:(NSInteger)index
{
    return YES;
}

- (void)GMGridView:(GMGridView *)gridView moveItemAtIndex:(NSInteger)oldIndex toIndex:(NSInteger)newIndex
{
    NSObject *ass = [self.currentData objectAtIndex:oldIndex];
    [self.currentData removeObject:ass];
    [self.currentData insertObject:ass atIndex:newIndex];
    
}

- (void)GMGridView:(GMGridView *)gridView exchangeItemAtIndex:(NSInteger)index1 withItemAtIndex:(NSInteger)index2
{
    [self.currentData exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
}


@end

