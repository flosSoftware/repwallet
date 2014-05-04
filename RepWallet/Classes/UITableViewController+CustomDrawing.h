//
//  UITableViewController+CustomDrawing.h
//  repWallet
//
//  Created by Alberto Fiore on 7/18/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UITableViewController (UITableViewController_CustomDrawing)

- (void) customizeTableViewDrawingWithHeader:(NSString *)headerText headerBg:(NSString *)headerBgImgName footer:(NSString *)footerText footerBg:(NSString *)footerBgImgName background:(NSString *)bgImageName backgroundColor:(UIColor *)backgroundColor rowHeight:(int)rowHeight headerHeight:(int)headerHeight footerHeight:(int)footerHeight deviceOrientationIsPortrait:(BOOL)deviceOrientationIsPortrait;

- (void) customizeDrawingForCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath dequeued:(BOOL)cellHasBeenDequed topText:(NSString *)topTxt bottomText:(NSString *)bottomTxt subBottomText:(NSString *)subBottomTxt subSubBottomText:(NSString *)subSubBottomTxt showImage:(BOOL)showImg imageName:(NSString *)imageName rowWithoutShadowHeight:(float)rowWithoutShadowHeight deviceOrientationIsPortrait:(BOOL)deviceOrientationIsPortrait;

- (void) customizeDrawingForFormCell:(UITableViewCell *)cell dequeued:(BOOL)cellHasBeenDequeued deviceOrientationIsPortrait:(BOOL)deviceOrientationIsPortrait;

- (void) customizeDrawingForSearchFormCell:(UITableViewCell *)cell dequeued:(BOOL)cellHasBeenDequeued deviceOrientationIsPortrait:(BOOL)deviceOrientationIsPortrait;

@end
