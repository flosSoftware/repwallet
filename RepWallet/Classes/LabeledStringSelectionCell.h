//
//  LabeledStringSelection.h
//  repWallet
//
//  Created by Alberto Fiore on 3/13/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseSelectionCell.h"
#import "UnsectionedStringSelectionViewController.h"

@interface LabeledStringSelectionCell : BaseSelectionCell<UnsectionedStringSelectionViewControllerDelegate>

@property (nonatomic,retain) UnsectionedStringSelectionViewController *stringSelectionVC;
@property (nonatomic,retain) NSString *stringValue;
@property (nonatomic,retain) NSArray *dataSourceArray;

- (id)initWithStyle:(UITableViewCellStyle)style dataSource:(NSArray *)aDataSource reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)aClassName dataKey:(NSString *)aDataKey label:(NSString *)aLabel;

- (void)reload;

- (NSString *)getLabelValue;

@end
