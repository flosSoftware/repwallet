//
//  MapController.m
//  repWallet
//
//  Created by Alberto Fiore on 2/10/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "MapController.h"
#import "RepWalletAppDelegate.h"
#import "MapAnnotation.h"
#import <MapKit/MapKit.h>
#import "InstructionsView.h"
#import "FirmViewController.h"
#import "RevGeocoderResponse.h"
#import "RMShape.h"
#import "RMMapQuestOpenAerialSource.h"
#import "RMMapQuestOSMSource.h"
#import "RMOpenCycleMapSource.h"
#import "RMOpenSeaMapSource.h"
#import "RouteOverlay.h"
#import "SettingsViewController.h"

@implementation MapController

@synthesize dataSourceArray;
@synthesize dao;
@synthesize preSaveView;
@synthesize zoomSpanMiles;
@synthesize centerLoc;
@synthesize centerLocSpecified;
@synthesize geocoderV2;
@synthesize onlyForVisualization;
@synthesize routeInstructions;
@synthesize moreInfoView;
@synthesize mapView;
@synthesize longPressureEnabled;
@synthesize math;
@synthesize traffic;
@synthesize trafficView;
@synthesize instrView;
@synthesize routePoints;
@synthesize trafficIncidents;
@synthesize bBoxForRoute;
@synthesize routeOverlay;
@synthesize geoFilteringEnabled;
@synthesize filterBBoxNorthEast;
@synthesize filterBBoxSouthWest;
@synthesize filterBBox;
@synthesize bBoxForZoom;
@synthesize delegate;
@synthesize addEditVC;

# pragma mark - Change orientation

- (NSUInteger)supportedInterfaceOrientations
{
    return (1 << UIInterfaceOrientationPortrait) | (1 << UIInterfaceOrientationPortraitUpsideDown) | (1 << UIInterfaceOrientationLandscapeLeft) | (1 << UIInterfaceOrientationLandscapeRight);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return ((orientation == UIInterfaceOrientationPortrait) ||
            (orientation == UIInterfaceOrientationPortraitUpsideDown) ||
            (orientation == UIInterfaceOrientationLandscapeLeft) ||
            (orientation == UIInterfaceOrientationLandscapeRight));
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    projRectPriorToRotation = self.mapView.projectedBounds;
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self.mapView setProjectedBounds:projRectPriorToRotation];
    
    if (self.routeOverlay) {
        self.routeOverlay.frame = CGRectMake(0.0f,
                                             0.0f,
                                             //UIDeviceOrientationIsPortrait(toInterfaceOrientation) ?
                                             self.mapView.bounds.size.width
                                             //: self.mapView.bounds.size.height
                                             ,
                                             //UIDeviceOrientationIsPortrait(toInterfaceOrientation) ?
                                             self.mapView.bounds.size.height
                                             //: self.mapView.bounds.size.width
                                             );
    }
    
    if(self.moreInfoView.mapAnnotation == nil)
        
        [self hideCallout];
    
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    
    
}

#pragma mark - Animation

- (void) addJumpAnimation:(RMMapLayer *) layer  {
    CABasicAnimation *jump = [CABasicAnimation animationWithKeyPath:@"position"];
    jump.byValue = [NSValue valueWithCGPoint:CGPointMake(0.0, -10.0)]; // y increases downwards on iOS
    jump.autoreverses = YES; // Animate back to normal afterwards
    jump.duration = 0.5; // The duration for one part of the animation (0.2 up and 0.2 down)
    jump.repeatCount = MAXFLOAT;
    //Add animation to a specific element's layer. Must be called after the element is displayed.
    [layer addAnimation:jump forKey:@"myJumpAnimation"];
}

- (void) addScaleAnimation:(RMMapLayer *) layer {
    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scale.fromValue = [NSNumber numberWithFloat:0.8];
    scale.toValue = [NSNumber numberWithFloat:1];
    scale.autoreverses = YES; // Animate back to normal afterwards
    scale.duration = 0.7; // The duration for one part of the animation (0.2 up and 0.2 down)
    scale.repeatCount = MAXFLOAT;
    //Add animation to a specific element's layer. Must be called after the element is displayed.
    [layer addAnimation:scale forKey:@"myScaleAnimation"];
}

- (void) addDropAnimation:(RMMapLayer *) layer {
    
    CGFloat delay = 0;
    //        0.1 * _annotations.count;
    CGFloat start = delay;
    CGFloat totalDuration = 0.0;
    CGFloat pause = 0.01;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
    animation.duration = 0.7;
    animation.beginTime = start;
    start = start + animation.duration + pause;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    animation.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0, -self.mapView.frame.size.height, 0)];
    animation.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    animation.fillMode = kCAFillModeForwards;
    
    CABasicAnimation *animation2 = [CABasicAnimation animationWithKeyPath:@"transform"];
    animation2.duration = 0.10;
    animation2.beginTime = start;
    start = start + animation2.duration + pause;
    animation2.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    animation2.toValue = [NSValue valueWithCATransform3D:CATransform3DScale(CATransform3DMakeTranslation(0, layer.frame.size.height*kDropCompressAmount, 0), 1.0, 1.0-kDropCompressAmount, 1.0)];
    animation2.fillMode = kCAFillModeForwards;
    
    CABasicAnimation *animation3 = [CABasicAnimation animationWithKeyPath:@"transform"];
    animation3.duration = 0.15;
    animation3.beginTime = start;
    totalDuration = start + animation3.duration + pause;
    animation3.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    animation3.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    animation3.fillMode = kCAFillModeForwards;
    
    CAAnimationGroup* group = [CAAnimationGroup animation];
    [group setDuration: totalDuration];  //Set the duration of the group to the time for all animations
    group.fillMode = kCAFillModeForwards;
    [group setAnimations: [NSArray arrayWithObjects: animation, animation2, animation3, nil]];
    [layer addAnimation:group forKey:nil];
    
}

- (void) addShadow:(RMMapLayer *) layer {
    
    layer.shadowColor = [[UIColor blackColor] CGColor];
    layer.shadowOpacity = 0.8;
    layer.shadowRadius = 3.0;
    layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    CGSize size = layer.bounds.size;
    CGRect ovalRect = CGRectMake(10, size.height - 4, size.width - 20, 6);
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:ovalRect];
    layer.shadowPath = path.CGPath;
}


#pragma mark - More info view

-(void)moreInfoViewBeganPanningGesture:(UIPanGestureRecognizer *)recognizer {
    lastDraggingTranslation = CGPointZero;
    if (self.routeOverlay) {
        self.routeOverlay.hidden = YES;
    }
}

-(void)moreInfoViewChangedPanningGesture:(UIPanGestureRecognizer *)recognizer {
    
    RMMapScrollView * scrollV = [self.mapView getScrollView];
    CGPoint off = scrollV.contentOffset;
    
    CGPoint translation = [recognizer translationInView:scrollV];
    CGPoint delta = CGPointMake(lastDraggingTranslation.x - translation.x, lastDraggingTranslation.y - translation.y);
    lastDraggingTranslation = translation;
    
    [scrollV setContentOffset:CGPointMake(off.x+delta.x, off.y+delta.y) animated:NO];
    
}

-(void)moreInfoViewEndedPanningGesture:(UIPanGestureRecognizer *)recognizer {
    if (self.routeOverlay) {
        self.routeOverlay.hidden = NO;
        [self.routeOverlay setNeedsDisplay];
    }
}

- (void) moreInfoViewWasTappedOnTransparentPoint:(UITouch *)tap {
    
    [self.mapView respondToSingleTap:tap];
}

- (void) moreInfoViewWasDoubleTappedOnTransparentPoint:(UITouch *)tap {
    [self.mapView respondToDoubleTap:tap];
}

