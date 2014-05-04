//
//  PhotoViewController.h
//  repWallet
//
//  Created by Alberto Fiore on 12/27/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//
#import "PhotoAlbumViewController.h"
#import "PhotoViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "GMGridView.h"
#import "RepWalletAppDelegate.h"
#import "ALAssetsManager.h"
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

@interface PhotoViewController () <GMGridViewDataSource, GMGridViewSortingDelegate, GMGridViewActionDelegate, MWPhotoBrowserDelegate, UIAccelerometerDelegate, PhotoAlbumViewControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    NSInteger _lastDeleteItemIndexAsked;
    BOOL histeresisExcited;
    UIInterfaceOrientation lastOrientation;
    BOOL viewDidDisappear;
    pthread_mutex_t mutex;
}

@property (nonatomic, retain) MWPhotoBrowser *photoBrowser;
@property (nonatomic, retain) GMGridView *gmGridView;
@property (nonatomic, retain) NSMutableArray *currentData;
@property (nonatomic, retain) MWPhoto* currentPhoto;
@property (nonatomic, retain) UIAcceleration* lastAcceleration;
@property (nonatomic, retain) MBProgressHUD *progressHUD;
@property (nonatomic, retain) UIImagePickerController *photoCamera;
@property (nonatomic, retain) PhotoAlbumViewController *albumVC;

- (void) getAssetGroups;

- (void) startCamera;

@end


//////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark ViewController implementation
//////////////////////////////////////////////////////////////

@implementation PhotoViewController

@synthesize photoCamera, progressHUD, currentData, gmGridView, photoBrowser, delegate, lastAcceleration, currentPhoto, albumVC;

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
    
    if (self.albumVC) {
        self.albumVC.delegate = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    pthread_mutex_destroy(&mutex);

    [self.albumVC release];
    [self.photoCamera release];
    [self.progressHUD release];
    [self.currentPhoto release];
    [self.photoBrowser release];
    [self.lastAcceleration release];
    [self.currentData release];
    [self.gmGridView release];
    [super dealloc];
}

- (void) toggleEditingForGridView
{
    self.gmGridView.editing = !self.gmGridView.isEditing;    
    [self.gmGridView layoutSubviewsWithAnimation:GMGridViewItemAnimationFade];
}

#pragma mark - Toolbar

- (void) showTabBar:(UITabBarController *) tabbarcontroller
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    float fHeight = screenRect.size.height - self.tabBarController.tabBar.frame.size.height;
    
    if(  UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) )
    {
        fHeight = screenRect.size.width - self.tabBarController.tabBar.frame.size.height;
    }
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.2];
    for(UIView *view in tabbarcontroller.view.subviews)
    {
        if([view isKindOfClass:[UITabBar class]])
        {
            [view setFrame:CGRectMake(view.frame.origin.x, fHeight, view.frame.size.width, view.frame.size.height)];
        }
        else
        {
            [view setFrame:CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, fHeight)];
        }
    }
    
    [self.gmGridView setFrame:CGRectMake(self.gmGridView.frame.origin.x, self.gmGridView.frame.origin.y, self.gmGridView.frame.size.width, fHeight
                                        - [UIApplication sharedApplication].statusBarFrame.size.height
                                        - self.navigationController.toolbar.frame.size.height
                                        - self.navigationController.navigationBar.frame.size.height
                                        )];
    [UIView commitAnimations];
}

- (void) hideTabBar:(UITabBarController *) tabbarcontroller
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.2];
    float fHeight = screenRect.size.height;
    if(  UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) )
    {
        fHeight = screenRect.size.width;
    }
    
    for(UIView *view in tabbarcontroller.view.subviews)
    {
        if([view isKindOfClass:[UITabBar class]])
        {
            [view setFrame:CGRectMake(view.frame.origin.x, fHeight, view.frame.size.width, view.frame.size.height)];
        }
        else
        {
            [view setFrame:CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, fHeight)];
            view.backgroundColor = [UIColor blackColor];
        }
    }
    
    [self.gmGridView setFrame:CGRectMake(self.gmGridView.frame.origin.x, self.gmGridView.frame.origin.y, self.gmGridView.frame.size.width, fHeight - [UIApplication sharedApplication].statusBarFrame.size.height
                                        - self.navigationController.toolbar.frame.size.height
                                        - self.navigationController.navigationBar.frame.size.height
                                        )];
    
    [UIView commitAnimations];
}

