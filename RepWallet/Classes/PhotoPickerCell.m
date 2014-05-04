//
//  PhotoPickerCell.m
//  repWallet
//
//  Created by Alberto Fiore on 12/27/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//

#import "PhotoPickerCell.h"
#import "Photo.h"
#import "ALAssetsManager.h"
#import <libkern/OSAtomic.h>
#import "AddEditViewController.h"

@implementation PhotoPickerCell

@synthesize btn, oldPhotos, photos, dao, delegate, photoVC;


-(void)photoViewControllerCanceled {
    
    [self setControlValue:self.oldPhotos];
    
}

-(void)photoViewControllerRemovedAssetWithURL:(NSURL *)assetURL {
    
    if (!self.photos) {
        
        [self setControlValue:[NSSet set]];
        
    } else {
        
        NSString * url = [assetURL absoluteString];

        NSMutableSet *s = [NSMutableSet setWithSet:self.photos];
        
        NSMutableArray *a = [NSMutableArray array];
        
        for (Photo *p in s) {
            if ([p.url isEqualToString:url]) {
                [a addObject:p];
                break;
            }
        }
        
        for(Photo *p in a) {
            [s removeObject:p];
        }

        [self setControlValue:[NSSet setWithSet:s]]; 
        
    }
}

-(void)photoViewControllerAddedAssetWithURL:(NSURL *)assetURL {
    
    Photo *ph = [(Photo *)[[NSManagedObject alloc] initWithEntity:[self.dao getEntityDescriptionForName:@"Photo"] insertIntoManagedObjectContext:self.dao.managedObjectContext] autorelease];
    
    ph.url = [assetURL absoluteString];
    
    if (!self.photos) {
        
        [self setControlValue:[NSSet setWithObject:ph]];
        
    } else {
        
        [self setControlValue:[self.photos setByAddingObject:ph]]; 
        
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(photoPickerAddedAssetWithURL:)]) {
        [self.delegate photoPickerAddedAssetWithURL:assetURL];
    }
}

- (void) presentImageViewControllerWithImages:(NSMutableArray *)photosToShow {
    
    PhotoViewController * mainViewController = [[PhotoViewController alloc] initWithImageAssets:photosToShow];
    self.photoVC = mainViewController;
    [mainViewController release];
    self.photoVC.delegate = self;
    self.photoVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    self.photoVC.modalPresentationStyle = UIModalPresentationFormSheet;
    
	// Add create and configure the navigation controller.
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.photoVC];
    UIColor * c = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    navigationController.navigationBar.tintColor = c;
    navigationController.toolbar.tintColor = c;
	UIViewController *vc = [self viewController];
    
    if ([vc respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        
        [vc presentViewController:navigationController animated:YES completion:NULL];
        
    } else if([vc respondsToSelector:@selector(presentModalViewController:animated:)]) {
        
        [vc presentModalViewController:navigationController animated:YES];
        
    }
    
	[navigationController release];
    
}

