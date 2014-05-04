//
//  BusinessCategorySuggestionCell.h
//  repWallet
//
//  Created by Alberto Fiore on 12/4/12.
//  Copyright (c) 2012 Alberto Fiore. All rights reserved.
//

#import "TextCell.h"
#import "BusinessCategory.h"
#import "DAO.h"

@interface BusinessCategorySuggestionCell: TextCell {
    
}

@property (nonatomic, retain) DAO * dao;
@property (nonatomic, retain) NSMutableArray * businessCategories;

- (void) show:(id)sender;
- (void) removedBusinessCategory: (NSNotification*)n;
- (void) removedParentBusinessCategory: (NSNotification*)n;
- (void) insertedParentBusinessCategory: (NSNotification*)n;
- (void) insertedBusinessCategory: (NSNotification*)n;
- (void) gotSuggestion: (NSNotification*)n;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label dao:(DAO *)aDao;

@end
