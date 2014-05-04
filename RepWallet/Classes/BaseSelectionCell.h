//
//  BaseSelectionCell.h
//  repWallet
//
//  Created by Alberto Fiore on 3/13/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "BaseDataEntryCell.h"

#define CHOOSE_BTN_HEIGHT 40.0
#define CHOOSE_BTN_WIDTH 125.0
#define IPAD_CHOOSE_BTN_HEIGHT 80.0
#define IPAD_CHOOSE_BTN_WIDTH 250.0
#define CHOOSE_BTN_INTERNAL_HEIGHT 22.75
#define IPAD_CHOOSE_BTN_INTERNAL_HEIGHT 45.5

@interface BaseSelectionCell : BaseDataEntryCell

@property (nonatomic,retain) UIButton *btn;
@property (nonatomic,assign) BOOL addedUnderline;
@property (nonatomic,retain) UIView *underline;


@end