- (void) hideTabBar {
    
    [self hideTabBar:self.tabBarController];
}

- (void) showTabBar {
    
    [self showTabBar:self.tabBarController];
}

- (void) createToolbar {
    
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"import.png"] style:UIBarButtonItemStylePlain target:self action:@selector(getAssetGroups)];
    UIBarButtonItem *item3 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(startCamera)];
    UIBarButtonItem *item4 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"change.png"] style:UIBarButtonItemStylePlain target:self action:@selector(toggleEditingForGridView)];
    
    NSArray *items = nil;
    
    if ([UIImagePickerController isSourceTypeAvailable:
          UIImagePickerControllerSourceTypeCamera] == NO) {
        
        items = [NSArray arrayWithObjects:item2, flexibleItem, item4, nil];
        
    } else {
        
        items = [NSArray arrayWithObjects:item2, flexibleItem, item4, flexibleItem, item3, nil];
    }

    [self setToolbarItems:items animated:YES];
    
    [flexibleItem release];
    
    [item2 release];
    [item3 release];
    [item4 release];
    
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
#pragma mark Camera


- (BOOL) startCameraControllerFromViewController: (UIViewController*) controller
                                   usingDelegate: (id <UIImagePickerControllerDelegate,
                                                   UINavigationControllerDelegate>) delegate {
    
    if (([UIImagePickerController isSourceTypeAvailable:
          UIImagePickerControllerSourceTypeCamera] == NO)
        || (delegate == nil)
        || (controller == nil))
        return NO;
    
    
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    // Displays a control that allows the user to choose picture
    cameraUI.mediaTypes = [NSArray arrayWithObjects: (NSString *) kUTTypeImage, nil];
    
    // Hides the controls for moving & scaling pictures, or for
    // trimming movies. To instead show the controls, use YES.
    cameraUI.allowsEditing = NO;
    
    cameraUI.delegate = delegate;
    
    [controller presentModalViewController:cameraUI animated:YES];
    
    self.photoCamera = cameraUI;
    
    [cameraUI release];
    
    return YES;
}

- (void) startCamera {
    [self startCameraControllerFromViewController:self usingDelegate:self];
}

// For responding to the user tapping Cancel.
- (void) imagePickerControllerDidCancel: (UIImagePickerController *) picker {
    
    [self dismissModalViewControllerAnimated:YES];
}