- (void) moreInfoViewWasTappedForLongOnTransparentPoint:(UILongPressGestureRecognizer *)recognizer {
    
    [self longSingleTapOnMap:self.mapView at:[recognizer locationInView:self.mapView]];
}

- (void) moveCalloutForMapAnnotation:(CGPoint)offset {
    self.moreInfoView.frame = CGRectMake(self.moreInfoView.frame.origin.x + offset.x,
                                         self.moreInfoView.frame.origin.y + offset.y
                                         ,
                                         self.moreInfoView.frame.size.width,
                                         self.moreInfoView.frame.size.height);
}

- (void) showCalloutForMapAnnotation:(MapAnnotation*)m animated:(BOOL)animated {
    
    if (animated) {
        [UIView beginAnimations: @"moveCNGCallout" context: nil];
        [UIView setAnimationDelegate: self];
        [UIView setAnimationDuration: 0.3];
        [UIView setAnimationCurve: UIViewAnimationCurveEaseInOut];
    }
    
    float x = [self.mapView coordinateToPixel:m.coordinate].x;
    float y = [self.mapView coordinateToPixel:m.coordinate].y;
    
    self.moreInfoView.frame = CGRectMake(roundf(x
                                                - 0.5 * self.moreInfoView.frame.size.width),
                                         roundf(y
                                                - m.annotationIcon.size.height
                                                - self.moreInfoView.frame.size.height)
                                         ,
                                         self.moreInfoView.frame.size.width,
                                         self.moreInfoView.frame.size.height);
    
    
    [self.moreInfoView setupMapAnnotation:m];
    
    if (animated) {
        [UIView commitAnimations];
    }
}

- (void)showCalloutForMapAnnotation:(MapAnnotation*)m withAccessoryBtn:(BOOL)showBtn animated:(BOOL)animated
{
    self.moreInfoView.btn.hidden = !showBtn;
    
	[self showCalloutForMapAnnotation:m animated:animated];
}

- (void)hideCallout
{
	[UIView beginAnimations: @"moveCNGCalloutOff" context: nil];
	[UIView setAnimationDelegate: self];
	[UIView setAnimationDuration: 0.5];
	[UIView setAnimationCurve: UIViewAnimationCurveEaseInOut];
    
    self.moreInfoView.frame = CGRectMake(10.0,
                                         self.view.bounds.origin.y
                                         + self.view.bounds.size.height
                                         + 10,
                                         self.moreInfoView.frame.size.width,
                                         self.moreInfoView.frame.size.height);
    [self.moreInfoView setMapAnnotation:nil];
    
	[UIView commitAnimations];
}

#pragma mark -
#pragma mark Traffic

- (void)addTrafficIncidents:(NSArray *)incidents {
    
    //    NSLog(@"adding traffic incidents");
    
    if (self.moreInfoView.mapAnnotation != nil) {
        [self hideCallout];
    }
    
    NSArray * arr = [[self.mapView annotations] copy];
    
    for (int i = 0; i < [arr count]; i++) {
        id m = [arr objectAtIndex:i];
        if ([m isMemberOfClass:[MapAnnotation class]] &&
            ([(MapAnnotation *)m index] != -1 && [m index] != 0)) {
            [self.mapView removeAnnotation:m];
        }
    }
    [arr release];
    
    int i = -2;
    
    for (id<Mappable> mappable in incidents) {
        
        double latitude = [[mappable latitude] doubleValue];
        double longitude = [[mappable longitude] doubleValue];
        
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
        
        if(!CLLocationCoordinate2DIsValid(coordinate)) {
            continue;
        }
        
        UIImage* markerImage = [UIImage imageNamed:@"traffic_incident.png"];
        
        MapAnnotation * m = [[MapAnnotation alloc] initWithImage:markerImage data:mappable isDraggable:NO canShowCallout:NO index:i-- coordinate:coordinate mapView:self.mapView];
        
        [self.mapView addAnnotation:m];
        
        [m release];
        
    }
    
}

- (void)trafficIncidentsQueryFailedWithError:(NSString *)errorMsg {
    NSString * s = @"";
    
    if (errorMsg) {
        s = errorMsg;
    }
    
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Cannot obtain traffic incidents. %@", s] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
	[alertView show];
	[alertView release];
}

- (void)trafficIncidentsQueryFoundIncidents:(NSMutableArray *)incidents {
    self.trafficIncidents = incidents;
    //    NSLog(@"got traffic incidents %@", self.trafficIncidents);
    
    disableAnnotationAnimation = NO;
    
    [self addTrafficIncidents:self.trafficIncidents];
    
    disableAnnotationAnimation = YES;
    
    [self addMapAnnotations:NO];
}

- (void)showTrafficIncidentsView:(MapAnnotation *)m {
    
    [UIView beginAnimations: @"moveIncidents" context: nil];
	[UIView setAnimationDelegate: self];
	[UIView setAnimationDuration: 0.5];
	[UIView setAnimationCurve: UIViewAnimationCurveEaseInOut];
    
    if(self.instrView){
        self.instrView.frame = CGRectMake(0,
                                          -self.instrView.frame.size.height,
                                          self.instrView.frame.size.width,
                                          self.instrView.frame.size.height);
    }
    
	self.trafficView.frame = CGRectMake(0,
                                        0,
                                        self.trafficView.frame.size.width,
                                        self.trafficView.frame.size.height);
    
    [self.trafficView setupMapAnnotation:m];
    
	[UIView commitAnimations];
    
}

- (void)hideTrafficIncidentsView {
    
    [UIView beginAnimations: @"moveIncidentsOff" context: nil];
	[UIView setAnimationDelegate: self];
	[UIView setAnimationDuration: 0.5];
	[UIView setAnimationCurve: UIViewAnimationCurveEaseInOut];
    
    if(self.instrView){
        self.instrView.frame = CGRectMake(0,
                                          0,
                                          self.instrView.frame.size.width,
                                          self.instrView.frame.size.height);
    }
    
	self.trafficView.frame = CGRectMake(0,
                                        -self.trafficView.frame.size.height,
                                        self.trafficView.frame.size.width,
                                        self.trafficView.frame.size.height);
    
    self.trafficView.mapAnnotation = nil;
    
	[UIView commitAnimations];
    
}

-(void)deselectTrafficMarker:(MapAnnotation *) toBeDeselected selectTrafficMarker:(MapAnnotation *) toBeSelected {
    
    CLLocationCoordinate2D center = [toBeSelected coordinate];
    [self.mapView setCenterCoordinate:center animated:NO];
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(center,
                                                                       0.02 * METERS_PER_MILE,
                                                                       0.02 * METERS_PER_MILE);
    
    double neLat=viewRegion.center.latitude+viewRegion.span.latitudeDelta/2;
    double neLng=viewRegion.center.longitude+viewRegion.span.longitudeDelta/2;
    
    CLLocationCoordinate2D ne = CLLocationCoordinate2DMake(neLat, neLng);
    
    double swLat=viewRegion.center.latitude-viewRegion.span.latitudeDelta/2;
    double swLng=viewRegion.center.longitude-viewRegion.span.longitudeDelta/2;
    
    CLLocationCoordinate2D sw = CLLocationCoordinate2DMake(swLat, swLng);
    
    [self.mapView zoomWithLatitudeLongitudeBoundsSouthWest:sw northEast:ne animated:YES];
    
    toBeDeselected.selected = NO;
    [(RMMarker *)toBeDeselected.layer replaceUIImage:[UIImage imageNamed:@"traffic_incident.png"] anchorPoint:toBeDeselected.anchorPoint];
    toBeSelected.selected = YES;
    [(RMMarker *)toBeSelected.layer replaceUIImage:[UIImage imageNamed:@"traffic_incident_selected.png"] anchorPoint:toBeSelected.anchorPoint];
    [self showTrafficIncidentsView:toBeSelected];
    
}

