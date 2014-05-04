//
//  UITableViewController+CustomDrawing.m
//  repWallet
//
//  Created by Alberto Fiore on 7/18/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "UIViewController+CustomDrawing.h"
#import "RepWalletAppDelegate.h"
#import "MyGradientView.h"


@implementation UIViewController (UIViewController_CustomDrawing)

- (void) customizeTableViewDrawingWithHeader:(NSString *)headerText headerBg:(NSString *)headerBgImgName footer:(NSString *)footerText footerBg:(NSString *)footerBgImgName background:(NSString *)bgImageName backgroundColor:(UIColor *)backgroundColor rowHeight:(int)rowHeight headerHeight:(int)headerHeight footerHeight:(int)footerHeight forTableView:(UITableView *)tableView deviceOrientationIsPortrait:(BOOL)deviceOrientationIsPortrait
{
    RepWalletAppDelegate * appDelegate = (RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSString *whatToAdd = @"";
    
    if (!deviceOrientationIsPortrait) {
        
        whatToAdd = @"-landscape";
        
        if ([appDelegate isIphone5]) {
            whatToAdd = [NSString stringWithFormat:@"%@%@", whatToAdd, @"-iphone5"];
        }
    }
    
	tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.separatorColor = [UIColor clearColor];
	tableView.rowHeight = rowHeight;
    
    if (backgroundColor) {
        
        tableView.backgroundColor = backgroundColor;
        
    } else if(bgImageName) {
        
        tableView.backgroundColor = [UIColor clearColor];
        UIImage *backgroundImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@%@.png", bgImageName, whatToAdd]];
        UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
        tableView.backgroundView = backgroundImageView;
        [backgroundImageView release];
        
    } else {
        
        MyGradientView *view = [[MyGradientView alloc] initWithFrame:CGRectZero];
        
        [view greyGradient];
        
        tableView.backgroundView = view;
        
        [view release];
    }
    
	//
	// Create a header view. Wrap it in a container to allow us to position
	// it better.
	//
    
    if (headerText) {
        
        UIView *containerView =
        [[[UIView alloc]
          initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, headerHeight)]
         autorelease];
        containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
        UILabel *headerLabel =
        [[[UILabel alloc]
          initWithFrame:CGRectMake(10, 20, tableView.bounds.size.width, 40)]
         autorelease];
        headerLabel.text = headerText;
        headerLabel.textColor = [UIColor whiteColor];
        headerLabel.shadowColor = [UIColor blackColor];
        headerLabel.shadowOffset = CGSizeMake(0, 1);
        headerLabel.font = [UIFont boldSystemFontOfSize:22];
        headerLabel.backgroundColor = [UIColor clearColor];
        [containerView addSubview:headerLabel];
        tableView.tableHeaderView = containerView;
        
    } else if (headerBgImgName) {
        
        UIImageView *containerView =
        [[[UIImageView alloc]
          initWithFrame:CGRectZero]
         autorelease];
        containerView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@%@.png", headerBgImgName, whatToAdd]];
        containerView.frame = CGRectMake(0, 0, tableView.bounds.size.width, headerHeight);
        tableView.tableHeaderView = containerView;
        
    } else if(headerHeight > 0) {
        
        UIView *containerView =
        [[[UIView alloc]
          initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, headerHeight)]
         autorelease];
        tableView.tableHeaderView = containerView;
    }
    
    if (footerText) {
        
        UIView *containerView =
        [[[UIView alloc]
          initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, footerHeight)]
         autorelease];
        containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
        UILabel *footerLabel =
        [[[UILabel alloc]
          initWithFrame:CGRectMake(10, 20, tableView.bounds.size.width, 40)]
         autorelease];
        footerLabel.text = footerText;
        footerLabel.textColor = [UIColor whiteColor];
        footerLabel.shadowColor = [UIColor blackColor];
        footerLabel.shadowOffset = CGSizeMake(0, 1);
        footerLabel.font = [UIFont boldSystemFontOfSize:22];
        footerLabel.backgroundColor = [UIColor clearColor];
        [containerView addSubview:footerLabel];
        tableView.tableFooterView = containerView;
        
    } else if (footerBgImgName) {
        
        UIImageView *containerView =
        [[[UIImageView alloc]
          initWithFrame:CGRectZero]
         autorelease];
        containerView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@%@.png", footerBgImgName, whatToAdd]];
        containerView.frame = CGRectMake(0, 0, tableView.bounds.size.width, footerHeight);
        tableView.tableFooterView = containerView;
        
    } else if(footerHeight > 0) {
        
        UIView *containerView =
        [[[UIView alloc]
          initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, footerHeight)]
         autorelease];
        tableView.tableFooterView = containerView;
    }
}