// For responding to the user accepting a newly-captured picture or movie
- (void) imagePickerController: (UIImagePickerController *) picker
 didFinishPickingMediaWithInfo: (NSDictionary *) info {
    
    [self createProgressHUDForView:picker.view];
    
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    UIImage *originalImage, *editedImage, *imageToSave;
    
    // Handle a still image capture
    if (CFStringCompare ((CFStringRef) mediaType, kUTTypeImage, 0)
        == kCFCompareEqualTo) {
        
        editedImage = (UIImage *) [info objectForKey:
                                   UIImagePickerControllerEditedImage];
        originalImage = (UIImage *) [info objectForKey:
                                     UIImagePickerControllerOriginalImage];
        
        if (editedImage) {
            imageToSave = editedImage;
        } else {
            imageToSave = originalImage;
        }
        
        // Save the new image (original or edited) to the album 'repWallet'
        
        [self showProgressHUDWithMessage:@"Saving"];
        
        [[ALAssetsManager defaultAssetsLibrary] saveImage:imageToSave toAlbum:@"repWallet" withCompletionBlock:^(NSError *error, NSURL *assetURL) {
            
            if (error) {
                
                [self dismissModalViewControllerAnimated:YES];
                
                [self hideProgressHUD:YES];
                
                NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while saving the image. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alertView show];
                [alertView release];
                
                
            } else {
                
                if (assetURL) {

                    ALAssetsLibraryAssetForURLResultBlock assetForURL =  ^(ALAsset *asset) {
                        
                        if (asset) {
                            
                            CGImageRef i;
                            if ([asset respondsToSelector:@selector(aspectRatioThumbnail)]) {
                                i = [asset aspectRatioThumbnail];
                            } else if ([asset respondsToSelector:@selector(thumbnail)]) {
                                i = [asset thumbnail];
                            }
                            
                            UIImage * img = [UIImage imageWithCGImage:i];
                            
                            [self.currentData addObject:[NSDictionary dictionaryWithObjectsAndKeys:img, @"image", assetURL, @"url", nil]];
                            
                            [self.gmGridView insertObjectAtIndex:[self.currentData count] - 1 withAnimation:GMGridViewItemAnimationFade | GMGridViewItemAnimationScroll];
                            
                            if (self.delegate && [self.delegate respondsToSelector:@selector(photoViewControllerAddedAssetWithURL:)]) {
                                [self.delegate photoViewControllerAddedAssetWithURL:assetURL];
                            }
                            
                            [self dismissModalViewControllerAnimated:YES];
                            
                            [self hideProgressHUD:YES];
                            
                        } else {
                            
                            [self dismissModalViewControllerAnimated:YES];
                            
                            [self hideProgressHUD:YES];
                        }
                        
                    };

                        
                    [[ALAssetsManager defaultAssetsLibrary] assetForURL:assetURL resultBlock:assetForURL failureBlock:^(NSError *error) {
                        
                        NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
                        
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while retrieving the images. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                        [alertView show];
                        [alertView release];
                        
                    }];

                    
                } else {
                  
                    [self dismissModalViewControllerAnimated:YES];
                    
                    [self hideProgressHUD:YES];
                    
                }
            }
        }];
    }
}

#pragma mark -
#pragma mark Shake gesture

- (BOOL) L0AccelerationIsShakingWithLast:(UIAcceleration*)last current:(UIAcceleration*)current threshold:(double) threshold {
	double
    deltaX = fabs(last.x - current.x),
    deltaY = fabs(last.y - current.y),
    deltaZ = fabs(last.z - current.z);
    
	return
    (deltaX > threshold && deltaY > threshold) ||
    (deltaX > threshold && deltaZ > threshold) ||
    (deltaY > threshold && deltaZ > threshold);
}

- (void) accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    
	if (self.lastAcceleration) {
        
		if (!histeresisExcited && [self L0AccelerationIsShakingWithLast:self.lastAcceleration current:acceleration threshold:0.7]) {
            
			histeresisExcited = YES;
            
            [self toggleEditingForGridView];
            
		} else if (histeresisExcited && ![self L0AccelerationIsShakingWithLast:self.lastAcceleration current:acceleration threshold:0.2]) {
			histeresisExcited = NO;
		}
	}
    
	self.lastAcceleration = acceleration;
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
        
        NSMutableArray *arr = [NSMutableArray array];
        
        __block int counter = 0;
        
        for (int i = 0; i < self.currentData.count; i++) {
            
            NSURL *assetURL = [[self.currentData objectAtIndex:i] objectForKey:@"url"];
            
            // the result block
            ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
            {
                counter++;
                
                if (myasset) {
                    
                    [arr addObject:myasset.defaultRepresentation.url];
                    
                }
                
                if (counter == self.currentData.count) {
                    
                    for (int k = 0; k < self.currentData.count; k++) {
                        
                        NSURL *assetURL = [[self.currentData objectAtIndex:k] objectForKey:@"url"];
                        
                        if (![arr containsObject:assetURL]) {
                            
                            if (self.delegate && [self.delegate respondsToSelector:@selector(photoViewControllerRemovedAssetWithURL:)]) {
                                [self.delegate photoViewControllerRemovedAssetWithURL:assetURL];
                            }
                            
                            [self.currentData removeObjectAtIndex:k];
                            
                            k--;

                        }
                    }
                    
                    [self.gmGridView reloadData];
                }
            };

            ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *error)
            {
                NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while processing the image. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alertView show];
                [alertView release];
                
            };
            
            // schedules the asset read
            ALAssetsLibrary* assetslibrary = [ALAssetsManager defaultAssetsLibrary];
            
            [assetslibrary assetForURL:assetURL
                           resultBlock:resultblock
                          failureBlock:failureblock];
        }
    }
}


