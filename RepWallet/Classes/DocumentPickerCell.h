//
//  DocumentPickerCell.h
//  repWallet
//
//  Created by Alberto Fiore on 27/02/13.
//  Copyright (c) 2013 Alberto Fiore. All rights reserved.
//

#import "BaseDataEntryCell.h"
#import "DocumentViewController.h"

#define SEE_BUTTON_HEIGHT 40.0
#define SEE_BUTTON_WIDTH 125.0
#define IPAD_SEE_BUTTON_HEIGHT 80.0
#define IPAD_SEE_BUTTON_WIDTH 250.0
#define SEE_BTN_INTERNAL_HEIGHT 22.75
#define IPAD_SEE_BTN_INTERNAL_HEIGHT 45.5

@interface DocumentPickerCell : BaseDataEntryCell<DocumentViewControllerDelegate> {

}

@property (nonatomic, retain) UIButton *btn;

@property (nonatomic, retain) NSSet *docs;

@property (nonatomic, retain) NSSet *oldDocs;

@property (nonatomic, retain) DAO *dao;

@property (nonatomic, retain) DocumentViewController *docuVC;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label dao:(DAO *)dao;

@end