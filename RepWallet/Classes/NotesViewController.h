//
//  NotesViewController.h
//  repWallet
//
//  Created by Alberto Fiore on 11/15/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "NotesCell.h"

@class NotesCell; // Forward declaration

@interface NotesViewController : UIViewController {
    
}

@property (nonatomic, retain) UITextView * t;
@property (nonatomic, retain) NotesCell* nn;

-(id)initWithNotesCell:(NotesCell*)nn;

@end
