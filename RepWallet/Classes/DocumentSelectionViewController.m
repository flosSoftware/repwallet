//
//  DocumentSelectionViewController.h
//  repWallet
//
//  Created by Alberto Fiore on 27/02/13.
//  Copyright (c) 2013 Alberto Fiore. All rights reserved.
//


#import <QuartzCore/QuartzCore.h>
#import "DocumentSelectionViewController.h"
#import "RepWalletAppDelegate.h"
#import "GMGridView.h"
#import "DocFileBrowserItem.h"
#import "UIViewController+Utils.h"
#import <FPPicker/FPPicker.h>
#import "NSFileManager+DirectoryLocations.h"
#import "NSFileManager+Utils.h"

#define LABEL_TAG 1001

@interface DocumentSelectionViewController () <GMGridViewDataSource, GMGridViewSortingDelegate, GMGridViewActionDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, FPPickerDelegate, FPSaveDelegate>
{
    NSInteger _lastDeleteItemIndexAsked;
    BOOL selectionModeIsOn;
    UIInterfaceOrientation lastOrientation;
    BOOL viewDidDisappear;
    NSInteger currentItemIndex;
    BOOL isMovingTheFile;
}

@property (nonatomic, retain) GMGridView *gmGridView;
@property (nonatomic, retain) NSMutableSet *selectedCellURLs;
@property (nonatomic, retain) NSMutableSet *actualDocumentsURLs;
@property (nonatomic, retain) NSMutableArray *currentData;
@property (nonatomic, retain) NSMutableArray *paths;
@property (nonatomic, retain) NSString *currentPath;
@property (nonatomic, retain) NSString *startPath;
@property (nonatomic, retain) NSString *fileTypeToUse;
@property (nonatomic, retain) NSArray *fileTypes;
@property (nonatomic, retain) UIBarButtonItem *backBtn;
@property (nonatomic, retain) UIBarButtonItem *pasteBtn;
@property (nonatomic, retain) UITextField *inputField;
@property (nonatomic, retain) DocFileBrowserItem *copiedItem;
@property (nonatomic, assign) BOOL onlyOneToSelect;
@property (nonatomic, retain) DocFileBrowserItem *movingItem;
@property (nonatomic, retain) DocFileBrowserItem *destinationFolder;

- (void)copyTheStuff:(DocFileBrowserItem *)itemToCopy;
- (void)pasteTheStuff;
- (void)nuFolder;
- (void)back;
- (void)resetPath;
- (void)refreshView;
- (void)openFolderNamed:(NSString*)folderName;
- (BOOL)fileShouldBeHidden:(NSString*)fileName;
- (void)loadFileFromDisk:(DocFileBrowserItem *)item;
- (BOOL)folder:(DocFileBrowserItem *)folder containsItem:(DocFileBrowserItem *)item;
- (void) showFilePickerIOInput;
- (void) showFileSaveDialog:(DocFileBrowserItem *)item;

@end

@implementation DocumentSelectionViewController

@synthesize currentData, gmGridView, delegate, selectedCellURLs, actualDocumentsURLs, paths, currentPath, startPath, fileTypeToUse, fileTypes, backBtn, inputField, pasteBtn, copiedItem, onlyOneToSelect, movingItem, destinationFolder;

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
    [self.movingItem release];
    [self.destinationFolder release];
    [self.copiedItem release];
    [self.pasteBtn release];
    [self.inputField release];
    [self.backBtn release];
    [self.actualDocumentsURLs release];
    [self.fileTypes release];
    [self.fileTypeToUse release];
    [self.startPath release];
    [self.paths release];
    [self.currentPath release];
    [self.selectedCellURLs release];
    [self.currentData release];
    [self.gmGridView release];
    [super dealloc];
}

#pragma mark - Toolbar

- (void) switchSelectionMode {
    
    selectionModeIsOn = !selectionModeIsOn;
    
    if ([self.navigationItem.rightBarButtonItem.title isEqualToString:@"Select"]) {
        self.navigationItem.rightBarButtonItem.title = @"Done";
    } else
        self.navigationItem.rightBarButtonItem.title = @"Select";
    
}

- (void) createToolbar {
    
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back.png"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    
    item.enabled = NO;
    
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"paste.png"] style:UIBarButtonItemStylePlain target:self action:@selector(pasteTheStuff)];
    
    item2.enabled = NO;
    
    UIBarButtonItem *item3 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(nuFolder)];
    
    UIBarButtonItem *item4 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"cloud.png"] style:UIBarButtonItemStylePlain target:self action:@selector(showFilePickerIOInput)];
    
    NSArray *items = [NSArray arrayWithObjects:item, flexibleItem, item2, flexibleItem, item3, flexibleItem, item4, nil];
    
    [self setToolbarItems:items animated:YES];
    
    [flexibleItem release];
    
    self.backBtn = item;
    
    self.pasteBtn = item2;
    
    [item release];
    
    [item2 release];
    
    [item3 release];
    
    [item4 release];
    
}

#pragma mark - FilePickerIO

