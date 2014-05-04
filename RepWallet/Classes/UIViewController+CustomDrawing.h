//
//  UITableViewController+CustomDrawing.h
//  repWallet
//
//  Created by Alberto Fiore on 7/18/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UIViewController (UIViewController_CustomDrawing)

- (void) customizeTableViewDrawingWithHeader:(NSString *)headerText headerBg:(NSString *)headerBgImgName footer:(NSString *)footerText footerBg:(NSString *)footerBgImgName background:(NSString *)bgImageName backgroundColor:(UIColor *)backgroundColor rowHeight:(int)rowHeight headerHeight:(int)headerHeight footerHeight:(int)footerHeight forTableView:(UITableView *)tableView deviceOrientationIsPortrait:(BOOL)deviceOrientationIsPortrait;

- (void) customizeDrawingForCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath dequeued:(BOOL)cellHasBeenDequeued topText:(NSString *)topTxt bottomText:(NSString *)bottomTxt subBottomText:(NSString *)subBottomTxt subSubBottomText:(NSString *)subSubBottomTxt showImage:(BOOL)showImg imageName:(NSString *)imageName forTableView:(UITableView *)tableView rowWithoutShadowHeight:(float)rowWithoutShadowHeight deviceOrientationIsPortrait:(BOOL)deviceOrientationIsPortrait;

@end