#pragma mark -
#pragma mark Photo browser

-(void)photoAlbumAddedAssetWithURL:(NSURL *)assetURL {
    
    ALAssetsLibrary* library = [ALAssetsManager defaultAssetsLibrary];
    
    ALAssetsLibraryAssetForURLResultBlock assetForURL =  ^(ALAsset *asset) {
        
        CGImageRef i;
        if ([asset respondsToSelector:@selector(aspectRatioThumbnail)]) {
            i = [asset aspectRatioThumbnail];
        } else if ([asset respondsToSelector:@selector(thumbnail)]) {
            i = [asset thumbnail];
        }
        
        UIImage * img = [UIImage imageWithCGImage:i];
        
        [self.currentData addObject:[NSDictionary dictionaryWithObjectsAndKeys:img, @"image", asset.defaultRepresentation.url, @"url", nil]];
        [self.gmGridView insertObjectAtIndex:[self.currentData count] - 1 withAnimation:GMGridViewItemAnimationFade | GMGridViewItemAnimationScroll];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(photoViewControllerAddedAssetWithURL:)]) {
            [self.delegate photoViewControllerAddedAssetWithURL:asset.defaultRepresentation.url];
        }
    };
    
    [library assetForURL:assetURL resultBlock:assetForURL failureBlock:^(NSError *error) {
        
        NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while processing the image. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
    }];
}

-(void)photoAlbumRemovedAssetWithURL:(NSURL *)assetURL {
    
    for (int i = 0; i < self.currentData.count; i++) {
        
        if ([[[self.currentData objectAtIndex:i] objectForKey:@"url"] isEqual:assetURL]) {
            
            [self.gmGridView removeObjectAtIndex:i withAnimation:GMGridViewItemAnimationFade | GMGridViewItemAnimationScroll];
            
            [self.currentData removeObjectAtIndex:i];
            
            break;
        }
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(photoViewControllerRemovedAssetWithURL:)]) {
        [self.delegate photoViewControllerRemovedAssetWithURL:assetURL];
    }
}

- (void)browsePhotoAlbums:(NSMutableArray *)photoAlbums 
{
    NSMutableArray *arr = [NSMutableArray array];
    
    for (int i = 0; i < self.currentData.count; i++) {
        [arr addObject:[[self.currentData objectAtIndex:i] objectForKey:@"url"]];
    }
    
	PhotoAlbumViewController * imgDemo = [[PhotoAlbumViewController alloc] initWithAlbumAssets:photoAlbums URLsOfActualAssets:arr];
    self.albumVC = imgDemo;
    [imgDemo release];
    self.albumVC.delegate = self;
    [self.navigationController pushViewController:self.albumVC animated:YES];
}

- (void)browsePhotosToRemoveJumpAtPhotoIndex:(NSUInteger) index 
{
	MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    browser.displayActionButton = YES;
    [self.navigationController pushViewController:browser animated:YES];
    [browser setInitialPageIndex:index];
    self.photoBrowser = browser;
    [browser release];
}