-(void)trafficIncidentsViewChangedIncidentForMarkerAtIndex:(int)index {
    if (index > -2) {
        return;
    } else {
        
        NSArray * a = [self.mapView annotations];
        MapAnnotation * toBeDeselected = nil;
        MapAnnotation * toBeSelected = nil;
        for (int i = 0; i < [a count]; i++) {
            if ([[a objectAtIndex:i] isMemberOfClass:[MapAnnotation class]] && [[a objectAtIndex:i] selected] == YES) {
                
                toBeDeselected = [a objectAtIndex:i];
                
                if (toBeSelected) {
                    
                    [self deselectTrafficMarker:toBeDeselected selectTrafficMarker:toBeSelected];
                    break;
                }
            } else if ([[a objectAtIndex:i] isMemberOfClass:[MapAnnotation class]]
                       && [[a objectAtIndex:i] selected] == NO
                       && [[a objectAtIndex:i] index] == index) {
                
                toBeSelected = [a objectAtIndex:i];
                
                if (toBeDeselected) {
                    
                    [self deselectTrafficMarker:toBeDeselected selectTrafficMarker:toBeSelected];
                    break;
                }
            }
        }
    }
}

#pragma mark - Routes

- (void) addRouteToMap
{
    double neLat=self.bBoxForRoute.center.latitude+self.bBoxForRoute.span.latitudeDelta/2;
    double neLng=self.bBoxForRoute.center.longitude+self.bBoxForRoute.span.longitudeDelta/2;
    
    CLLocationCoordinate2D neBBoxLimitForRoute = CLLocationCoordinate2DMake(neLat, neLng);
    
    double swLat=self.bBoxForRoute.center.latitude-self.bBoxForRoute.span.latitudeDelta/2;
    double swLng=self.bBoxForRoute.center.longitude-self.bBoxForRoute.span.longitudeDelta/2;
    
    CLLocationCoordinate2D swBBoxLimitForRoute = CLLocationCoordinate2DMake(swLat, swLng);
    
    [self.routeOverlay setRoute:self.routePoints];
    [self.routeOverlay setMapView:self.mapView isPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
    
    [self.traffic startGettingIncidentsInBBoxWithNorthEast:neBBoxLimitForRoute southWest:swBBoxLimitForRoute];
    
    [self.mapView zoomWithLatitudeLongitudeBoundsSouthWest:swBBoxLimitForRoute northEast:neBBoxLimitForRoute animated:YES];
    
    // alternative way - but it's slowwwww....
    //    RMAnnotation * ann = [[RMAnnotation alloc] initWithMapView:self.mapView coordinate:CLLocationCoordinate2DMake(neBBoxLimitForRoute.latitude, swBBoxLimitForRoute.longitude) andTitle:nil];
    //    [ann setBoundingBoxCoordinatesSouthWest:swBBoxLimitForRoute northEast:neBBoxLimitForRoute];
    //    [self.mapView addAnnotation:ann];
    //    [ann release];
    
    self.routeOverlay.hidden = NO;
    [self.routeOverlay setNeedsDisplay];
}

- (void) showRoutePointWithLocation:(CLLocation *)loc
{    
    NSArray *a = [[self.mapView annotations] copy];
    
    for (int i = 0; i < [a count]; i++) {
        id m = [a objectAtIndex:i];
        if ([m isMemberOfClass:[MapAnnotation class]]) {
            [self.mapView removeAnnotation:m];
        }
    }
    
    [a release];
    
    CLLocationCoordinate2D center = [loc coordinate];
    [self.mapView setCenterCoordinate:center animated:NO];
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(center,
                                                                       0.02 * METERS_PER_MILE,
                                                                       0.02 * METERS_PER_MILE);
    
    double neLat=viewRegion.center.latitude+viewRegion.span.latitudeDelta/2;
    double neLng=viewRegion.center.longitude+viewRegion.span.longitudeDelta/2;
    
    CLLocationCoordinate2D ne = CLLocationCoordinate2DMake(neLat, neLng);
    
    double swLat=viewRegion.center.latitude-viewRegion.span.latitudeDelta/2;
    double swLng=viewRegion.center.longitude-viewRegion.span.longitudeDelta/2;
    
    CLLocationCoordinate2D sw = CLLocationCoordinate2DMake(swLat, swLng);
    
    [self.mapView zoomWithLatitudeLongitudeBoundsSouthWest:sw northEast:ne animated:YES];
    
    MapAnnotation *m = [[MapAnnotation alloc] initWithImage:[UIImage imageNamed:@"highlight_border.png"] data:nil isDraggable:NO canShowCallout:NO index:-1 coordinate:center mapView:self.mapView]; // highlighted route point has -1 index
    
    [self.mapView addAnnotation:m];
    
    [m release];
    
    if (self.trafficIncidents) {
        [self addTrafficIncidents:self.trafficIncidents];
    }
    
    disableAnnotationAnimation = YES;
    
    [self addMapAnnotations:NO];
}

- (void) showRoutePointWithIndex:(int)index
{
    [self showRoutePointWithLocation:[self.routePoints objectAtIndex:index]];
}

- (void) instructionsViewChangedInstructionForRoutingAtRouteIndex:(int)index
{
    [self showRoutePointWithIndex:index];
    
}

- (void) instructionsViewChangedInstructionForRoutingAtLocation:(CLLocation *)location
{    
    [self showRoutePointWithLocation:location];
    
}



#pragma mark - Map Annotations

- (void)addMapAnnotations:(BOOL)isReloading
{
    //    NSLog(@"addMapAnnotations %@", self);
    
    if (self.moreInfoView.mapAnnotation != nil) {
        [self hideCallout];
    }
    
    if (isReloading) {
        
        [self.mapView removeAllAnnotations];
        
    } else {
        ;
    }
    
    int i = 1;
    
    for (int k = 0; k < [self.dataSourceArray count]; k++) {
        
        id<Mappable> mappable = [self.dataSourceArray objectAtIndex:k];
        
        double latitude = [[mappable latitude] doubleValue];
        double longitude = [[mappable longitude] doubleValue];
        
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
        
        //        NSLog(@"Checking coord: %f %f",latitude,longitude);
        
        if(!CLLocationCoordinate2DIsValid(coordinate)) {
            //            NSLog(@"Not valid, skip");
            continue;
        }
        
        //        NSLog(@"Valid");
        
        UIImage* markerImage = nil;
        
        if (self.routePoints && k == 0) {
            markerImage = [UIImage imageNamed:@"marker-green.png"];
        } else if (self.routePoints && k == 1) {
            markerImage = [UIImage imageNamed:@"marker-red.png"];
        } else
            markerImage = [UIImage imageNamed:@"marker-blue.png"];
        
        MapAnnotation * m = nil;
        
        if ([self isPreSaveView] && ![self mapIsForVisualizationOnly]) {
            
            m = [[MapAnnotation alloc] initWithImage:markerImage data:mappable isDraggable:YES canShowCallout:YES index:i++ coordinate:coordinate mapView:self.mapView];
            
        } else {
            
            m = [[MapAnnotation alloc] initWithImage:markerImage data:mappable isDraggable:NO canShowCallout:YES index:i++ coordinate:coordinate mapView:self.mapView];
            
        }
        
        [self.mapView addAnnotation:m];
        
        [m release];
        
    }
}

#pragma mark - Map annotation delegate

- (RMMapLayer *)mapView:(RMMapView *)aMapView layerForAnnotation:(RMAnnotation *)annotation
{
    if ([annotation isMemberOfClass:[MapAnnotation class]]) {
        
        MapAnnotation * ann = (MapAnnotation *)annotation;
        
        RMMarker *marker = [[[RMMarker alloc] initWithUIImage:ann.annotationIcon anchorPoint:ann.anchorPoint] autorelease];
        
        marker.enableDragging = ann.isDraggable;
        
        if (!disableAnnotationAnimation && ann.index != -1 && ann.index != 0) {
            [self addDropAnimation:marker];
        }
        
        if (ann.index > 0) {
            [self addShadow:marker];
        }
        
        return marker;
        
    } else if(self.geoFilteringEnabled) {
        
        RMShape *path = [[[RMShape alloc] initWithView:self.mapView] autorelease];
        
        [path setLineColor:[UIColor colorWithRed:0.0f green:0.0f blue:(156.0 /255) alpha:0.5f]];
        [path setLineWidth:4.0f];
        [path setFillColor:[UIColor colorWithRed:0.0f green:0.0f blue:(156.0 /255) alpha:0.3f]];
        
        [path moveToCoordinate:self.filterBBoxNorthEast];
        
        [path addLineToCoordinate:CLLocationCoordinate2DMake(self.filterBBoxNorthEast.latitude, self.filterBBoxSouthWest.longitude)];
        [path addLineToCoordinate:self.filterBBoxSouthWest];
        [path addLineToCoordinate:CLLocationCoordinate2DMake(self.filterBBoxSouthWest.latitude, self.filterBBoxNorthEast.longitude)];
        [path addLineToCoordinate:self.filterBBoxNorthEast];
        
        [path closePath];
        
        return path;
        
    } else {  // route annotation
        
        RMShape *path = [[[RMShape alloc] initWithView:self.mapView] autorelease];
        
        [path setLineColor:[UIColor colorWithRed:0.0f green:0.0f blue:(156.0 /255) alpha:0.5f]];
        [path setLineWidth:4.0f];
        
        for(int i = 0; i < self.routePoints.count; i++) {
            
            //            NSLog(@"%.8f %.8f",[[self.routePoints objectAtIndex:i] coordinate].latitude, [[self.routePoints objectAtIndex:i] coordinate].longitude);
            
			if(i == 0) {
                
				[path moveToCoordinate:[[self.routePoints objectAtIndex:i] coordinate]];
                
                
			} else {
                
				[path addLineToCoordinate:[[self.routePoints objectAtIndex:i] coordinate]];
                
			}
		}
        
        return path;
    }
    
    return nil;
}

- (void) tapOnAnnotation: (RMAnnotation*) annotation onMap: (RMMapView*) map
{
    if ([annotation isMemberOfClass:[MapAnnotation class]]) {
        
        MapAnnotation * m = (MapAnnotation *)annotation;
        
        if((m.canShowCallout && self.moreInfoView.mapAnnotation == nil)
           || (m.canShowCallout
               && self.moreInfoView.mapAnnotation != nil
               && self.moreInfoView.mapAnnotation.index != m.index)) {
               
               [self showCalloutForMapAnnotation:m withAccessoryBtn:![self isPreSaveView] animated:YES];
               
           } else if(m.canShowCallout
                     && self.moreInfoView.mapAnnotation != nil
                     && self.moreInfoView.mapAnnotation.index == m.index) {
               
               [self hideCallout];
               
           } else if([m.annotationType isEqualToString:TRAFFIC_MARKER]
                     && self.trafficView.mapAnnotation == nil) {
               
               m.selected = YES;
               [(RMMarker *)m.layer replaceUIImage:[UIImage imageNamed:@"traffic_incident_selected.png"] anchorPoint:m.anchorPoint];
               [self showTrafficIncidentsView:m];
               
           } else if([m.annotationType isEqualToString:TRAFFIC_MARKER]
                     && self.trafficView.mapAnnotation != nil
                     && self.trafficView.mapAnnotation.index != m.index) {
               
               NSArray * a = [self.mapView annotations];
               
               for (int i = 0; i < [a count]; i++) {
                   if ([[a objectAtIndex:i] isMemberOfClass:[MapAnnotation class]] && [[a objectAtIndex:i] selected] == YES) {
                       MapAnnotation * t = [a objectAtIndex:i];
                       t.selected = NO;
                       [(RMMarker *)t.layer replaceUIImage:[UIImage imageNamed:@"traffic_incident.png"] anchorPoint:t.anchorPoint];
                       break;
                   }
               }
               
               m.selected = YES;
               [(RMMarker *)m.layer replaceUIImage:[UIImage imageNamed:@"traffic_incident_selected.png"] anchorPoint:m.anchorPoint];
               [self showTrafficIncidentsView:m];
               
           } else if([m.annotationType isEqualToString:TRAFFIC_MARKER]
                     && self.trafficView.mapAnnotation != nil
                     && self.trafficView.mapAnnotation.index == m.index) {
               m.selected = NO;
               [(RMMarker *)m.layer replaceUIImage:[UIImage imageNamed:@"traffic_incident.png"] anchorPoint:m.anchorPoint];
               [self hideTrafficIncidentsView];
               
           }
    }
    
}

#pragma mark - Callout disclosure button delegate

-(void)accessoryBtnClicked:(UIButton*)sender
{
    MapAnnotation *m = self.moreInfoView.mapAnnotation;
    
    if ([m.annotationType isEqualToString:FIRM_MARKER]) {
        
        Firm *firm = (Firm *)[m data];
        
        if([AddEditViewController isEditingFirmWithID:[firm objectID]]) {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"This firm is already open for modification in another tab." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
            [alertView release];
            
            return;
        }
        
        AddEditViewController *viewController = [[AddEditViewController alloc] initWithStyle:UITableViewStylePlain title:ADDEDITVIEWCONTROLLER_EDIT_MODE_TITLE entity:firm andDao:self.dao];
        self.addEditVC = viewController;
        [viewController release];
        
        self.addEditVC.delegate = self;
        [self hideCallout];
        [self.navigationController pushViewController:self.addEditVC animated:YES];
        
        return;
    }
}

#pragma mark - Geo filtering

- (void) geoFilteredData {
    
    CLLocation * neLoc = [[CLLocation alloc] initWithLatitude:self.filterBBoxNorthEast.latitude longitude:self.filterBBoxNorthEast.longitude];
    
    CLLocation * swLoc = [[CLLocation alloc] initWithLatitude:self.filterBBoxSouthWest.latitude longitude:self.filterBBoxSouthWest.longitude];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(mapControllerGeoFilteredLocationsWithNorthEastBoundingLocation:southWestBoundingLocation:)]) {
        [self.delegate mapControllerGeoFilteredLocationsWithNorthEastBoundingLocation:neLoc southWestBoundingLocation:swLoc];
    }
    
    [neLoc release];
    [swLoc release];
    
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Map delegate

