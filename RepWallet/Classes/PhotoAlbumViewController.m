//
//  PhotoAlbumViewController.h
//  repWallet
//
//  Created by Alberto Fiore on 12/27/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//
#import "PhotoAlbumViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "GMGridView.h"
#import "RepWalletAppDelegate.h"
#import "ALAssetsManager.h"
#import "UIImage+UIImageExtras.h"
#import "MBProgressHUD.h"
#import "PhotoSelectionViewController.h"
#import "SWSnapshotStackView.h"

//////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark ViewController (privates methods)
//////////////////////////////////////////////////////////////

@interface PhotoAlbumViewController () <GMGridViewDataSource, GMGridViewSortingDelegate, GMGridViewActionDelegate, PhotoSelectionViewControllerDelegate>
{
    NSInteger _lastDeleteItemIndexAsked;
    UIInterfaceOrientation lastOrientation;
    BOOL viewDidDisappear;
}

@property (nonatomic, retain) GMGridView *gmGridView;
@property (nonatomic, retain) NSMutableArray *currentData;
@property (nonatomic, retain) NSMutableArray *actualAssetsURLs;
@property (nonatomic, retain) MBProgressHUD *progressHUD;
@property (nonatomic, retain) PhotoSelectionViewController *selectVC;


@end

//////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark ViewController implementation
//////////////////////////////////////////////////////////////

@implementation PhotoAlbumViewController

@synthesize currentData, gmGridView, actualAssetsURLs, delegate, progressHUD, selectVC;

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

#pragma mark - MBProgressHUD

- (MBProgressHUD *)createProgressHUDForView:(UIView *)view {
    if (!self.progressHUD || ![self.progressHUD.superview isEqual:view]) {
        MBProgressHUD * p = [[MBProgressHUD alloc] initWithView:view];
        self.progressHUD = p;
        [p release];
        self.progressHUD.minSize = CGSizeMake(120, 120);
        self.progressHUD.minShowTime = 0.5;
        self.progressHUD.customView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MWPhotoBrowser.bundle/images/Checkmark.png"]] autorelease];
        [view addSubview:self.progressHUD];
    }
    return self.progressHUD;
}

- (void)showProgressHUDWithMessage:(NSString *)message {
    self.progressHUD.labelText = message;
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    [self.progressHUD show:YES];
}

- (void)hideProgressHUD:(BOOL)animated {
    [self.progressHUD hide:animated];
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
}

- (void)getAssetsForGroup:(ALAssetsGroup *)assGroup
{
    NSMutableArray *assetsForGroup = [NSMutableArray array];
    
    ALAssetsGroupEnumerationResultsBlock assetEnumerator = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if(result != NULL
           && [[result valueForProperty:ALAssetPropertyType] isEqual:ALAssetTypePhoto]
           ) {
                [assetsForGroup addObject:result];
            
        } else if(result == NULL) {
            
            *stop = YES;
            
            if (assetsForGroup.count > 0) {
                
                PhotoSelectionViewController *selContr = [[PhotoSelectionViewController alloc] initWithImageAssets:assetsForGroup actualAssetsURLs:self.actualAssetsURLs];
                self.selectVC = selContr;
                [selContr release];
                self.selectVC.delegate = self;
                self.selectVC.assetGroupID = [assGroup valueForProperty:ALAssetsGroupPropertyPersistentID];
                self.selectVC.title = [assGroup valueForProperty:ALAssetsGroupPropertyName];
                [self.navigationController pushViewController:self.selectVC animated:YES];
                                
            } else {
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"The album is empty." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alertView show];
                [alertView release];
                
            }
        }
    };
    
    [assGroup enumerateAssetsUsingBlock:assetEnumerator];
}

#pragma mark - Asset update notifrication

- (void) updateAssetGroups:(NSNotification *)notification {
    
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
        
        NSMutableArray *assGroups = [NSMutableArray array];
        
        ALAssetsLibraryGroupsEnumerationResultsBlock assetGroupEnumerator =  ^(ALAssetsGroup *group, BOOL *stop) {
            if(group != nil) {
                [assGroups addObject:group];
            } else {
                *stop = YES;
                [self.currentData removeAllObjects];
                self.currentData = [NSMutableArray arrayWithArray:assGroups];
                [self.gmGridView reloadData];
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

#pragma mark - ImageSelectionViewControllerDelegate

-(void)photoSelectionControllerSelectedAssetWithURL:(NSURL *)assetURL {
    
    [self.actualAssetsURLs addObject:assetURL];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(photoAlbumAddedAssetWithURL:)]) {
        [self.delegate photoAlbumAddedAssetWithURL:assetURL];
    }
    
}

-(void)photoSelectionControllerUnselectedAssetWithURL:(NSURL *)assetURL {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(photoAlbumRemovedAssetWithURL:)]) {
        [self.delegate photoAlbumRemovedAssetWithURL:assetURL];
    }
    
    [self.actualAssetsURLs removeObject:assetURL];

}

