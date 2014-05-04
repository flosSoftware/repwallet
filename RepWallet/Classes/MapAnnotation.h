//
//  MapAnnotation.h
//  repWallet
//
//  Created by Alberto Fiore on 10/1/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMMarker.h"
#import "Mappable.h"
#import "RMAnnotation.h"

#define FIRM_MARKER @"firmMarker"
#define EVENT_MARKER @"eventMarker"
#define UNPAID_MARKER @"unpaidMarker"
#define TRAFFIC_MARKER @"trafficMarker"

@interface MapAnnotation : RMAnnotation {

}
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, retain) id<Mappable> data;
@property (nonatomic, assign) BOOL isDraggable;
@property (nonatomic, assign) BOOL canShowCallout;
@property (nonatomic, retain) NSString *calloutTitle;
@property (nonatomic, retain) NSString *calloutSubtitle;
@property (nonatomic, retain) NSString *calloutSubbottomtitle;
@property (nonatomic, assign) int index; 
// index < -1 = traffic marker
// index = -1 = currently highlighted route point
// index = 0 = current location marker
// index > 0 = normal entity (firm, evt, unpaid) marker


- (id) initWithImage:(UIImage *)image data:(id<Mappable>)data isDraggable:(BOOL)isDraggable canShowCallout:(BOOL) canShowCallout index:(int)idx coordinate:(CLLocationCoordinate2D)coordinate mapView:(RMMapView *)mapView;
- (id) initActualLocationAnnotationWithImage:(UIImage *)image coordinate:(CLLocationCoordinate2D)coordinate mapView:(RMMapView *)mapView;

@end
