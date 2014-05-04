//
//  FirmSelectionCell.h
//  repWallet
//
//  Created by alberto fiore on 2/7/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseSelectionCell.h"
#import "Firm.h"
#import "DAO.h"
#import "FirmSelectionViewController.h"


@interface FirmSelectionCell : BaseSelectionCell<FirmSelectionViewControllerDelegate> {
}

@property (nonatomic,retain) FirmSelectionViewController * firmSelectionVC;
@property (nonatomic,retain) Firm * firm;
@property (nonatomic,retain) DAO * dao;

- (id)initWithStyle:(UITableViewCellStyle)style dao:(DAO *)aDao reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)aClassName dataKey:(NSString *)aDataKey label:(NSString *)aLabel;

@end