- (void) beforeMapZoom:(RMMapView *)map
{
    if (self.routeOverlay) {
        self.routeOverlay.hidden = YES;
    }
    
    self.moreInfoView.hidden = YES;
}

- (void) afterMapZoom:(RMMapView *)map
{
    if (self.routeOverlay) {
        self.routeOverlay.hidden = NO;
        [self.routeOverlay setNeedsDisplay];
    }
    
    if(self.moreInfoView.mapAnnotation) {
        
        [self showCalloutForMapAnnotation:self.moreInfoView.mapAnnotation withAccessoryBtn:![self isPreSaveView] animated:NO];
    }
    
    self.moreInfoView.hidden = NO;
}

- (void) beforeMapMove:(RMMapView *) map
{
    if (self.routeOverlay) {
        self.routeOverlay.hidden = YES;
    }
}

- (void) mapDidScroll:(CGPoint)newContentOffset
{
    if(self.moreInfoView.mapAnnotation) {
        
        [self moveCalloutForMapAnnotation:CGPointMake(lastContentOffset.x-newContentOffset.x, lastContentOffset.y-newContentOffset.y)];
    }
    
    lastContentOffset = newContentOffset;
}

- (void) afterMapMove:(RMMapView *) map
{
    if (self.routeOverlay) {
        self.routeOverlay.hidden = NO;
        [self.routeOverlay setNeedsDisplay];
    }
}

