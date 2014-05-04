//
//  DocumentViewController.m
//  repWallet
//
//  Created by Alberto Fiore on 28/02/13.
//  Copyright (c) 2013 Alberto Fiore. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "RepWalletAppDelegate.h"
#import "GMGridView.h"
#import "DocFileBrowserItem.h"
#import "DocumentViewController.h"
#import "DocumentSelectionViewController.h"
#import "NSFileManager+DirectoryLocations.h"

@interface DocumentViewController ()<GMGridViewDataSource, GMGridViewSortingDelegate, GMGridViewActionDelegate, UINavigationControllerDelegate, DocumentSelectionViewControllerDelegate>
{
    NSInteger _lastDeleteItemIndexAsked;
    UIInterfaceOrientation lastOrientation;
    BOOL viewDidDisappear;
}

@property (nonatomic, retain) GMGridView *gmGridView;
@property (nonatomic, retain) NSMutableArray *currentData;
@property (nonatomic, retain) DocumentSelectionViewController *docSelVC;

@end

@implementation DocumentViewController

@synthesize currentData, gmGridView, delegate, docSelVC;

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
    
    if (self.docSelVC) {
        self.docSelVC.delegate = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.docSelVC release];
    [self.currentData release];
    [self.gmGridView release];
    [super dealloc];
}

#pragma mark - Toolbar

- (void) toggleEditingForGridView
{
    self.gmGridView.editing = !self.gmGridView.isEditing;
    [self.gmGridView layoutSubviewsWithAnimation:GMGridViewItemAnimationFade];
}

- (void) showSelectionViewController {
    DocumentSelectionViewController * docSelVC = [[DocumentSelectionViewController alloc] initWithDirPath:[[NSFileManager defaultManager] applicationDocumentsDirectory] actualDocumentsURLs:[NSMutableSet setWithArray:self.currentData] onlyOneToSelect:NO];
    [docSelVC browseForFileWithType:@"*"];
    self.docSelVC = docSelVC;
    [docSelVC release];
    self.docSelVC.delegate = self;
    [self.navigationController pushViewController:self.docSelVC animated:YES];
}

- (void) createToolbar {
    
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"change.png"] style:UIBarButtonItemStylePlain target:self action:@selector(toggleEditingForGridView)];
    
    UIBarButtonItem *item3 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"import.png"] style:UIBarButtonItemStylePlain target:self action:@selector(showSelectionViewController)];
    
    NSArray *items = [NSArray arrayWithObjects:item3, flexibleItem, item2, nil];
    
    [self setToolbarItems:items animated:YES];
    
    [flexibleItem release];
    
    [item2 release];
    
    [item3 release];
    
}

#pragma mark - DocumentSelectionViewController delegate

-(void)documentSelectionControllerSelectedDocumentWithURL:(NSURL *)docURL {
    
    [self.currentData addObject:docURL];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(documentViewControllerAddedDocumentWithURL:)]) {
        [self.delegate documentViewControllerAddedDocumentWithURL:docURL];
    }
}

-(void)documentSelectionControllerUnselectedDocumentWithURL:(NSURL *)docURL {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(documentViewControllerRemovedDocumentWithURL:)]) {
        [self.delegate documentViewControllerRemovedDocumentWithURL:docURL];
    }
    
    [self.currentData removeObject:docURL];

}

#pragma mark - initialization