- (void) showFileSaveDialog:(DocFileBrowserItem *)item {
    
    // To create the object
    FPSaveController *fpSave = [[FPSaveController alloc] init];
    
    // Set the delegate
    fpSave.fpdelegate = self;
    
    // Set the data and data type to be saved.
    NSData *data = [[NSData alloc] initWithContentsOfFile:item.path];
    fpSave.data = data;
    [data release];
    fpSave.dataType = [NSFileManager mimeTypeForFileAtPath:item.path];
    
    //optional: propose the default file name
    fpSave.proposedFilename = [item.fileTitle stringByDeletingPathExtension];
    
    // Display it.
    if ([self respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        
        [self presentViewController:fpSave animated:YES completion:NULL];
        
    } else if([self respondsToSelector:@selector(presentModalViewController:animated:)]) {
        
        [self presentModalViewController:fpSave animated:YES];
        
    }
    
    [fpSave release];
    
}

-(void)FPSaveControllerDidCancel:(FPSaveController *)picker {
    
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else if ([self respondsToSelector:@selector(dismissModalViewControllerAnimated:)]) {
        [self dismissModalViewControllerAnimated:YES];
    }
}

-(void)FPSaveControllerDidSave:(FPSaveController *)picker {

}

-(void)FPSaveController:(FPSaveController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else if ([self respondsToSelector:@selector(dismissModalViewControllerAnimated:)]) {
        [self dismissModalViewControllerAnimated:YES];
    }
}

-(void)FPSaveController:(FPSaveController *)picker didError:(NSDictionary *)info {

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was a problem while importing the file." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alertView show];
    [alertView release];
    
}

- (void) showFilePickerIOInput {
    
    // To create the object
    FPPickerController *fpController = [[FPPickerController alloc] init];
    
    fpController.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
    
    // Set the delegate
    fpController.fpdelegate = self;
    
    NSMutableArray * arr = [NSMutableArray array];
    
    // Ask for specific data types. (Optional) Default is all files.
    for (NSString *type in self.fileTypes) {
        
//        if ([type isEqualToString:@"csv"]) {
//            [arr addObject:@"text/csv"];
//        }
        
        if (![type isEqualToString:@"*"]) {
            [arr addObject:[NSFileManager mimeTypeForPathExtension:type]];
        }

    }
    
    if (arr.count > 0) {
        fpController.dataTypes = arr;
    }
    
    // Select and order the sources (Optional) Default is all sources
    fpController.sourceNames = [NSArray arrayWithObjects: FPSourceBox, FPSourceDropbox, FPSourceFacebook, FPSourceFlickr, FPSourceGithub, FPSourceGmail, FPSourceGoogleDrive, FPSourceImagesearch, FPSourceInstagram, FPSourcePicasa, nil];
    
    // You can set some of the in built Camera properties as you would with UIImagePicker
    fpController.allowsEditing = NO;
    
    
    /* Control if we should upload or download the files for you.
     * Default is yes.
     * When a user selects a local file, we'll upload it and return a remote url
     * When a user selects a remote file, we'll download it and return the filedata to you.
     */
    //fpController.shouldUpload = NO;
    //fpController.shouldDownload = NO;
    
    // Display it.
    if ([self respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        
        [self presentViewController:fpController animated:YES completion:NULL];
        
    } else if([self respondsToSelector:@selector(presentModalViewController:animated:)]) {
        
        [self presentModalViewController:fpController animated:YES];
        
    }
    
    [fpController release];
    
}

-(void)FPPickerController:(FPPickerController *)picker didPickMediaWithInfo:(NSDictionary *)info {
//    NSLog(@"picked media with info %@", info);
    
}

-(void)FPPickerController:(FPPickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
   NSFileManager *man = [NSFileManager defaultManager];
    
//    NSLog(@"finished picking media with info %@", info);

    NSError *err = nil;
    
    NSURL *from = [info objectForKey:@"FPPickerControllerMediaURL"];
    
    NSString *str = [[info objectForKey:@"FPPickerControllerFilename"] stringByDeletingPathExtension];
    
    NSDirectoryEnumerator *dirEnum = [man enumeratorAtPath:self.currentPath];
    
    NSString *file;
    
    NSString *regEx = [NSString stringWithFormat:@"%@ ([0-9]+)", str];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regEx options:NSRegularExpressionCaseInsensitive error:NULL];
    
    BOOL foundPattern = NO;
    
    NSInteger maxNr = -1;
    
    while (file = [dirEnum nextObject]) {
        
        if ([[[dirEnum fileAttributes] objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory]) {
            
            [dirEnum skipDescendants];
            
            continue;
        }
        
        file = [file stringByDeletingPathExtension];
        
        if([file hasPrefix:str])
        {
            if ([file isEqualToString:str]) {
                
                if(maxNr == -1)
                    maxNr = 1;
                
            } else {
                
                NSTextCheckingResult *match = [regex firstMatchInString:file options:0 range:NSMakeRange(0, [file length])];
                if (match && NSEqualRanges(NSMakeRange(0, [file length]), match.range)) {
                    
                    // full match, get the number
                    NSInteger i = [[file substringWithRange:[match rangeAtIndex:1]] integerValue];
                    
                    if ((foundPattern && maxNr < i)
                        || !foundPattern) {
                        maxNr = i;
                    }
                    
                    foundPattern = YES;
                }
            }
        }
    }
    
    NSString *aho = [[NSString stringWithFormat:@"%@%@", str,
                maxNr != -1 ? [NSString stringWithFormat:@" %i", maxNr+1] : @""] stringByAppendingPathExtension:[[info objectForKey:@"FPPickerControllerFilename"] pathExtension]];
    
    NSURL *to = [NSURL fileURLWithPath:[[man applicationDocumentsDirectory] stringByAppendingPathComponent:aho] isDirectory:NO];
    
//    NSLog(@"to: %@", [to absoluteString]);
    
    [man copyItemAtURL:from toURL:to error:&err];
    
    if (err) {
        
        NSString * errorDesc = [err localizedDescription] ? [err localizedDescription] : @"";
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while importing the file. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
    }
    
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else if ([self respondsToSelector:@selector(dismissModalViewControllerAnimated:)]) {
        [self dismissModalViewControllerAnimated:YES];
    }
    
    [self refreshView];
}

-(void)FPPickerControllerDidCancel:(FPPickerController *)picker {
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else if ([self respondsToSelector:@selector(dismissModalViewControllerAnimated:)]) {
        [self dismissModalViewControllerAnimated:YES];
    }
}

#pragma mark - initialization

- (id)initWithDirPath:(NSString *)dirPath actualDocumentsURLs:(NSMutableSet *)actualDocumentsURLs onlyOneToSelect:(BOOL)onlyOneToSelect
{
    if ((self = [super init]))
    {
        self.navigationController.toolbarHidden = NO;
        self.navigationController.toolbar.translucent = NO;
        
        self.onlyOneToSelect = onlyOneToSelect;
        
        if (!self.onlyOneToSelect) {
            UIBarButtonItem *selectButton = [[UIBarButtonItem alloc] initWithTitle:@"Select" style:UIBarButtonItemStyleBordered target:self action:@selector(switchSelectionMode)];
            
            self.navigationItem.rightBarButtonItem = selectButton;
            
            [selectButton release];
        }

        self.startPath = dirPath;
        
        self.selectedCellURLs = [NSMutableSet set];
        
        self.actualDocumentsURLs = actualDocumentsURLs;
        
        self.currentData = [NSMutableArray array];
        
        self.paths = [NSMutableArray array];
        
        selectionModeIsOn = NO;
        
        viewDidDisappear = NO;
        
        isMovingTheFile = NO;
        
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.gmGridView.mainSuperView = self.navigationController.view;

    [self resetPath];
}

- (void)viewDidUnload
{
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

#pragma mark - file browser

- (void)resetPath
{
	[self.paths removeAllObjects];
	NSString *dirPath = [self.startPath stringByAppendingString:@"/"];
//    NSLog(@"reset path to dirPath: %@", dirPath);
	[self.paths addObject:dirPath];
	[self refreshView];
}

- (void)refreshView
{
	int fileCount = 0;
    
    [self.currentData removeAllObjects];
    
	self.currentPath = @"";
    
	for (NSString *path in self.paths) {
		self.currentPath = [self.currentPath stringByAppendingString:path];
	}
    
	// populate data
	NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.currentPath error:NULL];
    
//    NSLog(@"files at current path %@", files);
    
	NSString *currFile;
	BOOL isDir;
    
	for(NSString *file in files) {
        
		currFile = [self.currentPath stringByAppendingString:file];

		[[NSFileManager defaultManager] fileExistsAtPath:currFile isDirectory:&isDir];
		
        if(![self fileShouldBeHidden:file]) {
            
			NSString *ext = [currFile pathExtension];
			BOOL isFileType = false;
            
			for(NSString *ft in self.fileTypes) {
                
				if([ft isEqualToString:ext] || [ft isEqualToString:@"*"]) {
					isFileType = true;
				}
			}
            
			// check the file extension
			DocFileBrowserItem *item = [DocFileBrowserItem itemWithTitle:file andPath:currFile isDirectory:isDir];
            
			if(!isDir) {
				item.isSelectable = isFileType;
			}
            
			[self.currentData addObject:item];
			fileCount ++;
		}
	}
    
    for (int i = 0; i < self.currentData.count; i++) {
        
        NSURL * docURL = [NSURL fileURLWithPath:[[self.currentData objectAtIndex:i] path]
                                    isDirectory:[[self.currentData objectAtIndex:i] isDirectory]];

        if ([self.actualDocumentsURLs containsObject:docURL]) {
            [self.selectedCellURLs addObject:docURL];
        }
    }
	
	if(self.paths.count <= 1) {
        
        NSRange range = [self.startPath rangeOfString:@"/" options:NSBackwardsSearch];
        self.title = [self.startPath substringFromIndex:range.location+1];
        
	} else {
        
		self.title = [[self.paths lastObject] stringByDeletingPathExtension];
	}
//    
//    self.title = [NSString stringWithFormat:@"Folder '%@'", self.title];
	
	[self.gmGridView reloadData];
}

- (BOOL)fileShouldBeHidden:(NSString*)fileName {
	int max = 1;
	NSRange range = NSMakeRange(0, max);
	if(max <= [fileName length]){
		if([[fileName substringWithRange:range] isEqualToString:@"."]){
			return YES;
		}
	}
	max = 2;
	if(max <= [fileName length]){
		range = NSMakeRange(0, max);
		if([[fileName substringWithRange:range] isEqualToString:@"__"]){
			return YES;
		}
	}
	max = 3;
	if(max <= [fileName length]){
		range = NSMakeRange(0, max);
		if([[fileName substringWithRange:range] isEqualToString:@"tmp"]){
			return YES;
		}
	}
	return NO;
}

- (void)browseForFileWithType:(NSString*)fileType {
    
	self.fileTypeToUse = fileType;
	self.fileTypes = [NSArray arrayWithObject:fileType];
	[self resetPath];
}

- (void)browseForFileWithTypes:(NSArray*)ft {
    
	self.fileTypes = ft;
	[self resetPath];
}

- (void)openFolderNamed:(NSString*)folderName {
    
    if (self.copiedItem) {
        
        self.pasteBtn.enabled = YES;
        
    } else {
        
        self.pasteBtn.enabled = NO;
        
        self.copiedItem = nil;
        
    }
    
    self.backBtn.enabled = YES;
    
	NSString *newDir = [folderName stringByAppendingString:@"/"];
    
	[self.paths addObject:newDir];
    
	self.currentPath = @"";
    
	for (NSString *path in self.paths) {
		self.currentPath = [self.currentPath stringByAppendingString:path];
	}
    
	[self refreshView];
}

- (void)back {
    
	if(self.paths.count <= 1) {
        return;
    }
    
    if (self.copiedItem) {
        
        self.pasteBtn.enabled = YES;
        
    } else {
        
        self.pasteBtn.enabled = NO;
        
        self.copiedItem = nil;
        
    }
    
	[self.paths removeLastObject];
    
    if(self.paths.count <= 1) {
        self.backBtn.enabled = NO;
    }
    
	for (NSString *path in self.paths) {
		self.currentPath = [self.currentPath stringByAppendingString:path];
	}
    
	[self refreshView];
}

-(void)renameItem:(DocFileBrowserItem *)item to:(NSString *)newItemName {
    
    NSString *newPath = nil;
    
    if (item.isDirectory) {
        
        newPath = [[item.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:newItemName];
        
    } else {
        
        newPath = [[[item.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:newItemName] stringByAppendingPathExtension:[item.path pathExtension]];
        
    }
    
    if ([item.path isEqualToString:newPath]) {
        
        return;
        
    }
    
    NSError *err = nil;
    
    [[NSFileManager defaultManager] moveItemAtPath:item.path toPath:newPath error:&err];
    
    if (err) {
        
        NSString * errorDesc = [err localizedDescription] ? [err localizedDescription] : @"";
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while moving the file. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        return;
    }
    
    // aggiorno l'url nel caso di file che erano selezionati
    
    NSURL *url = [NSURL fileURLWithPath:item.path isDirectory:item.isDirectory];
    
    NSURL *url2 = [NSURL fileURLWithPath:newPath isDirectory:item.isDirectory];
    
    if ([self.selectedCellURLs containsObject:url]) {
        
        if (self.delegate
            && [self.delegate respondsToSelector:@selector(documentSelectionControllerUnselectedDocumentWithURL:)]) {
            
            [self.delegate documentSelectionControllerUnselectedDocumentWithURL:url];
        }
        
        [self.selectedCellURLs removeObject:url];
        
        [self.selectedCellURLs addObject:url2];
        
        if (self.delegate
            && [self.delegate respondsToSelector:@selector(documentSelectionControllerSelectedDocumentWithURL:)]) {
            
            [self.delegate documentSelectionControllerSelectedDocumentWithURL:url2];
        }
    }
    
    if (self.copiedItem && [self.copiedItem.path isEqualToString:item.path]) {
        
        self.pasteBtn.enabled = NO;
        
        self.copiedItem = nil;
        
    }
    
    [self refreshView];
    
}

-(void)nuFolder {
    
    NSFileManager *man = [NSFileManager defaultManager];
    
    NSDirectoryEnumerator *dirEnum = [man enumeratorAtPath:self.currentPath];
    
    NSString *file;
    
    NSString *regEx = @"new folder ([0-9]+)";
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regEx options:NSRegularExpressionCaseInsensitive error:NULL];
    
    BOOL foundPattern = NO;
    
    BOOL foundPrefix = NO;
    
    NSInteger maxNr;
    
    while (file = [dirEnum nextObject]) {
        
//        NSLog(@"file %@", file);

        if([[[dirEnum fileAttributes] objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory]
           && [file hasPrefix:@"new folder"]
           ){
            
            foundPrefix = YES;
            
            NSTextCheckingResult *match = [regex firstMatchInString:file options:0 range:NSMakeRange(0, [file length])];
            if (match && NSEqualRanges(NSMakeRange(0, [file length]), match.range)) {
                
                // full match, get the number
                NSInteger i = [[file substringWithRange:[match rangeAtIndex:1]] integerValue];
                
                if ((foundPattern && maxNr < i)
                    || !foundPattern) {
                    maxNr = i;
                }
                
                foundPattern = YES;
            }

            [dirEnum skipDescendants];
        }
    }
    
    [man createDirectoryAtPath:
     [self.currentPath stringByAppendingPathComponent:
      [NSString stringWithFormat:@"new folder%@",
       foundPattern ? [NSString stringWithFormat:@" %i", maxNr+1] : foundPrefix ? @" 2" : @""]]
                          withIntermediateDirectories:YES attributes:nil error:nil];
    
    [self refreshView];
}

- (void) copyTheStuff:(DocFileBrowserItem *)itemToCopy {
    
    self.copiedItem = itemToCopy;
    
    self.pasteBtn.enabled = YES;
}

- (void) pasteTheStuff {
    
    NSFileManager *man = [NSFileManager defaultManager];
    
    NSString *str = [NSString stringWithFormat:@"%@ copy", [self.copiedItem.fileTitle stringByDeletingPathExtension]];
    
    NSDirectoryEnumerator *dirEnum = [man enumeratorAtPath:self.currentPath];
    
    NSString *file;
    
    NSString *regEx = [NSString stringWithFormat:@"%@ ([0-9]+)", str];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regEx options:NSRegularExpressionCaseInsensitive error:NULL];
    
    BOOL foundPattern = NO;
    
    NSInteger maxNr = -1;
    
    while (file = [dirEnum nextObject]) {
        
        if ([[[dirEnum fileAttributes] objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory]) {
            [dirEnum skipDescendants];
        }
        
        if (([[[dirEnum fileAttributes] objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory]
            && !self.copiedItem.isDirectory)
            || (![[[dirEnum fileAttributes] objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory]
                && self.copiedItem.isDirectory)) {
                
            continue;
        }
        
        file = [file stringByDeletingPathExtension];
        
        if([file hasPrefix:str])
        {
            if ([file isEqualToString:str]) {
                
                if(maxNr == -1)
                    maxNr = 1;
                
            } else {
                
                NSTextCheckingResult *match = [regex firstMatchInString:file options:0 range:NSMakeRange(0, [file length])];
                if (match && NSEqualRanges(NSMakeRange(0, [file length]), match.range)) {
                    
                    // full match, get the number
                    NSInteger i = [[file substringWithRange:[match rangeAtIndex:1]] integerValue];
                    
                    if ((foundPattern && maxNr < i)
                        || !foundPattern) {
                        maxNr = i;
                    }
                    
                    foundPattern = YES;
                }
            }
        }
    }

    NSString *aho = nil;
    
    if (self.copiedItem.isDirectory) {
        
        aho = [NSString stringWithFormat:@"%@%@", str,
                maxNr != -1 ? [NSString stringWithFormat:@" %i", maxNr+1] : @""];
    } else {
        
        aho = [[NSString stringWithFormat:@"%@%@", str,
                maxNr != -1 ? [NSString stringWithFormat:@" %i", maxNr+1] : @""] stringByAppendingPathExtension:[self.copiedItem.fileTitle pathExtension]];
    }
    
    NSError *err = nil;
        
    [[NSFileManager defaultManager] copyItemAtPath:copiedItem.path toPath:[self.currentPath stringByAppendingPathComponent:aho] error:&err];
    
    if (err) {
        
        NSString * errorDesc = [err localizedDescription] ? [err localizedDescription] : @"";
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while moving the file. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        return;
    }
    
    [self refreshView];
}

- (void)loadFileFromDisk:(DocFileBrowserItem *)item {
    
	NSURL *url = [NSURL fileURLWithPath:item.path isDirectory:item.isDirectory];
    
	if (self.delegate
        && [self.delegate respondsToSelector:@selector(documentSelectionControllerSelectedDocumentWithURL:)]) {
        
        [self.delegate documentSelectionControllerSelectedDocumentWithURL:url];
    }
    
	[self.navigationController popViewControllerAnimated:YES];
}

-(BOOL)folder:(DocFileBrowserItem *)folder containsItem:(DocFileBrowserItem *)item {
    
    if ([item.path rangeOfString:folder.path].location == NSNotFound) {
        return NO;
    }
    
    return YES;
    
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
    
    DocFileBrowserItem * item = [self.currentData objectAtIndex:index];
    
    UIImage *img = nil;
    
    if (item.isDirectory) {
        
        img = [UIImage imageNamed:@"folderIconBig.png"];
        
        
    } else {
        
        img = [UIImage imageNamed:@"docIconBig.png"];
        
    }
    
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0,
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
    label.tag = LABEL_TAG;
    label.text = item.fileTitle;
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
    
    if ([self.selectedCellURLs containsObject:[NSURL fileURLWithPath:item.path isDirectory:item.isDirectory]]) {
        
        UIView *mask = [[UIView alloc] initWithFrame:imgView.frame];
        [mask setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.35]];
        [cell.contentView addSubview:mask];
        [mask release];
        
        UIImageView *imV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tick_mark"]];
        imV.frame = CGRectMake(imgView.frame.size.width - 40, imgView.frame.size.height - 40, imV.frame.size.width, imV.frame.size.height);
        [cell.contentView addSubview:imV];
        [imV release];
    }
    
    if (!item.isSelectable) {
        UIView *mask = [[UIView alloc] initWithFrame:imgView.frame];
        [mask setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.35]];
        [cell.contentView addSubview:mask];
        [mask release];

    }
    
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

-(void)GMGridView:(GMGridView *)gridView didDoubleTapOnItemAtIndex:(NSInteger)position
{
    DocFileBrowserItem *item = [self.currentData objectAtIndex:position];
    
    NSURL * url = [NSURL fileURLWithPath:item.path isDirectory:item.isDirectory];
    
    if (!item.isSelectable) {
        
        return;
        
    } else if (item.isDirectory) {
        
        [self openFolderNamed:item.fileTitle];
        
        
    } else if (selectionModeIsOn && ![self.selectedCellURLs containsObject:url]) {
        
        [self.selectedCellURLs addObject:url];
        
        [self.gmGridView reloadData];
        
        if (self.delegate
            && [self.delegate respondsToSelector:@selector(documentSelectionControllerSelectedDocumentWithURL:)]) {
            
            [self.delegate documentSelectionControllerSelectedDocumentWithURL:url];
        }
        
    } else if (selectionModeIsOn && [self.selectedCellURLs containsObject:url]) {
        
        if (self.delegate
            && [self.delegate respondsToSelector:@selector(documentSelectionControllerUnselectedDocumentWithURL:)]) {
            
            [self.delegate documentSelectionControllerUnselectedDocumentWithURL:url];
        }
        
        [self.selectedCellURLs removeObject:url];
        
        [self.gmGridView reloadData];
        
    } else {
        
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
}

- (void)GMGridView:(GMGridView *)gridView didTapOnItemAtIndex:(NSInteger)position
{
    DocFileBrowserItem *item = [self.currentData objectAtIndex:position];
    
    NSURL * url = [NSURL fileURLWithPath:item.path isDirectory:item.isDirectory];
    
    if (!item.isSelectable) {
        
        return;
        
    } else if (item.isDirectory) {
        
        RepWalletAppDelegate *appDelegate = (RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        currentItemIndex = position;
        
        UIActionSheet *a = [[UIActionSheet alloc] initWithTitle:@"Choose an action" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        [a addButtonWithTitle:@"Open"];
        [a addButtonWithTitle:@"Copy"];
        [a addButtonWithTitle:@"Rename"];
        [a addButtonWithTitle:@"Delete"];
        [a addButtonWithTitle:@"Export in the Cloud"];
        [a addButtonWithTitle:@"Cancel"];
        
        a.cancelButtonIndex = 5;
        
        [a setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
        
        if ([appDelegate isIpad]) {
            
            GMGridViewCell *cell = [self.gmGridView cellForItemAtIndex:currentItemIndex];
            
            UILabel *label = (UILabel *)[cell.contentView viewWithTag:LABEL_TAG];
            
            CGRect popoverRect = [[self view] convertRect:[label frame]
                                                 fromView:[label superview]];
            
            [a showFromRect:popoverRect inView:self.view animated:YES];
            
        } else {
            
            [a showFromToolbar:self.navigationController.toolbar];
        }
        
        [a release];
        
        
    } else if (selectionModeIsOn && ![self.selectedCellURLs containsObject:url]) {
        
        [self.selectedCellURLs addObject:url];
        
        [self.gmGridView reloadData];
        
        if (self.delegate
            && [self.delegate respondsToSelector:@selector(documentSelectionControllerSelectedDocumentWithURL:)]) {
            
            [self.delegate documentSelectionControllerSelectedDocumentWithURL:url];
        }
        
    } else if (selectionModeIsOn && [self.selectedCellURLs containsObject:url]) {
        
        if (self.delegate
            && [self.delegate respondsToSelector:@selector(documentSelectionControllerUnselectedDocumentWithURL:)]) {
            
            [self.delegate documentSelectionControllerUnselectedDocumentWithURL:url];
        }
        
        [self.selectedCellURLs removeObject:url];
        
        [self.gmGridView reloadData];
        
    } else {
        
        RepWalletAppDelegate *appDelegate = (RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        currentItemIndex = position;
        
        UIActionSheet *a = [[UIActionSheet alloc] initWithTitle:@"Choose an action" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        int c = 0;
        if (self.onlyOneToSelect) {
            [a addButtonWithTitle:@"Select"];
            c++;
        }
        [a addButtonWithTitle:@"Preview"];
        c++;
        [a addButtonWithTitle:@"Copy"];
        c++;
        [a addButtonWithTitle:@"Rename"];
        c++;
        [a addButtonWithTitle:@"Delete"];
        c++;
        [a addButtonWithTitle:@"Export in the Cloud"];
        c++;
        [a addButtonWithTitle:@"Cancel"];
        
        a.cancelButtonIndex = c;
        
        [a setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
        
        if ([appDelegate isIpad]) {
            
            GMGridViewCell *cell = [self.gmGridView cellForItemAtIndex:currentItemIndex];
            
            UILabel *label = (UILabel *)[cell.contentView viewWithTag:LABEL_TAG];
            
            CGRect popoverRect = [[self view] convertRect:[label frame]
                                                 fromView:[label superview]];
            
            [a showFromRect:popoverRect inView:self.view animated:YES];
            
        } else {
            
            [a showFromToolbar:self.navigationController.toolbar];
        }
        
        [a release];

    }
}

- (void)GMGridView:(GMGridView *)gridView processDeleteActionForItemAtIndex:(NSInteger)index
{
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
    DocFileBrowserItem *item = [self.currentData objectAtIndex:index];
	NSURL *url = [NSURL fileURLWithPath:item.path isDirectory:item.isDirectory];
    
    return url;
}

#pragma mark -
#pragma mark Action sheet


-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Rename"]) {
        
        DocFileBrowserItem *item = [self.currentData objectAtIndex:currentItemIndex];
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Rename" message:@"\n\n\n" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        UITextField *textField;
        textField = [[UITextField alloc] init];
        [textField setBackgroundColor:[UIColor whiteColor]];
        textField.borderStyle = UITextBorderStyleLine;
        textField.frame = CGRectMake(15, 60, 255, 30);
        textField.placeholder = [item.fileTitle stringByDeletingPathExtension];
        textField.textAlignment = UITextAlignmentCenter;
        [textField becomeFirstResponder];
        self.inputField = textField;
        [textField release];
        [alert addSubview:self.inputField];
        [alert show];
        
        [alert release];
        
        if (self.copiedItem) {
            
            if([self.copiedItem.path isEqualToString:item.path]
               || (item.isDirectory && [self folder:item containsItem:self.copiedItem])) {
                
                self.pasteBtn.enabled = NO;
                
                self.copiedItem = nil;
                
            }
        }
        
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Preview"]) {
        
        // mostra la preview
        
        QLPreviewController *previewer = [[QLPreviewController alloc] init];
        
        // Set data source
        [previewer setDataSource:self];
        
        // Which item to preview
        [previewer setCurrentPreviewItemIndex:currentItemIndex];
        
        // Push new viewcontroller, previewing the document
        [[self navigationController] pushViewController:previewer animated:YES];
        
        [previewer release];
        
    } else if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Open"]) {
        
        DocFileBrowserItem *item = [self.currentData objectAtIndex:currentItemIndex];
        [self openFolderNamed:item.fileTitle];
        
    }  else if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Delete"]) {
        
        DocFileBrowserItem *item = [self.currentData objectAtIndex:currentItemIndex];
        
        NSError *err = nil;
        
        [[NSFileManager defaultManager] removeItemAtPath:item.path error:&err];
        
        if (err) {
            
            NSString * errorDesc = [err localizedDescription] ? [err localizedDescription] : @"";
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while deleting the file. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
            [alertView release];
            return;
        }
        
        // aggiorno l'url nel caso di file che erano selezionati
        
        NSURL *url = [NSURL fileURLWithPath:item.path isDirectory:item.isDirectory];
        
        if ([self.selectedCellURLs containsObject:url]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(documentSelectionControllerUnselectedDocumentWithURL:)]) {
                
                [self.delegate documentSelectionControllerUnselectedDocumentWithURL:url];
            }
            
            [self.selectedCellURLs removeObject:url];
  
        }
        
        if (item.isDirectory) {
            
            for (NSURL *url in self.selectedCellURLs) {
                
                NSString *selPath = [url path];
                NSString *foldPath = item.path;
                
                if ([selPath rangeOfString:foldPath].location != NSNotFound) {
                    
                    if (self.delegate
                        && [self.delegate respondsToSelector:@selector(documentSelectionControllerUnselectedDocumentWithURL:)]) {
                        
                        [self.delegate documentSelectionControllerUnselectedDocumentWithURL:url];
                    }
                    
                    [self.selectedCellURLs removeObject:url];
                                        
                }
            }
        }
        
        if (self.copiedItem) {
            
            if([self.copiedItem.path isEqualToString:item.path]
               || (item.isDirectory && [self folder:item containsItem:self.copiedItem])) {
                
                self.pasteBtn.enabled = NO;
                
                self.copiedItem = nil;
                
            }
        }

        [self refreshView];
        
    }  else if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Copy"]) {
        
        DocFileBrowserItem *item = [self.currentData objectAtIndex:currentItemIndex];
        [self copyTheStuff:item];
        
    }  else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Select"]) {
        
        DocFileBrowserItem *item = [self.currentData objectAtIndex:currentItemIndex];
        [self loadFileFromDisk:item];
        
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Export in the Cloud"]) {
        
        [self showFileSaveDialog:[self.currentData objectAtIndex:currentItemIndex]];
        
    }
}

#pragma mark - alertview delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (isMovingTheFile) {
        
        if (buttonIndex == 1) {
            
            NSURL * url = [NSURL fileURLWithPath:self.movingItem.path isDirectory:self.movingItem.isDirectory];
            
            NSString *nuItemPath = [self.destinationFolder.path stringByAppendingPathComponent:self.movingItem.fileTitle];
            
            // remove the old file
            
            NSError *err = nil;
            
            [[NSFileManager defaultManager] removeItemAtPath:nuItemPath error:&err];

            if (err) {
                
                NSString * errorDesc = [err localizedDescription] ? [err localizedDescription] : @"";
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while moving the file. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alertView show];
                [alertView release];
                
                [self refreshView];
                
                return;
            }
            
            // copy the new file
            
            [[NSFileManager defaultManager] copyItemAtPath:self.movingItem.path toPath:nuItemPath error:&err];
            
            if (err) {
                
                NSString * errorDesc = [err localizedDescription] ? [err localizedDescription] : @"";
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while moving the file. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alertView show];
                [alertView release];
                
                [self refreshView];
                
                return;
            }
            
            // aggiorno l'url nel caso di file che erano selezionati
            
            if ([self.selectedCellURLs containsObject:url]) {
                
                if (self.delegate
                    && [self.delegate respondsToSelector:@selector(documentSelectionControllerUnselectedDocumentWithURL:)]) {
                    
                    [self.delegate documentSelectionControllerUnselectedDocumentWithURL:url];
                }
                
                [self.selectedCellURLs removeObject:url];
                
                
                NSURL * nuUrl = [NSURL fileURLWithPath:nuItemPath isDirectory:NO];
                
                [self.selectedCellURLs addObject:nuUrl];
                
                if (self.delegate
                    && [self.delegate respondsToSelector:@selector(documentSelectionControllerSelectedDocumentWithURL:)]) {
                    
                    [self.delegate documentSelectionControllerSelectedDocumentWithURL:nuUrl];
                }
            }
            
            // remove the file
            
            [[NSFileManager defaultManager] removeItemAtPath:self.movingItem.path error:&err];
            
            if (err) {
                
                NSString * errorDesc = [err localizedDescription] ? [err localizedDescription] : @"";
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while moving the file. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alertView show];
                [alertView release];
                
                [self refreshView];
                
                return;
            }
            
            if (self.copiedItem) {
                
                if([self.copiedItem.path isEqualToString:self.movingItem.path]
                   || (self.movingItem.isDirectory && [self folder:self.movingItem containsItem:self.copiedItem])) {
                    
                    self.pasteBtn.enabled = NO;
                    
                    self.copiedItem = nil;
                    
                }
            }
            
        } else {
            
            [self refreshView];
        }
        
        isMovingTheFile = NO;

        return;


    } else {
        
        
        if ([self.inputField.text length] <= 0 || buttonIndex == 0){
            return; //If cancel or 0 length string the string doesn't matter
        }
        
        if (buttonIndex == 1) {
            
            DocFileBrowserItem *item = [self.currentData objectAtIndex:currentItemIndex];
            
            [self renameItem:item to:self.inputField.text];
            
        }
    }
}