- (void)doubleTapOnMap:(RMMapView *)map
                    at:(CGPoint)point {
    [self.mapView zoomByFactor:2.0 near:point animated:YES];
}

- (void)singleTapOnMap:(RMMapView *)map at:(CGPoint)point {
    
    if (self.geoFilteringEnabled) {
        
        //        NSLog(@"clicked on %g %g",[map pixelToCoordinate:point].latitude, [map pixelToCoordinate:point].longitude);
        
        if (!CLLocationCoordinate2DIsValid(self.filterBBoxSouthWest)) { // first click
            
            self.filterBBoxSouthWest = [map pixelToCoordinate:point];
            
            return;
            
        } else if (!CLLocationCoordinate2DIsValid(self.filterBBoxNorthEast)) { // second click
            
            self.filterBBoxNorthEast = [map pixelToCoordinate:point];
            
            // Three of four cases require
            // tricks to correctly initialize
            // LatLngBounds
            
            // ne is higher than sw and to the left
            if (self.filterBBoxNorthEast.latitude > self.filterBBoxSouthWest.latitude
                && self.filterBBoxNorthEast.longitude < self.filterBBoxSouthWest.longitude) {
                
                CLLocationCoordinate2D newSw = CLLocationCoordinate2DMake(self.filterBBoxSouthWest.latitude, self.filterBBoxNorthEast.longitude);
                CLLocationCoordinate2D newNe = CLLocationCoordinate2DMake(self.filterBBoxNorthEast.latitude, self.filterBBoxSouthWest.longitude);
                self.filterBBoxNorthEast = newNe;
                self.filterBBoxSouthWest = newSw;
                
                //                NSLog(@"ne is higher than sw and to the left");
            }
            // ne is lower than sw and to the left
            else if (self.filterBBoxNorthEast.latitude < self.filterBBoxSouthWest.latitude
                     && self.filterBBoxNorthEast.longitude < self.filterBBoxSouthWest.longitude) {
                
                CLLocationCoordinate2D newSw = CLLocationCoordinate2DMake(self.filterBBoxNorthEast.latitude, self.filterBBoxNorthEast.longitude);
                CLLocationCoordinate2D newNe = CLLocationCoordinate2DMake(self.filterBBoxSouthWest.latitude, self.filterBBoxSouthWest.longitude);
                self.filterBBoxNorthEast = newNe;
                self.filterBBoxSouthWest = newSw;
                
                //                NSLog(@"ne is lower than sw and to the left");
            }
            // ne is lower than sw and to the right
            else if (self.filterBBoxNorthEast.latitude < self.filterBBoxSouthWest.latitude
                     && self.filterBBoxNorthEast.longitude > self.filterBBoxSouthWest.longitude) {
                
                CLLocationCoordinate2D newSw = CLLocationCoordinate2DMake(self.filterBBoxNorthEast.latitude, self.filterBBoxSouthWest.longitude);
                CLLocationCoordinate2D newNe = CLLocationCoordinate2DMake(self.filterBBoxSouthWest.latitude, self.filterBBoxNorthEast.longitude);
                self.filterBBoxNorthEast = newNe;
                self.filterBBoxSouthWest = newSw;
                
                //                NSLog(@"ne is lower than sw and to the right");
            }
            else if ([self.math firstDouble:self.filterBBoxNorthEast.latitude isEqualTo:self.filterBBoxSouthWest.latitude]
                     &&
                     [self.math firstDouble:self.filterBBoxNorthEast.longitude isEqualTo:self.filterBBoxSouthWest.longitude]) {
                
                self.filterBBoxNorthEast = CLLocationCoordinate2DMake(-360, -360);
                self.filterBBoxSouthWest = CLLocationCoordinate2DMake(-360, -360);
                
                //                NSLog(@"NE AND SW ARE THE SAME");
                
                return;
                
            }
            // ne is higher and to the right
            else {
                //                NSLog(@"ne is higher than sw and to the right, ok!");
            }
            
            RMAnnotation * ann = [[RMAnnotation alloc] initWithMapView:self.mapView
                                                            coordinate:CLLocationCoordinate2DMake(self.filterBBoxNorthEast.latitude, self.filterBBoxNorthEast.longitude)
                                                              andTitle:nil];
            [ann setBoundingBoxCoordinatesSouthWest:self.filterBBoxSouthWest northEast:self.filterBBoxNorthEast];
            self.filterBBox = ann;
            
            NSArray * arr = [[self.mapView annotations] copy];
            
            for (int i = 0; i < [arr count]; i++) {
                id m = [arr objectAtIndex:i];
                if ([m isMemberOfClass:[MapAnnotation class]] &&
                    ([(MapAnnotation *)m index] != -1 && [m index] != 0)) {
                    [self.mapView removeAnnotation:m];
                }
            }
            [arr release];
            
            [self.mapView addAnnotation:self.filterBBox];
            
            disableAnnotationAnimation = YES;
            
            [self addMapAnnotations:NO];
            
            [ann release];
            
            return;
            
        } else { // third click resets
            
            [self.mapView removeAnnotation:self.filterBBox];
            self.filterBBox = nil;
            self.filterBBoxSouthWest = [map pixelToCoordinate:point];
            self.filterBBoxNorthEast = CLLocationCoordinate2DMake(-360, -360);
        }
    }
}

- (BOOL) mapView:(RMMapView *)map shouldDragAnnotation:(RMAnnotation *)annotation
{
    if ([annotation isMemberOfClass:[MapAnnotation class]]) {
        MapAnnotation * m = (MapAnnotation *)annotation;
        return m.isDraggable;
    }
    return NO;
}

- (void)mapView:(RMMapView *)map didDragAnnotation:(RMAnnotation *)annotation withDelta:(CGPoint)delta
{
    if (self.moreInfoView.mapAnnotation != nil) {
        [self hideCallout];
    }
    
    CGPoint screenPosition = CGPointMake(annotation.position.x - delta.x, annotation.position.y - delta.y);
    
    annotation.coordinate = [mapView pixelToCoordinate:screenPosition];
    annotation.position = screenPosition;
}

- (void)mapView:(RMMapView *)map didEndDragAnnotation:(RMAnnotation *)annotation
{
    if ([annotation isMemberOfClass:[MapAnnotation class]]) {
        
        MapAnnotation * m = (MapAnnotation *)annotation;
        
        if ([m.annotationType isEqualToString:FIRM_MARKER]) {
            
            Firm * f = (Firm *)m.data;
            
            CLLocationCoordinate2D pos = m.coordinate;
            [f setLatitude: [NSNumber numberWithDouble:pos.latitude]];
            [f setLongitude: [NSNumber numberWithDouble:pos.longitude]];
            
            CLLocation * l = [[CLLocation alloc] initWithLatitude:pos.latitude longitude:pos.longitude];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(mapControllerUpdatedLocation:forObjectOfClass:)]) {
                [self.delegate mapControllerUpdatedLocation:l forObjectOfClass:NSStringFromClass([Firm class])];
            }
            
            [l release];
            
        }
    }
}

-(void)mapView:(RMMapView *)mapView didUpdateUserLocation:(RMUserLocation *)userLocation
{
    //    NSLog(@"mapcontroller received user location %@", [userLocation location]);
    
    if (!self.geoFilteringEnabled && !self.routePoints && ![self centerLocHasBeenSpecified]) {
        CLLocation * l = [userLocation location];
        self.centerLoc = l.coordinate;
        [self setCenterLocSpecified:YES];
        
        [self.mapView setCenterCoordinate:self.centerLoc animated:YES];
    }
}


