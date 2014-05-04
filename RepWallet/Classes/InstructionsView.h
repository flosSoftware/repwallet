//
//  InstructionsView.h
//  repWallet
//
//  Created by Alberto Fiore on 10/15/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@protocol InstructionsViewDelegate <NSObject>

@optional

-(void) instructionsViewChangedInstructionForRoutingAtRouteIndex:(int)index;
-(void) instructionsViewChangedInstructionForRoutingAtLocation:(CLLocation *)location;

@end

@interface InstructionsView : UIView {
}

@property (nonatomic, assign) id<InstructionsViewDelegate> delegate;

@property (nonatomic, retain) UILabel*  text;
//@property (nonatomic, retain) UIButton *backBtn;
//@property (nonatomic, retain) UIButton *fwdBtn;
@property (nonatomic, retain) NSArray *instructionsArray;
@property (nonatomic, assign) NSInteger actualPointer;
@property (nonatomic, retain) UISwipeGestureRecognizer *leftSwipeReco;
@property (nonatomic, retain) UISwipeGestureRecognizer *rightSwipeReco;

- (id)initWithInstrus:(NSArray *)instrArr andFrame:(CGRect)frame;
- (void)prevInstro;
- (void)nextInstro;
@end