//////////////////////////////////////////////////////////////
#pragma mark GMGridViewSortingDelegate
//////////////////////////////////////////////////////////////

-(void)GMGridView:(GMGridView *)gridView highlightCellAtIndex:(NSInteger)index {
//    GMGridViewCell *cell = [self GMGridView:gridView cellForItemAtIndex:index];
//    UILabel *label = (UILabel *)[cell.contentView viewWithTag:LABEL_TAG];
//    [label setBackgroundColor:[UIColor blueColor]];
//    [label setTextColor:[UIColor whiteColor]];
}

-(void)GMGridView:(GMGridView *)gridView moveItemAtIndex:(NSInteger)itemIndex toFolderAtIndex:(NSInteger)folderIndex {
    
    isMovingTheFile = YES;
    
    DocFileBrowserItem *item = [self.currentData objectAtIndex:itemIndex];
    
    NSURL * url = [NSURL fileURLWithPath:item.path isDirectory:item.isDirectory];
    
    DocFileBrowserItem *folder = [self.currentData objectAtIndex:folderIndex];
    
    NSString *nuItemPath = [folder.path stringByAppendingPathComponent:item.fileTitle];
    
    BOOL isD;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:nuItemPath isDirectory:&isD]
        && isD == item.isDirectory) {
        
        self.movingItem = item;
        self.destinationFolder = folder;
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:[NSString stringWithFormat:@"An element with the same name is already present in the folder '%@'. Do you want to overwrite it?", folder.fileTitle] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        
        [alert show];
        
        [alert release];
        
        return;
    }
    
    
    NSError *err = nil;
    
    [[NSFileManager defaultManager] copyItemAtPath:item.path toPath:nuItemPath error:&err];
    
    if (err) {
        
        NSString * errorDesc = [err localizedDescription] ? [err localizedDescription] : @"";
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while moving the file. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        
        [self refreshView];
        
        isMovingTheFile = NO;
        
        return;
    }
    
    // aggiorno l'url nel caso di file che erano selezionati
    
    if ([self.selectedCellURLs containsObject:url]) {
        
        if (self.delegate
            && [self.delegate respondsToSelector:@selector(documentSelectionControllerUnselectedDocumentWithURL:)]) {
            
            [self.delegate documentSelectionControllerUnselectedDocumentWithURL:url];
        }
        
        [self.selectedCellURLs removeObject:url];
        
        NSURL * nuUrl = [NSURL fileURLWithPath:nuItemPath isDirectory:NO];
        
        [self.selectedCellURLs addObject:nuUrl];
        
        if (self.delegate
            && [self.delegate respondsToSelector:@selector(documentSelectionControllerSelectedDocumentWithURL:)]) {
            
            [self.delegate documentSelectionControllerSelectedDocumentWithURL:nuUrl];
        }
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:item.path error:&err];
    
    if (err) {
        
        NSString * errorDesc = [err localizedDescription] ? [err localizedDescription] : @"";
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while moving the file. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        
        [self refreshView];
        
        isMovingTheFile = NO;
        
        return;
    }
    
    if (self.copiedItem) {
        
        if([self.copiedItem.path isEqualToString:item.path]
           || (item.isDirectory && [self folder:item containsItem:self.copiedItem])) {
            
            self.pasteBtn.enabled = NO;
            
            self.copiedItem = nil;
            
        }
    }
    
    isMovingTheFile = NO;

}

-(BOOL)checkIfFolderForCellAtIndex:(NSInteger)index GMGridView:(GMGridView *)gridView {
//    NSLog(@"check for directory at position %i ...", index);
    return [[self.currentData objectAtIndex:index] isDirectory];
}

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