#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if (self) {
        lastContentOffset = CGPointZero;
        lastDraggingTranslation = CGPointZero;
        self.trafficIncidents = nil;
        // default
        self.zoomSpanMiles = 0.5;
        self.centerLoc = CLLocationCoordinate2DMake(45.057595, 12.056022); // Adria
        [self setCenterLocSpecified:NO]; // uso il centro di default o la localizzazione, se disponibile
    }
    return self;
}

- (id) initWithArray:(NSArray *)mappablesArray routePoints:(NSArray *)routePoints boundingBoxForRoute:(MKCoordinateRegion)bBoxForRoute routeInstructions:(NSArray *)routeInstructions andDao:(DAO *)aDao
{
    self = [self init];
    
    if (self) {
        
        self.longPressureEnabled = NO;
        
        self.routePoints = routePoints;
        
        self.bBoxForRoute = bBoxForRoute;
        
        RouteOverlay * r = [[RouteOverlay alloc] init];
        
        self.routeOverlay = r;
        
        [r release];
        
        self.routeInstructions = routeInstructions;
        
        self.onlyForVisualization = YES;
        
        [self setPreSaveView:NO];
        
        self.dao = aDao;
        
        if(mappablesArray) {
            
            self.dataSourceArray = mappablesArray;
        }
    }
    
    return self;
}

- (id)initWithArray:(NSArray *)mappablesArray andDao:(DAO *)aDao geoFilteringEnabled:(BOOL)geoFilteringEnabled ne:(CLLocationCoordinate2D)ne sw:(CLLocationCoordinate2D)sw
{
    self = [self initWithArray:mappablesArray andDao:aDao isPreSave:NO longPressureEnabled:NO];
    
    if (self) {
        
        self.geoFilteringEnabled = geoFilteringEnabled;
        
        if (geoFilteringEnabled) {
            self.filterBBox = nil;
            self.filterBBoxNorthEast = ne;
            self.filterBBoxSouthWest = sw;
        }
    }
    
    return self;
}

- (id)initWithArray:(NSArray *)mappablesArray andDao:(DAO *)aDao isPreSave:(BOOL)isPreSaveView longPressureEnabled:(BOOL)longPressureEnabled
{
    self = [self init];
    
    if (self) {
        
        self.routePoints = nil;
        
        self.routeOverlay = nil;
        
        self.onlyForVisualization = NO;
        
        self.longPressureEnabled = longPressureEnabled;
        
        [self setPreSaveView:isPreSaveView];
        
        self.dao = aDao;
        
        if(mappablesArray) {
            
            self.dataSourceArray = mappablesArray;
        }
    }
    
    return self;
}

- (id)initWithArray:(NSArray *)mappablesArray andDao:(DAO *)aDao isPreSave:(BOOL)isPreSaveView zoomLvl:(double)zoomLvl longPressureEnabled:(BOOL)longPressureEnabled
{
    self = [self initWithArray:mappablesArray andDao:aDao isPreSave:isPreSaveView longPressureEnabled:longPressureEnabled];
    
    if (self) {
        
        self.zoomSpanMiles = zoomLvl;
    }
    
    return self;
}

- (id)initWithArray:(NSArray *)mappablesArray andDao:(DAO *)aDao isPreSave:(BOOL)isPreSaveView centerLocation:(CLLocationCoordinate2D)centerLoc zoomLvl:(double)zoomLvl longPressureEnabled:(BOOL)longPressureEnabled
{
    self = [self initWithArray:mappablesArray andDao:aDao isPreSave:isPreSaveView longPressureEnabled:longPressureEnabled];
    
    if (self) {
        self.centerLoc = centerLoc;
        self.zoomSpanMiles = zoomLvl;
        [self setCenterLocSpecified:YES];
    }
    
    return self;
}

- (id) initWithArray:(NSArray *)mappablesArray andDao:(DAO *)aDao isPreSave:(BOOL)isPreSaveView bBoxForZoom:(MKCoordinateRegion)bBoxForZoom longPressureEnabled:(BOOL)longPressureEnabled
{
    self = [self initWithArray:mappablesArray andDao:aDao isPreSave:isPreSaveView longPressureEnabled:longPressureEnabled];
    
    if (self) {
        self.bBoxForZoom = bBoxForZoom;
        self.zoomSpanMiles = -1;
        [self setCenterLocSpecified:YES];
    }
    
    return self;
}

#pragma mark -
#pragma mark View lifecycle

- (void) getBack
{
    if([self isPreSaveView] && ![self mapIsForVisualizationOnly])
        [self postCancelEditingNotification];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) getToRoot
{
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void) showTabBar:(UITabBarController *) tabbarcontroller
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    float fHeight = screenRect.size.height - self.tabBarController.tabBar.frame.size.height;
    
    if(  UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) )
    {
        fHeight = screenRect.size.width - self.tabBarController.tabBar.frame.size.height;
    }
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.2];
    for(UIView *view in tabbarcontroller.view.subviews)
    {
        if([view isKindOfClass:[UITabBar class]])
        {
            [view setFrame:CGRectMake(view.frame.origin.x, fHeight, view.frame.size.width, view.frame.size.height)];
        }
        else
        {
            [view setFrame:CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, fHeight)];
        }
    }
    
    [UIView commitAnimations];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
    [self showTabBar:self.tabBarController];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO force:YES];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.mapView.showsUserLocation = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    //    NSLog(@"viewWillAppear %@", self);
    
    [super viewWillAppear:animated];
    
    if(!self.routePoints) {
        
        if (![self centerLocHasBeenSpecified]) {
            
            // se possibile, non uso il default ma la posizione del primo elemento dell'array
            
            if (self.dataSourceArray && [self.dataSourceArray count] > 0) {
                CLLocationCoordinate2D locCoord = CLLocationCoordinate2DMake([[[self.dataSourceArray objectAtIndex:0] latitude] doubleValue], [[[self.dataSourceArray objectAtIndex:0] longitude] doubleValue]);
                
                if (CLLocationCoordinate2DIsValid(locCoord)) {
                    self.centerLoc = locCoord;
                } else {
                    self.centerLoc = CLLocationCoordinate2DMake(37.317492, -122.041949);
                }
            }
            
        } else {
            
            ;
        }
        
        MKCoordinateRegion viewRegion;
        
        if (self.zoomSpanMiles != -1) {
            
//            NSLog(@"center loc : %f %f, self.zoom %f", self.centerLoc.latitude, self.centerLoc.longitude, self.zoomSpanMiles);
            viewRegion = MKCoordinateRegionMakeWithDistance(self.centerLoc,
                                                            self.zoomSpanMiles * METERS_PER_MILE,
                                                            self.zoomSpanMiles * METERS_PER_MILE);
        } else {
            viewRegion = self.bBoxForZoom;
            //            NSLog(@"bbox = %f %f - %f %f", self.bBoxForZoom.center.latitude, self.bBoxForZoom.center.longitude, self.bBoxForZoom.span.latitudeDelta, self.bBoxForZoom.span.longitudeDelta);
        }
        
        double neLat=viewRegion.center.latitude+viewRegion.span.latitudeDelta/2;
        double neLng=viewRegion.center.longitude+viewRegion.span.longitudeDelta/2;
        
        CLLocationCoordinate2D ne = CLLocationCoordinate2DMake(neLat, neLng);
        
        double swLat=viewRegion.center.latitude-viewRegion.span.latitudeDelta/2;
        double swLng=viewRegion.center.longitude-viewRegion.span.longitudeDelta/2;
        
        CLLocationCoordinate2D sw = CLLocationCoordinate2DMake(swLat, swLng);
        
        [self.mapView zoomWithLatitudeLongitudeBoundsSouthWest:sw northEast:ne animated:YES];
        
        NSArray *a = [self.mapView annotations];
        
        for(int i = 0; i < [a count]; i++) {
            RMAnnotation *m =  [a objectAtIndex:i];
            CLLocationCoordinate2D c = m.coordinate;
            if([m isMemberOfClass:[MapAnnotation class]]
               && [(MapAnnotation *)m index] > 0
               && [self.math firstDouble:c.latitude isEqualTo:self.centerLoc.latitude]
               && [self.math firstDouble:c.longitude isEqualTo:self.centerLoc.longitude]) {
                [self showCalloutForMapAnnotation:(MapAnnotation *)m withAccessoryBtn:![self isPreSaveView] animated:YES];
                break;
            }
        }
        
    }
    
}

