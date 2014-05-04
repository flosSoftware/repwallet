//
//  PhotoPickerCell.h
//  repWallet
//
//  Created by Alberto Fiore on 12/27/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//

#import "BaseDataEntryCell.h"
#import "PhotoViewController.h"

#define SEE_BUTTON_HEIGHT 40.0
#define SEE_BUTTON_WIDTH 125.0
#define IPAD_SEE_BUTTON_HEIGHT 80.0
#define IPAD_SEE_BUTTON_WIDTH 250.0
#define SEE_BTN_INTERNAL_HEIGHT 22.75
#define IPAD_SEE_BTN_INTERNAL_HEIGHT 45.5

@protocol PhotoPickerDelegate <NSObject>

@optional

-(void) photoPickerAddedAssetWithURL:(NSURL *)assetURL;

@end

@interface PhotoPickerCell : BaseDataEntryCell<PhotoViewControllerDelegate> {
    pthread_mutex_t mutex;
}

@property (nonatomic, assign) id<PhotoPickerDelegate> delegate;

@property (nonatomic, retain) UIButton * btn;

@property (nonatomic, retain) NSSet *photos;

@property (nonatomic, retain) NSSet *oldPhotos;

@property (nonatomic, retain) DAO *dao;

@property (nonatomic, retain) PhotoViewController *photoVC;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label dao:(DAO *)dao;

@end
