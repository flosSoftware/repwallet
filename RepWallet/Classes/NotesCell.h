//
//  NotesCell.h
//  repWallet
//
//  Created by Alberto Fiore on 11/15/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseDataEntryCell.h"
#import "NotesViewController.h"

#define WRITE_BTN_HEIGHT 40.0
#define WRITE_BTN_WIDTH 125.0
#define IPAD_WRITE_BTN_HEIGHT 80.0
#define IPAD_WRITE_BTN_WIDTH 250.0
#define WRITE_BTN_INTERNAL_HEIGHT 22.75
#define IPAD_WRITE_BTN_INTERNAL_HEIGHT 45.5

@interface NotesCell : BaseDataEntryCell {
    
}

@property (nonatomic, retain) NSString *textValue;
@property (nonatomic,retain) UIButton* btn;
@property (nonatomic,retain) NotesViewController *notes;

@end