- (void)viewDidLoad
{
    //    NSLog(@"viewDidLoad for mapcontroller %@", self);
    
    [super viewDidLoad];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    MathUtils * mat = [[MathUtils alloc] init];
    self.math = mat;
    [mat release];
    
    RepWalletAppDelegate *app = (RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    CGRect rect = CGRectMake(self.view.bounds.origin.x,
                             self.view.bounds.origin.y,
                             self.view.bounds.size.width,
                             self.view.bounds.size.height
                             );
    
    RMMapView * r = [[RMMapView alloc] initWithFrame:rect];
    
    self.mapView = r;
    
    [r release];
    
    self.mapView.decelerationMode = RMMapDecelerationOff;
    
    self.mapView.debugTiles = NO;
    
    if (app.isRetina) {
        
        self.mapView.adjustTilesForRetinaDisplay = YES;
        
    } else {
        
        self.mapView.adjustTilesForRetinaDisplay = NO;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults stringForKey:MAP_TYPE_SETTING_KEY]) {
        self.mapView.tileSource = [[[NSClassFromString([defaults stringForKey:MAP_TYPE_SETTING_KEY]) alloc] init] autorelease];
    }
    
	[[self view] addSubview:mapView];
    
    self.mapView.delegate = self;
    
    self.mapView.showsUserLocation = YES;
    
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth
    | UIViewAutoresizingFlexibleHeight
    | UIViewAutoresizingFlexibleRightMargin
    | UIViewAutoresizingFlexibleBottomMargin;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tileNotification:)
                                                 name:RMTileRequested object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tileNotification:)
                                                 name:RMTileRetrieved object:nil];
    
    
    MoreInfoView * m = [[MoreInfoView alloc] initWithTarget:self];
    
    m.mapView = self.mapView;
    
    self.moreInfoView = m;
    
    [m release];
    
    self.moreInfoView.delegate = self;
    
    self.moreInfoView.frame = CGRectMake(20.0,
                                         self.view.bounds.origin.y
                                         + self.view.bounds.size.height
                                         + 10,
                                         self.moreInfoView.frame.size.width,
                                         self.moreInfoView.frame.size.height);
    
    [self.view addSubview:self.moreInfoView];
    
    if ([self isPreSaveView] && ![self mapIsForVisualizationOnly]) {
        
        UIBarButtonItem * bi = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(postEndEditingNotification)];
        self.navigationItem.rightBarButtonItem = bi;
        [bi release];
        
        bi = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(getBack)];
        [bi setStyle:UIBarButtonItemStyleBordered];
        self.navigationItem.leftBarButtonItem = bi;
        [bi release];
        
    } else if(self.longPressureEnabled) {
        
        RevGeocoder *g = [[RevGeocoder alloc] init];
        
        self.geocoderV2 = g;
        
        [g release];
        
        self.geocoderV2.delegate = self;
        
    } else if(self.geoFilteringEnabled) {
        
        UIBarButtonItem * bi = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(geoFilteredData)];
        self.navigationItem.rightBarButtonItem = bi;
        [bi release];
        self.title = @"Set Area";
        
        if(self.filterBBox) {
            
            [self.mapView addAnnotation:self.filterBBox];
            
        } else if(CLLocationCoordinate2DIsValid(self.filterBBoxNorthEast)
                  && CLLocationCoordinate2DIsValid(self.filterBBoxSouthWest)) {
            
            RMAnnotation * ann = [[RMAnnotation alloc] initWithMapView:self.mapView
                                                            coordinate:CLLocationCoordinate2DMake(self.filterBBoxNorthEast.latitude, self.filterBBoxNorthEast.longitude)
                                                              andTitle:nil];
            [ann setBoundingBoxCoordinatesSouthWest:self.filterBBoxSouthWest northEast:self.filterBBoxNorthEast];
            self.filterBBox = ann;
            
            [self.mapView addAnnotation:self.filterBBox];
            
            [ann release];
            
        }
    } else
        ;
    
    if (self.routePoints) {
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(getToRoot)
         name:ADDED_OR_EDITED_FIRM_NOTIFICATION
         object:nil];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(getToRoot)
         name:REMOVED_FIRM_NOTIFICATION
         object:nil];
        
        if(self.routeInstructions && [self.routeInstructions count] > 0) {
            
            InstructionsView * aView = [[InstructionsView alloc] initWithInstrus:self.routeInstructions
                                                                        andFrame:CGRectMake(0.0,
                                                                                            0.0,
                                                                                            self.view.bounds.size.width,
                                                                                            80)];
            self.instrView = aView;
            
            [aView release];
            
            self.instrView.autoresizingMask = UIViewAutoresizingFlexibleWidth
            | UIViewAutoresizingFlexibleRightMargin;
            
            self.instrView.delegate = self;
            
            [self.view addSubview:self.instrView];
        }
        
        TrafficIncidents * tr = [[TrafficIncidents alloc] init];
        
        self.traffic = tr;
        
        [tr release];
        
        self.traffic.delegate = self;
        
        TrafficIncidentsView * t = [[TrafficIncidentsView alloc] initWithFrame:CGRectMake(0.0,
                                                                                          -80,
                                                                                          self.view.bounds.size.width,
                                                                                          80)];
        self.trafficView = t;
        
        [t release];
        
        self.trafficView.autoresizingMask = UIViewAutoresizingFlexibleWidth
        | UIViewAutoresizingFlexibleRightMargin;
        
        self.trafficView.delegate = self;
        
        [self.view addSubview:self.trafficView];
        
        [self addRouteToMap];
        
        if (self.trafficIncidents) {
            [self addTrafficIncidents:self.trafficIncidents];
        }
    }
    
    disableAnnotationAnimation = NO;
    
    [self addMapAnnotations:NO];
}

- (void)viewDidUnload
{
    //    NSLog(@"viewDidUnload for mapcontroller %@", self);
    
    if (self.moreInfoView)
        self.moreInfoView.delegate = nil;
    if (self.geocoderV2)
        self.geocoderV2.delegate = nil;
    if (self.instrView)
        self.instrView.delegate = nil;
    if (self.traffic)
        self.traffic.delegate = nil;
    if (self.trafficView)
        self.trafficView.delegate = nil;
    if (self.addEditVC)
        self.addEditVC.delegate = nil;
    if (self.mapView)
        self.mapView.delegate = nil;
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:RMTileRequested
                                                  object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:RMTileRetrieved
                                                  object:nil];
    
    if (self.routePoints) {
        
        [[NSNotificationCenter defaultCenter]
         removeObserver:self
         name:ADDED_OR_EDITED_FIRM_NOTIFICATION
         object:nil];
        
        [[NSNotificationCenter defaultCenter]
         removeObserver:self
         name:REMOVED_FIRM_NOTIFICATION
         object:nil];
    }
    
    self.mapView = nil;
    
    self.moreInfoView = nil;
    
    self.math = nil;
    
    self.instrView = nil;
    
    self.geocoderV2 = nil;
    
    self.trafficView = nil;
    
    self.traffic = nil;
    
    self.trafficIncidents = nil;
    
    self.filterBBox = nil;
    
    if (self.routeOverlay) {
        [self.routeOverlay setRoute:nil];
        [self.routeOverlay setMapView:nil isPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
        self.routeOverlay.hidden = YES;
    }
    
    self.addEditVC = nil;
    
    [super viewDidUnload];
}

