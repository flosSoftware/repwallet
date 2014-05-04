//
//  CountrySelectionCell.h
//  repWallet
//
//  Created by Alberto Fiore on 3/13/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseSelectionCell.h"
#import "StringSelectionViewController.h"

@interface CountrySelectionCell : BaseSelectionCell<StringSelectionViewControllerDelegate>

@property (nonatomic,retain) StringSelectionViewController *stringSelectionVC;
@property (nonatomic,retain) NSString *stringValue;
@property (nonatomic,retain) NSArray *dataSourceArray;

- (NSString *)getLabelValue;
- (NSString *)getISOCodeForControlValue;
- (void)reload;

@end