- (void) customizeDrawingForCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath dequeued:(BOOL)cellHasBeenDequeued topText:(NSString *)topTxt bottomText:(NSString *)bottomTxt subBottomText:(NSString *)subBottomTxt subSubBottomText:(NSString *)subSubBottomTxt showImage:(BOOL)showImg imageName:(NSString *)imageName forTableView:(UITableView *)tableView rowWithoutShadowHeight:(float)rowWithoutShadowHeight deviceOrientationIsPortrait:(BOOL)deviceOrientationIsPortrait
{
    RepWalletAppDelegate * appDelegate = (RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSString *whatToAdd = @"";
    
    if (!deviceOrientationIsPortrait) {
        
        whatToAdd = @"-landscape";
        
        if ([appDelegate isIphone5]) {
            whatToAdd = [NSString stringWithFormat:@"%@%@", whatToAdd, @"-iphone5"];
        }
    }
    
    float bigFontSize, smallFontSize;
    
    if([appDelegate isIpad]){
        bigFontSize = [UIFont labelFontSize] + 14;
        smallFontSize = bigFontSize - 2;
    } else {
        bigFontSize = [UIFont labelFontSize];
        smallFontSize = bigFontSize - 2;
    }
    
    float LABEL_HEIGHT;
    
    if([appDelegate isIpad]){
        LABEL_HEIGHT = 38;
    } else {
        LABEL_HEIGHT = 20;
    }
    
	// Set the background and selected background images for the text.
	// Since we will round the corners at the top and bottom of sections, we
	// need to conditionally choose the images based on the row index and the
	// number of rows in the section.
	//
	UIImage *rowBackground;
	UIImage *selectionBackground;
	NSInteger sectionRows = [tableView numberOfRowsInSection:[indexPath section]];
	NSInteger row = [indexPath row];
    float offSet = 0.0;
    
	if (row == 0 && row == sectionRows - 1)
	{
		rowBackground = [UIImage imageNamed:[NSString stringWithFormat:@"topAndBottomRow%@.png", whatToAdd]];
		selectionBackground = [UIImage imageNamed:[NSString stringWithFormat:@"topAndBottomRowSelected%@.png", whatToAdd]];
	}
	else if (row == 0)
	{
		rowBackground = [UIImage imageNamed:[NSString stringWithFormat:@"topRow%@.png", whatToAdd]];
		selectionBackground = [UIImage imageNamed:[NSString stringWithFormat:@"topRowSelected%@.png", whatToAdd]];
	}
	else if (row == sectionRows - 1)
	{
		rowBackground = [UIImage imageNamed:[NSString stringWithFormat:@"bottomRow%@.png", whatToAdd]];
		selectionBackground = [UIImage imageNamed:[NSString stringWithFormat:@"bottomRowSelected%@.png", whatToAdd]];
	}
	else
	{
		rowBackground = [UIImage imageNamed:[NSString stringWithFormat:@"middleRow%@.png", whatToAdd]];
		selectionBackground = [UIImage imageNamed:[NSString stringWithFormat:@"middleRowSelected%@.png", whatToAdd]];
	}
    
    //
    // Configure the properties for the text that are the same on every row
    //
    
    const NSInteger TOP_LABEL_TAG = 1001;
	const NSInteger BOTTOM_LABEL_TAG = 1002;
    const NSInteger SUB_BOTTOM_LABEL_TAG = 1003;
    const NSInteger SUB_SUB_BOTTOM_LABEL_TAG = 1004;
    const NSInteger IMAGE_TAG = 1005;
    const NSInteger ACC_IMAGE_TAG = 1006;
    
	UILabel *topLabel;
	UILabel *bottomLabel;
    UILabel *subBottomLabel;
    UILabel *subSubBottomLabel;
    UIImageView * imgV;
    UIImageView * accImgV;
    
    if (cellHasBeenDequeued) {
        
        if (topTxt) {
            topLabel = (UILabel *)[cell viewWithTag:TOP_LABEL_TAG];
            topLabel.text = topTxt;
        }
        
        if (bottomTxt) {
            bottomLabel = (UILabel *)[cell viewWithTag:BOTTOM_LABEL_TAG];
            bottomLabel.text = bottomTxt;
        }
        
        if (subBottomTxt) {
            subBottomLabel = (UILabel *)[cell viewWithTag:SUB_BOTTOM_LABEL_TAG];
            subBottomLabel.text = subBottomTxt;
        }
        
        if (subSubBottomTxt) {
            subSubBottomLabel = (UILabel *)[cell viewWithTag:SUB_SUB_BOTTOM_LABEL_TAG];
            subSubBottomLabel.text = subSubBottomTxt;
        }
        
        if (imgV) {
            imgV = (UIImageView *)[cell viewWithTag:IMAGE_TAG];
            imgV.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", imageName]];
        }
        
        if (accImgV) {
            accImgV = (UIImageView *)[cell viewWithTag:ACC_IMAGE_TAG];
            accImgV.image = [UIImage imageNamed:@"accessoryBtn.png"];
        }
        
    } else {
        
        // le seguenti verifiche sono utili quando forzo il ricaricamento della grafica (non solo come contenuti,
        // ma anche come struttura) della cella
        // NMMMB - la UITableView gestisce solo un numero limitato di celle che poi va a riusare anche quando mostra nuove righe
        // per la prima volta!
        
        if ([cell viewWithTag:TOP_LABEL_TAG]) {
            [[cell viewWithTag:TOP_LABEL_TAG] removeFromSuperview];
        }
        
        if ([cell viewWithTag:BOTTOM_LABEL_TAG]) {
            [[cell viewWithTag:BOTTOM_LABEL_TAG] removeFromSuperview];
        }
        
        if ([cell viewWithTag:SUB_BOTTOM_LABEL_TAG]) {
            [[cell viewWithTag:SUB_BOTTOM_LABEL_TAG] removeFromSuperview];
        }
        
        if ([cell viewWithTag:SUB_SUB_BOTTOM_LABEL_TAG]) {
            [[cell viewWithTag:SUB_SUB_BOTTOM_LABEL_TAG] removeFromSuperview];
        }
        
        if ([cell viewWithTag:IMAGE_TAG]) {
            [[cell viewWithTag:IMAGE_TAG] removeFromSuperview];
        }
        
        if ([cell viewWithTag:ACC_IMAGE_TAG]) {
            [[cell viewWithTag:ACC_IMAGE_TAG] removeFromSuperview];
        }
        
        
        int howMany = 0;
        
        if (topTxt)
            howMany++;
        if (bottomTxt)
            howMany++;
        if (subBottomTxt)
            howMany++;
        if (subSubBottomTxt)
            howMany++;
        
        //
        // Here I set the accessory image
        //
        cell.accessoryView = nil;
        
        accImgV = [[[UIImageView alloc] initWithFrame:CGRectZero] autorelease];
        
        accImgV.image = [UIImage imageNamed:@"accessoryBtn.png"];
        
        accImgV.frame = CGRectMake(tableView.bounds.size.width -
                                   accImgV.image.size.width - cell.indentationWidth, 
                                   roundf(0.5 * (rowWithoutShadowHeight - 
                                                  accImgV.image.size.height)) 
                                   + offSet, 
                                   accImgV.image.size.width, 
                                   accImgV.image.size.height);
        
        [cell addSubview:accImgV];
        
        accImgV.tag = ACC_IMAGE_TAG;
        
        //
        // Here I set an image based for the row
        //

        if(showImg) {
            
            imgV = [[[UIImageView alloc] initWithFrame:CGRectZero] autorelease];
                
            imgV.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", imageName]];
            
            imgV.frame = CGRectMake(cell.indentationWidth, 
                                    roundf(0.5 * (rowWithoutShadowHeight - 
                                                  imgV.image.size.height)) 
                                    + offSet, 
                                    imgV.image.size.width, 
                                    imgV.image.size.height);
            
            [cell addSubview:imgV];
            
            imgV.tag = IMAGE_TAG;
            
        }
        
        
        //
        // Create the label for the top row of text
        //
        if(topTxt) {
            
            if(showImg) {
                
                topLabel = [[[UILabel alloc] initWithFrame:CGRectMake(
                                                                      imgV.image.size.width + 
                                                                      2 * cell.indentationWidth,
                                                                      roundf(0.5 * (rowWithoutShadowHeight 
                                                                                    - howMany * LABEL_HEIGHT)) 
                                                                      + offSet,
                                                                      tableView.bounds.size.width -
                                                                      imgV.image.size.width - 
                                                                      4 * cell.indentationWidth - 
                                                                      accImgV.image.size.width,
                                                                      LABEL_HEIGHT)]
                            autorelease];
            } else {
                
                topLabel = [[[UILabel alloc] initWithFrame:CGRectMake(
                                                                      cell.indentationWidth,
                                                                      roundf(0.5 * (rowWithoutShadowHeight 
                                                                                    - howMany * LABEL_HEIGHT)) 
                                                                      + offSet,
                                                                      tableView.bounds.size.width -
                                                                      3 * cell.indentationWidth - 
                                                                      accImgV.image.size.width,
                                                                      LABEL_HEIGHT)]
                            autorelease];
                
            }
            
            [cell addSubview:topLabel];
            
            topLabel.tag = TOP_LABEL_TAG;
            topLabel.backgroundColor = [UIColor clearColor];
            topLabel.textColor = [UIColor colorWithRed:0.5 green:0.7 blue:1.0 alpha:1.0];
            topLabel.highlightedTextColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
            topLabel.font = [UIFont boldSystemFontOfSize:bigFontSize];
            
            topLabel.text = topTxt;
            
        }
        
		//
		// Create the label for the bottom row of text
		//
        
        if (bottomTxt) {
            
            if(showImg) {
                bottomLabel = [[[UILabel alloc] initWithFrame:CGRectMake(
                                                                         imgV.image.size.width 
                                                                         + 2 * cell.indentationWidth,
                                                                         roundf(0.5 * (rowWithoutShadowHeight 
                                                                                       - howMany * LABEL_HEIGHT)) 
                                                                         + LABEL_HEIGHT
                                                                         + offSet,
                                                                         tableView.bounds.size.width -
                                                                         imgV.image.size.width - 4 * cell.indentationWidth
                                                                         - accImgV.image.size.width,
                                                                         LABEL_HEIGHT)]
                               autorelease];
            } else {
                bottomLabel = [[[UILabel alloc] initWithFrame:CGRectMake(
                                                                         cell.indentationWidth,
                                                                         roundf(0.5 * (rowWithoutShadowHeight 
                                                                                       - howMany * LABEL_HEIGHT)) 
                                                                         + LABEL_HEIGHT
                                                                         + offSet,
                                                                         tableView.bounds.size.width -
                                                                         3 * cell.indentationWidth
                                                                         - accImgV.image.size.width,
                                                                         LABEL_HEIGHT)]
                               autorelease];
            }
            
            
            [cell addSubview:bottomLabel];
            
            //
            // Configure the properties for the text that are the same on every row
            //
            bottomLabel.tag = BOTTOM_LABEL_TAG;
            bottomLabel.backgroundColor = [UIColor clearColor];
            bottomLabel.textColor = [UIColor colorWithRed:0.5 green:0.7 blue:1.0 alpha:1.0];
            bottomLabel.highlightedTextColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
            bottomLabel.font = [UIFont systemFontOfSize:smallFontSize];
            
            bottomLabel.text = bottomTxt;
        }
        
        //
		// Create the label for the sub-bottom row of text
		//
        
        if (subBottomTxt) {
            
            if(showImg) {
                
                subBottomLabel = [[[UILabel alloc] initWithFrame:CGRectMake(
                                                                            imgV.image.size.width 
                                                                            + 2 * cell.indentationWidth,
                                                                            roundf(0.5 * (rowWithoutShadowHeight 
                                                                                          - howMany * LABEL_HEIGHT)) 
                                                                            + 2 * LABEL_HEIGHT
                                                                            + offSet,
                                                                            tableView.bounds.size.width -
                                                                            imgV.image.size.width - 4 * cell.indentationWidth
                                                                            - accImgV.image.size.width,
                                                                            LABEL_HEIGHT)]
                                  autorelease];
                
            } else {
                
                subBottomLabel = [[[UILabel alloc] initWithFrame:CGRectMake(
                                                                            cell.indentationWidth,
                                                                            roundf(0.5 * (rowWithoutShadowHeight 
                                                                                          - howMany * LABEL_HEIGHT)) 
                                                                            + 2 * LABEL_HEIGHT
                                                                            + offSet,
                                                                            tableView.bounds.size.width -
                                                                            3 * cell.indentationWidth
                                                                            - accImgV.image.size.width,
                                                                            LABEL_HEIGHT)]
                                  autorelease];
            }
            
            [cell addSubview:subBottomLabel];
            
            //
            // Configure the properties for the text that are the same on every row
            //
            subBottomLabel.tag = SUB_BOTTOM_LABEL_TAG;
            subBottomLabel.backgroundColor = [UIColor clearColor];
            subBottomLabel.textColor = [UIColor colorWithRed:0.5 green:0.7 blue:1.0 alpha:1.0];
            subBottomLabel.highlightedTextColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
            subBottomLabel.font = [UIFont systemFontOfSize:smallFontSize];
            
            subBottomLabel.text = subBottomTxt;
            
        }
 
        //
		// Create the label for the sub-sub-bottom row of text
		//
        if (subSubBottomTxt) {
            
            if(showImg) {
                
                subSubBottomLabel = [[[UILabel alloc] initWithFrame:CGRectMake(
                                                                               imgV.image.size.width 
                                                                               + 2 * cell.indentationWidth,
                                                                               roundf(0.5 * (rowWithoutShadowHeight 
                                                                                             - howMany * LABEL_HEIGHT)) 
                                                                               + 3 * LABEL_HEIGHT
                                                                               + offSet,
                                                                               tableView.bounds.size.width -
                                                                               imgV.image.size.width - 4.0 * cell.indentationWidth
                                                                               - accImgV.image.size.width,
                                                                               LABEL_HEIGHT)]
                                     autorelease];
                
            } else {
                
                subSubBottomLabel = [[[UILabel alloc] initWithFrame:CGRectMake(
                                                                               cell.indentationWidth,
                                                                               roundf(0.5 * (rowWithoutShadowHeight 
                                                                                             - howMany * LABEL_HEIGHT)) 
                                                                               + 3 * LABEL_HEIGHT
                                                                               + offSet,
                                                                               tableView.bounds.size.width -
                                                                               3 * cell.indentationWidth
                                                                               - accImgV.image.size.width,
                                                                               LABEL_HEIGHT)]
                                     autorelease];
            }
            
            [cell addSubview:subSubBottomLabel];
            
            //
            // Configure the properties for the text that are the same on every row
            //
            subSubBottomLabel.tag = SUB_SUB_BOTTOM_LABEL_TAG;
            subSubBottomLabel.backgroundColor = [UIColor clearColor];
            subSubBottomLabel.textColor = [UIColor colorWithRed:0.5 green:0.7 blue:1.0 alpha:1.0];
            subSubBottomLabel.highlightedTextColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
            subSubBottomLabel.font = [UIFont systemFontOfSize:smallFontSize];
            
            subSubBottomLabel.text = subSubBottomTxt;
            
        }
        
        //
        // Create a background image view.
        //
        cell.backgroundView = [[[UIImageView alloc] init] autorelease];
        cell.selectedBackgroundView = [[[UIImageView alloc] init] autorelease];
    }
	
    ((UIImageView *)cell.backgroundView).image = rowBackground;
	((UIImageView *)cell.selectedBackgroundView).image = selectionBackground;

}

@end
