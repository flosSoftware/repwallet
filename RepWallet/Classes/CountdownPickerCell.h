//
//  CountdownPickerCell.h
//  repWallet
//
//  Created by Alberto Fiore on 1/27/13.
//  Copyright (c) 2013 Alberto Fiore. All rights reserved.
//

#import "DatePickerCell.h"

@interface CountdownPickerCell : DatePickerCell

@property (nonatomic, assign) NSTimeInterval timeLeft;

@end