- (void) btnClicked {
    
    if (!self.photos) {
        
        self.oldPhotos = nil;
        
    } else {
        
        self.oldPhotos = [NSSet setWithSet:self.photos];
        
    }
    
    NSMutableArray *photosToShow = [NSMutableArray array];
    
    ALAssetsLibrary* library = [ALAssetsManager defaultAssetsLibrary];
    
    if (self.photos && self.photos.count > 0) {
        
        __block NSInteger photosCount = self.photos.count;
        
        __block NSInteger counter = 0;
        
        ALAssetsLibraryAssetForURLResultBlock assetForURL =  ^(ALAsset *asset) {
            
            OSAtomicIncrement32(&counter);
            
            if (asset) {
                
                pthread_mutex_lock(&mutex);

                CGImageRef i;
                if ([asset respondsToSelector:@selector(aspectRatioThumbnail)]) {
                    i = [asset aspectRatioThumbnail];
                } else if ([asset respondsToSelector:@selector(thumbnail)]) {
                    i = [asset thumbnail];
                }
                
                UIImage * img = [UIImage imageWithCGImage:i];
                
                [photosToShow addObject:[NSDictionary dictionaryWithObjectsAndKeys:img, @"image", asset.defaultRepresentation.url, @"url", nil]];
                
                pthread_mutex_unlock(&mutex);
                
            } else {
                
                ;
            }
            
            if(OSAtomicCompareAndSwapInt(counter, counter, &photosCount)) {
                
                [self presentImageViewControllerWithImages:photosToShow];
                
            }

        };
        
        for(Photo * ph in self.photos) {
            
            [library assetForURL:[NSURL URLWithString:[ph url]] resultBlock:assetForURL failureBlock:^(NSError *error) {
                
                NSString * errorDesc = [error localizedDescription] ? [error localizedDescription] : @"";
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while retrieving the images. %@", errorDesc] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alertView show];
                [alertView release];

            }];
        }

    } else {
        
        [self presentImageViewControllerWithImages:photosToShow];
    }
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label dao:(DAO *)dao
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier boundClassName:boundClassName dataKey:dataKey label:label]) {
        
        pthread_mutex_init(&mutex, NULL);
        
        self.dao = dao;

        // Configuro il btn
        UIButton *b = [[UIButton alloc] initWithFrame:CGRectZero];
        b.backgroundColor = [UIColor clearColor];
        [b setBackgroundImage:[UIImage imageNamed:@"see.png"] forState:UIControlStateNormal];
        [b setBackgroundImage:[UIImage imageNamed:@"seeDisabled.png"] forState:UIControlStateDisabled];
        [b addTarget:self action:@selector(btnClicked) forControlEvents:UIControlEventTouchUpInside];
        self.btn = b;
        [self.contentView addSubview:self.btn];
        [b release];
    }
    
    return self;
}

- (void)layoutSubviews 
{
	[super layoutSubviews];
    
    float btnW, btnH, internalBtnHeight, sepRowHeight, btnPadding;
    if ([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad]) {
        btnW = IPAD_SEE_BUTTON_WIDTH;
        btnH = IPAD_SEE_BUTTON_HEIGHT;
        internalBtnHeight = IPAD_SEE_BTN_INTERNAL_HEIGHT;
        sepRowHeight = IPAD_SEPARATOR_ROW_HEIGHT;
        btnPadding = IPAD_BTN_BOTTOM_PADDING;
    } else {
        btnW = SEE_BUTTON_WIDTH;
        btnH = SEE_BUTTON_HEIGHT;
        internalBtnHeight = SEE_BTN_INTERNAL_HEIGHT;
        sepRowHeight = SEPARATOR_ROW_HEIGHT;
        btnPadding = BTN_BOTTOM_PADDING;
    }
    
    CGRect rect;
    
    if (!_isAddEditCell) {
        rect = CGRectMake(self.textLabel.frame.origin.x 
                          + self.textLabel.frame.size.width  
                          + 1.0 * self.indentationWidth, 
                          self.textLabel.frame.origin.y
                          + self.textLabel.frame.size.height
                          - roundf((0.5 * (btnH - internalBtnHeight)) + internalBtnHeight)
                          - btnPadding, 
                          btnW, 
                          btnH);
        
    } else {
        rect = CGRectMake(self.textLabel.frame.origin.x 
                          + self.textLabel.frame.size.width  
                          + 1.0 * self.indentationWidth, 
                          self.contentView.center.y 
                          - roundf(btnH * 0.5
                                   + 0.5 * internalBtnHeight
                                   + 0.5 * sepRowHeight)
                          - btnPadding
                          , 
                          btnW, 
                          btnH);
    }
    
    [self.btn setFrame:rect];
}

-(void)setControlValue:(id)value
{
    self.photos = value;
}

-(id)getControlValue
{
    return self.photos;
}

-(void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    [self.btn setEnabled:enabled];
}

- (void)dealloc {
    
    pthread_mutex_destroy(&mutex);
    
    if (self.photoVC) {
        self.photoVC.delegate = nil;
    }
    
    [self.photoVC release];
    [self.oldPhotos release];
    [self.dao release];
    [self.photos release];
    [self.btn release];
    [super dealloc];
}

@end
