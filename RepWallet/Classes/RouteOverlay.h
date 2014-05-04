//
//  RouteOverlayMapView.h
//  repWallet
//
//  Created by Alberto Fiore on 2/10/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "RMMapView.h"
#import <MapKit/MapKit.h>

@interface RouteOverlay : UIView {

}

- (id)init;
- (void)setMapView:(RMMapView *)mapView isPortrait:(BOOL)isPortrait;
- (void)setRoute:(NSArray *)routePoints;

@property (nonatomic, retain) RMMapView *inMapView;
@property (nonatomic, retain) NSArray *routePoints;
@property (nonatomic, retain) UIColor *lineColor; 

@end
