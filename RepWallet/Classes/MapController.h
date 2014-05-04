//
//  MapController.h
//  repWallet
//
//  Created by Alberto Fiore on 2/10/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "Firm.h"
#import "DAO.h"
#import "Mappable.h"
#import "RMMapView.h"
#import "MoreInfoView.h"
#import "MathUtils.h"
#import "TrafficIncidents.h"
#import "TrafficIncidentsView.h"
#import "InstructionsView.h"
#import "RevGeocoder.h"
#import "RouteOverlay.h"
#import "AddEditViewControllerDelegate.h"
#import "AddEditViewController.h"

#define METERS_PER_MILE 1609.344

@protocol MapControllerDelegate <NSObject>

@optional

-(void) mapControllerEndedEditingForObjectOfClass:(NSString *)clazz;
-(void) mapControllerCanceledEditingForObjectOfClass:(NSString *)clazz;
-(void) mapControllerUpdatedLocation:(CLLocation *)location forObjectOfClass:(NSString *)clazz;
-(void) mapControllerGeoFilteredLocationsWithNorthEastBoundingLocation:(CLLocation *)ne southWestBoundingLocation:(CLLocation *)sw;
@end

@interface MapController : UIViewController <RMMapViewDelegate, CLLocationManagerDelegate, RevGeocoderDelegate, TrafficIncidentsDelegate, MoreInfoViewDelegate, InstructionsViewDelegate, TrafficIncidentsViewDelegate, AddEditViewControllerDelegate> 
{
    CGPoint lastContentOffset;
    CGPoint lastDraggingTranslation;
    BOOL disableAnnotationAnimation;
    RMProjectedRect projRectPriorToRotation;
}

@property (nonatomic, assign) id<MapControllerDelegate> delegate;

@property (nonatomic, retain) AddEditViewController* addEditVC;
@property (nonatomic, retain) RouteOverlay* routeOverlay;
@property (nonatomic, retain) RMMapView* mapView;
@property (nonatomic, retain) RevGeocoder * geocoderV2;
@property (nonatomic, retain) DAO *dao;
@property (nonatomic, retain) NSArray *dataSourceArray;
@property (nonatomic, assign, getter=isPreSaveView) BOOL preSaveView;
@property (nonatomic, assign) double zoomSpanMiles; // number of miles that the map will span longitudinally and latitudinally
@property (nonatomic, assign) MKCoordinateRegion bBoxForZoom;
@property (nonatomic, assign) CLLocationCoordinate2D centerLoc;
@property (nonatomic, assign, getter=centerLocHasBeenSpecified) BOOL centerLocSpecified;
@property (nonatomic, assign, getter=mapIsForVisualizationOnly) BOOL onlyForVisualization; // to disable annotation addition/editing
@property (nonatomic, assign) BOOL longPressureEnabled;
@property (nonatomic, retain) NSArray * routeInstructions;
@property (nonatomic, retain) MoreInfoView* moreInfoView;
@property (nonatomic, retain) MathUtils *math;
@property (nonatomic, retain) TrafficIncidents *traffic;
@property (nonatomic, retain) NSArray *trafficIncidents;
@property (nonatomic, retain) TrafficIncidentsView *trafficView;
@property (nonatomic, retain) InstructionsView *instrView;
@property (nonatomic, retain) NSArray * routePoints;
@property (nonatomic, assign) MKCoordinateRegion bBoxForRoute;
@property (nonatomic, assign) BOOL geoFilteringEnabled;
@property (nonatomic, assign) CLLocationCoordinate2D filterBBoxNorthEast;
@property (nonatomic, assign) CLLocationCoordinate2D filterBBoxSouthWest;
@property (nonatomic, retain) RMAnnotation * filterBBox;

- (void) postEndEditingNotification;
- (void) postCancelEditingNotification;

- (id) init;
- (id) initWithArray:(NSArray *)mappablesArray routePoints:(NSArray *)routePoints boundingBoxForRoute:(MKCoordinateRegion)bBoxForRoute routeInstructions:(NSArray *)routeInstructions andDao:(DAO *)aDao;
- (id) initWithArray:(NSArray *)mappablesArray andDao:(DAO *)aDao geoFilteringEnabled:(BOOL)geoFilteringEnabled ne:(CLLocationCoordinate2D)ne sw:(CLLocationCoordinate2D)sw;
- (id) initWithArray:(NSArray *)mappablesArray andDao:(DAO *)dao isPreSave:(BOOL)isPreSaveView longPressureEnabled:(BOOL)longPressureEnabled;
- (id) initWithArray:(NSArray *)mappablesArray andDao:(DAO *)aDao isPreSave:(BOOL)isPreSaveView zoomLvl:(double)zoomLvl longPressureEnabled:(BOOL)longPressureEnabled;
- (id) initWithArray:(NSArray *)mappablesArray andDao:(DAO *)aDao isPreSave:(BOOL)isPreSaveView centerLocation:(CLLocationCoordinate2D) centerLoc zoomLvl:(double)zoomLvl longPressureEnabled:(BOOL)longPressureEnabled;
- (id) initWithArray:(NSArray *)mappablesArray andDao:(DAO *)aDao isPreSave:(BOOL)isPreSaveView bBoxForZoom:(MKCoordinateRegion)bBoxForZoom longPressureEnabled:(BOOL)longPressureEnabled;

- (void) reverseGeocodeLocation:(CLLocationCoordinate2D)locationCoordinate;
- (void) addRouteToMap;
- (void) accessoryBtnClicked:(UIButton *)sender;
- (void) addMapAnnotations: (BOOL)isReloading;

@end