- (void)getAssetGroups
{
    NSMutableArray *assGroups = [NSMutableArray array];
    
    ALAssetsLibraryGroupsEnumerationResultsBlock assetGroupEnumerator =  ^(ALAssetsGroup *group, BOOL *stop) {
        if(group != nil) {
            [assGroups addObject:group];
        } else {
            *stop = YES;
            [self browsePhotoAlbums:assGroups];
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


#pragma mark - MWPhotoBrowserDelegate

-(void)photoBrowserChosePhotoToBeRemovedWithAssetURL:(NSURL *)assetURL {

    for (int i = 0; i < self.currentData.count; i++) {
        
        if ([[[self.currentData objectAtIndex:i] objectForKey:@"url"] isEqual:assetURL]) {
            
            [self.gmGridView removeObjectAtIndex:i withAnimation:GMGridViewItemAnimationFade | GMGridViewItemAnimationScroll];
            [self.currentData removeObjectAtIndex:i];
            
            if (self.currentData.count == 0) {
                
                [self.navigationController popViewControllerAnimated:YES];
                
            } else if (i == self.currentData.count) {
                
                [self.photoBrowser reloadData];
                [self.photoBrowser gotoPreviousPage];
                
            } else {
                
                [self.photoBrowser reloadData];
                
            }
            
            break;
        }
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(photoViewControllerRemovedAssetWithURL:)]) {
        [self.delegate photoViewControllerRemovedAssetWithURL:assetURL];
    }

}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.currentData.count;
}

- (MWPhoto *)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    
    if (index < self.currentData.count){
    
        // sets up a condition lock with "pending reads"
        __block NSConditionLock * albumReadLock = [[NSConditionLock alloc] initWithCondition:WDASSETURL_PENDINGREADS];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSURL *assetURL = [[self.currentData objectAtIndex:index] objectForKey:@"url"];
            
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

#pragma mark - initialization

- (id)initWithImageAssets:(NSMutableArray *)imageAssets
{
    if ((self = [super init])) 
    {
        self.title = @"Imported Photos";
        
        self.navigationController.toolbarHidden = NO;
        self.navigationController.toolbar.translucent = NO;
        
        self.currentData = imageAssets;
        
        viewDidDisappear = NO;
        
        pthread_mutex_init(&mutex, NULL);
        
    }
    
    return self;
}

//////////////////////////////////////////////////////////////
#pragma mark - controller events
//////////////////////////////////////////////////////////////

-(void) getBack {
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else if ([self respondsToSelector:@selector(dismissModalViewControllerAnimated:)]) {
        [self dismissModalViewControllerAnimated:YES];
    }
}

- (void)loadView 
{
    [super loadView];
    
    [self createToolbar];

    self.view.backgroundColor = [UIColor whiteColor];
    
    NSInteger spacing = ![(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad] ? 10 : 15;
    
    GMGridView *gmGridView = [[GMGridView alloc] initWithFrame:self.view.bounds];
    self.gmGridView = gmGridView;
    [gmGridView release];
    self.gmGridView.style = GMGridViewStyleSwap;
    self.gmGridView.itemSpacing = spacing;
    self.gmGridView.minEdgeInsets = UIEdgeInsetsMake(spacing, spacing, spacing, spacing);
    self.gmGridView.centerGrid = YES;
    self.gmGridView.actionDelegate = self;
    self.gmGridView.sortingDelegate = self;
    self.gmGridView.dataSource = self;
    self.gmGridView.disableEditOnEmptySpaceTap = YES;
    self.gmGridView.backgroundColor = [UIColor clearColor];
    self.gmGridView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.gmGridView];
    
}

- (void) undoModifications {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(photoViewControllerCanceled)]) {
        [self.delegate photoViewControllerCanceled];
    }
    
    [self getBack];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.gmGridView.mainSuperView = self.navigationController.view;
    
    UIBarButtonItem * cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(undoModifications)];
    cancelButton.style = UIBarButtonItemStyleBordered;
    self.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];
    
    UIBarButtonItem * doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(getBack)];
    doneButton.style = UIBarButtonItemStyleBordered;
    self.navigationItem.rightBarButtonItem = doneButton;
    [doneButton release];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(updateAssets:)
     name:ALAssetsLibraryChangedNotification
     object:nil];
}

- (void)viewDidUnload
{
    if (self.albumVC) {
        self.albumVC.delegate = nil;
    }
    
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:ALAssetsLibraryChangedNotification
     object:nil];

    self.albumVC = nil;
    
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.navigationController setToolbarHidden:NO animated:animated];
    
    self.gmGridView.editing = NO;
    
    if (viewDidDisappear
        && self.interfaceOrientation != lastOrientation) {
        
        [self.gmGridView reloadData];
    }
}