- (id)initWithDocumentsURLs:(NSArray *)documentsURLs
{
    if ((self = [super init]))
    {
        self.title = @"Imported Documents";
        self.navigationController.toolbarHidden = NO;
        self.navigationController.toolbar.translucent = NO;
        
        self.currentData = documentsURLs;
        
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
    
    [self createToolbar];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSInteger spacing = ![(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad] ? 60 : 60;
    
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

-(void) getBack {
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else if ([self respondsToSelector:@selector(dismissModalViewControllerAnimated:)]) {
        [self dismissModalViewControllerAnimated:YES];
    }
}

- (void) undoModifications {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(documentViewControllerCanceled)]) {
        [self.delegate documentViewControllerCanceled];
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
}

- (void)viewDidUnload
{
    if (self.docSelVC) {
        self.docSelVC.delegate = nil;
    }
    
    self.docSelVC = nil;
    
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
    
    [self.navigationController setToolbarHidden:NO animated:animated];
}

- (void) viewControllerWillBePopped {
    
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
            return CGSizeMake(64, 64);
        }
        else
        {
            return CGSizeMake(64, 64);
        }
    }
    else
    {
        if (UIInterfaceOrientationIsLandscape(orientation))
        {
            return CGSizeMake(64, 64);
        }
        else
        {
            return CGSizeMake(64, 64);
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
    
    NSURL *url = [self.currentData objectAtIndex:index];
    
    UIImage *img = [UIImage imageNamed:@"docIconBig.png"];
    
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0,
                                                                         0,
                                                                         img.size.width,
                                                                         img.size.height)];
    
//    CGRect imageRrect = CGRectMake(0, 0, img.size.width, img.size.height);
//    UIGraphicsBeginImageContext(imageRrect.size);
//    [img drawInRect:CGRectMake(1, 1, img.size.width-2, img.size.height-2)];
//    img = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
    
    [imgView setImage:img];
    
    [cell.contentView addSubview:imgView];
    
    [imgView release];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(-20, size.height + 10, size.width + 40, 0)];
    NSString *urlStr = [url absoluteString];
    NSRange range = [urlStr rangeOfString:@"/" options:NSBackwardsSearch];
    label.text = [urlStr substringFromIndex:range.location+1];
    label.textAlignment = UITextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor blackColor];
    label.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]+2];
    label.lineBreakMode = UILineBreakModeMiddleTruncation;
    label.numberOfLines = 0;
    
    CGSize sizeThatFits = [label sizeThatFits:label.frame.size];
    
    CGFloat lineHeight = label.font.leading;
    NSUInteger linesInLabel = floor(sizeThatFits.height/lineHeight);
    
    CGFloat height = (linesInLabel > 2 ? 2 : linesInLabel) * lineHeight;
    
    [label setFrame:CGRectMake(label.frame.origin.x, label.frame.origin.y, label.frame.size.width, height)];
    
    [cell.contentView addSubview:label];
    
    [label release];
    
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
    // mostra la preview
    
    QLPreviewController *previewer = [[QLPreviewController alloc] init];
    
    // Set data source
    [previewer setDataSource:self];
    
    // Which item to preview
    [previewer setCurrentPreviewItemIndex:position];
    
    // Push new viewcontroller, previewing the document
    [[self navigationController] pushViewController:previewer animated:YES];
    
    [previewer release];
}

- (void)GMGridView:(GMGridView *)gridView processDeleteActionForItemAtIndex:(NSInteger)index
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(documentViewControllerRemovedDocumentWithURL:)]) {
        [self.delegate documentViewControllerRemovedDocumentWithURL:[self.currentData objectAtIndex:index]];
    }
    
    _lastDeleteItemIndexAsked = index;
    [self.currentData removeObjectAtIndex:_lastDeleteItemIndexAsked];
    [self.gmGridView removeObjectAtIndex:_lastDeleteItemIndexAsked withAnimation:GMGridViewItemAnimationFade];
}

/*---------------------------------------------------------------------------
 *
 *--------------------------------------------------------------------------*/
- (NSInteger) numberOfPreviewItemsInPreviewController: (QLPreviewController *) controller
{
	return self.currentData.count;
}

/*---------------------------------------------------------------------------
 *
 *--------------------------------------------------------------------------*/
- (id <QLPreviewItem>)previewController: (QLPreviewController *)controller previewItemAtIndex:(NSInteger)index
{
    NSURL *url = [self.currentData objectAtIndex:index];
    return url;
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