- (NSInteger) numberOfPhotosInAssetsGroup:(ALAssetsGroup *)assGroup {
    
    [assGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
    
    return [assGroup numberOfAssets];
    
}


- (void)dealloc {
    
    if (self.selectVC) {
        self.selectVC.delegate = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.selectVC release];
    [self.progressHUD release];
    [self.actualAssetsURLs release];
    [self.currentData release];
    [self.gmGridView release];
    [super dealloc];
}

#pragma mark - initialization

- (id)initWithAlbumAssets:(NSMutableArray *)albumAssets URLsOfActualAssets:(NSMutableArray *)assetsURLs
{
    if ((self = [super init])) 
    {
        self.title = @"Albums";
        
        self.currentData = albumAssets;
        
        self.actualAssetsURLs = [NSMutableArray arrayWithArray:assetsURLs];
        
        viewDidDisappear = NO;
    }
    
    return self;
}

//////////////////////////////////////////////////////////////
#pragma mark - controller events
//////////////////////////////////////////////////////////////

- (void)loadView 
{
    [super loadView];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSInteger spacing = ![(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad] ? 55 : 55;
    
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.gmGridView.mainSuperView = self.navigationController.view;
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(updateAssetGroups:)
     name:ALAssetsLibraryChangedNotification
     object:nil];
}


- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:ALAssetsLibraryChangedNotification
     object:nil];
    
    if (self.selectVC) {
        self.selectVC.delegate = nil;
    }

    [super viewDidUnload];
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    if (viewDidDisappear
        && self.interfaceOrientation != lastOrientation) {
        
        [self.gmGridView reloadData];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    [self.navigationController setToolbarHidden:YES animated:animated];
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
            return CGSizeMake(120, 120);
        }
        else
        {
            return CGSizeMake(120, 120);
        }
    }
    else
    {
        if (UIInterfaceOrientationIsLandscape(orientation)) 
        {
            return CGSizeMake(120, 120);
        }
        else
        {
            return CGSizeMake(120, 120);
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
    
    UIImage * posterImg = [UIImage imageWithCGImage:[[self.currentData objectAtIndex:index] posterImage]];
    
    SWSnapshotStackView *snap = nil;
    
    if (posterImg == nil || CGSizeEqualToSize(posterImg.size, CGSizeZero)) {
        // TODO 
        posterImg = [UIImage imageNamed:@"notAvailableSquared.png"];
    }
    
    if (posterImg.size.height < size.height && posterImg.size.width < size.width) {
        
        posterImg = [UIImage imageNamed:@"notAvailableSquared.png"];
        
//        snap = [[SWSnapshotStackView alloc] initWithFrame:CGRectMake(roundf(0.5 * (size.width - posterImg.size.width)),
//                                                                    roundf(0.5 * (size.height - posterImg.size.height)),
//                                                                    posterImg.size.width,
//                                                                    posterImg.size.height)];
        
//        NSLog(@"1: %f %f", posterImg.size.width, posterImg.size.height);
        
    }
    
//    else {
    
        snap = [[SWSnapshotStackView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        
//        NSLog(@"2: %f %f", posterImg.size.width, posterImg.size.height);
        
//    }
    
//    CGRect imageRrect = CGRectMake(0, 0, posterImg.size.width, posterImg.size.height);
//    UIGraphicsBeginImageContext(imageRrect.size); 
//    [posterImg drawInRect:CGRectMake(1, 1, posterImg.size.width-2, posterImg.size.height-2)];
//    posterImg = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
    
    [snap setImage:posterImg];
    [snap setDisplayAsStack:YES];
    
    [cell.contentView addSubview:snap];
    
    [snap release];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(-20, size.height+5, size.width + 40, 0)];
    
    NSString *nrOfPhotosStr = nil;
    
    NSInteger nrOfPhotos = [self numberOfPhotosInAssetsGroup:[self.currentData objectAtIndex:index]];
    
    if (nrOfPhotos != 1) {
        nrOfPhotosStr = @"photos";
    }
    else
       nrOfPhotosStr = @"photo"; 
    
    label.text = [NSString stringWithFormat:@"%@ (%i %@)", [[self.currentData objectAtIndex:index] valueForProperty:ALAssetsGroupPropertyName], nrOfPhotos, nrOfPhotosStr];
    label.textAlignment = UITextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor blackColor];
    label.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
    label.lineBreakMode = UILineBreakModeMiddleTruncation;
    label.numberOfLines = 0;
    
    CGSize sizeThatFits = [label sizeThatFits:label.frame.size];
    
    CGFloat lineHeight = label.font.leading;
    NSUInteger linesInLabel = floor(sizeThatFits.height/lineHeight);
    
    CGFloat height = (linesInLabel > 2 ? 2 : linesInLabel) * lineHeight;
    
    [label setFrame:CGRectMake(label.frame.origin.x, label.frame.origin.y, label.frame.size.width, height)];
    
    [cell.contentView addSubview:label];
    
    [label release];
    
//    if (nrOfPhotos == 0) {
//        
//        UIView *mask = [[UIView alloc] initWithFrame:view.frame];
//        mask.layer.cornerRadius = 8;
//        [mask setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.20]];
//        [view addSubview:mask];
//        [mask release];
//        label.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
//    }
    
    return cell;
}


- (BOOL)GMGridView:(GMGridView *)gridView canDeleteItemAtIndex:(NSInteger)index
{
    return YES; //index % 2 == 0;
}

//////////////////////////////////////////////////////////////
#pragma mark GMGridViewActionDelegate
//////////////////////////////////////////////////////////////

- (void)GMGridView:(GMGridView *)gridView didTapOnItemAtIndex:(NSInteger)position
{
    ALAssetsGroup * ass = [self.currentData objectAtIndex:position];
    [self getAssetsForGroup:ass];
}

- (void)GMGridView:(GMGridView *)gridView processDeleteActionForItemAtIndex:(NSInteger)index
{
    _lastDeleteItemIndexAsked = index;
    [self.currentData removeObjectAtIndex:_lastDeleteItemIndexAsked];
    [self.gmGridView removeObjectAtIndex:_lastDeleteItemIndexAsked withAnimation:GMGridViewItemAnimationFade];
}


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