- (void) viewControllerWillBePopped
{
    if (self.progressHUD && self.progressHUD.superview) {
        
        [self hideProgressHUD:YES];
        
        [(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO force:NO];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(photoViewControllerWillBePoppedWithAssets:)]) {
        [self.delegate photoViewControllerWillBePoppedWithAssets:self.currentData];
    }
    
}

-(void)viewWillDisappear:(BOOL)animated 
{
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    if (viewControllers.count > 1 && [viewControllers objectAtIndex:viewControllers.count-2] == self) {
        // View is disappearing because a new view controller was pushed onto the stack
    } else if ([viewControllers indexOfObject:self] == NSNotFound) {
        // View is disappearing because it was popped from the stack
        [self viewControllerWillBePopped];
    }
    
    [super viewWillDisappear:animated];
}


-(void)viewDidDisappear:(BOOL)animated {
    
    viewDidDisappear = YES;
    
    [super viewDidDisappear:animated];
}

//////////////////////////////////////////////////////////////
#pragma mark - memory management
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
#pragma mark - GMGridViewDataSource
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
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        view.backgroundColor = [UIColor clearColor];
        view.layer.masksToBounds = NO;
        
        cell.contentView = view;
        [view release];
    }
    
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

    UIImage * img = [[self.currentData objectAtIndex:index] objectForKey:@"image"];
    
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
    
    [cell.contentView addSubview:snap];
    
    CGSize scaledImageSize = [snap showMeTheSize];
    
    cell.deleteButtonOffset = CGPointMake(roundf(size.width / 2.0)
                                          - roundf(0.5 * scaledImageSize.width)
                                          - 25,
                                          roundf(size.height / 2.0)
                                          - roundf(0.5 * scaledImageSize.height)
                                          - 25);

    [snap release];
    
    return cell;
}


- (BOOL)GMGridView:(GMGridView *)gridView canDeleteItemAtIndex:(NSInteger)index
{
    return YES; //index % 2 == 0;
}

//////////////////////////////////////////////////////////////
#pragma mark - GMGridViewActionDelegate
//////////////////////////////////////////////////////////////

- (void)GMGridView:(GMGridView *)gridView didTapOnItemAtIndex:(NSInteger)position
{
    [self browsePhotosToRemoveJumpAtPhotoIndex:position];
}

- (void)GMGridView:(GMGridView *)gridView processDeleteActionForItemAtIndex:(NSInteger)index
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(photoViewControllerRemovedAssetWithURL:)]) {
        [self.delegate photoViewControllerRemovedAssetWithURL:[[self.currentData objectAtIndex:index] objectForKey:@"url"]];
    }
    
    _lastDeleteItemIndexAsked = index;
    [self.currentData removeObjectAtIndex:_lastDeleteItemIndexAsked];
    [self.gmGridView removeObjectAtIndex:_lastDeleteItemIndexAsked withAnimation:GMGridViewItemAnimationFade];
}


//////////////////////////////////////////////////////////////
#pragma mark - GMGridViewSortingDelegate
//////////////////////////////////////////////////////////////

- (BOOL)GMGridView:(GMGridView *)gridView shouldAllowShakingBehaviorWhenMovingCell:(GMGridViewCell *)cell atIndex:(NSInteger)index
{
    return YES;
}

- (void)GMGridView:(GMGridView *)gridView moveItemAtIndex:(NSInteger)oldIndex toIndex:(NSInteger)newIndex
{
    NSObject *object = [self.currentData objectAtIndex:oldIndex];
    [self.currentData removeObject:object];
    [self.currentData insertObject:object atIndex:newIndex];
}

- (void)GMGridView:(GMGridView *)gridView exchangeItemAtIndex:(NSInteger)index1 withItemAtIndex:(NSInteger)index2
{
    [self.currentData exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
}


@end
