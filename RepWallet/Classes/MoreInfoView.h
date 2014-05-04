//
//  MoreInfoViewDelegate.h
//  repWallet
//
//  Created by Alberto Fiore on 2/10/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapAnnotation.h"
#import "RMMapView.h"

@protocol MoreInfoViewDelegate <NSObject>

@optional
-(void) moreInfoViewEndedPanningGesture:(UIPanGestureRecognizer *)recognizer;
-(void) moreInfoViewChangedPanningGesture:(UIPanGestureRecognizer *)recognizer;
-(void) moreInfoViewBeganPanningGesture:(UIPanGestureRecognizer *)recognizer;
-(void) moreInfoViewWasTappedOnTransparentPoint:(UITouch *)tap;
-(void) moreInfoViewWasDoubleTappedOnTransparentPoint:(UITouch *)tap;
-(void) moreInfoViewWasTappedForLongOnTransparentPoint:(UILongPressGestureRecognizer *)recognizer;

@end

@interface MoreInfoView : UIImageView {
    CGPoint lastDraggingTranslation;
}

@property (nonatomic, assign) id<MoreInfoViewDelegate> delegate;

@property (nonatomic, retain) UILabel*  text;

@property (nonatomic, retain) UILabel*  bottomtext;

@property (nonatomic, retain) UILabel*  subbottomtext;

@property (nonatomic, retain) UIButton *btn;

@property (nonatomic, retain) MapAnnotation *mapAnnotation;

@property (nonatomic, retain) RMMapView *mapView;

-(id)initWithTarget:(id)target;
-(void)setupMapAnnotation:(MapAnnotation *)mapAnnotation;

@end