- (void)dealloc
{
    
    //    NSLog(@"dealloc for mapcontroller %@", self);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (self.moreInfoView)
        self.moreInfoView.delegate = nil;
    if (self.geocoderV2)
        self.geocoderV2.delegate = nil;
    if (self.instrView)
        self.instrView.delegate = nil;
    if (self.traffic)
        self.traffic.delegate = nil;
    if (self.trafficView)
        self.trafficView.delegate = nil;
    if (self.addEditVC)
        self.addEditVC.delegate = nil;
    if (self.mapView)
        self.mapView.delegate = nil;
    
    [self.addEditVC release];
    [self.filterBBox release];
    [self.routeOverlay release];
    [self.routePoints release];
    [self.routeInstructions release];
    [self.dao release];
    [self.dataSourceArray release];
    [self.moreInfoView release];
    [self.geocoderV2 release];
    [self.mapView release];
    [self.math release];
    [self.traffic release];
    [self.trafficIncidents release];
    [self.trafficView release];
    [self.instrView release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    //    NSLog(@"didReceiveMemoryWarning for mapcontroller %@", self);
    
    [super didReceiveMemoryWarning];
    
    // only want to do this on iOS 6
    if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
        //  Don't want to rehydrate the view if it's already unloaded
        BOOL isLoaded = [self isViewLoaded];
        
        //  We check the window property to make sure that the view is not visible
        if (isLoaded && self.view.window == nil) {
            
            //  Give a chance to implementors to get model data from their views
            [self performSelectorOnMainThread:@selector(viewWillUnload)
                                   withObject:nil
                                waitUntilDone:YES];
            
            //  Detach it from its parent (in cases of view controller containment)
            [self.view removeFromSuperview];
            self.view = nil;    //  Clear out the view.  Goodbye!
            
            //  The view is now unloaded...now call viewDidUnload
            [self performSelectorOnMainThread:@selector(viewDidUnload)
                                   withObject:nil
                                waitUntilDone:YES];
        }
    }
}

#pragma mark -
#pragma mark Notifications

- (void)tileNotification:(NSNotification *)notification
{
	static int outstandingTiles = 0;
    
	if (notification.name == RMTileRequested)
		outstandingTiles++;
	else if(notification.name == RMTileRetrieved)
		outstandingTiles--;
    
	[(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate]
     setNetworkActivityIndicatorVisible:(outstandingTiles > 0) force:NO];
}

- (void)postEndEditingNotification
{
    BOOL saveFirm = NO;
    BOOL saveEvt = NO;
    BOOL saveUnp = NO;
    
    for (id<Mappable> m in self.dataSourceArray) {
        
        if ([m isMemberOfClass:[Firm class]]) {
            
            saveFirm = YES;
            
        } else if ([m isMemberOfClass:[Event class]]) {
            
            saveEvt = YES;
            
        } else if ([m isMemberOfClass:[UnpaidInvoice class]]) {
            
            saveUnp = YES;
            
        }
    }
    
    [self.navigationController popViewControllerAnimated:NO];
    
    if (saveFirm) {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(mapControllerEndedEditingForObjectOfClass:)]) {
            [self.delegate mapControllerEndedEditingForObjectOfClass:NSStringFromClass([Firm class])];
        }
    }
    
    if (saveEvt) {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(mapControllerEndedEditingForObjectOfClass:)]) {
            [self.delegate mapControllerEndedEditingForObjectOfClass:NSStringFromClass([Event class])];
        }
    }
    
    if (saveUnp) {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(mapControllerEndedEditingForObjectOfClass:)]) {
            [self.delegate mapControllerEndedEditingForObjectOfClass:NSStringFromClass([UnpaidInvoice class])];
        }
    }
}

- (void) postCancelEditingNotification
{
    BOOL cancelFirmEdit = NO;
    BOOL cancelEvtEdit = NO;
    BOOL cancelUnpEdit = NO;
    
    for (id<Mappable> m in self.dataSourceArray) {
        
        if ([m isMemberOfClass:[Firm class]]) {
            
            cancelFirmEdit = YES;
            
        } else if ([m isMemberOfClass:[Event class]]) {
            
            cancelEvtEdit = YES;
            
        } else if ([m isMemberOfClass:[UnpaidInvoice class]]) {
            
            cancelUnpEdit = YES;
            
        }
    }
    
    if (cancelFirmEdit) {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(mapControllerCanceledEditingForObjectOfClass:)]) {
            [self.delegate mapControllerCanceledEditingForObjectOfClass:NSStringFromClass([Firm class])];
        }
    }
    
    if (cancelEvtEdit) {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(mapControllerCanceledEditingForObjectOfClass:)]) {
            [self.delegate mapControllerCanceledEditingForObjectOfClass:NSStringFromClass([Event class])];
        }
    }
    
    if (cancelUnpEdit) {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(mapControllerCanceledEditingForObjectOfClass:)]) {
            [self.delegate mapControllerCanceledEditingForObjectOfClass:NSStringFromClass([UnpaidInvoice class])];
        }
    }
}

#pragma mark -
#pragma mark Reverse geocoder delegate

-(void)revGeocoderFailedWithError:(NSString *)errorMsg
{
    [(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO force:NO];
    
    NSString * s = @"";
    
    if (errorMsg) {
        s = errorMsg;
    }
    
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while obtaining customer address. %@", s] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
	[alertView show];
	[alertView release];
}

-(void)revGeocoderFoundAddress:(RevGeocoderResponse *)address
{
    [(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO force:NO];
    
    Firm *f = [(Firm *)[NSManagedObject alloc] initWithEntity:[self.dao getEntityDescriptionForName:NSStringFromClass([Firm class])] insertIntoManagedObjectContext:nil];
    [f setInsertDate:[NSDate date]];
    [f setZip:address.postalCode];
    [f setCountry:address.countryRegion];
    [f setState:address.adminDistrict];
    [f setTown:address.locality];
    [f setStreet:address.addressLine];
    [f setLatitude:[NSNumber numberWithDouble:address.point.coordinate.latitude]];
    [f setLongitude:[NSNumber numberWithDouble:address.point.coordinate.longitude]];
    
    AddEditViewController *viewController = [[AddEditViewController alloc] initWithStyle:UITableViewStylePlain title:ADDEDITVIEWCONTROLLER_INSERT_MODE_TITLE entity:f andDao:self.dao];
    self.addEditVC = viewController;
    [viewController release];
    self.addEditVC.delegate = self;
    [self.navigationController pushViewController:self.addEditVC animated:YES];
    
    [f release];
}

#pragma mark -
#pragma mark Reverse geocoding

// metodo chiamato al completamento dell'aggiunta/modifica di una Firm
- (void)addEditViewControllerAsksDataReloadAndUpdateOfMapCenter:(CLLocation *)center
{
    self.dataSourceArray = [self.dao getFirmsExcludingPending:YES excludingSubentities:YES withSorting:NO propsToFetch:nil];
    
    if ([self.dataSourceArray count] > 0) {
        
        self.centerLoc = center.coordinate;
        
        self.centerLocSpecified = YES;
        
        disableAnnotationAnimation = NO;
        
        [self addMapAnnotations:YES];
        
    }
}

- (void)longSingleTapOnMap:(RMMapView *)map at:(CGPoint)point
{
    if (self.longPressureEnabled) {
        CLLocationCoordinate2D touchMapCoordinate = [self.mapView pixelToCoordinate:point];
        
        [self reverseGeocodeLocation:touchMapCoordinate];
    }
}

- (void)reverseGeocodeLocation:(CLLocationCoordinate2D)locationCoordinate 
{
    [(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES force:NO];
    [self.geocoderV2 startGeocodingWithLatitude:locationCoordinate.latitude longitude:locationCoordinate.longitude];     
}


@end
