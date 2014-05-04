//
//  TrafficIncidentsView.h
//  repWallet
//
//  Created by Alberto Fiore on 11/9/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MapAnnotation.h"

@protocol TrafficIncidentsViewDelegate <NSObject>

@optional

- (void) trafficIncidentsViewChangedIncidentForMarkerAtIndex:(int)index;

@end

@interface TrafficIncidentsView : UIView {
    
}

@property (nonatomic, assign) id<TrafficIncidentsViewDelegate> delegate;
@property (nonatomic, retain) UILabel*  text;
@property (nonatomic, retain) MapAnnotation *mapAnnotation;
@property (nonatomic, retain) UISwipeGestureRecognizer *leftSwipeReco;
@property (nonatomic, retain) UISwipeGestureRecognizer *rightSwipeReco;

- (void)setupMapAnnotation:(MapAnnotation *)mapAnnotation;
- (void)prevIncident;
- (void)nextIncident;

@end
