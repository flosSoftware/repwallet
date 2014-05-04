//
//  NumberCell.h
//  repWallet
//
//  Created by Alberto Fiore on 2/2/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TextCell.h"

@interface NumberCell : TextCell {
    
}

@property (nonatomic, retain) NSNumber *number;
@property (nonatomic, retain) NSNumber *upperLimitnumber;
@property (nonatomic, retain) NSNumber *lowerLimitnumber;
@property (nonatomic,retain) NSString *controlMode;

- (void) setConnectedNumberCellWithDK:(NSString *)numberCellDK controlMode:(NSString *)controlMode;

@end
